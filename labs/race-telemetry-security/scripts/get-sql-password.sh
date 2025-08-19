#!/bin/bash
# =============================================================
# Retrieve the SQL admin password securely from Azure Key Vault
# =============================================================
# Uses the Azure CLI and current logged-in identity.
# Best used in CI/CD pipelines to avoid hardcoding credentials.
# =============================================================

KEYVAULT_NAME="telemetry-kv"
SECRET_NAME="sql-admin-password"

echo "Retrieving secret '$SECRET_NAME' from Key Vault '$KEYVAULT_NAME'..."

# Check login
if ! az account show > /dev/null 2>&1; then
  echo "Not logged in. Please run 'az login' first."
  exit 1
fi

# Get secret
SECRET_VALUE=$(az keyvault secret show \
  --vault-name "$KEYVAULT_NAME" \
  --name "$SECRET_NAME" \
  --query value -o tsv)

if [ -z "$SECRET_VALUE" ]; then
  echo "Failed to retrieve secret. Check Key Vault access policies."
  exit 1
fi

echo "Secret retrieved successfully."
# In pipelines, export it instead of echoing:
# export SQL_ADMIN_PASSWORD="$SECRET_VALUE"
