#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ingest_logs.py
--------------
Secure, parameterized ingestion of JSON logs into Azure Cosmos DB (or Log Analytics),
with credentials pulled from Azure Key Vault using workload identity or managed identity.
- No plaintext secrets.
- Idempotent writes optional (via upsert).
- Structured logging for SOC pipelines.

Example:
  python ingest_logs.py --source-file ./samples.json --db LogsDB --container SecurityLogs
Env:
  KEYVAULT_URL   : https://<your-kv-name>.vault.azure.net
  COSMOS_DB_NAME : (optional default)
  COSMOS_CONT    : (optional default)
  LOG_LEVEL      : INFO|DEBUG|ERROR
"""

import argparse, json, logging, os, sys, uuid
from typing import Iterable, Dict, Any

# Azure SDKs
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.cosmos import CosmosClient, exceptions as cosmos_exceptions

def get_logger() -> logging.Logger:
    level = os.getenv("LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, level, logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s - %(message)s"
    )
    return logging.getLogger("ingest_logs")

log = get_logger()

def kv_get_secret(vault_url: str, name: str) -> str:
    """Fetch a secret value from Azure Key Vault."""
    cred = DefaultAzureCredential()
    client = SecretClient(vault_url=vault_url, credential=cred)
    return client.get_secret(name).value

def read_records(source_file: str) -> Iterable[Dict[str, Any]]:
    """Yield JSON records from file or stdin."""
    stream = open(source_file, "r", encoding="utf-8") if source_file else sys.stdin
    try:
        for line in stream:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except json.JSONDecodeError:
                # Allow JSON arrays for convenience
                if line.startswith("["):
                    for rec in json.loads(line):
                        yield rec
                    continue
                raise
            yield rec
    finally:
        if source_file:
            stream.close()

def connect_cosmos(vault_url: str) -> CosmosClient:
    """Create a CosmosClient using secrets from Key Vault."""
    cosmos_url = kv_get_secret(vault_url, "cosmos-db-url")
    cosmos_key = kv_get_secret(vault_url, "cosmos-db-key")
    return CosmosClient(url=cosmos_url, credential=cosmos_key)

def ensure_container(client: CosmosClient, db_name: str, container: str, pk: str):
    """Create DB/container if missing (safe for idempotent Dev/Test)."""
    db = client.create_database_if_not_exists(db_name)
    return db.create_container_if_not_exists(id=container, partition_key={"paths":[pk], "kind":"Hash"})

def upsert_record(container, record: Dict[str, Any], id_field: str) -> None:
    """Upsert a record, auto-generate id if missing."""
    if "id" not in record:
        record["id"] = str(record.get(id_field)) if id_field in record else str(uuid.uuid4())
    container.upsert_item(record)

def main():
    p = argparse.ArgumentParser(description="Secure log ingestion into CosmosDB")
    p.add_argument("--source-file", help="Path to NDJSON/JSON file (default: stdin)")
    p.add_argument("--db", default=os.getenv("COSMOS_DB_NAME", "LogsDB"), help="Cosmos DB name")
    p.add_argument("--container", default=os.getenv("COSMOS_CONT", "SecurityLogs"), help="Cosmos container")
    p.add_argument("--partition-key", default="/eventType", help="Cosmos partition key path")
    p.add_argument("--id-field", default="eventId", help="If present, use as id")
    p.add_argument("--vault-url", default=os.getenv("KEYVAULT_URL"), required=not os.getenv("KEYVAULT_URL"),
                   help="Key Vault URL e.g., https://kv.vault.azure.net")
    args = p.parse_args()

    try:
        client = connect_cosmos(args.vault_url)
        cont = ensure_container(client, args.db, args.container, args.partition-key)
        count = 0
        for rec in read_records(args.source_file):
            try:
                upsert_record(cont, rec, args.id_field)
                count += 1
            except cosmos_exceptions.CosmosHttpResponseError as e:
                log.error("Cosmos error: %s | record=%s", e, rec)
        log.info("Ingestion complete. records=%d db=%s container=%s", count, args.db, args.container)
    except Exception as e:
        log.exception("Fatal error: %s", e)
        sys.exit(1)

if __name__ == "__main__":
    main()
