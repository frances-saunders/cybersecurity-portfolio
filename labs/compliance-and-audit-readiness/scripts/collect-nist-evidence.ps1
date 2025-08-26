<# 
.SYNOPSIS
  Collects NIST-aligned Azure Policy evidence and exports CSV/JSON artifacts.

.DESIGN
  - Prefers Managed Identity (Az PowerShell) when running in Azure.
  - Falls back to interactive Device Login if no identity available.
  - No secrets are embedded; outputs are local files only.

.OUTPUTS
  ./evidence/nist/summary.csv
  ./evidence/nist/noncompliant.csv
  ./evidence/nist/assignments.json
  ./evidence/manifest.json
#>

param(
  [Parameter(Mandatory=$true)]
  [string] $SubscriptionId,

  [Parameter(Mandatory=$false)]
  [string] $AssignmentNameFilter = "NIST",   # Matches initiative or assignment display/name

  [Parameter(Mandatory=$false)]
  [int] $Days = 30
)

function Connect-Azure() {
  try {
    # Managed Identity first
    Connect-AzAccount -Identity -ErrorAction Stop | Out-Null
  } catch {
    Write-Verbose "Managed Identity not available. Falling back to device login."
    Connect-AzAccount -UseDeviceAuthentication | Out-Null
  }
  Set-AzContext -Subscription $SubscriptionId | Out-Null
}

function Ensure-Path([string]$Path) {
  if (-not (Test-Path $Path)) { New-Item -Path $Path -ItemType Directory | Out-Null }
}

# Main
$ErrorActionPreference = "Stop"
Connect-Azure

$base = Join-Path -Path (Get-Location) -ChildPath "evidence/nist"
Ensure-Path $base

# Pull assignments to locate scopes and IDs
$assignments = Get-AzPolicyAssignment | Where-Object {
  $_.Properties.DisplayName -like "*$AssignmentNameFilter*" -or $_.Name -like "*$AssignmentNameFilter*"
}

$assignmentsFile = Join-Path $base "assignments.json"
$assignments | ConvertTo-Json -Depth 8 | Out-File -FilePath $assignmentsFile -Encoding UTF8

# Query Policy Insights for state over window
$from = (Get-Date).AddDays(-1 * $Days).ToString("o")
$to   = (Get-Date).ToString("o")

# Summary: Compliant vs NonCompliant across NIST assignments
$summary = @()
$noncompliant = @()

foreach ($a in $assignments) {
  $scope = $a.Properties.Scope
  $ps = Get-AzPolicyState -QueryStartTime $from -QueryEndTime $to -Filter "PolicyAssignmentId eq '$($a.Id)'" -Top 5000

  if ($ps) {
    $grouped = $ps | Group-Object -Property ComplianceState | Select-Object Name,Count
    $c = ($grouped | Where-Object Name -eq "Compliant").Count
    $n = ($grouped | Where-Object Name -eq "NonCompliant").Count
    $pct = if (($c + $n) -gt 0) { [math]::Round(100.0 * $c / ($c + $n), 1) } else { 0 }

    $summary += [pscustomobject]@{
      AssignmentName = $a.Properties.DisplayName
      Scope          = $scope
      Compliant      = $c
      NonCompliant   = $n
      CompliancePct  = $pct
      WindowDays     = $Days
    }

    $noncompliant += $ps | Where-Object ComplianceState -eq "NonCompliant" |
      Select-Object Timestamp, PolicyDefinitionName, PolicyDefinitionAction, ResourceId, PolicyAssignmentName, ComplianceState
  }
}

$summaryPath = Join-Path $base "summary.csv"
$noncompliantPath = Join-Path $base "noncompliant.csv"
$summary | Export-Csv -NoTypeInformation -Path $summaryPath -Encoding UTF8
$noncompliant | Export-Csv -NoTypeInformation -Path $noncompliantPath -Encoding UTF8

# Update lab-wide manifest
$manifest = @{
  collectedAt = (Get-Date).ToString("o")
  framework   = "NIST"
  subscription = $SubscriptionId
  windowDays  = $Days
  files       = @(
    (Resolve-Path $assignmentsFile).Path,
    (Resolve-Path $summaryPath).Path,
    (Resolve-Path $noncompliantPath).Path
  )
}
$manifest | ConvertTo-Json -Depth 6 | Out-File -FilePath (Join-Path (Split-Path $base) "manifest.json") -Encoding UTF8

Write-Host "NIST evidence collection complete."
