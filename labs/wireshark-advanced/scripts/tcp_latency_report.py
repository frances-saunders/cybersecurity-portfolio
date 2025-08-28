#!/usr/bin/env python3
"""
Compute TCP handshake time, RTT stats, retransmission counts, and zero-window events per 5-tuple.
Outputs CSV & Markdown summary for executive readability.

Requires: tshark in PATH.
"""
import argparse, csv, json, subprocess, shutil, statistics, sys
from collections import defaultdict

def tshark_available():
    return shutil.which("tshark") is not None

# Pull fields needed for RTT & reliability
FIELDS = [
    "frame.time_epoch",
    "ip.src","ip.dst","tcp.srcport","tcp.dstport",
    "tcp.stream",
    "tcp.analysis.ack_rtt",
    "tcp.analysis.retransmission",
    "tcp.analysis.zero_window",
    "tcp.flags.syn","tcp.flags.ack"
]

def run_tshark(pcap):
    cmd = ["tshark","-r",pcap,"-T","fields"]
    for f in FIELDS:
        cmd += ["-e", f]
    cmd += ["-E","separator=,","-E","quote=d","-E","header=y"]
    return subprocess.check_output(cmd, text=True, errors="ignore")

def parse_csv(text):
    lines = text.splitlines()
    hdr = [h.strip('"') for h in lines[0].split(",")]
    rows = []
    for line in lines[1:]:
        if not line.strip(): continue
        parts = [p.strip('"') for p in line.split(",")]
        rows.append(dict(zip(hdr, parts)))
    return rows

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-r","--read",required=True)
    ap.add_argument("-o","--out-prefix",required=True)
    args = ap.parse_args()

    if not tshark_available():
        print("ERROR: tshark not found in PATH", file=sys.stderr)
        sys.exit(2)

    rows = parse_csv(run_tshark(args.read))

    flows = defaultdict(lambda: {"rtts":[], "retrans":0, "zero":0, "first_syn":None, "first_synack":None, "client":None, "server":None})
    for r in rows:
        src, dst = r["ip.src"], r["ip.dst"]
        sp, dp = r["tcp.srcport"], r["tcp.dstport"]
        stream = r.get("tcp.stream","")
        key = (stream, src, sp, dst, dp)

        syn = r.get("tcp.flags.syn","") == "1"
        ack = r.get("tcp.flags.ack","") == "1"
        ts  = float(r["frame.time_epoch"])
        if syn and not ack:
            flows[stream]["first_syn"] = ts
            flows[stream]["client"] = f"{src}:{sp}"
        elif syn and ack:
            flows[stream]["first_synack"] = ts
            flows[stream]["server"] = f"{src}:{sp}"

        if r.get("tcp.analysis.ack_rtt",""):
            try: flows[stream]["rtts"].append(float(r["tcp.analysis.ack_rtt"]))
            except: pass
        if r.get("tcp.analysis.retransmission","") == "1":
            flows[stream]["retrans"] += 1
        if r.get("tcp.analysis.zero_window","") == "1":
            flows[stream]["zero"] += 1

    out_rows = []
    for sid, stats in flows.items():
        syn, synack = stats["first_syn"], stats["first_synack"]
        hs = (synack - syn) if (syn and synack) else None
        rtts = stats["rtts"]
        row = {
            "tcp.stream": sid,
            "client": stats["client"] or "",
            "server": stats["server"] or "",
            "handshake_sec": round(hs, 6) if hs else "",
            "rtt_median_ms": round(statistics.median(rtts)*1000, 2) if rtts else "",
            "retransmissions": stats["retrans"],
            "zero_window_events": stats["zero"]
        }
        out_rows.append(row)

    csv_path = f"{args.out_prefix}.csv"
    with open(csv_path,"w",newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out_rows[0].keys()) if out_rows else ["tcp.stream"])
        w.writeheader()
        for r in out_rows: w.writerow(r)

    md_path = f"{args.out_prefix}.md"
    with open(md_path,"w") as f:
        f.write("# TCP Latency Report\n\n")
        f.write("| stream | client | server | handshake(s) | rtt_median(ms) | retrans | zero win |\n")
        f.write("|---|---|---|---:|---:|---:|---:|\n")
        for r in out_rows:
            f.write(f"| {r['tcp.stream']} | {r['client']} | {r['server']} | {r['handshake_sec']} | {r['rtt_median_ms']} | {r['retransmissions']} | {r['zero_window_events']} |\n")

    print(f"Wrote {csv_path} and {md_path} (flows={len(out_rows)})")

if __name__ == "__main__":
    main()
