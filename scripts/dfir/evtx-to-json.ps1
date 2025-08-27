<#
.SYNOPSIS
  Convert selected EVTX channels to JSON for rapid timeline building.

.DESCRIPTION
  - Filters by channels and optional time window and Event IDs
  - Outputs one JSON file per channel (line-delimited JSON)
#>

[CmdletBinding()]
param(
  [string[]]$Channels = @("Security","Microsoft-Windows-Sysmon/Operational","System"),
  [datetime]$StartTime,
  [datetime]$EndTime,
  [int[]]$EventId,
  [string]$OutDir = ".\evtx-json"
)

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

foreach ($ch in $Channels) {
  $filter = @{LogName=$ch}
  if ($PSBoundParameters.ContainsKey("StartTime")) { $filter.StartTime = $StartTime }
  if ($PSBoundParameters.ContainsKey("EndTime"))   { $filter.EndTime   = $EndTime }
  if ($PSBoundParameters.ContainsKey("EventId"))   { $filter.Id        = $EventId }

  $out = Join-Path $OutDir ("$($ch -replace '[\\/]','_').json")
  Get-WinEvent -FilterHashtable $filter | ForEach-Object {
    $obj = [pscustomobject]@{
      TimeCreated = $_.TimeCreated.ToString("o")
      Provider    = $_.ProviderName
      Id          = $_.Id
      Level       = $_.LevelDisplayName
      Machine     = $_.MachineName
      Message     = $_.Message
      RecordId    = $_.RecordId
    }
    $obj | ConvertTo-Json -Depth 6
  } | Out-File -FilePath $out -Encoding utf8
  Write-Output "Wrote $out"
}
