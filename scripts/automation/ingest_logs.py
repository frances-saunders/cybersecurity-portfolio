#!/usr/bin/env python3
"""
Secure log ingestion utility.

Supports:
- Azure Cosmos DB (Core API)
- Azure Log Analytics (HTTP Data Collector API)
- Azure SQL (pyodbc optional)

Secrets:
- Prefer Managed Identity via DefaultAzureCredential.
- Fallback to Key Vault (KEYVAULT_URL + secret names).
- Never store secrets in plaintext.

Usage:
  python ingest_logs.py --source-file logs.jsonl --sink cosmos --db LogsDB --container SecurityLogs
  python ingest_logs.py --source-file logs.jsonl --sink loganalytics --workspace-id XXX --table CustomLogs_CL
"""

import argparse
import json
import logging
import os
import sys
from typing import Dict, Iterable, Optional

# Azure SDKs (install if needed)
# pip install azure-identity azure-keyvault-secrets azure-cosmos requests
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=LOG_LEVEL, format="%(asctime)s %(levelname)s %(message)s")

def _credential():
    return DefaultAzureCredential(exclude_interactive_browser_credential=True)

def _kv_secret(name: str) -> str:
    kv_url = os.getenv("KEYVAULT_URL")
    if not kv_url:
        raise RuntimeError("KEYVAULT_URL is not set")
    client = SecretClient(kv_url, _credential())
    return client.get_secret(name).value

# ---------- CosmosDB ----------
def _cosmos_client():
    from azure.cosmos import CosmosClient
    # Prefer MSI via AAD (no key), otherwise use KV secrets
    cosmos_url = os.getenv("COSMOS_URL") or _kv_secret("cosmos-url")
    cosmos_key = os.getenv("COSMOS_KEY") or _kv_secret("cosmos-key")
    return CosmosClient(url=cosmos_url, credential=cosmos_key)

def _cosmos_ingest(items: Iterable[Dict], db: str, container: str):
    client = _cosmos_client()
    database = client.get_database_client(db)
    cont = database.get_container_client(container)
    count = 0
    for item in items:
        try:
            # Ensure an id
            item.setdefault("id", f"{item.get('time', 't')}-{count}")
            cont.create_item(item)
            count += 1
        except Exception as e:
            logging.exception("Cosmos insert failed for record: %s", item)
    logging.info("Cosmos ingestion complete: %s records", count)

# ---------- Log Analytics ----------
def _la_ingest(items: Iterable[Dict], workspace_id: str, table: str):
    """
    Ingest via HTTP Data Collector.
    Requires:
      - LA_WORKSPACE_SHARED_KEY env or KeyVault secret "loganalytics-shared-key"
    """
    import hashlib, hmac, base64
    from datetime import datetime
    import requests

    shared_key = os.getenv("LA_SHARED_KEY") or _kv_secret("loganalytics-shared-key")
    customer_id = workspace_id

    def build_sig(content_len, rfc1123date):
        string_to_hash = f"POST\n{content_len}\napplication/json\nx-ms-date:{rfc1123date}\n/api/logs"
        bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
        decoded_key = base64.b64decode(shared_key)
        encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, hashlib.sha256).digest()).decode()
        return f"SharedKey {customer_id}:{encoded_hash}"

    uri = f"https://{customer_id}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    batch = []
    count = 0
    for item in items:
        batch.append(item)
        if len(batch) >= 1000:
            body = json.dumps(batch)
            rfc1123date = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
            sig = build_sig(len(body), rfc1123date)
            headers = {
                "Content-Type": "application/json",
                "Log-Type": table,
                "x-ms-date": rfc1123date,
                "Authorization": sig,
            }
            resp = requests.post(uri, data=body, headers=headers, timeout=30)
            if resp.status_code >= 200 and resp.status_code < 300:
                count += len(batch)
                batch = []
            else:
                logging.error("LA ingest failed: %s - %s", resp.status_code, resp.text)
                batch = []
    if batch:
        # send remainder
        body = json.dumps(batch)
        rfc1123date = datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
        sig = build_sig(len(body), rfc1123date)
        headers = {"Content-Type": "application/json", "Log-Type": table, "x-ms-date": rfc1123date, "Authorization": sig}
        import requests
        resp = requests.post(uri, data=body, headers=headers, timeout=30)
        if 200 <= resp.status_code < 300:
            count += len(batch)
        else:
            logging.error("LA ingest failed (final): %s - %s", resp.status_code, resp.text)

    logging.info("Log Analytics ingestion complete: %s records", count)

# ---------- Azure SQL ----------
def _sql_ingest(items: Iterable[Dict], table: str):
    """
    Optional: requires pyodbc and a system ODBC driver. Secrets via KV:
      sql-conn-string e.g. Driver={ODBC Driver 18 for SQL Server};Server=tcp:...;Database=...;Encrypt=yes;...
    """
    import pyodbc
    conn_str = os.getenv("SQL_CONN_STR") or _kv_secret("sql-conn-string")
    with pyodbc.connect(conn_str) as conn:
        cursor = conn.cursor()
        count = 0
        for i in items:
            cols = ",".join(i.keys())
            placeholders = ",".join("?" for _ in i.values())
            cursor.execute(f"INSERT INTO {table} ({cols}) VALUES ({placeholders})", list(i.values()))
            count += 1
        conn.commit()
        logging.info("Azure SQL ingestion complete: %s rows -> %s", count, table)

def _read_jsonl(path: str) -> Iterable[Dict]:
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            if line.strip():
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    logging.warning("Skipping invalid JSON line: %s", line[:120])

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--source-file", required=True, help="JSON Lines file to ingest")
    p.add_argument("--sink", required=True, choices=["cosmos", "loganalytics", "sql"])
    p.add_argument("--db", help="Cosmos database name")
    p.add_argument("--container", help="Cosmos container name")
    p.add_argument("--workspace-id", help="Log Analytics workspace ID")
    p.add_argument("--table", help="Log Analytics custom table or SQL table")
    args = p.parse_args()

    items = _read_jsonl(args.source_file)

    if args.sink == "cosmos":
        if not (args.db and args.container):
            p.error("--db and --container are required for cosmos sink")
        _cosmos_ingest(items, args.db, args.container)
    elif args.sink == "loganalytics":
        if not (args.workspace_id and args.table):
            p.error("--workspace-id and --table are required for loganalytics sink")
        _la_ingest(items, args.workspace_id, args.table)
    else:
        if not args.table:
            p.error("--table is required for sql sink")
        _sql_ingest(items, args.table)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.exception("Fatal error")
        sys.exit(1)
