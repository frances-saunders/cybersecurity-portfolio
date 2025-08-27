#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
evidence-hash-manifest.py
Walk a directory, compute SHA-256 for each file, and produce a JSON/CSV manifest
for chain-of-custody and tamper detection.

Usage
  python evidence-hash-manifest.py --root ./evidence --out-json manifest.json --out-csv manifest.csv
"""

import argparse, csv, hashlib, json, os, sys
from datetime import datetime

def sha256_file(p: str) -> str:
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", required=True)
    ap.add_argument("--out-json", default="manifest.json")
    ap.add_argument("--out-csv", default="manifest.csv")
    args = ap.parse_args()

    items = []
    for d, _, files in os.walk(args.root):
        for fn in files:
            path = os.path.join(d, fn)
            rel = os.path.relpath(path, args.root)
            try:
                digest = sha256_file(path)
                items.append({"file": rel, "sha256": digest, "bytes": os.path.getsize(path)})
            except Exception as e:
                items.append({"file": rel, "error": str(e)})

    meta = {"generated": datetime.utcnow().isoformat() + "Z", "root": os.path.abspath(args.root), "count": len(items)}
    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump({"meta": meta, "items": items}, f, indent=2)

    with open(args.out_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["file","sha256","bytes"])
        w.writeheader()
        for it in items:
            if "sha256" in it:
                w.writerow({"file": it["file"], "sha256": it["sha256"], "bytes": it["bytes"]})

    print(json.dumps({"json": args.out_json, "csv": args.out_csv, "count": len(items)}))

if __name__ == "__main__":
    main()
