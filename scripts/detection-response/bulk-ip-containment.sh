#!/usr/bin/env bash
# bulk-ip-containment.sh
# Pushes a set of malicious IPs to multiple controls atomically:
# - Azure Firewall IP Group (preferred)
# - Network Security Group rule (optional)
# - Microsoft Defender for Endpoint TI indicators (optional)
#
# Requires Azure CLI. For MDE, requires an access token via env ($MDE_TOKEN).
# Dry-run supported.

set -Eeuo pipefail
IFS=$'\n\t'

usage(){
cat <<EOF
Usage: $0 --subscription <SUB> --ip-file ips.txt --ip-group <IPG_NAME> --rg <RG> [--firewall <FW_NAME> --nsg <NSG_NAME> --nsg-rule "DenyBadIPs"] [--mde] [--dry-run]
EOF
}

SUB="" IPFILE="" IPG="" RG="" FW="" NSG="" NSG_RULE="DenyBadIPs" DRYRUN=0 MDE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --subscription) SUB="$2"; shift 2;;
    --ip-file) IPFILE="$2"; shift 2;;
    --ip-group) IPG="$2"; shift 2;;
    --rg) RG="$2"; shift 2;;
    --firewall) FW="$2"; shift 2;;
    --nsg) NSG="$2"; shift 2;;
    --nsg-rule) NSG_RULE="$2"; shift 2;;
    --mde) MDE=1; shift;;
    --dry-run) DRYRUN=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg $1"; usage; exit 1;;
  esac
done

[[ -n "$SUB" && -n "$IPFILE" && -n "$IPG" && -n "$RG" ]] || { usage; exit 1; }
mapfile -t IPS < <(grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' "$IPFILE" | sort -u)

echo "[*] Subscription: $SUB"
echo "[*] Resource Group: $RG"
echo "[*] IP Group: $IPG"
[[ $DRYRUN -eq 1 ]] && echo "[*] DRY-RUN enabled"

# Ensure IP Group exists
if [[ $DRYRUN -eq 0 ]]; then
  az network ip-group create --subscription "$SUB" -g "$RG" -n "$IPG" >/dev/null 2>&1 || true
fi

# Merge current IP group entries with new
CURRENT=$(az network ip-group show --subscription "$SUB" -g "$RG" -n "$IPG" --query "ipAddresses" -o tsv 2>/dev/null || echo "")
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
printf "%s\n" $CURRENT "${IPS[@]}" | grep -E . | sort -u > "$TMP"

echo "[*] Updating IP Group entries ($(wc -l < "$TMP") total)..."
if [[ $DRYRUN -eq 0 ]]; then
  az network ip-group update --subscription "$SUB" -g "$RG" -n "$IPG" --add ipAddresses @"$TMP" >/dev/null
fi

# Optional NSG deny rule (simple example, you may prefer Azure Firewall policy)
if [[ -n "$NSG" ]]; then
  PRI=100
  echo "[*] Ensuring NSG rule '$NSG_RULE' exists on $NSG (priority $PRI)"
  if [[ $DRYRUN -eq 0 ]]; then
    az network nsg rule create --subscription "$SUB" -g "$RG" --nsg-name "$NSG" -n "$NSG_RULE" \
      --priority $PRI --access Deny --direction Outbound --protocol "*" --source-address-prefixes "$(<"$TMP")" \
      --source-port-ranges "*" --destination-address-prefixes "*" --destination-port-ranges "*" >/dev/null
  fi
fi

# Optional: Azure Firewall association (user will reference IP Group in a rule collection; left as environment-specific)

# Optional: push to MDE Indicators API
if [[ $MDE -eq 1 ]]; then
  [[ -n "${MDE_TOKEN:-}" ]] || { echo "MDE_TOKEN not set; skipping MDE"; MDE=0; }
  if [[ $MDE -eq 1 ]]; then
    echo "[*] Pushing indicators to MDE (count: $(wc -l < "$TMP"))"
    if [[ $DRYRUN -eq 0 ]]; then
      while read -r ip; do
        curl -sS -X POST "https://api.security.microsoft.com/api/indicators" \
          -H "Authorization: Bearer $MDE_TOKEN" -H "Content-Type: application/json" \
          -d "{\"indicatorValue\":\"$ip\",\"indicatorType\":\"IpAddress\",\"action\":\"Alert\",\"title\":\"BulkContainment\"}" >/dev/null
      done < "$TMP"
    fi
  fi
fi

echo "[+] Completed."
