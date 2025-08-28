#!/usr/bin/env python3
"""
IOC extractor using tshark. Pulls SNI, DNS, HTTP Host/URI, TLS meta, and basic flow stats.
- Works without decryption; leverages metadata and headers.
- Attempts JA3/JA3S via tshark fields if available; else computes a 'lite' fingerprint.

Requires: tshark in PATH.
"""
import argparse, csv, json, subprocess, shutil, sys
from collections import defaultdict

FIELDS = [
    "frame.time_epoch",
    "ip.src","ip.dst","tcp.dstport","udp.dstport",
    "dns.qry.name",
    "http.host","http.request.full_uri",
    "tls.handshake.extensions_server_name",
    "tls.handshake.extensions_alpn_str",
    "tls.version",
    "tls.handshake.ja3","tls.handshake.ja3s"  # may not exist in all builds
]

def tshark_available():
    return shutil.which("tshark") is not None

def run_tshark(pcap):
    cmd = ["tshark","-r",pcap,"-T","fields"]
    for f in FIELDS:
        cmd += ["-e", f]
    cmd += ["-E","separator=,","-E","quote=d","-E","header=y"]
    # decode 443 as TLS to expose fields
    cmd += ["-d","tcp.port==443,ssl"]
    return subprocess.check_output(cmd, text=True, errors="ignore")

def lite_tls_fp(row):
    # Build a deterministic lite fingerprint from known columns
    alpn = row.get("tls.handshake.extensions_alpn_str","") or ""
    ver = row.get("tls.version","") or ""
    sni = row.get("tls.handshake.extensions_server_name","") or ""
    return f"litefp|ver:{ver}|alpn:{alpn}|sni_len:{len(sni)}"

def parse_csv(text):
    lines = text.splitlines()
    hdr = [h.strip('"') for h in lines[0].split(",")]
    rows = []
    for line in lines[1:]:
        if not line.strip(): continue
        parts = [p.strip('"') for p in line.split(",")]
        row = dict(zip(hdr, parts))
        rows.append(row)
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-r","--read",required=True,help="pcap file")
    ap.add_argument("-o","--out-prefix",required=True,help="output prefix (no extension)")
    args = ap.parse_args()

    if not tshark_available():
        print("ERROR: tshark not found in PATH", file=sys.stderr)
        sys.exit(2)

    text = run_tshark(args.read)
    rows = parse_csv(text)

    # Normalize and enrich
    out = []
    for r in rows:
        ts = r.get("frame.time_epoch","")
        src, dst = r.get("ip.src",""), r.get("ip.dst","")
        dport = r.get("tcp.dstport","") or r.get("udp.dstport","")
        sni = r.get("tls.handshake.extensions_server_name","")
        alpn = r.get("tls.handshake.extensions_alpn_str","")
        tls_ver = r.get("tls.version","")
        dnsq = r.get("dns.qry.name","")
        host, uri = r.get("http.host",""), r.get("http.request.full_uri","")
        ja3 = r.get("tls.handshake.ja3","") or r.get("tls.handshake.ja3s","")
        if not ja3:
            ja3 = lite_tls_fp(r)

        if any([sni, dnsq, host, uri]):  # keep only rows with potential indicators
            out.append({
                "timestamp": ts,
                "src_ip": src, "dst_ip": dst, "dst_port": dport,
                "sni": sni, "dns_qry": dnsq, "http_host": host, "uri": uri,
                "alpn": alpn, "tls_version": tls_ver, "ja3": ja3
            })

    # Write JSON and CSV
    json_path = f"{args.out_prefix}.json"
    csv_path = f"{args.out_prefix}.csv"
    with open(json_path,"w") as f:
        json.dump(out, f, indent=2)
    with open(csv_path,"w",newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()) if out else ["timestamp"])
        w.writeheader()
        for row in out: w.writerow(row)

    print(f"Wrote {json_path} and {csv_path} (rows={len(out)})")

if __name__ == "__main__":
    main()
