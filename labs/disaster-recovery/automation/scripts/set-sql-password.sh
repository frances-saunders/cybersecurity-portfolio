#!/bin/bash
# ------------------------------------------------------------------------------
# Rotates the SQL Server administrator password and stores it in Azure Key Vault
# Location: disaster-recovery/automation/scripts/set-sql-password.sh
# ------------------------------------------------------------------------------

RESOURCE_GROUP="rg-dr-lab"
SQL_SERVER_NAME="dr-sql-server"
KEYVAULT_NAME="dr-keyvault"
SECRET_NAME="SqlAdminPassword"

# Generate secure random password (20 chars, alphanumeric + symbols)
PASSWORD=$(openssl rand -base64 20 | tr -d "=+/")

echo "🔐 Generated new password for SQL Server: $SQL_SERVER_NAME"

# Update SQL Server admin password
az sql server update \
  --name $SQL_SERVER_NAME \
  --resource-group $RESOURCE_GROUP \
  --admin-password $PASSWORD

# Store in Key Vault
az keyvault secret set \
  --vault-name $KEYVAULT_NAME \
  --name $SECRET_NAME \
  --value $PASSWORD

echo "✅ Password rotated and stored in Key Vault ($KEYVAULT_NAME/$SECRET_NAME)"
