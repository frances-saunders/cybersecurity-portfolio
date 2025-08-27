#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ssp-skeleton-exporter.py
Produce a minimal System Security Plan (SSP) skeleton in Markdown
based on current policy/evidence CSV and environment metadata.

Inputs
- evidence CSV (from collect-nist-evidence.ps1 or similar)
- meta JSON with fields: system_name, owner, mission, data_types, boundaries, contacts:{...}

Usage
  python ssp-skeleton-exporter.py --evidence nist-evidence.csv --meta env.json --out ssp.md
"""

import argparse, json, pandas as pd, datetime as dt, sys

TEMPLATE = """# System Security Plan (Skeleton)

**System Name:** {system_name}  
**Owner:** {owner}  
**Mission/Function:** {mission}  
**Information Types:** {data_types}  
**System Boundary:** {boundaries}  
**Contacts:** {contacts}

## 1. Control Implementation Summary
Generated: {now}

| Control | ComplianceState | Evidence Count |
|--------|------------------|----------------|
{table_rows}

## 2. Inherited/Shared Controls
Describe controls provided by enterprise services (e.g., identity, network).

## 3. Continuous Monitoring Strategy
- Policy evaluation cadence
- Metrics and dashboards references
- Event sources and coverage

## 4. Residual Risk & POA&M Link
Link to current POA&M artifacts and risk acceptance statements.

"""

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--evidence", required=True)
    ap.add_argument("--meta", required=True)
    ap.add_argument("--out", default="ssp.md")
    args = ap.parse_args()

    meta = json.load(open(args.meta))
    df = pd.read_csv(args.evidence)
    grp = df.groupby(["PolicyDefinitionId","ComplianceState"]).size().reset_index(name="count")

    rows = []
    for _, r in grp.iterrows():
        ctrl = r["PolicyDefinitionId"]
        state = r["ComplianceState"]
        rows.append(f"| {ctrl} | {state} | {int(r['count'])} |")
    table = "\n".join(rows) if rows else "| _no data_ | _n/a_ | 0 |"

    md = TEMPLATE.format(
        system_name = meta.get("system_name","Unnamed System"),
        owner = meta.get("owner","security@company.tld"),
        mission = meta.get("mission",""),
        data_types = ", ".join(meta.get("data_types",[])),
        boundaries = meta.get("boundaries",""),
        contacts = json.dumps(meta.get("contacts",{})),
        now = dt.datetime.utcnow().isoformat() + "Z",
        table_rows = table
    )
    with open(args.out, "w", encoding="utf-8") as f:
        f.write(md)
    print(json.dumps({"out": args.out}))

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)})); sys.exit(1)
