<#
.SYNOPSIS
  Collect Microsoft Secure Score and control details via Microsoft Graph.

.DESCRIPTION
  - Authenticates to Graph with SecureScore permissions
  - Exports overall score and control-level details
  - Outputs CSV and JSON

.REQUIREMENTS
  - Microsoft.Graph PowerShell module
  - App/Delegated permissions: SecurityEvents.Read.All or SecureScores.Read.All (as applicable)
#>

[CmdletBinding()]
param(
  [string]$OutCsv = "secure-score.csv",
  [string]$OutJson = "secure-score.json"
)

try {
  if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "SecurityEvents.Read.All","Reports.Read.All" | Out-Null }
} catch { Write-Error "Graph auth failed. $_"; exit 1 }

$score = Get-MgSecuritySecureScore -Top 1
$controls = Get-MgSecuritySecureScoreControlProfile -All

$rows = @()
foreach ($c in $controls) {
  $rows += [pscustomobject]@{
    ControlId = $c.Id
    Title = $c.Title
    Tier = $c.ControlCategory
    ActionType = $c.ActionType
    ImplementationCost = $c.ImplementationCost
    UserImpact = $c.UserImpact
    Threats = ($c.Threats -join ";")
    Remediation = $c.Remediation
  }
}

$rows | Export-Csv -NoTypeInformation -Path $OutCsv
@{
  score = $score
  controls = $controls
} | ConvertTo-Json -Depth 6 | Out-File -FilePath $OutJson -Encoding utf8

Write-Output "Wrote $OutCsv and $OutJson"
