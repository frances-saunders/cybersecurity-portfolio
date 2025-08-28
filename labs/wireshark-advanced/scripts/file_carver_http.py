#!/usr/bin/env python3
"""
Carve HTTP objects from a PCAP using tshark, safely writing files and a manifest.
- Only extracts responses with content-length <= MAX_BYTES (default 20MB).
- Hashes every file (SHA256) and records original stream/host/uri.

Requires: tshark in PATH.
"""
import argparse, hashlib, json, os, re, shutil, subprocess, sys
from pathlib import Path

MAX_BYTES = 20 * 1024 * 1024

def tshark_available():
    return shutil.which("tshark") is not None

def safe_name(s: str) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+","_", s)[:120]

def export_http_objects(pcap, out_dir):
    # Use tshark to write HTTP objects (alt: use wireshark GUI)
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # Dump HTTP responses into PDML, then reconstruct payloads via tcp.stream boundaries (portable way)
    # Simpler approach: leverage 'tshark -z proto,colinfo,http.request.full_uri' is not enough for payloads.
    # Here we use 'tshark -r -Y http -T fields' to enumerate candidates, then call 'tshark -x' per packet range.
    listing = subprocess.check_output([
        "tshark","-r",pcap,"-Y","http.response && http.content_length",
        "-T","fields","-e","frame.number","-e","ip.src","-e","ip.dst",
        "-e","http.host","-e","http.request.uri","-e","http.content_type","-e","http.content_length",
        "-E","separator=,","-E","quote=d","-E","header=y"
    ], text=True, errors="ignore").splitlines()

    hdr = [h.strip('"') for h in listing[0].split(",")] if listing else []
    recs = []
    for line in listing[1:]:
        if not line.strip(): continue
        parts = [p.strip('"') for p in line.split(",")]
        row = dict(zip(hdr, parts))
        try:
            clen = int(row.get("http.content_length","0"))
        except:
            clen = 0
        if clen <= 0 or clen > MAX_BYTES:  # size guard
            continue

        frame_no = row["frame.number"]
        raw = subprocess.check_output(["tshark","-r",pcap,"-Y",f"frame.number=={frame_no}","-x"], text=True, errors="ignore")
        # Extract raw TCP payload bytes from hex dump
        hex_bytes = []
        for hl in raw.splitlines():
            if re.match(r"^\s*[0-9a-fA-F]{4}\s", hl):
                chunk = "".join(hl.split()[1:17])  # 16 bytes columns
                hex_bytes.append(chunk)
        try:
            blob = bytes.fromhex("".join(hex_bytes))
        except Exception:
            continue

        # naive HTTP response split: headers \r\n\r\n boundary
        m = blob.find(b"\r\n\r\n")
        if m == -1: 
            continue
        body = blob[m+4:]
        if len(body) < 1: 
            continue

        fname = safe_name(f"{row.get('http.host','')}_{row.get('http.request.uri','/')}_{frame_no}")
        fpath = out_dir / f"{fname}.bin"
        with open(fpath,"wb") as f: f.write(body)
        sha = hashlib.sha256(body).hexdigest()
        recs.append({
            "frame": frame_no,
            "src": row.get("ip.src",""),
            "dst": row.get("ip.dst",""),
            "host": row.get("http.host",""),
            "uri": row.get("http.request.uri",""),
            "content_type": row.get("http.content_type",""),
            "size": len(body),
            "sha256": sha,
            "file": str(fpath)
        })
    return recs

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-r","--read",required=True,help="pcap file")
    ap.add_argument("-o","--outdir",required=True,help="output directory")
    args = ap.parse_args()

    if not tshark_available():
        print("ERROR: tshark not found in PATH", file=sys.stderr)
        sys.exit(2)

    records = export_http_objects(args.read, args.outdir)
    manifest = os.path.join(args.outdir,"manifest.json")
    with open(manifest,"w") as f:
        json.dump(records, f, indent=2)
    print(f"[carver] wrote {len(records)} files; manifest={manifest}")

if __name__ == "__main__":
    main()
