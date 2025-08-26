#!/usr/bin/env bash
set -euo pipefail

# Purpose: Create an Azure Key Vault and populate secrets WITHOUT plaintext in code.
# Values are taken from environment variables when provided; otherwise, safe defaults are generated for non-sensitive items.
# Required: az CLI is logged in (preferably with managed identity or device login).

# Inputs (export before running as needed):
#   KV_NAME, RG, LOC
# Optional Secrets (export to set; if unset they are skipped or generated):
#   HKDF_SALT            # if absent, a random 32B value is generated
#   ANOMALY_THRESHOLD_Z  # e.g., "1.5"
#   COSMOS_ENDPOINT
#   COSMOS_DB_NAME
#   COSMOS_CONTAINER_NAME
#   SQL_SERVER
#   SQL_DATABASE

: "${KV_NAME:?Set KV_NAME}"
: "${RG:?Set RG}"
: "${LOC:?Set LOC}"

echo "Creating resource group ${RG} in ${LOC}..."
az group create --name "$RG" --location "$LOC" >/dev/null

echo "Creating Key Vault ${KV_NAME}..."
az keyvault create --name "$KV_NAME" --resource-group "$RG" --location "$LOC" --enable-rbac-authorization true >/dev/null

KV_URI="https://${KV_NAME}.vault.azure.net/"
echo "Key Vault URI: ${KV_URI}"

# HKDF_SALT (generate if missing)
if [[ -z "${HKDF_SALT:-}" ]]; then
  echo "Generating HKDF_SALT..."
  HKDF_SALT="$(openssl rand -base64 32)"
fi
az keyvault secret set --vault-name "$KV_NAME" --name "HKDF_SALT" --value "$HKDF_SALT" >/dev/null

# Optional numeric threshold
if [[ -n "${ANOMALY_THRESHOLD_Z:-}" ]]; then
  az keyvault secret set --vault-name "$KV_NAME" --name "ANOMALY_THRESHOLD_Z" --value "$ANOMALY_THRESHOLD_Z" >/dev/null
fi

# Optional connection metadata (not passwords)
for NAME in COSMOS_ENDPOINT COSMOS_DB_NAME COSMOS_CONTAINER_NAME SQL_SERVER SQL_DATABASE; do
  VAL="${!NAME:-}"
  if [[ -n "$VAL" ]]; then
    az keyvault secret set --vault-name "$KV_NAME" --name "$NAME" --value "$VAL" >/dev/null
  fi
done

echo "Done. Export AZURE_KEY_VAULT_URI=${KV_URI} for your workloads."
