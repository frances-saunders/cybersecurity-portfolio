<#
.SYNOPSIS
    Retrieve the SQL admin password securely from Azure Key Vault.

.DESCRIPTION
    Uses the Azure CLI and logged-in identity to pull a secret.
    Ensures credentials are never stored in plaintext within Terraform,
    pipelines, or Git repos.
#>

param(
    [string]$KeyVaultName = "telemetry-kv",
    [string]$SecretName   = "sql-admin-password"
)

Write-Host "Retrieving secret '$SecretName' from Key Vault '$KeyVaultName'..."

# Check Azure login
az account show > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not logged in. Run 'az login' first."
    exit 1
}

# Retrieve the secret securely
$secretValue = az keyvault secret show `
    --vault-name $KeyVaultName `
    --name $SecretName `
    --query value `
    -o tsv

if (-not $secretValue) {
    Write-Error "Secret retrieval failed. Verify Key Vault access policies."
    exit 1
}

Write-Host "Secret retrieved successfully."
# Usage in pipelines (secure):
# $env:SQL_ADMIN_PASSWORD = $secretValue
