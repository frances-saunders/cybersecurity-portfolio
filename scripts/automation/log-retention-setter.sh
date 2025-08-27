#!/usr/bin/env bash
# log-retention-setter.sh
# Apply minimum retention across Log Analytics Workspaces and Storage Accounts.
# - Uses Azure CLI; no plaintext credentials; honors --dry-run
# - Targets by subscription and optional resource group or tag filter
# - LAW: az monitor log-analytics workspace update --retention-time <days>
# - Storage (Blob service): az storage blob service-properties update --delete-retention-days <days>

set -Eeuo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: $0 --subscription <SUB_ID> [--resource-group <RG>] [--tag key=value] \
          --min-law-days <N> --min-storage-days <N> [--dry-run]

Examples:
  $0 --subscription 0000-... --min-law-days 30 --min-storage-days 30 --dry-run
EOF
}

SUB=""; RG=""; TAG=""
MIN_LAW=0; MIN_STOR=0; DRYRUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription) SUB="$2"; shift 2;;
    --resource-group) RG="$2"; shift 2;;
    --tag) TAG="$2"; shift 2;;
    --min-law-days) MIN_LAW="$2"; shift 2;;
    --min-storage-days) MIN_STOR="$2"; shift 2;;
    --dry-run) DRYRUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -n "$SUB" && $MIN_LAW -ge 0 && $MIN_STOR -ge 0 ]] || { usage; exit 1; }

echo "[*] Target subscription: $SUB"
[[ -n "$RG" ]] && echo "[*] Resource group filter: $RG"
[[ -n "$TAG" ]] && echo "[*] Tag filter: $TAG"
[[ $DRYRUN -eq 1 ]] && echo "[*] DRY-RUN enabled"

# --- LAW workspaces ---
LAW_Q='[].{name:name,rg:resourceGroup,retention:retentionInDays}'
LAW_CMD=(az monitor log-analytics workspace list --subscription "$SUB" -o json --query "$LAW_Q")
[[ -n "$RG" ]] && LAW_CMD+=( -g "$RG" )
[[ -n "$TAG" ]] && LAW_CMD+=( --tag "$TAG" )

mapfile -t LAW < <("${LAW_CMD[@]}" | jq -c '.[]')
for row in "${LAW[@]}"; do
  name=$(jq -r '.name' <<<"$row")
  rg=$(jq -r '.rg' <<<"$row")
  current=$(jq -r '.retention' <<<"$row")
  if [[ "$current" -lt "$MIN_LAW" ]]; then
    echo "[LAW] $rg/$name: $current -> $MIN_LAW days"
    if [[ $DRYRUN -eq 0 ]]; then
      az monitor log-analytics workspace update --subscription "$SUB" -g "$rg" -n "$name" --retention-time "$MIN_LAW" >/dev/null
    fi
  fi
done

# --- Storage Accounts (Blob delete retention) ---
ST_Q='[].{name:name,rg:resourceGroup}'
ST_CMD=(az storage account list --subscription "$SUB" -o json --query "$ST_Q")
[[ -n "$RG" ]] && ST_CMD+=( -g "$RG" )
[[ -n "$TAG" ]] && ST_CMD+=( --tags "$TAG" )

mapfile -t ST < <("${ST_CMD[@]}" | jq -c '.[]')
for row in "${ST[@]}"; do
  name=$(jq -r '.name' <<<"$row")
  rg=$(jq -r '.rg' <<<"$row")
  # Query current retention; fall back to 0 on error
  current=$(az storage blob service-properties show --account-name "$name" 2>/dev/null | jq -r '.deleteRetentionPolicy.days // 0')
  if [[ "$current" -lt "$MIN_STOR" ]]; then
    echo "[STG] $rg/$name: $current -> $MIN_STOR days"
    if [[ $DRYRUN -eq 0 ]]; then
      az storage blob service-properties update --account-name "$name" --enable-delete-retention true --delete-retention-days "$MIN_STOR" >/dev/null
    fi
  fi
done

echo "[+] Completed."
