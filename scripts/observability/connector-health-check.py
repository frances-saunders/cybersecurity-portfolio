#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
connector-health-check.py
Verify Sentinel connector health by checking ingestion in the last N minutes per expected table.

- Queries LA for record counts and latest TimeGenerated
- Emits JSON with status=ok/warn/critical based on thresholds
- No plaintext secrets: use AZ_TOKEN (AAD) or Managed Identity in CI where applicable

Requires:
  pip install requests
"""

import argparse, json, os, sys, time, requests
from datetime import datetime, timedelta

def la_query(workspace_id: str, kql: str, token: str) -> dict:
    url = f"https://api.loganalytics.io/v1/workspaces/{workspace_id}/query"
    headers = {"Content-Type":"application/json","Authorization": f"Bearer {token}"}
    r = requests.post(url, headers=headers, json={"query": kql}, timeout=30)
    r.raise_for_status()
    return r.json()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace-id", required=True)
    ap.add_argument("--tables", nargs="+", required=True, help="Tables to check, e.g., SecurityEvent OfficeActivity")
    ap.add_argument("--lookback-min", type=int, default=60)
    ap.add_argument("--critical-minutes", type=int, default=30, help="If last event older than this, critical")
    args = ap.parse_args()

    token = os.getenv("AZ_TOKEN")
    if not token:
        print(json.dumps({"error":"AZ_TOKEN not set"})); sys.exit(1)

    report = {"workspace": args.workspace_id, "lookback": args.lookback_min, "items": []}
    now = datetime.utcnow()

    for tbl in args.tables:
        kql = f"{tbl} | where TimeGenerated > ago({args.lookback_min}m) | summarize count(), max(TimeGenerated)"
        data = la_query(args.workspace_id, kql, token)
        if not data.get("tables"):
            report["items"].append({"table": tbl, "status":"warn", "detail":"no result"})
            continue
        cols = [c["name"] for c in data["tables"][0]["columns"]]
        rows = data["tables"][0]["rows"]
        if not rows:
            report["items"].append({"table": tbl, "status":"warn", "count": 0})
            continue
        cnt, last = rows[0]
        last_dt = datetime.fromisoformat(last.replace("Z","+00:00"))
        delta = (now - last_dt).total_seconds()/60.0
        status = "ok" if delta <= args.critical_minutes else "critical"
        report["items"].append({"table": tbl, "status": status, "count": int(cnt), "last": last, "lag_min": round(delta,1)})

    print(json.dumps(report, indent=2))
    if any(x["status"] == "critical" for x in report["items"]):
        sys.exit(2)

if __name__ == "__main__":
    main()
