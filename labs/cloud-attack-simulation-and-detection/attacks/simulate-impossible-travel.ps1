<#
.SYNOPSIS
Simulates "impossible travel" login activity by invoking Azure CLI with two different IP addresses (requires VPN/proxy switch). The user password is retrieved from an Azure Key Vault secret.

.DESCRIPTION
This script demonstrates how an attacker might appear to log in from geographically distant locations within minutes — a common indicator of credential compromise. Credentials are obtained from a Key Vault rather than hardcoded.

.NOTES
Blue Team will detect this via Sentinel KQL analytics.
#>

param (
    [string]$UserPrincipalName,
    [string]$KeyVaultName,
    [string]$SecretName = "UserPassword",
    [string]$FirstIP = "40.112.72.205",   # US-based IP
    [string]$SecondIP = "52.178.34.120"   # EU-based IP
)

# Retrieve password from Azure Key Vault
$Password = az keyvault secret show --vault-name $KeyVaultName --name $SecretName --query value -o tsv

if (-not $Password) {
    throw "Failed to retrieve secret '$SecretName' from key vault '$KeyVaultName'"
}

Write-Host "[*] Simulating login from IP: $FirstIP..."
az login -u $UserPrincipalName -p $Password --tenant YOURTENANTID --allow-no-subscriptions
# (In practice: use proxy/VPN for IP swap)

Start-Sleep -Seconds 60

Write-Host "[*] Simulating login from IP: $SecondIP..."
az login -u $UserPrincipalName -p $Password --tenant YOURTENANTID --allow-no-subscriptions
