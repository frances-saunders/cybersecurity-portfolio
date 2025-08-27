<#
.SYNOPSIS
  Bulk disable Azure AD users by UPN or ObjectId with rollback capability.

.PARAMETER Input
  CSV with header 'user' (UPN or ObjectId). Example:
  user
  user1@contoso.com

.PARAMETER RollbackFile
  File storing successfully disabled users for potential rollback.

.EXAMPLE
  ./bulk-disable-users.ps1 -Input compromised_users.csv -RollbackFile disabled.log
#>
param(
  [Parameter(Mandatory=$true)] [string]$Input,
  [string]$RollbackFile = "disabled-users-$(Get-Date -Format yyyyMMddHHmmss).log",
  [switch]$WhatIf
)

Import-Module AzureAD -ErrorAction Stop
Connect-AzureAD -ErrorAction Stop | Out-Null

$users = Import-Csv $Input
foreach ($u in $users) {
  $id = $u.user.Trim()
  try {
    $account = Get-AzureADUser -ObjectId $id -ErrorAction Stop
    if ($WhatIf) { Write-Host "[WHATIF] Would disable $($account.UserPrincipalName)"; continue }
    Set-AzureADUser -ObjectId $account.ObjectId -AccountEnabled $false -ErrorAction Stop
    "$($account.ObjectId),$($account.UserPrincipalName)" | Out-File -Append -FilePath $RollbackFile
    Write-Host "Disabled: $($account.UserPrincipalName)"
  } catch {
    Write-Warning "Failed to disable: $id | $_"
  }
}
Write-Host "Done. Rollback list: $RollbackFile"
