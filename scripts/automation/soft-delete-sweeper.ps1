<#
.SYNOPSIS
  Reviews soft-deleted secrets/keys/certs in Azure Key Vault and (optionally) purges those older than a policy threshold.

.DESCRIPTION
  - Lists deleted items across types
  - Filters by AgeDays > threshold
  - Prompts for approval unless -Approve is set (supports -WhatIf)
  - Emits a CSV/JSON report for audit trail

.REQUIREMENTS
  - Az.KeyVault module, az CLI
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [Parameter(Mandatory)][string]$VaultName,
  [int]$OlderThanDays = 30,
  [switch]$Approve,                     # if set, will purge without interactive confirmation (still honors -WhatIf)
  [string]$OutCsv = "kv-softdelete-report.csv",
  [string]$OutJson = "kv-softdelete-report.json"
)

function Parse-Date { param([string]$s) [datetime]::Parse($s) }

$now = Get-Date
$items = @()

Write-Verbose "Enumerating deleted certificates..."
$certs = az keyvault certificate list-deleted --vault-name $VaultName | ConvertFrom-Json
foreach ($c in ($certs | ForEach-Object { $_ })) {
  $age = ($now - (Parse-Date $c.deletedDate)).TotalDays
  $items += [pscustomobject]@{ type="certificate"; name=$c.name; deletedDate=$c.deletedDate; ageDays=[math]::Round($age,2) }
}

Write-Verbose "Enumerating deleted keys..."
$keys = az keyvault key list-deleted --vault-name $VaultName | ConvertFrom-Json
foreach ($k in ($keys | ForEach-Object { $_ })) {
  $age = ($now - (Parse-Date $k.deletedDate)).TotalDays
  $items += [pscustomobject]@{ type="key"; name=$k.name; deletedDate=$k.deletedDate; ageDays=[math]::Round($age,2) }
}

Write-Verbose "Enumerating deleted secrets..."
$secrets = az keyvault secret list-deleted --vault-name $VaultName | ConvertFrom-Json
foreach ($s in ($secrets | ForEach-Object { $_ })) {
  $age = ($now - (Parse-Date $s.deletedDate)).TotalDays
  $items += [pscustomobject]@{ type="secret"; name=$s.name; deletedDate=$s.deletedDate; ageDays=[math]::Round($age,2) }
}

$toPurge = $items | Where-Object { $_.ageDays -ge $OlderThanDays }

$items | Export-Csv -Path $OutCsv -NoTypeInformation
$items | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $OutJson

Write-Output "Found $($items.Count) deleted items; $($toPurge.Count) exceed $OlderThanDays days. Report: $OutCsv / $OutJson"

if ($toPurge.Count -eq 0) { return }

if (-not $Approve) {
  $resp = Read-Host "Purge $($toPurge.Count) items older than $OlderThanDays days? (y/N)"
  if ($resp -notin @("y","Y","yes","YES")) { Write-Output "Aborted purge."; return }
}

foreach ($i in $toPurge) {
  $op = "Purge $($i.type) '$($i.name)'"
  if ($PSCmdlet.ShouldProcess("$VaultName", $op)) {
    try {
      switch ($i.type) {
        "certificate" { az keyvault certificate purge --vault-name $VaultName --name $i.name | Out-Null }
        "key"         { az keyvault key purge         --vault-name $VaultName --name $i.name | Out-Null }
        "secret"      { az keyvault secret purge      --vault-name $VaultName --name $i.name | Out-Null }
      }
      Write-Output "Purged: $($i.type)/$($i.name)"
    } catch {
      Write-Warning "Failed to purge $($i.type)/$($i.name): $($_.Exception.Message)"
    }
  }
}
