#!/usr/bin/env bash
# docker-bench-wrapper.sh
# Wrapper to run Docker Bench for Security with an allowlist and machine-readable JSON summary.
# - Requires Docker or root to run docker/docker-bench-security
# - Allowlist file contains check IDs (e.g., 5.9, 4.1) to ignore FAIL/WARN
# - Output: summary.json with pass/warn/fail counts and failing checks (minus allowlisted)

set -Eeuo pipefail
IFS=$'\n\t'

usage(){ cat <<EOF
Usage: $0 [--allowlist allow.txt] [--out summary.json]
EOF
}

ALLOW=""; OUT="summary.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --allowlist) ALLOW="$2"; shift 2;;
    --out) OUT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg $1"; usage; exit 1;;
  esac
done

ALLOW_RE=""
if [[ -n "$ALLOW" && -f "$ALLOW" ]]; then
  # Build regex like: (5\.9|4\.1|...)
  ALLOW_RE="$(paste -sd'|' <(sed -E 's/\./\\./g' "$ALLOW"))"
fi

# Run Docker Bench (official container)
LOG=$(mktemp)
docker run --rm --net host --pid host --cap-add audit_control \
  -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro -v /etc:/etc:ro \
  docker/docker-bench-security > "$LOG"

# Parse results
FAILS=(); WARNS=(); PASSES=0
while IFS= read -r line; do
  # Lines look like: [PASS] 5.9  Ensure ... OR [WARN]/[FAIL]
  if [[ "$line" =~ ^\[(PASS|WARN|FAIL)\]\ ([0-9]+\.[0-9]+) ]]; then
    status="${BASH_REMATCH[1]}"; check="${BASH_REMATCH[2]}"
    if [[ "$status" == "PASS" ]]; then
      ((PASSES++))
    elif [[ "$status" == "WARN" ]]; then
      if [[ -n "$ALLOW_RE" && "$check" =~ $ALLOW_RE ]]; then continue; fi
      WARNS+=("$check")
    else
      if [[ -n "$ALLOW_RE" && "$check" =~ $ALLOW_RE ]]; then continue; fi
      FAILS+=("$check")
    fi
  fi
done < "$LOG"

jq -n --argjson pass $PASSES \
      --argjson warn_count ${#WARNS[@]} \
      --argjson fail_count ${#FAILS[@]} \
      --argjson warns "$(printf '%s\n' "${WARNS[@]:-}" | jq -R . | jq -s .)" \
      --argjson fails "$(printf '%s\n' "${FAILS[@]:-}" | jq -R . | jq -s .)" \
      '{pass:$pass, warn_count:$warn_count, fail_count:$fail_count, warns:$warns, fails:$fails}' > "$OUT"

echo "[+] Summary written to $OUT"
rm -f "$LOG"
