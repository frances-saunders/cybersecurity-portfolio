#!/usr/bin/env python3
"""
Script: zabbix-sentinel-forwarder.py
Purpose: Forwards Zabbix webhook alerts into Azure Log Analytics
Author: Frances Saunders Portfolio

This script acts as a lightweight HTTP endpoint for Zabbix webhook integration.
It parses the Zabbix JSON payload, enriches it, and forwards it securely into
an Azure Log Analytics workspace via REST API.
"""

import os
import json
import hmac
import hashlib
import base64
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

# Environment variables (injected at runtime, no plaintext secrets in code)
LOG_ANALYTICS_CUSTOMER_ID = os.environ.get("LOG_ANALYTICS_CUSTOMER_ID")
LOG_ANALYTICS_SHARED_KEY = os.environ.get("LOG_ANALYTICS_SHARED_KEY")
LOG_TYPE = "Zabbix_Events"

def build_signature(customer_id, shared_key, date, content_length, method, content_type, resource):
    x_headers = 'x-ms-date:' + date
    string_to_hash = f"{method}\n{content_length}\n{content_type}\n{x_headers}\n{resource}"
    bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
    decoded_key = base64.b64decode(shared_key)
    encoded_hash = base64.b64encode(
        hmac.new(decoded_key, bytes_to_hash, hashlib.sha256).digest()
    ).decode()
    return f"SharedKey {customer_id}:{encoded_hash}"

@app.route("/zabbix", methods=["POST"])
def ingest_zabbix_event():
    body = request.json
    headers = {
        "Content-Type": "application/json",
        "Log-Type": LOG_TYPE,
        "x-ms-date": request.headers.get("Date")
    }

    # Forward payload to Azure Log Analytics
    uri = f"https://{LOG_ANALYTICS_CUSTOMER_ID}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    content = json.dumps(body)
    headers["Authorization"] = build_signature(
        LOG_ANALYTICS_CUSTOMER_ID, LOG_ANALYTICS_SHARED_KEY,
        headers["x-ms-date"], len(content), "POST", "application/json", "/api/logs"
    )

    response = requests.post(uri, data=content, headers=headers)
    return jsonify({"status": response.status_code, "message": "Event forwarded"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
