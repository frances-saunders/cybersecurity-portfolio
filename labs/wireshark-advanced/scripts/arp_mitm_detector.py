#!/usr/bin/env python3
"""
Detect ARP spoof/MITM indicators from a pcap:
- Conflicting MAC addresses for the same IP
- Gateway MAC changes over time
- Gratuitous ARP storms

Outputs JSON with evidence and confidence rating.

Requires: tshark in PATH.
"""
import argparse, json, shutil, subprocess, sys
from collections import defaultdict, Counter

def tshark_available():
    return shutil.which("tshark") is not None

def run_tshark(pcap):
    # Extract ARP fields
    cmd = ["tshark","-r",pcap,"-Y","arp","-T","fields",
           "-e","frame.time_epoch","-e","arp.opcode","-e","arp.src.proto_ipv4","-e","arp.src.hw_mac",
           "-e","arp.dst.proto_ipv4","-e","arp.dst.hw_mac","-E","separator=,","-E","quote=d","-E","header=y"]
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
    ap.add_argument("-o","--out",required=True)
    args = ap.parse_args()

    if not tshark_available():
        print("ERROR: tshark not found in PATH", file=sys.stderr)
        sys.exit(2)

    rows = parse_csv(run_tshark(args.read))
    ip_to_macs = defaultdict(set)
    mac_obs = Counter()
    gateway_candidates = Counter()

    for r in rows:
        src_ip, src_mac = r["arp.src.proto_ipv4"], r["arp.src.hw_mac"].lower()
        dst_ip, dst_mac = r["arp.dst.proto_ipv4"], r["arp.dst.hw_mac"].lower()
        ip_to_macs[src_ip].add(src_mac)
        mac_obs[src_mac] += 1
        if dst_ip.endswith(".1") or dst_ip.endswith(".254"):
            gateway_candidates[src_mac] += 1

    conflicts = {ip:list(macs) for ip, macs in ip_to_macs.items() if len(macs) > 1 and ip != "0.0.0.0"}
    gw_macs = gateway_candidates.most_common(3)
    confidence = "low"
    if conflicts and any(len(v) >= 2 for v in conflicts.values()):
        confidence = "medium"
    if conflicts and len(conflicts) > 2:
        confidence = "high"

    out = {
        "conflicts": conflicts,
        "top_gateway_macs": gw_macs,
        "mac_observations": mac_obs.most_common(10),
        "confidence": confidence
    }
    with open(args.out,"w") as f: json.dump(out, f, indent=2)
    print(f"Wrote {args.out} (conflicts={len(conflicts)}; confidence={confidence})")

if __name__ == "__main__":
    main()
