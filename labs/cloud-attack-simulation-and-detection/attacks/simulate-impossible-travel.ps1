<#
.SYNOPSIS
Simulates "impossible travel" login activity by invoking Azure CLI 
with two different IP addresses (requires VPN/proxy switch).

.DESCRIPTION
This script demonstrates how an attacker might appear to log in 
from geographically distant locations within minutes — a common 
indicator of credential compromise.

.NOTES
Blue Team will detect this via Sentinel KQL analytics.
#>

param (
    [string]$UserPrincipalName,
    [string]$Password,
    [string]$FirstIP = "40.112.72.205",   # US-based IP
    [string]$SecondIP = "52.178.34.120"   # EU-based IP
)

Write-Host "[*] Simulating login from IP: $FirstIP..."
az login -u $UserPrincipalName -p $Password --tenant YOURTENANTID --allow-no-subscriptions
# (In practice: use proxy/VPN for IP swap)

Start-Sleep -Seconds 60

Write-Host "[*] Simulating login from IP: $SecondIP..."
az login -u $UserPrincipalName -p $Password --tenant YOURTENANTID --allow-no-subscriptions
