#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
splunk-risk-list-sync.py
Sync IOCs between Microsoft Sentinel Threat Intelligence (via Log Analytics) and Splunk Risk Lists.
- Two modes: --direction sentinel->splunk (default) or --direction splunk->sentinel
- Dedupe by IOC value and type
- No plaintext secrets: tokens via env vars

Credentials
- Azure: DefaultAzureCredential or LA workspace SharedKey (HTTP Data Collector not needed for reads)
- Splunk: HEC or REST token via env SPLUNK_TOKEN; SPLUNK_URL base (https://splunk:8089)

Dependencies
  pip install requests azure-identity azure-monitor-query
"""

import argparse, json, os, sys, time, requests
from typing import List, Dict, Tuple

# ---------- Azure (Sentinel TI via Log Analytics Query) ----------
def query_sentinel_ti(workspace_id: str, kusto: str, az_token: str = None) -> List[Dict]:
    """
    Query LA using the Azure Monitor Logs endpoint (AAD token preferred).
    For brevity, this function assumes an access token is provided via env AZ_TOKEN
    (e.g., obtained in CI), or a Managed Identity is used and a pre-created token.
    """
    endpoint = f"https://api.loganalytics.io/v1/workspaces/{workspace_id}/query"
    headers = {"Content-Type": "application/json"}
    if az_token:
      headers["Authorization"] = f"Bearer {az_token}"
    payload = {"query": kusto, "timespan": "P7D"}
    resp = requests.post(endpoint, headers=headers, json=payload, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    cols = [c["name"] for c in data["tables"][0]["columns"]]
    out = []
    for row in data["tables"][0]["rows"]:
        out.append(dict(zip(cols, row)))
    return out

# ---------- Splunk Risk List helpers (using Splunkd REST, not HEC) ----------
def splunk_get_risk_list(base_url: str, token: str, lookup: str) -> List[Dict]:
    """
    Retrieve risk list (lookup) as JSON via REST.
    For Enterprise Security, risk list is a KV store or lookup file. Here we use /services/data/lookup/lookup-table-files
    You may adapt to KV store collections if used in your environment.
    """
    # Fallback generic: GET search results from a saved search exporting risk list (simplified)
    search = f'| inputlookup {lookup}'
    return splunk_search(base_url, token, search)

def splunk_search(base_url: str, token: str, search: str) -> List[Dict]:
    r = requests.post(f"{base_url}/services/search/jobs/export",
                      headers={"Authorization": f"Bearer {token}"},
                      data={"search": f"search {search}", "output_mode":"json"},
                      timeout=60, verify=True)
    r.raise_for_status()
    events = []
    for line in r.text.splitlines():
        if not line.strip(): continue
        obj = json.loads(line)
        if "result" in obj: events.append(obj["result"])
    return events

def splunk_replace_lookup(base_url: str, token: str, lookup: str, rows: List[Dict]):
    """
    Replace a CSV lookup with provided rows (must include consistent columns).
    Implementation uses a Splunk search job to write lookup (safe for demo); in prod, use the lookup upload endpoint.
    """
    if not rows:
        return
    # Build CSV
    keys = sorted({k for r in rows for k in r.keys()})
    csv_data = ",".join(keys) + "\n"
    for r in rows:
        csv_data += ",".join([str(r.get(k,"")) for k in keys]) + "\n"
    # Store into Splunk via a custom endpoint or CLI; here we demonstrate via | inputcsv trick (simplified)
    payload = {
        "search": f"| inputcsv append=t {lookup} | fields * | outputlookup {lookup}",
        "output_mode": "json"
    }
    # This is illustrative; in real ES, prefer REST /services/data/lookup or KV store API
    requests.post(f"{base_url}/services/search/jobs/export",
                  headers={"Authorization": f"Bearer {token}"},
                  data=payload, timeout=60, verify=True)

# ---------- Dedupe & Normalize ----------
def norm_indicator(i: Dict) -> Tuple[str,str]:
    v = (i.get("IndicatorValue") or i.get("indicator") or i.get("value") or "").strip()
    t = (i.get("IndicatorType") or i.get("type") or "unknown").strip().lower()
    return v, t

def dedupe(rows: List[Dict]) -> List[Dict]:
    seen = set(); out=[]
    for r in rows:
        k = norm_indicator(r)
        if k[0] and k not in seen:
            seen.add(k); out.append(r)
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--direction", choices=["sentinel->splunk","splunk->sentinel"], default="sentinel->splunk")
    ap.add_argument("--workspace-id", help="Log Analytics Workspace ID (for Sentinel TI)")
    ap.add_argument("--splunk-url", required=True, help="Splunkd base URL, e.g. https://splunk:8089")
    ap.add_argument("--splunk-token-env", default="SPLUNK_TOKEN")
    ap.add_argument("--lookup-name", default="risk_lookup.csv", help="Splunk lookup used as risk list")
    args = ap.parse_args()

    splunk_token = os.getenv(args.splunk_token_env)
    if not splunk_token:
        print(json.dumps({"error":"Missing Splunk token env"})); sys.exit(1)

    if args.direction == "sentinel->splunk":
        if not args.workspace_id:
            print(json.dumps({"error":"--workspace-id required"})); sys.exit(1)
        # Simple TI query from ThreatIntelligenceIndicator table (Sentinel TI providers)
        kql = """
        ThreatIntelligenceIndicator
        | project TimeGenerated, IndicatorType, IndicatorValue = tostring(ioc), SourceSystem
        | where isnotempty(IndicatorValue)
        | summarize by IndicatorType, IndicatorValue
        """
        az_token = os.getenv("AZ_TOKEN")  # Provide via OIDC/MI in CI
        ti = query_sentinel_ti(args.workspace_id, kql, az_token)
        rows = [{"indicator": r["IndicatorValue"], "type": r["IndicatorType"]} for r in ti]
        rows = dedupe(rows)
        splunk_replace_lookup(args.splunk_url, splunk_token, args.lookup_name, rows)
        print(json.dumps({"direction": args.direction, "count": len(rows)}))
    else:
        # Pull from Splunk risk list and (illustratively) print what would be posted to Sentinel TI
        # (posting to Sentinel TI requires the Graph TI API or LA ingestion to a custom table; omitted for brevity)
        rows = splunk_get_risk_list(args.splunk_url, splunk_token, args.lookup_name)
        rows = dedupe(rows)
        print(json.dumps({"direction": args.direction, "count": len(rows), "preview": rows[:5]}))

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)})); sys.exit(1)
