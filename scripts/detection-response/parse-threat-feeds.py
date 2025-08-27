#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
parse-threat-feeds.py
---------------------
Normalizes threat intel feeds to a common schema (STIX-lite) and posts to SIEM.
- Supports HTTP JSON feeds and local files
- Basic de-duplication
- Robust error handling & metrics

Example:
  python parse-threat-feeds.py --feed-url https://example/feed.json --sink sentinel --sink-url https://ingest
"""

import argparse, hashlib, json, os, sys, time
from typing import List, Dict, Any
import requests

def load_feed(url: str = None, file: str = None) -> List[Dict[str, Any]]:
    if url:
        r = requests.get(url, timeout=15)
        r.raise_for_status()
        return r.json().get("indicators", [])
    if file:
        with open(file, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data.get("indicators", data)
    raise ValueError("Provide --feed-url or --feed-file")

def normalize(ind: Dict[str, Any]) -> Dict[str, Any]:
    ioc = ind.get("value") or ind.get("ioc") or ind.get("indicator")
    t  = ind.get("type", "unknown").lower()
    return {
        "id": hashlib.sha256((ioc or "").encode()).hexdigest(),
        "type": t,
        "value": ioc,
        "source": ind.get("source","unknown"),
        "first_seen": ind.get("first_seen") or time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "confidence": ind.get("confidence", 50)
    }

def post_siem(sink_url: str, items: List[Dict[str, Any]], token: str = None):
    headers = {"Content-Type": "application/json"}
    if token: headers["Authorization"] = f"Bearer {token}"
    r = requests.post(sink_url, headers=headers, data=json.dumps(items), timeout=20)
    r.raise_for_status()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--feed-url")
    ap.add_argument("--feed-file")
    ap.add_argument("--sink-url", required=True)
    ap.add_argument("--token-env", default="SIEM_TOKEN")
    args = ap.parse_args()

    try:
        raw = load_feed(args.feed-url, args.feed_file)
        norm = [normalize(x) for x in raw if x.get("value") or x.get("ioc")]
        # dedupe by id
        seen, dedup = set(), []
        for r in norm:
            if r["id"] in seen: continue
            seen.add(r["id"]); dedup.append(r)

        post_siem(args.sink_url, dedup, os.getenv(args.token_env))
        print(json.dumps({"count": len(dedup), "status":"ok"}))
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)

if __name__ == "__main__":
    main()
