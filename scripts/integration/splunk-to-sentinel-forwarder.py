#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
splunk-to-sentinel-forwarder.py
-------------------------------
Bridges Splunk events to Microsoft Sentinel (HTTP Data Collector API, or custom endpoint).
- Batches events
- Retries with backoff
- Token via env (no plaintext)

Example:
  python splunk-to-sentinel-forwarder.py --splunk-file events.json --sink-url https://ingest --batch-size 500
"""

import argparse, json, os, sys, time, requests
from typing import List

def chunks(lst: List[dict], n: int):
    for i in range(0, len(lst), n):
        yield lst[i:i+n]

def post_with_retry(url: str, batch: List[dict], token: str, retries=3, backoff=2.0):
    hdr = {"Content-Type":"application/json"}
    if token: hdr["Authorization"] = f"Bearer {token}"
    for attempt in range(1, retries+1):
        r = requests.post(url, headers=hdr, data=json.dumps(batch), timeout=20)
        if r.ok: return
        time.sleep(backoff * attempt)
    r.raise_for_status()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--splunk-file", required=True)
    ap.add_argument("--sink-url", required=True)
    ap.add_argument("--token-env", default="SENTINEL_TOKEN")
    ap.add_argument("--batch-size", type=int, default=1000)
    args = ap.parse_args()

    try:
        events = json.load(open(args.splunk_file, "r", encoding="utf-8"))
        token = os.getenv(args.token_env)
        sent = 0
        for batch in chunks(events, args.batch_size):
            post_with_retry(args.sink_url, batch, token)
            sent += len(batch)
        print(json.dumps({"forwarded": sent, "status":"ok"}))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
