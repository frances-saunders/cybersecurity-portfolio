#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
log-lag-monitor.py
Measure end-to-end log latency: difference between ingestion_time() and event TimeGenerated.

- Emits JSON metric for Prometheus pushgateway or LA custom log ingestion
- Requires AZ_TOKEN and WORKSPACE_ID if writing back to LA (optional)

Usage:
  python log-lag-monitor.py --table SecurityEvent --window-min 15
"""

import argparse, json, os, sys, requests
from datetime import datetime

def la_query(workspace_id: str, kql: str, token: str) -> dict:
    url = f"https://api.loganalytics.io/v1/workspaces/{workspace_id}/query"
    headers = {"Content-Type":"application/json","Authorization": f"Bearer {token}"}
    r = requests.post(url, headers=headers, json={"query": kql}, timeout=30)
    r.raise_for_status()
    return r.json()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--workspace-id", required=True)
    ap.add_argument("--table", required=True)
    ap.add_argument("--window-min", type=int, default=15)
    args = ap.parse_args()

    token = os.getenv("AZ_TOKEN")
    if not token:
        print(json.dumps({"error":"AZ_TOKEN not set"})); sys.exit(1)

    kql = f"""
    {args.table}
    | where TimeGenerated > ago({args.window_min}m)
    | extend Ingested = ingestion_time()
    | extend LagMin = datetime_diff('minute', Ingested, TimeGenerated) * -1
    | summarize avg(LagMin), max(LagMin), min(LagMin)
    """
    data = la_query(args.workspace_id, kql, token)
    if not data.get("tables") or not data["tables"][0]["rows"]:
        print(json.dumps({"table": args.table, "error":"no data"})); sys.exit(1)
    avg_lag, max_lag, min_lag = data["tables"][0]["rows"][0]
    print(json.dumps({"table": args.table, "avg_min": avg_lag, "max_min": max_lag, "min_min": min_lag}))

if __name__ == "__main__":
    main()
