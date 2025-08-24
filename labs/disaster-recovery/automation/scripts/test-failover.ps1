<#
.SYNOPSIS
  Simulates disaster recovery failover for Azure SQL and retrieves the SQL admin password from Azure Key Vault.

.DESCRIPTION
  Forces failover of SQL failover group to secondary region, retrieves the SQL admin password securely from Key Vault, validates connectivity, and reports recovery time.
#>

param(
  [string]$FailoverGroup = "TelemetryDB-fog",
  [string]$ResourceGroup = "rg-dr-lab",
  [string]$KeyVaultName = "dr-keyvault",
  [string]$SecretName   = "SqlAdminPassword"
)

$start = Get-Date
Write-Host "Initiating failover for $FailoverGroup..."

az sql failover-group set-primary `
  --name $FailoverGroup `
  --resource-group $ResourceGroup `
  --server $FailoverGroup-secondary

$end = Get-Date
$duration = ($end - $start).TotalSeconds
Write-Host "Failover complete. RTO: $duration seconds"

# Retrieve SQL admin password from Key Vault
$SqlAdminPassword = az keyvault secret show --vault-name $KeyVaultName --name $SecretName --query value -o tsv
if (-not $SqlAdminPassword) {
    throw "Failed to retrieve secret '$SecretName' from key vault '$KeyVaultName'"
}

# Validate connectivity
try {
    sqlcmd -S "$FailoverGroup-secondary.database.windows.net" -d "TelemetryDB" -U telemetryadmin -P $SqlAdminPassword -Q "SELECT TOP 1 GETDATE();"
    Write-Host "Database connectivity validated post-failover."
} catch {
    Write-Error "Connectivity validation failed!"
}
