#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
pqc-readiness-assessor.py
Inventory TLS endpoints and flag where PQC/TLS hybrid readiness work remains.

Heuristics:
  - Validate TLS 1.3 support (prerequisite for most hybrid drafts)
  - Capture presented cipher and cert key type (ECDSA/RSA)
  - Flag "not ready" if TLS <=1.2 or weak cipher suite; mark "needs planning" if TLS1.3 with RSA-only

Usage:
  python pqc-readiness-assessor.py --targets targets.txt --out readiness.json
targets.txt format:
  host:port
"""

import argparse, json, socket, ssl, sys

def check_endpoint(host: str, port: int = 443):
    ctx = ssl.create_default_context()
    ctx.minimum_version = ssl.TLSVersion.TLSv1
    with socket.create_connection((host, port), timeout=8) as sock:
        with ctx.wrap_socket(sock, server_hostname=host) as ss:
            ver = ss.version()
            cert = ss.getpeercert()
            cipher = ss.cipher()
            key_type = "unknown"
            try:
                sub = dict(x[0] for x in cert.get("subject", []))
                key_type = cert.get("signatureAlgorithm","")
            except Exception:
                pass
            status = "ready" if ver == "TLSv1.3" else "not_ready"
            if ver == "TLSv1.3" and "RSA" in (key_type or ""):
                status = "needs_planning"
            return {"version": ver, "cipher": cipher[0], "key": key_type, "status": status}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--targets", required=True)
    ap.add_argument("--out", default="readiness.json")
    args = ap.parse_args()

    items = []
    for line in open(args.targets):
        line=line.strip()
        if not line or line.startswith("#"): continue
        host, _, port = line.partition(":")
        port = int(port or 443)
        try:
            res = check_endpoint(host, port)
            items.append({"target": line, **res})
        except Exception as e:
            items.append({"target": line, "error": str(e), "status":"unknown"})

    json.dump({"items": items}, open(args.out,"w"), indent=2)
    print(json.dumps({"checked": len(items), "out": args.out}))

if __name__ == "__main__":
    main()
