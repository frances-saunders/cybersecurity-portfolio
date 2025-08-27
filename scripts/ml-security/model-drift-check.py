#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
model-drift-check.py
Track drift on key features using Population Stability Index (PSI) against a saved baseline.
Alert when thresholds exceed configured limits.

Usage:
  python model-drift-check.py --current current.csv --baseline baseline.json --columns f1 f2 f3 --out drift.json --psi-threshold 0.2

Requires:
  pip install pandas numpy
"""

import argparse, json, numpy as np, pandas as pd, sys

def psi(expected, actual, bins=10):
    e_perc, a_perc = np.histogram(expected, bins=bins)[0], np.histogram(actual, bins=bins)[0]
    e_perc = e_perc / max(e_perc.sum(), 1)
    a_perc = a_perc / max(a_perc.sum(), 1)
    a_perc = np.where(a_perc==0, 1e-6, a_perc); e_perc = np.where(e_perc==0, 1e-6, e_perc)
    return float(((a_perc - e_perc) * np.log(a_perc / e_perc)).sum())

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--current", required=True)
    ap.add_argument("--baseline", required=True, help="JSON with per-column baseline arrays or summary stats")
    ap.add_argument("--columns", nargs="+", required=True)
    ap.add_argument("--psi-threshold", type=float, default=0.2)
    ap.add_argument("--out", default="drift.json")
    args = ap.parse_args()

    cur = pd.read_csv(args.current)
    base = json.load(open(args.baseline))
    results = []
    alert = False
    for c in args.columns:
        if c not in cur.columns or c not in base:
            results.append({"column": c, "error":"missing"})
            continue
        p = psi(np.array(base[c], dtype=float), cur[c].astype(float).to_numpy(), bins=10)
        results.append({"column": c, "psi": round(p,4), "status": "ok" if p < args.psi_threshold else "drift"})
        if p >= args.psi_threshold:
            alert = True

    out = {"items": results, "alert": alert, "threshold": args.psi_threshold}
    json.dump(out, open(args.out,"w"), indent=2)
    print(json.dumps({"alert": alert, "out": args.out}))
    sys.exit(2 if alert else 0)

if __name__ == "__main__":
    main()
