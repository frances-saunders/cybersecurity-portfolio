#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
anomaly-batch-score.py
Batch-score logs using Isolation Forest; push anomalies to SIEM (LAW HTTP Data Collector) with trace IDs.

Inputs:
  --input CSV/JSON with numeric features (e.g., counts, durations)
  --columns list of feature columns to use
  --id-col unique identifier for traceability
  --out anomalies.json (local)
  Optional LAW sink via WORKSPACE_ID / SHARED_KEY envs.

Requires:
  pip install pandas scikit-learn requests
"""

import argparse, json, os, sys, uuid, requests, pandas as pd
from sklearn.ensemble import IsolationForest
from datetime import datetime
import base64, hashlib, hmac

def build_signature(customer_id, shared_key, date, content_length, method="POST", content_type="application/json", resource="/api/logs"):
    x_headers = "x-ms-date:" + date
    string_to_hash = f"{method}\n{content_length}\n{content_type}\n{x_headers}\n{resource}"
    bytes_to_hash = bytes(string_to_hash, encoding="utf-8")
    decoded_key = base64.b64decode(shared_key)
    encoded_hash = base64.b64encode(hmac.new(decoded_key, bytes_to_hash, digestmod=hashlib.sha256).digest()).decode()
    return f"SharedKey {customer_id}:{encoded_hash}"

def post_to_law(workspace_id, shared_key, log_type, rows):
    body = json.dumps(rows)
    rfc1123date = datetime.utcnow().strftime('%a, %d %b %Y %H:%M:%S GMT')
    sig = build_signature(workspace_id, shared_key, rfc1123date, len(body))
    uri = f"https://{workspace_id}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    headers = {"Content-Type":"application/json","Authorization":sig,"Log-Type":log_type,"x-ms-date":rfc1123date}
    r = requests.post(uri, headers=headers, data=body, timeout=30)
    r.raise_for_status()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--columns", nargs="+", required=True)
    ap.add_argument("--id-col", default="id")
    ap.add_argument("--out", default="anomalies.json")
    ap.add_argument("--contamination", type=float, default=0.02)
    ap.add_argument("--law-log-type", default="AnomalyBatch_CL")
    args = ap.parse_args()

    # Load
    if args.input.endswith(".json"):
      df = pd.read_json(args.input, lines=True)
    else:
      df = pd.read_csv(args.input)

    X = df[args.columns].values
    model = IsolationForest(n_estimators=200, contamination=args.contamination, random_state=42)
    scores = model.fit_predict(X)
    df["_anomaly"] = (scores == -1)

    anomalies = []
    for _, row in df[df["_anomaly"]].iterrows():
      anomalies.append({
        "TraceId": str(uuid.uuid4()),
        "RecordId": row.get(args.id_col, ""),
        "Timestamp": datetime.utcnow().isoformat()+"Z",
        "Features": {c: row[c] for c in args.columns},
        "Anomaly": True,
        "ScoreHint": float(model.score_samples([row[args.columns].values])[0])
      })

    with open(args.out, "w", encoding="utf-8") as f:
      json.dump(anomalies, f, indent=2)

    ws, key = os.getenv("WORKSPACE_ID"), os.getenv("SHARED_KEY")
    if ws and key and anomalies:
      post_to_law(ws, key, args.law_log_type, anomalies)

    print(json.dumps({"count": len(anomalies), "out": args.out}))

if __name__ == "__main__":
    main()
