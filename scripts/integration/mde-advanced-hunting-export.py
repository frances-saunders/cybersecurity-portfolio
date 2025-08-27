#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
mde-advanced-hunting-export.py
Query Microsoft Defender Advanced Hunting (AH) and forward results to Log Analytics (HTTP Data Collector) or CosmosDB.
- Retries with exponential backoff
- No plaintext secrets: tokens via env, Cosmos creds via Key Vault (optional)

Requires:
  pip install requests azure-identity azure-keyvault-secrets azure-cosmos

AH Auth:
  Provide an OAuth token in env MDE_TOKEN (client credentials in CI with OIDC recommended).

LAW HEC:
  Provide WORKSPACE_ID and SHARED_KEY env vars to post. (Standard HTTP Data Collector auth)

Cosmos:
  KEYVAULT_URL with secrets 'cosmos-db-url' and 'cosmos-db-key' if using Cosmos sink.

Usage:
  python mde-advanced-hunting-export.py --query "DeviceEvents | take 100" --sink law
  python mde-advanced-hunting-export.py --query-file q.kql --sink cosmos
"""

import argparse, base64, hashlib, hmac, json, os, sys, time, requests
from datetime import datetime
from typing import List, Dict, Any

# ---------- AH ----------
def run_advanced_hunting(query: str, token: str) -> List[Dict[str, Any]]:
    url = "https://api.security.microsoft.com/api/advancedhunting/run"
    headers = {"Authorization": f"Bearer {token}", "Content-Type":"application/json"}
    payload = {"Query": query}
    for attempt in range(1, 6):
        r = requests.post(url, headers=headers, json=payload, timeout=60)
        if r.ok:
            rows = r.json().get("Results", [])
            return rows
        time.sleep(min(2**attempt, 30))
    r.raise_for_status()

# ---------- LAW HEC ----------
def build_signature(customer_id: str, shared_key: str, date: str, content_length: int, method="POST", content_type="application/json", resource="/api/logs") -> str:
    x_headers = "x-ms-date:" + date
    string_to_hash = f"{method}\n{content_length}\n{content_type}\n{x_headers}\n{resource}"
    bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
    decoded_key = base64.b64decode(shared_key)
    encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()).decode()
    return f"SharedKey {customer_id}:{encoded_hash}"

def post_to_law(workspace_id: str, shared_key: str, log_type: str, rows: List[Dict[str, Any]]):
    body = json.dumps(rows)
    rfc1123date = datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
    sig = build_signature(workspace_id, shared_key, rfc1123date, len(body))
    uri = f"https://{workspace_id}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    headers = {"Content-Type":"application/json","Authorization":sig,"Log-Type":log_type,"x-ms-date":rfc1123date}
    r = requests.post(uri, headers=headers, data=body, timeout=60)
    r.raise_for_status()

# ---------- Cosmos (optional) ----------
def cosmos_sink(rows: List[Dict[str, Any]]):
    from azure.identity import DefaultAzureCredential
    from azure.keyvault.secrets import SecretClient
    from azure.cosmos import CosmosClient
    kv = os.environ.get("KEYVAULT_URL")
    cred = DefaultAzureCredential()
    sc = SecretClient(vault_url=kv, credential=cred)
    url = sc.get_secret("cosmos-db-url").value
    key = sc.get_secret("cosmos-db-key").value
    client = CosmosClient(url, credential=key)
    db = client.create_database_if_not_exists("SecurityData")
    cont = db.create_container_if_not_exists(id="MDEAdvancedHunting", partition_key={"paths":["/DeviceId"],"kind":"Hash"})
    for r in rows:
        r.setdefault("id", r.get("EventUid") or r.get("DeviceId") or f"mde-{int(time.time()*1000)}")
        cont.upsert_item(r)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--query")
    ap.add_argument("--query-file")
    ap.add_argument("--sink", choices=["law","cosmos"], default="law")
    ap.add_argument("--log-type", default="MDEAdvancedHunting_CL")
    args = ap.parse_args()

    q = args.query or (open(args.query_file, "r", encoding="utf-8").read() if args.query_file else None)
    if not q:
        print(json.dumps({"error":"Provide --query or --query-file"})); sys.exit(1)

    token = os.getenv("MDE_TOKEN")
    if not token:
        print(json.dumps({"error":"Missing MDE_TOKEN"})); sys.exit(1)

    rows = run_advanced_hunting(q, token)
    if not rows:
        print(json.dumps({"result":"no_rows"})); return

    if args.sink == "law":
        ws = os.getenv("WORKSPACE_ID"); key = os.getenv("SHARED_KEY")
        if not (ws and key):
            print(json.dumps({"error":"WORKSPACE_ID/SHARED_KEY envs required for LAW sink"})); sys.exit(1)
        post_to_law(ws, key, args.log_type, rows)
    else:
        cosmos_sink(rows)

    print(json.dumps({"rows": len(rows), "sink": args.sink}))

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)})); sys.exit(1)
