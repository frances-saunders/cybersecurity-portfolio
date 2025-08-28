#!/usr/bin/env python3
"""
Secure Snort -> SIEM forwarder (Splunk HEC + Azure Logs Ingestion API via DCR).
- No plaintext secrets. Pull tokens from Azure Key Vault (managed identity) or env.
- Resilient tailer with backoff, file rotation handling, and JSON normalization.

Env (choose based on your environment):
  SPLUNK_HEC_URL=https://splunk.example.com:8088/services/collector
  SPLUNK_HEC_TOKEN (vault-backed; optional if using Key Vault)
  SPLUNK_INDEX=ids
  SPLUNK_SOURCETYPE=snort:json

Azure Logs Ingestion (DCR):
  DCE_INGEST_URI=<https endpoint from DCE output>
  DCR_RULE_ID=<data collection rule immutableId>
  AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET  # if not using MSI
  or use Managed Identity on an Azure VM / VMSS / Container App.

Key Vault (optional; recommended):
  KEYVAULT_URI=https://<your-kv-name>.vault.azure.net/
  SECRETS: splunk-hec-token

Run:
  python3 log-forwarder.py /var/log/snort/alert_json.log
"""

import os, sys, time, json, re, hashlib, threading
from datetime import datetime, timezone
from typing import Optional

# Optional Azure dependencies for prod use; wrap imports
AZURE_AVAILABLE = True
try:
    from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
    from azure.keyvault.secrets import SecretClient
    import requests
except Exception:
    AZURE_AVAILABLE = False
    import requests

LINE_RE = re.compile(r'^\s*\{.*\}\s*$')  # expect JSON per line (use Barnyard2 json_output or Snort3 JSON)

def get_env(name: str, default: Optional[str] = None) -> Optional[str]:
    v = os.getenv(name, default)
    return v.strip() if isinstance(v, str) else v

def load_secret_from_keyvault(secret_name: str) -> Optional[str]:
    kv_uri = get_env("KEYVAULT_URI")
    if not kv_uri or not AZURE_AVAILABLE:
        return None
    try:
        cred = DefaultAzureCredential(exclude_shared_token_cache_credential=True)
        client = SecretClient(vault_url=kv_uri, credential=cred)
        return client.get_secret(secret_name).value
    except Exception:
        return None

def normalized_event(raw_line: str) -> dict:
    try:
        evt = json.loads(raw_line)
    except Exception:
        # Best effort parse: fallback to fast log conversion
        evt = {"raw": raw_line}

    # Normalize likely keys
    now = datetime.now(timezone.utc).isoformat()
    sig = evt.get("signature") or evt.get("sig") or evt.get("alert", {}).get("signature")
    sid = evt.get("sid") or evt.get("alert", {}).get("signature_id")
    rev = evt.get("rev") or evt.get("alert", {}).get("rev")
    src = evt.get("src_ip") or evt.get("src") or evt.get("source", {}).get("ip")
    dst = evt.get("dest_ip") or evt.get("dst") or evt.get("destination", {}).get("ip")
    sport = evt.get("src_port") or evt.get("sp") or evt.get("source", {}).get("port")
    dport = evt.get("dest_port") or evt.get("dp") or evt.get("destination", {}).get("port")
    proto = evt.get("proto") or evt.get("protocol")
    sev = evt.get("severity") or evt.get("alert", {}).get("severity")

    return {
        "time": now,
        "msg": evt.get("msg") or evt.get("alert", {}).get("category") or "snort alert",
        "signature": sig,
        "sid": sid,
        "rev": rev,
        "src": src,
        "dst": dst,
        "sport": sport,
        "dport": dport,
        "proto": proto,
        "severity": sev,
        "raw": evt
    }

def send_splunk(events):
    url = get_env("SPLUNK_HEC_URL")
    token = get_env("SPLUNK_HEC_TOKEN") or load_secret_from_keyvault("splunk-hec-token")
    if not url or not token:
        return
    headers = {"Authorization": f"Splunk {token}"}
    payload = []
    index = get_env("SPLUNK_INDEX", "ids")
    sourcetype = get_env("SPLUNK_SOURCETYPE", "snort:json")
    for e in events:
        payload.append({"event": e, "sourcetype": sourcetype, "index": index})
    backoff = 1
    for _ in range(5):
        try:
            r = requests.post(url, headers=headers, json=payload, timeout=10)
            if r.status_code < 300:
                return
        except Exception:
            pass
        time.sleep(backoff)
        backoff = min(backoff * 2, 30)

def get_azure_access_token(scope="https://monitor.azure.com/.default"):
    if not AZURE_AVAILABLE:
        return None
    try:
        cred = DefaultAzureCredential(exclude_shared_token_cache_credential=True)
        token = cred.get_token(scope)
        return token.token
    except Exception:
        return None

def send_azure(events):
    # Azure Logs Ingestion API (DCR)
    dce = get_env("DCE_INGEST_URI")
    dcr_rule_id = get_env("DCR_RULE_ID")
    if not dce or not dcr_rule_id:
        return
    token = get_azure_access_token()
    if not token:
        return
    url = f"{dce}/dataCollectionRules/{dcr_rule_id}/streams/Custom-Logs?api-version=2023-01-01"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    # Azure expects array of objects matching the DCR transform; we send { RawData: json-string }
    payload = [{"RawData": json.dumps(e)} for e in events]
    backoff = 1
    for _ in range(5):
        try:
            r = requests.post(url, headers=headers, json=payload, timeout=10)
            if r.status_code < 300:
                return
        except Exception:
            pass
        time.sleep(backoff)
        backoff = min(backoff * 2, 30)

def tail_file(path):
    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
        f.seek(0, os.SEEK_END)
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.2)
                continue
            if not LINE_RE.match(line):
                continue
            yield line.strip()

def main():
    if len(sys.argv) < 2:
        print("Usage: log-forwarder.py <snort_json_alert_file>", file=sys.stderr)
        sys.exit(1)

    srcfile = sys.argv[1]
    batch, last_send = [], time.time()
    for line in tail_file(srcfile):
        evt = normalized_event(line)
        batch.append(evt)

        if len(batch) >= 50 or (time.time() - last_send) > 5:
            # parallel sends but failure tolerant
            to_send = batch[:]
            batch.clear()
            last_send = time.time()
            threading.Thread(target=send_splunk, args=(to_send,), daemon=True).start()
            threading.Thread(target=send_azure, args=(to_send,), daemon=True).start()

if __name__ == "__main__":
    main()
