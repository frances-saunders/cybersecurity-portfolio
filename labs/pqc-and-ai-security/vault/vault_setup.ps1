<#
Purpose: Create Azure Key Vault and populate secrets securely (no plaintext in code).
Pre-reqs: Az.Accounts, Az.KeyVault modules. Login with Connect-AzAccount or managed identity.
Inputs (set in session):
  $KV_NAME, $RG, $LOC
Optional secrets:
  $HKDF_SALT, $ANOMALY_THRESHOLD_Z, $COSMOS_ENDPOINT, $COSMOS_DB_NAME, $COSMOS_CONTAINER_NAME, $SQL_SERVER, $SQL_DATABASE
#>

param()

if (-not $env:KV_NAME -or -not $env:RG -or -not $env:LOC) {
  throw "Set KV_NAME, RG, LOC environment variables."
}

$KV_NAME = $env:KV_NAME
$RG = $env:RG
$LOC = $env:LOC

Write-Host "Creating resource group $RG in $LOC..."
az group create --name $RG --location $LOC | Out-Null

Write-Host "Creating Key Vault $KV_NAME..."
az keyvault create --name $KV_NAME --resource-group $RG --location $LOC --enable-rbac-authorization true | Out-Null

$kvUri = "https://$KV_NAME.vault.azure.net/"
Write-Host "Key Vault URI: $kvUri"

# HKDF_SALT (generate if missing)
if (-not $env:HKDF_SALT) {
  Write-Host "Generating HKDF_SALT..."
  $bytes = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $env:HKDF_SALT = [Convert]::ToBase64String($bytes)
}
az keyvault secret set --vault-name $KV_NAME --name "HKDF_SALT" --value $env:HKDF_SALT | Out-Null

# Optional numeric threshold
if ($env:ANOMALY_THRESHOLD_Z) {
  az keyvault secret set --vault-name $KV_NAME --name "ANOMALY_THRESHOLD_Z" --value $env:ANOMALY_THRESHOLD_Z | Out-Null
}

# Optional non-secret connection metadata
$names = @("COSMOS_ENDPOINT","COSMOS_DB_NAME","COSMOS_CONTAINER_NAME","SQL_SERVER","SQL_DATABASE")
foreach ($n in $names) {
  $v = [Environment]::GetEnvironmentVariable($n)
  if ($v) {
    az keyvault secret set --vault-name $KV_NAME --name $n --value $v | Out-Null
  }
}

Write-Host "Done. Set AZURE_KEY_VAULT_URI=$kvUri in your workloads."
