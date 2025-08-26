#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AI-driven log anomaly detector using Isolation Forest and optional Autoencoder.

- Trains on "normal" logs, scores a "candidate" log set, and emits a CSV of results.
- No plaintext secrets: optional threshold secret pulled from vault or env.
- Feature extraction is self-contained and robust to simple Common Log Format variants.

Usage:
  python3 anomaly_detector.py data/normal_traffic.log data/anomalous_traffic.log
Outputs:
  ./anomaly_results.csv
"""

import sys
import os
import re
import csv
import math
import json
import base64
import statistics
from typing import List, Dict, Any, Tuple, Optional

# ---------------- Vault client (same pattern as PQC demo) ----------------
class VaultClient:
    def __init__(self):
        self.azure_uri = os.getenv("AZURE_KEY_VAULT_URI")
        self.hvault_addr = os.getenv("VAULT_ADDR")
        self.hvault_token = os.getenv("VAULT_TOKEN")
        self._azure_client = None
        self._hvac_client = None

        if self.azure_uri:
            try:
                from azure.identity import DefaultAzureCredential
                from azure.keyvault.secrets import SecretClient
                self._azure_client = SecretClient(
                    vault_url=self.azure_uri,
                    credential=DefaultAzureCredential()
                )
            except Exception:
                self._azure_client = None

        if self.hvault_addr and self.hvault_token:
            try:
                import hvac
                self._hvac_client = hvac.Client(url=self.hvault_addr, token=self.hvault_token, verify=True)
            except Exception:
                self._hvac_client = None

    def get_secret(self, name: str) -> Optional[bytes]:
        if self._azure_client:
            try:
                v = self._azure_client.get_secret(name)
                if v and v.value is not None:
                    return v.value.encode("utf-8")
            except Exception:
                pass
        if self._hvac_client:
            try:
                mount = os.getenv("VAULT_KV_MOUNT", "secret")
                resp = self._hvac_client.secrets.kv.v2.read_secret_version(path=name) if hasattr(self._hvac_client.secrets, "kv") else self._hvac_client.read(f"{mount}/data/{name}")
                if resp:
                    data = resp["data"]["data"] if "data" in resp and "data" in resp["data"] else resp.get("data")
                    if data and name in data:
                        val = data[name]
                        return val.encode("utf-8") if isinstance(val, str) else val
            except Exception:
                pass
        env_val = os.getenv(name)
        return env_val.encode("utf-8") if env_val else None


# ---------------- Log parsing and feature engineering ----------------
CLF_REGEX = re.compile(
    r'(?P<ip>\S+)\s+\S+\s+\S+\s+\[(?P<ts>[^\]]+)\]\s+"(?P<method>\S+)\s+(?P<path>\S+)\s+(?P<proto>[^"]+)"\s+(?P<status>\d{3})\s+(?P<bytes>\S+)\s+"(?P<ref>[^"]*)"\s+"(?P<ua>[^"]*)"'
)

SUSPICIOUS_TOKENS = [
    "union", "select", "drop", "sleep(", "' or '1'='1", "%27", "../", ";--", "xp_cmdshell", "<script", "benchmark(", "load_file", "outfile"
]

def shannon_entropy(s: str) -> float:
    if not s:
        return 0.0
    freq = {}
    for ch in s:
        freq[ch] = freq.get(ch, 0) + 1
    ent = 0.0
    for c in freq.values():
        p = c / len(s)
        ent -= p * math.log2(p)
    return ent

def parse_line(line: str) -> Optional[Dict[str, Any]]:
    m = CLF_REGEX.match(line.strip())
    if not m:
        return None
    d = m.groupdict()
    d["status"] = int(d["status"])
    d["bytes"] = 0 if d["bytes"] == "-" else int(d["bytes"])
    return d

def extract_features(d: Dict[str, Any]) -> List[float]:
    path = d.get("path", "")
    ua = d.get("ua", "")
    method = d.get("method", "")

    method_map = {"GET": 0, "POST": 1, "PUT": 2, "DELETE": 3, "PATCH": 4, "HEAD": 5, "OPTIONS": 6}
    method_id = method_map.get(method.upper(), -1)

    suspicious = any(tok in path.lower() for tok in SUSPICIOUS_TOKENS)
    qlen = len(path.split("?", 1)[1]) if "?" in path else 0

    feats = [
        float(method_id),
        float(d.get("status", 0)),
        float(d.get("bytes", 0)),
        float(len(path)),
        float(qlen),
        float(shannon_entropy(path)),
        float(shannon_entropy(ua)),
        1.0 if suspicious else 0.0,
    ]
    return feats

def load_dataset(path: str) -> Tuple[List[List[float]], List[str]]:
    X, raw = [], []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            parsed = parse_line(line)
            if not parsed:
                continue
            X.append(extract_features(parsed))
            raw.append(line.rstrip("\n"))
    return X, raw


# ---------------- Models: Isolation Forest + optional Autoencoder ----------------
def run_isolation_forest(X_train: List[List[float]], X_test: List[List[float]]) -> List[float]:
    try:
        from sklearn.ensemble import IsolationForest
    except Exception:
        print("scikit-learn is required for Isolation Forest. Install 'scikit-learn'.")
        sys.exit(1)

    iso = IsolationForest(
        n_estimators=200,
        max_samples="auto",
        contamination="auto",
        random_state=42,
        n_jobs=-1
    )
    iso.fit(X_train)
    # decision_function: higher = less anomalous, lower = more anomalous
    scores = iso.decision_function(X_test)
    # Convert to anomaly scores where higher = more anomalous
    inv = [-s for s in scores]
    return inv

def try_autoencoder_scores(X_train: List[List[float]], X_test: List[List[float]]) -> Optional[List[float]]:
    try:
        import torch
        import torch.nn as nn
        import torch.optim as optim
        import numpy as np
    except Exception:
        return None

    Xtr = torch.tensor(X_train, dtype=torch.float32)
    Xte = torch.tensor(X_test, dtype=torch.float32)

    in_dim = Xtr.shape[1]
    bottleneck = max(2, in_dim // 2)

    class AE(nn.Module):
        def __init__(self):
            super().__init__()
            self.enc = nn.Sequential(
                nn.Linear(in_dim, max(8, in_dim)),
                nn.ReLU(),
                nn.Linear(max(8, in_dim), bottleneck),
                nn.ReLU(),
            )
            self.dec = nn.Sequential(
                nn.Linear(bottleneck, max(8, in_dim)),
                nn.ReLU(),
                nn.Linear(max(8, in_dim), in_dim),
            )

        def forward(self, x):
            z = self.enc(x)
            return self.dec(z)

    model = AE()
    opt = optim.Adam(model.parameters(), lr=1e-3)
    loss_fn = nn.MSELoss()

    model.train()
    for epoch in range(50):  # light training for demo
        opt.zero_grad()
        out = model(Xtr)
        loss = loss_fn(out, Xtr)
        loss.backward()
        opt.step()

    model.eval()
    with torch.no_grad():
        rec = model(Xte)
        mse = ((rec - Xte) ** 2).mean(dim=1).cpu().numpy().tolist()
    return mse

def combine_scores(scores_a: List[float], scores_b: Optional[List[float]]) -> List[float]:
    if not scores_b:
        return scores_a
    # Normalize to z-scores and average
    def z(lst):
        mu = statistics.mean(lst)
        sd = statistics.pstdev(lst) or 1.0
        return [(x - mu) / sd for x in lst]
    za, zb = z(scores_a), z(scores_b)
    return [(a + b) / 2.0 for a, b in zip(za, zb)]


# ---------------- Main ----------------
def main():
    if len(sys.argv) != 3:
        print("Usage: python3 anomaly_detector.py <normal_log> <candidate_log>")
        sys.exit(1)

    normal_path, candidate_path = sys.argv[1], sys.argv[2]
    X_train, _ = load_dataset(normal_path)
    X_test, raw_lines = load_dataset(candidate_path)

    if len(X_train) < 10:
        print("Not enough training data. Provide at least ~50 normal lines for better results.")
    if len(X_test) == 0:
        print("No candidate lines parsed; check log format.")
        sys.exit(1)

    if_scores = run_isolation_forest(X_train, X_test)
    ae_scores = try_autoencoder_scores(X_train, X_test)
    scores = combine_scores(if_scores, ae_scores)

    # Threshold configuration (no plaintext): pull from vault or env; default to 1.5 std dev
    vault = VaultClient()
    thr_bytes = vault.get_secret("ANOMALY_THRESHOLD_Z")
    if thr_bytes:
        try:
            threshold_z = float(thr_bytes.decode("utf-8"))
        except Exception:
            threshold_z = 1.5
    else:
        threshold_z = 1.5

    # Convert to z-scores for flagging
    mu = statistics.mean(scores)
    sd = statistics.pstdev(scores) or 1.0
    zscores = [(s - mu) / sd for s in scores]
    flags = [1 if z >= threshold_z else 0 for z in zscores]

    # Heuristics: reasons
    reasons = []
    for line in raw_lines:
        l = line.lower()
        hits = [tok for tok in SUSPICIOUS_TOKENS if tok in l]
        reasons.append(",".join(hits) if hits else "")

    out_path = "anomaly_results.csv"
    with open(out_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["line", "anomaly_score", "zscore", "flag", "reason_tokens"])
        for ln, s, z, fl, r in zip(raw_lines, scores, zscores, flags, reasons):
            w.writerow([ln, f"{s:.6f}", f"{z:.3f}", fl, r])

    print(f"Wrote results to {out_path}")
    flagged = sum(flags)
    print(f"Flagged {flagged} of {len(flags)} lines as anomalous (threshold_z={threshold_z}).")

if __name__ == "__main__":
    main()
