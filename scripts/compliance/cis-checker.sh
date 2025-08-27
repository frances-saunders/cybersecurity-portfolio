#!/bin/bash
# Run CIS checks (Linux baseline example)

echo "[*] Checking password policy..."
grep PASS_MAX_DAYS /etc/login.defs
