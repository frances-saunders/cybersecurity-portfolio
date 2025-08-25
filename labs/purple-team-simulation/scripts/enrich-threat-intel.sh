#!/usr/bin/env bash
# Enrich IOCs (IPs/domains/hashes) using OSINT sources.
# Secrets:
#   - Prefer Managed Identity/Key Vault; fallback to env vars.
# Env:
#   VT_API_KEY (VirusTotal), OTX_API_KEY (AlienVault) if not stored in Key Vault.

set -euo pipefail

INPUT_FILE="${1:-iocs.txt}"
OUT_FILE="${2:-enrichment.jsonl}"
KEYVAULT_NAME="${KEYVAULT_NAME:-}"

fetch_secret() {
  local name="$1"
  if [[ -n "$KEYVAULT_NAME" ]]; then
    az keyvault secret show --vault-name "$KEYVAULT_NAME" --name "$name" --query value -o tsv 2>/dev/null || true
  fi
}

VT_KEY="${VT_API_KEY:-$(fetch_secret VT_API_KEY)}"
OTX_KEY="${OTX_API_KEY:-$(fetch_secret OTX_API_KEY)}"

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

enrich_vt() {
  local ioc="$1"
  [[ -z "$VT_KEY" ]] && return 0
  curl -s -H "x-apikey: $VT_KEY" "https://www.virustotal.com/api/v3/search?query=$ioc" \
    | jq -c --arg source "virustotal" --arg ioc "$ioc" --arg ts "$(timestamp)" '{source:$source, ioc:$ioc, ts:$ts, data:.}' \
    || true
}

enrich_otx() {
  local ioc="$1"
  [[ -z "$OTX_KEY" ]] && return 0
  curl -s -H "X-OTX-API-KEY: $OTX_KEY" "https://otx.alienvault.com/api/v1/indicators/IPv4/$ioc/general" \
    | jq -c --arg source "otx" --arg ioc "$ioc" --arg ts "$(timestamp)" '{source:$source, ioc:$ioc, ts:$ts, data:.}' \
    || true
}

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Input file $INPUT_FILE not found"; exit 1
fi

: > "$OUT_FILE"
while IFS= read -r IOC; do
  [[ -z "$IOC" ]] && continue
  echo "Enriching $IOC ..."
  (enrich_vt "$IOC"; enrich_otx "$IOC") >> "$OUT_FILE"
done < "$INPUT_FILE"

echo "Enrichment complete -> $OUT_FILE"
