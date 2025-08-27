<#
.SYNOPSIS
    Collects cloud control evidence for NIST 800-53 from Azure Policy states.

.DESCRIPTION
    - Pulls policy compliance states
    - Filters by built-in or custom initiatives mapped to NIST
    - Outputs normalized CSV for auditors

.EXAMPLE
    .\collect-nist-evidence.ps1 -OutFile nist-evidence.csv -InitiativeLike "NIST" -SubscriptionId xxx
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$OutFile,
    [Parameter(Mandatory)] [string]$SubscriptionId,
    [string]$InitiativeLike = "NIST"
)

$ErrorActionPreference = "Stop"
Select-AzSubscription -SubscriptionId $SubscriptionId | Out-Null

$states = Get-AzPolicyState -All
$filtered = $states | Where-Object { $_.PolicyAssignmentName -match $InitiativeLike }

$normalized = $filtered | Select-Object `
    Timestamp, SubscriptionId, ResourceId,
    PolicyAssignmentId, PolicyDefinitionId,
    ComplianceState, IsCompliant,
    @{n='ControlRef';e={($_.PolicyDefinitionReferenceId)}}

$normalized | Export-Csv -NoTypeInformation -Path $OutFile
Write-Output "Wrote $($normalized.Count) records -> $OutFile"
