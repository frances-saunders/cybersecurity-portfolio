<#
.SYNOPSIS
    Disables Azure AD accounts in bulk (incident response).

.DESCRIPTION
    - Accepts CSV with a 'UserPrincipalName' column OR newline list
    - Logs results to CSV
    - Supports WhatIf and error handling
    - Optionally revokes sessions

.EXAMPLE
    .\bulk-disable-users.ps1 -InputFile compromised.csv -RevokeTokens
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)] [string]$InputFile,
    [switch]$RevokeTokens,
    [string]$OutFile = "bulk-disable-results.csv"
)

function Get-UserList {
    param([string]$Path)
    if ($Path.EndsWith(".csv")) {
        (Import-Csv $Path).UserPrincipalName
    } else {
        Get-Content $Path
    }
}

$results = @()
$users = Get-UserList -Path $InputFile | Where-Object { $_ -and $_.Trim() -ne "" } | Select-Object -Unique

foreach ($upn in $users) {
    try {
        if ($PSCmdlet.ShouldProcess($upn,"Disable account")) {
            Update-MgUser -UserId $upn -AccountEnabled:$false
            if ($RevokeTokens) { Revoke-MgUserSignInSession -UserId $upn | Out-Null }
            $results += [pscustomobject]@{User=$upn; Disabled=$true; Revoked=$RevokeTokens; Error=""}
        }
    } catch {
        $results += [pscustomobject]@{User=$upn; Disabled=$false; Revoked=$false; Error=$_.Exception.Message}
    }
}

$results | Export-Csv -NoTypeInformation -Path $OutFile
Write-Output "Completed. Results -> $OutFile"
