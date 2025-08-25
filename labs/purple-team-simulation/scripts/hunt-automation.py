"""
Runs KQL hunts from the detections folder against Log Analytics (Sentinel) and
writes results to ./hunt_results/*.csv. Uses DefaultAzureCredential (managed identity first)
and environment variables for configuration. No plaintext secrets.

Env:
  - LA_WORKSPACE_ID: Log Analytics Workspace ID (GUID)
  - HUNT_QUERIES_DIR: path to detections (default: ./detections)
  - LOGICAPP_WEBHOOK_URL: optional HTTP endpoint to notify on high-severity hits

Requires:
  pip install azure-identity azure-monitor-query pandas
"""

import os, glob, json, pathlib, datetime
from typing import List, Tuple
import pandas as pd
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient, LogsQueryStatus

WORKSPACE_ID = os.environ.get("LA_WORKSPACE_ID")
QUERIES_DIR = os.environ.get("HUNT_QUERIES_DIR", "./detections")
WEBHOOK = os.environ.get("LOGICAPP_WEBHOOK_URL")
RESULTS_DIR = pathlib.Path("./hunt_results")
RESULTS_DIR.mkdir(exist_ok=True)

if not WORKSPACE_ID:
    raise SystemExit("LA_WORKSPACE_ID environment variable is required.")

def load_queries() -> List[Tuple[str, str]]:
    files = glob.glob(os.path.join(QUERIES_DIR, "*.kql"))
    queries = []
    for f in files:
        with open(f, "r", encoding="utf-8") as fh:
            queries.append((os.path.basename(f), fh.read()))
    return queries

def notify_webhook(payload: dict):
    if not WEBHOOK:
        return
    try:
        import requests
        requests.post(WEBHOOK, json=payload, timeout=5)
    except Exception:
        pass

def save_frame(name: str, df: pd.DataFrame):
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    out = RESULTS_DIR / f"{name}_{timestamp}.csv"
    df.to_csv(out, index=False)
    return str(out)

def main():
    cred = DefaultAzureCredential(exclude_interactive_browser_credential=False)
    client = LogsQueryClient(cred)

    hunts = load_queries()
    summary = []

    for name, query in hunts:
        print(f"[+] Running hunt: {name}")
        resp = client.query_workspace(WORKSPACE_ID, query, timespan=datetime.timedelta(hours=24))
        if resp.status == LogsQueryStatus.PARTIAL:
            table = resp.partial_data[0]
        elif resp.status == LogsQueryStatus.SUCCESS:
            table = resp.tables[0] if resp.tables else None
        else:
            print(f"[!] Failed query {name}: {resp.error}")
            continue

        if table and len(table.rows) > 0:
            df = pd.DataFrame(data=table.rows, columns=[c.name for c in table.columns])
            outpath = save_frame(name.replace(".kql", ""), df)
            sev = "high" if "Severity" in df.columns and (df["Severity"] == "High").any() else "medium"
            print(f"    -> Hits: {len(df)} (saved {outpath})")
            summary.append({"name": name, "hits": len(df), "severity": sev, "file": outpath})
            if sev == "high":
                notify_webhook({"event": "hunt_hits", "query": name, "hits": len(df), "file": outpath})
        else:
            print("    -> No results")
            summary.append({"name": name, "hits": 0, "severity": "none", "file": None})

    with open(RESULTS_DIR / "summary.json", "w", encoding="utf-8") as fh:
        json.dump({"generated": datetime.datetime.utcnow().isoformat()+"Z", "items": summary}, fh, indent=2)
    print("[*] Done. Summary written to hunt_results/summary.json")

if __name__ == "__main__":
    main()
