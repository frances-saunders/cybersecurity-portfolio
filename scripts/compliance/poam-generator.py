#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
poam-generator.py
Generate a Plan of Actions & Milestones (POA&M) from a compliance evidence CSV
(e.g., output of collect-nist-evidence.ps1). Adds prioritization and target dates.

Inputs
- evidence CSV with columns: PolicyDefinitionId, ResourceId, ComplianceState, IsCompliant, Timestamp, ControlRef
- optional ownership mapping JSON: { "resourceGroupName": "owner@company.tld", ... }

Outputs
- poam.csv and poam.json

Usage
  python poam-generator.py --input nist-evidence.csv --owner-map owners.json --out-prefix poam
"""

import argparse, csv, datetime as dt, json, os, sys
import pandas as pd

SEVERITY_DEFAULTS = {"NonCompliant": "High", "Conflict": "Medium", "Compliant": "Info"}

def owner_for(resource_id: str, owner_map: dict) -> str:
    # Heuristic: pick owner by RG name
    rg = None
    parts = [p for p in resource_id.split("/") if p]
    if "resourceGroups" in parts:
        i = parts.index("resourceGroups")
        if i+1 < len(parts): rg = parts[i+1]
    return owner_map.get(rg or "", "security@company.tld")

def due_date_for(sev: str) -> str:
    days = {"High": 30, "Medium": 60, "Low": 90, "Info": 180}.get(sev, 60)
    return (dt.datetime.utcnow() + dt.timedelta(days=days)).date().isoformat()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--owner-map", help="JSON mapping RG->owner")
    ap.add_argument("--out-prefix", default="poam")
    args = ap.parse_args()

    df = pd.read_csv(args.input)
    owners = json.load(open(args.owner_map)) if args.owner_map else {}

    rows = []
    noncomp = df[df["IsCompliant"] == False]
    for _, r in noncomp.iterrows():
        sev = SEVERITY_DEFAULTS.get(str(r.get("ComplianceState")), "High")
        rows.append({
            "Control": r.get("ControlRef") or r.get("PolicyDefinitionId"),
            "ResourceId": r.get("ResourceId"),
            "CurrentState": r.get("ComplianceState"),
            "Severity": sev,
            "Owner": owner_for(r.get("ResourceId",""), owners),
            "Milestone": "Remediate control failure",
            "PlannedCompletion": due_date_for(sev),
            "LastObserved": r.get("Timestamp")
        })

    out_csv = f"{args.out_prefix}.csv"
    out_json = f"{args.out_prefix}.json"
    pd.DataFrame(rows).to_csv(out_csv, index=False)
    json.dump({"count": len(rows), "items": rows}, open(out_json, "w", encoding="utf-8"), indent=2)
    print(json.dumps({"count": len(rows), "csv": out_csv, "json": out_json}))

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)})); sys.exit(1)
