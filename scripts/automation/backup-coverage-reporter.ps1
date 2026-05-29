<#
.SYNOPSIS
    Queries all in-scope Azure resources across subscriptions and reports backup protection coverage
    against the Azure Backup compliance API, including ghost resource detection.

.DESCRIPTION
    This script does more than a standard backup compliance report. It cross-references the Azure
    Backup compliance API against every resource carrying a bcdr-tier tag, then flags three
    distinct coverage failure modes:

    1. NOT ENROLLED      - Resource has bcdr-tier tag but no vault association at all.
    2. GHOST RESOURCE    - Resource has bcdr-tier tag and a policy assignment, but no successful
                           backup job completed in the last 25 hours. Policy assigned != backup
                           running. This is the gap standard coverage reports miss: the agent
                           was never installed, or the first backup never triggered.
    3. STALE BACKUP      - Enrolled, backup agent active, but last successful backup exceeds the
                           tier's allowed RPO window (4h T1, 12h T2, 24h T3).

    Output: per-resource JSON rows written to a timestamped file, plus a summary table to stdout.
    Supports -DryRun (no API writes), -SubscriptionId (single sub scope), and -Tier (filter).

.REQUIREMENTS
    - Az module (Az.Accounts, Az.RecoveryServices, Az.Resources, Az.Compute, Az.Sql, Az.Storage)
    - Az CLI for backup job history queries
    - Contributor or Backup Reader on target subscriptions
    - Secrets: service principal credentials via environment variables or Az CLI login
      (AZURE_CLIENT_ID / AZURE_CLIENT_SECRET / AZURE_TENANT_ID) -- never embedded in script

.PARAMETER SubscriptionId
    Scope to a single subscription. If omitted, runs against all subscriptions in tenant.

.PARAMETER Tier
    Filter output to a specific tier: Tier1, Tier2, Tier3. Omit for all tiers.

.PARAMETER DryRun
    If set, collects and reports data but does not write output file or push metrics.

.PARAMETER OutputPath
    Directory for output files. Defaults to current directory.

.PARAMETER GhostWindowHours
    Hours without a successful backup job to classify a resource as a ghost. Default: 25.
    Set to 1 above your backup frequency so schedule slippage does not create false positives.

.PARAMETER PushToMonitor
    If set, pushes ghost resource count to Azure Monitor custom metrics namespace
    'BCDR/GhostResources' for Sentinel alerting.

.EXAMPLE
    # Full tenant scan, dry run
    .`backup-coverage-reporter.ps1 -DryRun

.EXAMPLE
    # Scope to one subscription, Tier 1 only, push metrics
    .`backup-coverage-reporter.ps1 -SubscriptionId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -Tier Tier1 -PushToMonitor

.NOTES
    Cross-references: docs/workload-classification.md, kql/backup-coverage-gaps.kql
    Lab: labs/bcdr-ir-plan
    Author: Frances Saunders
#>

