#!/usr/bin/env bash
# quarantine-device.sh
# Quarantines/isolation via EDR API using OAuth token from env/Key Vault (not plaintext).
# Exits non-zero on failure. Emits minimal JSON for pipeline consumption.

set -Eeuo pipefail
IFS=$'\n\t'

usage(){ echo "Usage: $0 -d <device_id> -u <api_url>"; }
DEVICE="" API_URL=""

while getopts ":d:u:" opt; do
  case $opt in
    d) DEVICE="$OPTARG" ;;
    u) API_URL="$OPTARG" ;;
    *) usage; exit 1 ;;
  esac
done

[[ -n "$DEVICE" && -n "$API_URL" ]] || { usage; exit 2; }
[[ -n "${EDR_TOKEN:-}" ]] || { echo '{"error":"EDR_TOKEN not set"}'; exit 3; }

resp=$(curl -sS -X POST "$API_URL" \
  -H "Authorization: Bearer $EDR_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"device\":\"$DEVICE\"}")

code=$?
if [[ $code -ne 0 ]]; then
  echo "{\"status\":\"error\",\"detail\":\"curl_exit_$code\"}"; exit $code
fi

echo "$resp"
