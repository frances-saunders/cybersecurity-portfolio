#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
detection-coverage-mapper.py
Parses KQL/SPL rule files for MITRE metadata and outputs a coverage matrix.

Conventions
- In rule headers/comments include YAML-like tags, e.g.:
  # tactics: TA0001, TA0003
  # techniques: T1059, T1078

Outputs
- coverage.json (tactic/technique -> rules)
- coverage.csv (rows=techniques, cols=[rule,file,tactics])

Usage
  python detection-coverage-mapper.py --rules-dir ./detections --out-json coverage.json --out-csv coverage.csv
"""

import argparse, json, os, re, csv
from typing import Dict, List

RX_TACTICS = re.compile(r"tactics\s*:\s*([A-Za-z0-9_,\s]+)", re.I)
RX_TECHS   = re.compile(r"techniques\s*:\s*([A-Za-z0-9_,\s]+)", re.I)

def scan_rules(root: str):
    items = []
    for d, _, files in os.walk(root):
        for fn in files:
            if not (fn.lower().endswith(".kql") or fn.lower().endswith(".spl")):
                continue
            path = os.path.join(d, fn)
            text = open(path, "r", encoding="utf-8", errors="ignore").read()
            tactics = []
            techs = []
            for m in RX_TACTICS.findall(text):
                tactics.extend([x.strip().upper() for x in m.split(",") if x.strip()])
            for m in RX_TECHS.findall(text):
                techs.extend([x.strip().upper() for x in m.split(",") if x.strip()])
            if tactics or techs:
                items.append({"file": os.path.relpath(path, root), "tactics": sorted(set(tactics)), "techniques": sorted(set(techs))})
    return items

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rules-dir", required=True)
    ap.add_argument("--out-json", default="coverage.json")
    ap.add_argument("--out-csv", default="coverage.csv")
    args = ap.parse_args()

    items = scan_rules(args.rules_dir)
    cov = {"tactics": {}, "techniques": {}}
    for it in items:
        for t in it["tactics"]:
            cov["tactics"].setdefault(t, []).append(it["file"])
        for te in it["techniques"]:
            cov["techniques"].setdefault(te, []).append(it["file"])

    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump({"items": items, "coverage": cov}, f, indent=2)

    with open(args.out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["file", "tactics", "techniques"])
        for it in items:
            w.writerow([it["file"], " ".join(it["tactics"]), " ".join(it["techniques"])])

    print(json.dumps({"rules": len(items), "json": args.out_json, "csv": args.out_csv}))

if __name__ == "__main__":
    main()
