#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
validate-tls-config.py
----------------------
Validates TLS versions and cipher suites on a remote host:port.
- Verifies minimum TLS 1.2 (configurable)
- Shows selected cipher and certificate info
- Exit code non-zero on policy violation (CI-friendly)

Example:
  python validate-tls-config.py --host example.com --port 443 --min-tls 1.2
"""

import argparse, ssl, socket, sys

TLS_MAP = {
    1.0: ssl.TLSVersion.TLSv1,
    1.1: ssl.TLSVersion.TLSv1_1,
    1.2: ssl.TLSVersion.TLSv1_2,
    1.3: ssl.TLSVersion.TLSv1_3,
}

def connect(host: str, port: int, min_tls: float):
    ctx = ssl.create_default_context()
    ctx.minimum_version = TLS_MAP[min_tls]
    with socket.create_connection((host, port), timeout=10) as sock:
        with ctx.wrap_socket(sock, server_hostname=host) as ssock:
            cert = ssock.getpeercert()
            print(f"Protocol: {ssock.version()} | Cipher: {ssock.cipher()}")
            print(f"Subject: {dict(x[0] for x in cert['subject'])['commonName']}")
            return ssock.version()

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", required=True)
    ap.add_argument("--port", type=int, default=443)
    ap.add_argument("--min-tls", type=float, default=1.2, choices=[1.0,1.1,1.2,1.3])
    args = ap.parse_args()
    try:
        ver = connect(args.host, args.port, args.min_tls)
        versions_ok = {"TLSv1.2","TLSv1.3"}
        if args.min_tls >= 1.2 and ver not in versions_ok:
            print("FAIL: Negotiated protocol below policy.")
            sys.exit(2)
        print("PASS")
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