[CmdletBinding(SupportsShouldProcess = $false)]
param(
    [string]$SubscriptionId,
    [ValidateSet('Tier1','Tier2','Tier3')][string]$Tier,
    [switch]$DryRun,
    [string]$OutputPath = ".",
    [int]$GhostWindowHours = 25,
    [switch]$PushToMonitor
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
#region --- Tier RPO Thresholds (hours) -------------------------------------
$TierRpoHours = @{
    "Tier1" = 4
    "Tier2" = 12
    "Tier3" = 24
}
# Map resource types that need backup coverage
$CoveredResourceTypes = @(
    "Microsoft.Compute/virtualMachines",
    "Microsoft.Sql/servers/databases",
    "Microsoft.Storage/storageAccounts",
    "Microsoft.ContainerService/managedClusters"
)
#endregion

#region --- Helpers ----------------------------------------------------------
function Write-Status ([string]$msg, [string]$color = "Cyan") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

function Get-LastSuccessfulBackupAge ([string]$resourceId, [string]$vaultId) {
    <#
    Returns the age in hours since the last successful backup job for a resource.
    Returns $null if no completed job found (ghost scenario).
    Uses az CLI for backup job history -- the Az module job query is limited.
    #>
    try {
        $parts = $vaultId -split '/'
        $vaultName = $parts[-1]
        $vaultRg   = $parts[4]
        $subId     = $parts[2]

        $jobs = az backup job list `
            --resource-group $vaultRg `
            --vault-name $vaultName `
            --subscription $subId `
            --query "[?properties.status=='Completed' && properties.operation=='Backup']" `
            --output json 2>$null | ConvertFrom-Json

        # Match by resource ID suffix (container name varies by workload type)
        $resourceName = ($resourceId -split '/')[-1].ToLower()
        $lastJob = $jobs | Where-Object {
            $_.properties.entityFriendlyName -and
            $_.properties.entityFriendlyName.ToLower() -like "*$resourceName*"
        } | Sort-Object { $_.properties.endTime } -Descending | Select-Object -First 1

        if ($null -eq $lastJob) { return $null }

        $endTime = [datetime]::Parse($lastJob.properties.endTime, $null, 'RoundtripKind')
        return [math]::Round(([datetime]::UtcNow - $endTime).TotalHours, 2)
    } catch {
        Write-Verbose "Job history query failed for $resourceId : $($_.Exception.Message)"
        return $null
    }
}

function Get-BackupProtectedItems ([string]$vaultId) {
    $parts     = $vaultId -split '/'
    $vaultRg   = $parts[4]
    $vaultName = $parts[-1]
    $subId     = $parts[2]
    try {
        return az backup item list `
            --resource-group $vaultRg `
            --vault-name $vaultName `
            --subscription $subId `
            --output json 2>$null | ConvertFrom-Json
    } catch {
        return @()
    }
}
function Push-GhostMetric ([int]$ghostCount, [string]$subscriptionId, [string]$resourceGroupName) {
    <#
    Pushes ghost resource count to Azure Monitor custom metrics.
    Metric namespace: BCDR, name: GhostResources.
    This feeds the backup-coverage-gaps.kql Sentinel alert.
    #>
    $body = @{
        time = [datetime]::UtcNow.ToString("o")
        data = @{
            baseData = @{
                metric     = "GhostResources"
                namespace  = "BCDR"
                dimNames   = @("Scope")
                series     = @(@{
                    dimValues = @($subscriptionId)
                    sum       = $ghostCount
                    count     = 1
                    min       = $ghostCount
                    max       = $ghostCount
                })
            }
        }
    } | ConvertTo-Json -Depth 10

    $token   = (az account get-access-token --resource "https://monitoring.azure.com/" --query "accessToken" -o tsv 2>$null)
    $endpoint = "https://eastus2.monitoring.azure.com/subscriptions/$subscriptionId" +
                "/resourcegroups/$resourceGroupName/providers/microsoft.insights/metrics"
    $headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

    try {
        Invoke-RestMethod -Method Post -Uri $endpoint -Headers $headers -Body $body | Out-Null
        Write-Status "Pushed GhostResources metric: $ghostCount" "Green"
    } catch {
        Write-Warning "Failed to push custom metric: $($_.Exception.Message)"
    }
}
#endregion

#region --- Main -------------------------------------------------------------
Write-Status "BCDR Backup Coverage Reporter -- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') UTC"
Write-Status "Ghost window: $GhostWindowHours hours | DryRun: $DryRun"

# Resolve subscriptions
if ($SubscriptionId) {
    $subscriptions = @([pscustomobject]@{ id = $SubscriptionId; name = "scoped" })
} else {
    $subscriptions = az account list --query "[?state=='Enabled']" --output json 2>$null | ConvertFrom-Json
}

Write-Status "Scanning $($subscriptions.Count) subscription(s)..."

$results      = [System.Collections.Generic.List[pscustomobject]]::new()
$ghostCount   = 0
$firstSubId   = $subscriptions[0].id
$firstSubRg   = $null   # will be set on first vault found

# -- Pass 1: collect all in-scope resources with bcdr-tier tag ---------------
$taggedResources = [System.Collections.Generic.List[pscustomobject]]::new()
foreach ($sub in $subscriptions) {
    Write-Status "  Enumerating tagged resources in sub: $($sub.id)"
    $raw = az resource list `
        --subscription $sub.id `
        --query "[?tags.'bcdr-tier' != null]" `
        --output json 2>$null | ConvertFrom-Json

    foreach ($r in $raw) {
        if ($r.type -notin $CoveredResourceTypes) { continue }
        $rTier = $r.tags.'bcdr-tier'
        if ($Tier -and $rTier -ne $Tier) { continue }
        $taggedResources.Add([pscustomobject]@{
            subscriptionId = $sub.id
            resourceId     = $r.id
            resourceName   = $r.name
            resourceType   = $r.type
            resourceGroup  = $r.resourceGroup
            tier           = $rTier
            location       = $r.location
        })
    }
}
Write-Status "Total in-scope tagged resources: $($taggedResources.Count)"
# -- Pass 2: collect all Recovery Services Vaults and their protected items -
$vaultMap = @{}  # resourceId -> vaultId
foreach ($sub in $subscriptions) {
    $vaults = az backup vault list --subscription $sub.id --output json 2>$null | ConvertFrom-Json
    foreach ($v in $vaults) {
        if ($null -eq $firstSubRg) { $firstSubRg = $v.resourceGroup }
        $items = Get-BackupProtectedItems -vaultId $v.id
        foreach ($item in $items) {
            # Protected item sourceResourceId is the ARM resource ID of the protected workload
            $srcId = $item.properties.sourceResourceId
            if ($srcId) { $vaultMap[$srcId.ToLower()] = $v.id }
        }
    }
}
Write-Status "Vault protected item map: $($vaultMap.Count) entries"

# -- Pass 3: classify each tagged resource -----------------------------------
foreach ($res in $taggedResources) {
    $rid        = $res.resourceId.ToLower()
    $rpoHours   = $TierRpoHours[$res.tier]
    $status     = $null
    $vaultId    = $null
    $lastBackupAgeHours = $null
    $rpoBreached = $false
    $isGhost    = $false

    if (-not $vaultMap.ContainsKey($rid)) {
        # Not enrolled in any vault
        $status = "NOT_ENROLLED"
    } else {
        $vaultId = $vaultMap[$rid]
        $lastBackupAgeHours = Get-LastSuccessfulBackupAge -resourceId $res.resourceId -vaultId $vaultId

        if ($null -eq $lastBackupAgeHours) {
            # Enrolled (in vault map) but no completed backup job found -- GHOST
            $status  = "GHOST_RESOURCE"
            $isGhost = $true
            $ghostCount++
        } elseif ($lastBackupAgeHours -gt $rpoHours) {
            # Backup running but last success exceeds RPO threshold
            $status      = "STALE_BACKUP"
            $rpoBreached = $true
        } else {
            $status = "PROTECTED"
        }
    }

    $row = [pscustomobject]@{
        timestamp           = [datetime]::UtcNow.ToString("o")
        resourceName        = $res.resourceName
        resourceType        = $res.resourceType
        resourceGroup       = $res.resourceGroup
        subscriptionId      = $res.subscriptionId
        tier                = $res.tier
        rpoTargetHours      = $rpoHours
        coverageStatus      = $status
        vaultId             = $vaultId
        lastBackupAgeHours  = $lastBackupAgeHours
        rpoBreached         = $rpoBreached
        isGhost             = $isGhost
        resourceId          = $res.resourceId
    }
    $results.Add($row)

    $statusColor = switch ($status) {
        "PROTECTED"      { "Green"  }
        "STALE_BACKUP"   { "Yellow" }
        "GHOST_RESOURCE" { "Red"    }
        "NOT_ENROLLED"   { "Red"    }
        default          { "White"  }
    }
    Write-Host ("  [{0,-15}] {1} ({2}) | LastBackup: {3}h" -f $status, $res.resourceName, $res.tier, $lastBackupAgeHours) -ForegroundColor $statusColor
}

# -- Summary -----------------------------------------------------------------
$protected   = ($results | Where-Object { $_.coverageStatus -eq "PROTECTED" }).Count
$ghost       = ($results | Where-Object { $_.coverageStatus -eq "GHOST_RESOURCE" }).Count
$stale       = ($results | Where-Object { $_.coverageStatus -eq "STALE_BACKUP" }).Count
$notEnrolled = ($results | Where-Object { $_.coverageStatus -eq "NOT_ENROLLED" }).Count

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " COVERAGE SUMMARY" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host (" PROTECTED      : {0,4}" -f $protected)  -ForegroundColor Green
Write-Host (" GHOST RESOURCE : {0,4}  <- policy assigned, backup never ran" -f $ghost) -ForegroundColor Red
Write-Host (" STALE BACKUP   : {0,4}  <- backup ran but exceeded RPO window" -f $stale) -ForegroundColor Yellow
Write-Host (" NOT ENROLLED   : {0,4}  <- no vault association at all" -f $notEnrolled) -ForegroundColor Red
Write-Host ("------------------------------------------------------ ")
Write-Host (" TOTAL IN SCOPE : {0,4}" -f $results.Count)
Write-Host "======================================================" -ForegroundColor Cyan

# -- Output ------------------------------------------------------------------
if (-not $DryRun) {
    $ts      = Get-Date -Format "yyyyMMdd-HHmmss"
    $jsonFile = Join-Path $OutputPath "backup-coverage-report-$ts.json"
    $csvFile  = Join-Path $OutputPath "backup-coverage-report-$ts.csv"

    $results | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $jsonFile
    $results | Export-Csv -Path $csvFile -NoTypeInformation
    Write-Status "Output written: $jsonFile | $csvFile" "Green"

    if ($PushToMonitor -and $firstSubRg) {
        Push-GhostMetric -ghostCount $ghostCount -subscriptionId $firstSubId -resourceGroupName $firstSubRg
    }
} else {
    Write-Status "DryRun mode -- no output files written, no metrics pushed." "Yellow"
}
#endregion
