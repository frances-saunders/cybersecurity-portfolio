"""
Runs UEBA/DLP hunts and writes results to ./hunt_results/*.csv.
Uses DefaultAzureCredential (managed identity preferred). No plaintext secrets.

Env:
  LA_WORKSPACE_ID  - Log Analytics Workspace ID
  HUNT_QUERIES_DIR - Path to detections (default ./detections)
  WEBHOOK_URL      - Optional webhook for high-severity notifications
"""
import os, glob, json, pathlib, datetime
import pandas as pd
from azure.identity import DefaultAzureCredential
from azure.monitor.query import LogsQueryClient, LogsQueryStatus
import requests

WORKSPACE_ID = os.environ.get("LA_WORKSPACE_ID")
QUERIES_DIR = os.environ.get("HUNT_QUERIES_DIR", "./detections")
WEBHOOK = os.environ.get("WEBHOOK_URL")
OUT = pathlib.Path("./hunt_results"); OUT.mkdir(exist_ok=True)

if not WORKSPACE_ID:
    raise SystemExit("LA_WORKSPACE_ID is required.")

def load_kql():
    return [(os.path.basename(f), open(f, "r", encoding="utf-8").read())
            for f in glob.glob(os.path.join(QUERIES_DIR, "*.kql"))]

def post(msg: dict):
    if not WEBHOOK: return
    try: requests.post(WEBHOOK, json=msg, timeout=5)
    except Exception: pass

def save(name: str, df: pd.DataFrame):
    stamp = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")
    path = OUT / f"{name}_{stamp}.csv"
    df.to_csv(path, index=False)
    return str(path)

def main():
    cred = DefaultAzureCredential(exclude_interactive_browser_credential=False)
    client = LogsQueryClient(cred)
    summary = []

    for name, q in load_kql():
        print(f"[+] {name}")
        resp = client.query_workspace(WORKSPACE_ID, q, timespan=datetime.timedelta(hours=24))
        if resp.status not in (LogsQueryStatus.SUCCESS, LogsQueryStatus.PARTIAL):
            print(f"    ! query failed: {resp.error}")
            continue
        table = (resp.tables or resp.partial_data or [None])[0]
        if table and len(table.rows) > 0:
            cols = [c.name for c in table.columns]
            df = pd.DataFrame(table.rows, columns=cols)
            path = save(name.replace(".kql",""), df)
            sev = "high" if ("Severity" in df.columns and (df["Severity"]=="High").any()) else "medium"
            summary.append({"query": name, "hits": len(df), "severity": sev, "file": path})
            if sev == "high":
                post({"event":"ueba_alert","query":name,"hits":int(len(df)),"file":path})
        else:
            print("    -> no results")
            summary.append({"query": name, "hits": 0, "severity": "none", "file": None})

    with open(OUT / "summary.json", "w", encoding="utf-8") as fh:
        json.dump({"generated": datetime.datetime.utcnow().isoformat()+"Z","items":summary}, fh, indent=2)
    print("[*] done")

if __name__ == "__main__":
    main()
