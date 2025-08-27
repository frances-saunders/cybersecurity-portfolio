#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate-compliance-report.py
-----------------------------
Converts evidence CSV (e.g., from collect-nist-evidence.ps1) into an
executive-readable summary with coverage and failing controls.
Outputs both console summary and a JSON artifact for dashboards.

Example:
  python generate-compliance-report.py --input nist-evidence.csv --out-json summary.json
"""

import argparse, json, pandas as pd, sys

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--out-json", default="compliance-summary.json")
    args = ap.parse_args()

    try:
        df = pd.read_csv(args.input)
        total = len(df)
        by_state = df.groupby("ComplianceState").size().to_dict()
        failing = df[df["IsCompliant"] == False]["PolicyDefinitionId"].nunique()

        summary = {
            "total_records": total,
            "by_state": by_state,
            "unique_failing_controls": int(failing)
        }
        print("Compliance Summary")
        for k,v in by_state.items(): print(f"  {k}: {v}")
        print(f"  Unique failing controls: {failing}")

        with open(args.out_json, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=2)
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
