#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Secure log ingestion to Cosmos DB (AAD auth) or Azure SQL (AAD token).
- No plaintext secrets. Values are read from Azure Key Vault or environment variables.
- Uses managed identity via DefaultAzureCredential when running in Azure.

Select backend via env:
  TARGET_BACKEND = "cosmos" | "sql"

Expected Key Vault secrets (or env vars as fallback):
  COSMOS_ENDPOINT, COSMOS_DB_NAME, COSMOS_CONTAINER_NAME
  SQL_SERVER, SQL_DATABASE

Usage:
  python3 ingest_logs.py ./data/anomalous_traffic.log
"""

import os, sys, re, json, datetime
from typing import Optional, Dict, Any

# ---------------- Vault client ----------------
class VaultClient:
    def __init__(self):
        self.azure_uri = os.getenv("AZURE_KEY_VAULT_URI")
        self._client = None
        if self.azure_uri:
            try:
                from azure.identity import DefaultAzureCredential
                from azure.keyvault.secrets import SecretClient
                self._client = SecretClient(vault_url=self.azure_uri, credential=DefaultAzureCredential())
            except Exception:
                self._client = None

    def get(self, name: str) -> Optional[str]:
        if self._client:
            try:
                v = self._client.get_secret(name)
                if v and v.value:
                    return v.value
            except Exception:
                pass
        return os.getenv(name)

# ---------------- Common Log Format parser ----------------
CLF_REGEX = re.compile(
    r'(?P<ip>\S+)\s+\S+\s+\S+\s+\[(?P<ts>[^\]]+)\]\s+"(?P<method>\S+)\s+(?P<path>\S+)\s+(?P<proto>[^"]+)"\s+(?P<status>\d{3})\s+(?P<bytes>\S+)\s+"(?P<ref>[^"]*)"\s+"(?P<ua>[^"]*)"'
)

def parse_line(line: str) -> Optional[Dict[str, Any]]:
    m = CLF_REGEX.match(line.strip())
    if not m:
        return None
    d = m.groupdict()
    d["status"] = int(d["status"])
    d["bytes"] = 0 if d["bytes"] == "-" else int(d["bytes"])
    d["@ingest_time"] = datetime.datetime.utcnow().isoformat() + "Z"
    return d

# ---------------- Cosmos DB (AAD) ----------------
def ingest_cosmos(vault: VaultClient, log_path: str):
    endpoint = vault.get("COSMOS_ENDPOINT")  # e.g., https://<acct>.documents.azure.com:443/
    db_name = vault.get("COSMOS_DB_NAME")
    container_name = vault.get("COSMOS_CONTAINER_NAME")
    if not all([endpoint, db_name, container_name]):
        print("Missing Cosmos config (COSMOS_ENDPOINT/DB_NAME/CONTAINER_NAME).")
        sys.exit(1)

    try:
        from azure.identity import DefaultAzureCredential
        from azure.cosmos import CosmosClient, PartitionKey
    except Exception:
        print("Please install azure-identity and azure-cosmos.")
        sys.exit(1)

    cred = DefaultAzureCredential()
    client = CosmosClient(url=endpoint, credential=cred)
    db = client.get_database_client(db_name)
    container = db.get_container_client(container_name)

    with open(log_path, "r", encoding="utf-8") as f:
        for line in f:
            doc = parse_line(line)
            if not doc: 
                continue
            # Use IP as partition key for demo. In production, choose a stable/high-cardinality key.
            doc["id"] = f"{doc['ip']}:{doc['ts']}"
            try:
                container.upsert_item(doc, partition_key=doc["ip"])
            except Exception as e:
                print(f"Failed to upsert: {e}")

    print(f"Ingested logs to Cosmos container '{container_name}'.")

# ---------------- Azure SQL (AAD token) ----------------
def ingest_sql(vault: VaultClient, log_path: str):
    server = vault.get("SQL_SERVER")   # e.g., myserver.database.windows.net
    database = vault.get("SQL_DATABASE")
    if not all([server, database]):
        print("Missing SQL config (SQL_SERVER/SQL_DATABASE).")
        sys.exit(1)

    try:
        import pyodbc
        from azure.identity import DefaultAzureCredential
    except Exception:
        print("Please install pyodbc and azure-identity.")
        sys.exit(1)

    # Get AAD access token
    cred = DefaultAzureCredential()
    token = cred.get_token("https://database.windows.net/.default")
    access_token = token.token.encode("utf-16-le")

    # ODBC connection using access token (no password)
    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{server},1433;"
        f"Database={database};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    conn = pyodbc.connect(conn_str, attrs_before={1256: access_token})  # 1256 = SQL_COPT_SS_ACCESS_TOKEN
    cursor = conn.cursor()

    cursor.execute("""
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='HttpAccessLog' AND xtype='U')
        CREATE TABLE HttpAccessLog (
            id INT IDENTITY(1,1) PRIMARY KEY,
            ip NVARCHAR(64),
            ts NVARCHAR(64),
            method NVARCHAR(16),
            path NVARCHAR(2048),
            proto NVARCHAR(32),
            status INT,
            bytes BIGINT,
            ref NVARCHAR(2048),
            ua NVARCHAR(1024),
            ingest_time DATETIME2
        )
    """)
    conn.commit()

    with open(log_path, "r", encoding="utf-8") as f:
        for line in f:
            doc = parse_line(line)
            if not doc: 
                continue
            cursor.execute("""
                INSERT INTO HttpAccessLog (ip, ts, method, path, proto, status, bytes, ref, ua, ingest_time)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, SYSUTCDATETIME())
            """, (doc["ip"], doc["ts"], doc["method"], doc["path"], doc["proto"], doc["status"], doc["bytes"], doc["ref"], doc["ua"]))
    conn.commit()
    cursor.close()
    conn.close()
    print("Ingested logs to Azure SQL table 'HttpAccessLog'.")

# ---------------- Main ----------------
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 ingest_logs.py <logfile>")
        sys.exit(1)

    target = os.getenv("TARGET_BACKEND", "cosmos").lower()
    vault = VaultClient()
    log_file = sys.argv[1]

    if target == "cosmos":
        ingest_cosmos(vault, log_file)
    elif target == "sql":
        ingest_sql(vault, log_file)
    else:
        print("Unsupported TARGET_BACKEND. Use 'cosmos' or 'sql'.")
        sys.exit(1)
