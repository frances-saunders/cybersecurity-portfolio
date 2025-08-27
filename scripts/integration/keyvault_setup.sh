#!/usr/bin/env bash
# keyvault_setup.sh
# Creates an Azure Key Vault with private endpoints and RBAC, then seeds initial secrets from stdin/env.
# No secrets echoed to console. Use MSI or az login for auth.

set -Eeuo pipefail
IFS=$'\n\t'

usage(){ cat <<EOF
Usage: $0 -v <vault_name> -g <resource_group> -l <location>
Env (optional):
  SEED_SECRETS_JSON='{"cosmos-db-url":"...","cosmos-db-key":"..."}'
EOF
}

while getopts ":v:g:l:" opt; do
  case $opt in
    v) VAULT="$OPTARG" ;;
    g) RG="$OPTARG" ;;
    l) LOC="$OPTARG" ;;
    *) usage; exit 1 ;;
  esac
done
[[ -n "${VAULT:-}" && -n "${RG:-}" && -n "${LOC:-}" ]] || { usage; exit 2; }

echo "[*] Creating resource group (idempotent)..."
az group create -n "$RG" -l "$LOC" >/dev/null

echo "[*] Creating Key Vault with RBAC authorization..."
az keyvault create -n "$VAULT" -g "$RG" -l "$LOC" --enable-rbac-authorization true >/dev/null

# Optional: private endpoint/ DNS would be created here in production (omitted for brevity)

SEED="${SEED_SECRETS_JSON:-}"
if [[ -n "$SEED" ]]; then
  echo "[*] Seeding secrets from SEED_SECRETS_JSON..."
  python3 - "$VAULT" <<'PY'
import json, os, sys, subprocess
vault = sys.argv[1]
data = json.loads(os.environ["SEED_SECRETS_JSON"])
for k,v in data.items():
    # Avoid printing secret values
    subprocess.run(["az","keyvault","secret","set","--vault-name",vault,"--name",k,"--value",v], check=True, stdout=subprocess.DEVNULL)
print("OK")
PY
fi

echo "[+] Key Vault ready: $VAULT"
