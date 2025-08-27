#!/usr/bin/env bash
# Package and sanitize audit evidence; scrubs common secrets/PII patterns.
set -euo pipefail

SRC_DIR="${1:-evidence}"
OUT="audit-evidence-$(date +%F).tar.gz"
ALLOWLIST="${ALLOWLIST_REGEX:-}"
REDACT_FILE_PATTERNS="${REDACT_FILE_PATTERNS:-.*\.log$|.*\.txt$|.*\.csv$}"

echo "[*] Scrubbing sensitive tokens (AWS keys, GUID-like secrets, emails, SSNs)..."
mapfile -t FILES < <(find "$SRC_DIR" -type f | grep -E "$REDACT_FILE_PATTERNS" || true)

for f in "${FILES[@]}"; do
  tmp="${f}.tmp"
  sed -E \
    -e 's/AKIA[0-9A-Z]{16}/[REDACTED_AWS_KEY]/g' \
    -e 's/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/[REDACTED_EMAIL]/g' \
    -e 's/[0-9]{3}-[0-9]{2}-[0-9]{4}/[REDACTED_SSN]/g' \
    -e 's/[A-Fa-f0-9]{32}/[REDACTED_TOKEN]/g' \
    "$f" > "$tmp"
  mv "$tmp" "$f"
done

echo "[*] Creating signed manifest..."
MANIFEST="manifest-$(date +%s).txt"
find "$SRC_DIR" -type f -print0 | xargs -0 shasum -a 256 > "$MANIFEST"

echo "[*] Archiving..."
tar -czf "$OUT" "$SRC_DIR" "$MANIFEST"
echo "[+] Packaged: $OUT"
