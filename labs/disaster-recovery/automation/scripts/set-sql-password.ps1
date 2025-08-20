<#
.SYNOPSIS
    Rotates the SQL Server administrator password and stores it in Azure Key Vault.

.DESCRIPTION
    This script generates a strong random password, updates the SQL Server admin
    password, and stores it in Key Vault for Terraform/automation use.
    Designed for use in the disaster-recovery lab portfolio.

.NOTES
    Location: disaster-recovery/automation/scripts/set-sql-password.ps1
#>

param(
    [string]$ResourceGroup = "rg-dr-lab",
    [string]$SqlServerName = "dr-sql-server",
    [string]$KeyVaultName  = "dr-keyvault",
    [string]$SecretName    = "SqlAdminPassword"
)

# Generate random secure password
$Password = [System.Web.Security.Membership]::GeneratePassword(20,3)

Write-Host "🔐 Generated new password for SQL Server: $SqlServerName"

# Update SQL Server admin password
az sql server update `
  --name $SqlServerName `
  --resource-group $ResourceGroup `
  --admin-password $Password

# Store in Key Vault
az keyvault secret set `
  --vault-name $KeyVaultName `
  --name $SecretName `
  --value $Password

Write-Host "✅ Password rotated and stored in Key Vault ($KeyVaultName/$SecretName)"
