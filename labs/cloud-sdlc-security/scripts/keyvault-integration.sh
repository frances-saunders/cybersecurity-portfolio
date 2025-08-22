#!/bin/bash
# Secure Key Vault Secret Retrieval Script
# Demonstrates pulling secrets at runtime without exposing plaintext

set -euo pipefail

# Variables (replace with your values or pipeline-injected ones)
SUBSCRIPTION_ID="<sub_id>"
RESOURCE_GROUP="rg-sdlc-lab"
KEYVAULT_NAME="sdlc-lab-kv"
SECRET_NAME="sql-admin-password"

echo "[INFO] Retrieving secret '$SECRET_NAME' from Key Vault: $KEYVAULT_NAME"

SECRET_VALUE=$(az keyvault secret show \
  --subscription "$SUBSCRIPTION_ID" \
  --vault-name "$KEYVAULT_NAME" \
  --name "$SECRET_NAME" \
  --query "value" -o tsv)

if [[ -z "$SECRET_VALUE" ]]; then
  echo "[ERROR] Failed to retrieve secret."
  exit 1
fi

echo "[INFO] Secret successfully retrieved and can be injected into Terraform or application runtime."
# Example: terraform apply -var="admin_password=$SECRET_VALUE"
