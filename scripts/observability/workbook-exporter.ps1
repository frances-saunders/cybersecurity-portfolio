<#
.SYNOPSIS
  Export Sentinel (Azure Monitor) workbooks as JSON with versioning for GitOps.

.DESCRIPTION
  - Lists workbooks in a subscription or resource group
  - Exports each workbook's serialized JSON to a file
  - Adds a simple version stamp to filename; idempotent

.REQUIREMENTS
  - Az.Monitor or use generic resource export (Az.ResourceGraph not required)
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$SubscriptionId,
  [string]$ResourceGroup,
  [string]$OutDir = ".\workbooks"
)

Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# Workbooks are Microsoft.Insights/workbooks
$filter = if ($ResourceGroup) { @{ ResourceGroupName = $ResourceGroup } } else { @{} }
$wbs = Get-AzResource -ResourceType "Microsoft.Insights/workbooks" @filter

foreach ($wb in $wbs) {
  $detail = Get-AzResource -ResourceId $wb.ResourceId -ExpandProperties
  $name = $detail.Name -replace '[^a-zA-Z0-9\-]','_'
  $ver = (Get-Date).ToString("yyyyMMddHHmmss")
  $file = Join-Path $OutDir "$name-$ver.json"
  $json = $detail.Properties | ConvertTo-Json -Depth 16
  $json | Out-File -FilePath $file -Encoding utf8
  Write-Output "Exported $($wb.Name) -> $file"
}
