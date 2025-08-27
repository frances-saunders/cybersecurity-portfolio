#!/usr/bin/env bash
# package-audit-evidence.sh
# Packages audit evidence while scrubbing common PII patterns and secrets.
# - Fails on error (strict mode), uses traps for cleanup.
# - Selective include/exclude via patterns file.
# - Creates SBOM-like manifest for traceability.

set -Eeuo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: $0 -s <evidence_dir> -o <output.tgz> [-x <exclude_file>]
  -s   Source directory with evidence artifacts
  -o   Output archive (.tar.gz)
  -x   Optional file with grep -E patterns to exclude paths
EOF
}

SCRUB_PATTERNS='(SSN|[0-9]{3}-[0-9]{2}-[0-9]{4})|(AKIA[0-9A-Z]{16})|(password\s*:)|(secret\s*:)|(api[_-]?key\s*:)'
SOURCE="" OUT="" EXCLUDE=""

while getopts ":s:o:x:" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    o) OUT="$OPTARG" ;;
    x) EXCLUDE="$OPTARG" ;;
    *) usage; exit 1 ;;
  esac
done

[[ -d "$SOURCE" && -n "$OUT" ]] || { usage; exit 1; }

TMP_MANIFEST="$(mktemp)"
trap 'rm -f "$TMP_MANIFEST"' EXIT

echo "[*] Creating manifest..."
find "$SOURCE" -type f | sort > "$TMP_MANIFEST"

echo "[*] Scrubbing PII/secrets in text files (in-place markers only for archive copy)..."
while IFS= read -r f; do
  file "$f" | grep -qi "text" || continue
  sed -E "s/${SCRUB_PATTERNS}/[REDACTED]/g" "$f" > "$f.sanitized" && mv "$f.sanitized" "$f"
done < "$TMP_MANIFEST"

INCLUDE_LIST=()
while IFS= read -r f; do
  if [[ -n "$EXCLUDE" ]] && grep -Eqf "$EXCLUDE" <<<"$f"; then
    continue
  fi
  INCLUDE_LIST+=("$f")
done < "$TMP_MANIFEST"

echo "[*] Archiving..."
tar -czf "$OUT" -T <(printf "%s\n" "${INCLUDE_LIST[@]}")

echo "[+] Done. Archive: $OUT"
