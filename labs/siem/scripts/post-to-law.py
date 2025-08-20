#!/usr/bin/env python3
"""
Utility script: post-to-law.py
Posts a JSON file into Azure Log Analytics via HTTP Data Collector API.
"""

import sys, json, datetime, hashlib, hmac, base64
import requests

workspace_id = sys.argv[1]
shared_key = sys.argv[2]
log_type = sys.argv[3]
file_path = sys.argv[4]

with open(file_path, "r") as f:
    body = f.read()

# Build signature
method = "POST"
content_type = "application/json"
resource = "/api/logs"
rfc1123date = datetime.datetime.utcnow().strftime("%a, %d %b %Y %H:%M:%S GMT")
content_length = len(body)
string_to_hash = f"{method}\n{content_length}\n{content_type}\nx-ms-date:{rfc1123date}\n{resource}"
bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
decoded_key = base64.b64decode(shared_key)
encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()).decode()
signature = f"SharedKey {workspace_id}:{encoded_hash}"

uri = f"https://{workspace_id}.ods.opinsights.azure.com{resource}?api-version=2016-04-01"

headers = {
    "content-type": content_type,
    "Authorization": signature,
    "Log-Type": log_type,
    "x-ms-date": rfc1123date,
}

# Send request
response = requests.post(uri, data=body, headers=headers)
if response.status_code >= 200 and response.status_code <= 299:
    print("Data successfully posted to Log Analytics.")
else:
    print(f"Error: {response.status_code}, {response.text}")
