#!/usr/bin/env python3
"""
Secure ingestion of logs into CosmosDB/SQL/Log Analytics.
Uses Key Vault for secrets retrieval to avoid plaintext credentials.
"""

import os
import json
import logging
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.cosmos import CosmosClient

logging.basicConfig(level=logging.INFO)

# Vault & DB setup
VAULT_URL = os.getenv("KEYVAULT_URL")
credential = DefaultAzureCredential()
secret_client = SecretClient(vault_url=VAULT_URL, credential=credential)

cosmos_key = secret_client.get_secret("cosmos-db-key").value
cosmos_url = secret_client.get_secret("cosmos-db-url").value
database_name = "LogsDB"
container_name = "SecurityLogs"

cosmos_client = CosmosClient(cosmos_url, credential=cosmos_key)
database = cosmos_client.get_database_client(database_name)
container = database.get_container_client(container_name)

def ingest_log(log_record: dict):
    """Insert sanitized log record into CosmosDB."""
    try:
        container.create_item(body=log_record)
        logging.info("Log ingested successfully: %s", log_record["id"])
    except Exception as e:
        logging.error("Error ingesting log: %s", e)

if __name__ == "__main__":
    sample_log = {"id": "log001", "event": "user_login", "status": "success"}
    ingest_log(sample_log)
