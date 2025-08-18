<#
.SYNOPSIS
Brute-force simulation against Azure AD account.

.DESCRIPTION
Rapid login attempts with incorrect passwords, 
triggering AAD Identity Protection and Sentinel detections.

.NOTES
Never run this against production accounts — lab only.
#>

param (
    [string]$UserPrincipalName,
    [int]$Attempts = 20
)

for ($i = 1; $i -le $Attempts; $i++) {
    Write-Host "[*] Attempt $i failed login..."
    az login -u $UserPrincipalName -p "WrongPassword$i" --allow-no-subscriptions
    Start-Sleep -Seconds 2
}
