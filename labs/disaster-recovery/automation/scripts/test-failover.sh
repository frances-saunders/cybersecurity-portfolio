#!/bin/bash
# Simulate failover of Azure SQL Failover Group and measure RTO

FAILOVER_GROUP="TelemetryDB-fog"
RESOURCE_GROUP="rg-dr-lab"
SECONDARY_SERVER="telemetry-sql-secondary"
KEYVAULT_NAME="dr-keyvault"
SECRET_NAME="SqlAdminPassword"

START=$(date +%s)
echo "Initiating failover for $FAILOVER_GROUP..."

az sql failover-group set-primary \
  --name $FAILOVER_GROUP \
  --resource-group $RESOURCE_GROUP \
  --server $SECONDARY_SERVER

END=$(date +%s)
RTO=$((END - START))

echo "Failover complete. RTO: ${RTO}s"

# Fetch SQL admin password from Key Vault
SQL_ADMIN_PASSWORD=$(az keyvault secret show \
  --vault-name "$KEYVAULT_NAME" \
  --name "$SECRET_NAME" \
  --query value -o tsv)

# Validate connectivity
sqlcmd -S "${SECONDARY_SERVER}.database.windows.net" -d "TelemetryDB" -U telemetryadmin -P "$SQL_ADMIN_PASSWORD" -Q "SELECT TOP 1 GETDATE();" \
  && echo "Database connectivity validated post-failover." \
  || echo "Connectivity validation failed!"
