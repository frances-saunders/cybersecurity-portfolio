<#
.SYNOPSIS
    Bulk disable compromised user accounts in Azure AD.
.DESCRIPTION
    Reads a CSV of UPNs and disables each account to stop lateral movement.
#>

param (
    [string]$CsvPath = "./compromised-users.csv"
)

$users = Import-Csv -Path $CsvPath

foreach ($user in $users) {
    Write-Output "Disabling user: $($user.UserPrincipalName)"
    # Example: sanitized cmdlet
    # Set-AzureADUser -ObjectId $user.UserPrincipalName -AccountEnabled $false
}
