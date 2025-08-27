#!/bin/bash
# Package compliance/audit evidence into a sanitized tarball

set -e
OUTPUT="audit-evidence-$(date +%F).tar.gz"
SOURCE_DIR="evidence/"

echo "[*] Sanitizing PII..."
find $SOURCE_DIR -type f -exec sed -i 's/[0-9]\{9\}/[REDACTED-SSN]/g' {} \;

echo "[*] Creating archive..."
tar -czf $OUTPUT $SOURCE_DIR

echo "[+] Evidence packaged: $OUTPUT"
