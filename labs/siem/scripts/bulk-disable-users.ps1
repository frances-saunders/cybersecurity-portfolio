<#
.SYNOPSIS
    Bulk disables Azure AD users flagged as compromised.

.DESCRIPTION
    This script ingests a CSV file of user accounts (exported from Sentinel,
    Defender, or other security tooling) and bulk-disables them in Azure AD.
    Intended for use in SOAR playbooks or incident response.

.PARAMETER CsvPath
    Path to the CSV file containing user account details.
    The CSV must have at least the column: UserPrincipalName

.EXAMPLE
    .\bulk-disable-users.ps1 -CsvPath "C:\path\to\<your_file>.csv"

.NOTES
    Author: Frances Saunders Portfolio Lab
    Safe for demo use: replace <your_file>.csv with real input in production
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

# Import AzureAD module (assumes session already authenticated)
Import-Module AzureAD -ErrorAction Stop

Write-Host "Reading users from file: $CsvPath" -ForegroundColor Cyan
$users = Import-Csv -Path $CsvPath

foreach ($user in $users) {
    try {
        Write-Host "Disabling account: $($user.UserPrincipalName)" -ForegroundColor Yellow
        Set-AzureADUser -ObjectId $user.UserPrincipalName -AccountEnabled $false
        Write-Host " -> SUCCESS" -ForegroundColor Green
    }
    catch {
        Write-Host " -> FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}
