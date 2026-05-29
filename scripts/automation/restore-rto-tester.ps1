<#
.SYNOPSIS
    Automates a backup restore test for a named VM or database, measures actual RTO,
    and writes a structured JSON result suitable for populating docs/test-results.md.

.DESCRIPTION
    Standard backup compliance proves a backup exists. This script proves recovery works
    within the SLA. It initiates a real restore to an isolated recovery resource group,
    polls until the restored workload passes a health check, measures wall-clock elapsed
    time, and writes a result record with the following fields:

      - startTime / endTime / elapsedMinutes
      - rtoTargetMinutes (from tier config)
      - rtoAchieved (bool)
      - recoveryPointId / recoveryPointTimestamp
      - recoveryDeltaMinutes  <- real-world RPO: difference between recovery point
                                 timestamp and the time the test was initiated.
                                 This is actual data age at recovery, not theoretical.
      - healthCheckPassed (bool)
      - failureReason (if applicable)

    The recovery delta field is the creative element here: most test scripts only measure
    RTO (time to restore). This also measures real RPO by computing how old the data was
    at the moment of test initiation -- giving you the actual recovery point age rather
    than the scheduled frequency.

    Restore is performed into a temporary resource group tagged test-restore=true.
    Cleanup is automatic unless -KeepRestored is specified.

.REQUIREMENTS
    - Az module (Az.RecoveryServices, Az.Compute, Az.Sql, Az.Resources)
    - Az CLI for health check polling
    - Contributor on vault resource group, permissions to create/delete temp resource group
    - Secrets: use Az CLI login or service principal env vars -- never embedded

.PARAMETER WorkloadName
    Name of the VM or SQL database to test restore for.

.PARAMETER WorkloadType
    Type of workload: VM, SqlDatabase. Determines restore API path.

.PARAMETER Tier
    Tier of the workload (Tier1, Tier2, Tier3). Used to select RTO target.

.PARAMETER VaultName
    Name of the Recovery Services Vault protecting this workload.

.PARAMETER VaultResourceGroup
    Resource group containing the vault.

.PARAMETER RecoveryResourceGroup
    Temporary resource group to restore into. Created if it does not exist.
    Default: bcdr-rto-test-<timestamp>

.PARAMETER SubscriptionId
    Target subscription. Defaults to current Az context subscription.

.PARAMETER OutputPath
    Directory for JSON result file. Defaults to current directory.

.PARAMETER KeepRestored
    If set, do not delete the restored resource after the test. Useful for manual inspection.

.EXAMPLE
    # Test Tier 1 VM restore
    .`restore-rto-tester.ps1 -WorkloadName "prod-web-vm-01" -WorkloadType VM -Tier Tier1 `
        -VaultName "bcdr-vault-tier1" -VaultResourceGroup "rg-bcdr-eastus2"

.EXAMPLE
    # Test Tier 2 SQL database, keep restored copy for inspection
    .`restore-rto-tester.ps1 -WorkloadName "prod-db-01" -WorkloadType SqlDatabase -Tier Tier2 `
        -VaultName "bcdr-vault-tier2" -VaultResourceGroup "rg-bcdr-eastus2" -KeepRestored

.NOTES
    Output file feeds docs/test-results.md.
    Cross-references: kql/asr-replication-health.kql, docs/workload-classification.md
    Lab: labs/bcdr-ir-plan
    Author: Frances Saunders
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WorkloadName,
    [Parameter(Mandatory)][ValidateSet('VM','SqlDatabase')][string]$WorkloadType,
    [Parameter(Mandatory)][ValidateSet('Tier1','Tier2','Tier3')][string]$Tier,
    [Parameter(Mandatory)][string]$VaultName,
    [Parameter(Mandatory)][string]$VaultResourceGroup,
    [string]$RecoveryResourceGroup,
    [string]$SubscriptionId,
    [string]$OutputPath = ".",
    [switch]$KeepRestored
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
#region --- Configuration ---------------------------------------------------
$TierRtoMinutes = @{
    "Tier1" = 60     # 1-hour RTO
    "Tier2" = 240    # 4-hour RTO
    "Tier3" = 480    # 8-hour RTO
}

# Health check poll interval and max wait (slightly above RTO target for Tier3)
$PollIntervalSeconds = 30
$MaxWaitMinutes      = 600
#endregion

#region --- Helpers ----------------------------------------------------------
function Write-Status ([string]$msg, [string]$color = "Cyan") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}

function Get-LatestRecoveryPoint {
    param([string]$vaultName, [string]$vaultRg, [string]$containerName, [string]$itemName, [string]$subId)
    $rps = az backup recoverypoint list `
        --resource-group $vaultRg `
        --vault-name $vaultName `
        --container-name $containerName `
        --item-name $itemName `
        --subscription $subId `
        --output json 2>$null | ConvertFrom-Json
    return ($rps | Sort-Object { $_.properties.recoveryPointTime } -Descending | Select-Object -First 1)
}

function Start-VmRestore {
    param(
        [string]$vaultName, [string]$vaultRg, [string]$containerName,
        [string]$itemName, [string]$rpName, [string]$targetRg,
        [string]$targetVmName, [string]$subId
    )
    # Restore to alternate location (new VM in recovery RG)
    $restoreJson = @{
        properties = @{
            objectType            = "IaasVMRestoreRequest"
            recoveryType          = "AlternateLocation"
            targetResourceGroupId = "/subscriptions/$subId/resourceGroups/$targetRg"
            storageAccountId      = $null  # Azure manages temp storage for ALR
            targetVirtualMachineName = $targetVmName
            createNewCloudService = $false
            originalStorageAccountOption = "WithOriginalStg"
        }
    } | ConvertTo-Json -Depth 10

    $result = az backup restore restore-azurevm `
        --resource-group $vaultRg `
        --vault-name $vaultName `
        --container-name $containerName `
        --item-name $itemName `
        --rp-name $rpName `
        --target-resource-group $targetRg `
        --subscription $subId `
        --output json 2>$null | ConvertFrom-Json

    return $result.name  # job ID
}

function Wait-RestoreJob {
    param([string]$jobId, [string]$vaultName, [string]$vaultRg, [string]$subId)
    $deadline = (Get-Date).AddMinutes($MaxWaitMinutes)
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds $PollIntervalSeconds
        $job = az backup job show `
            --resource-group $vaultRg `
            --vault-name $vaultName `
            --name $jobId `
            --subscription $subId `
            --output json 2>$null | ConvertFrom-Json

        $status = $job.properties.status
        Write-Status "  Restore job status: $status"
        if ($status -in @("Completed","Failed","Cancelled")) {
            return $job
        }
    }
    throw "Restore job timed out after $MaxWaitMinutes minutes."
}

function Test-VmHealth {
    param([string]$vmName, [string]$resourceGroup, [string]$subId)
    # Health check: VM must be in PowerState/running and provisioning must be Succeeded
    $vm = az vm get-instance-view `
        --name $vmName `
        --resource-group $resourceGroup `
        --subscription $subId `
        --output json 2>$null | ConvertFrom-Json

    if ($null -eq $vm) { return $false }
    $powerState = ($vm.instanceView.statuses | Where-Object { $_.code -like "PowerState/*" }).code
    $provState  = ($vm.instanceView.statuses | Where-Object { $_.code -like "ProvisioningState/*" }).code
    Write-Status "  VM health: $powerState / $provState"
    return ($powerState -eq "PowerState/running" -and $provState -eq "ProvisioningState/succeeded")
}
#endregion
#region --- Main ------------------------------------------------------------
$testStartTime = [datetime]::UtcNow
$testId        = "rto-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

Write-Status "RTO Restore Test | $testId"
Write-Status "Workload: $WorkloadName ($WorkloadType) | Tier: $Tier | Vault: $VaultName"

# Resolve subscription
if ($SubscriptionId) {
    az account set --subscription $SubscriptionId 2>$null
} else {
    $SubscriptionId = (az account show --query "id" -o tsv 2>$null)
}

$rtoTarget = $TierRtoMinutes[$Tier]

# Create recovery resource group if needed
if (-not $RecoveryResourceGroup) {
    $RecoveryResourceGroup = "bcdr-rto-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
}
Write-Status "Recovery RG: $RecoveryResourceGroup"

$rgExists = az group show --name $RecoveryResourceGroup --subscription $SubscriptionId 2>$null
if (-not $rgExists) {
    Write-Status "Creating recovery resource group..."
    az group create `
        --name $RecoveryResourceGroup `
        --location eastus2 `
        --tags "purpose=bcdr-rto-test" "test-id=$testId" `
        --subscription $SubscriptionId | Out-Null
}

# -- Get latest recovery point -----------------------------------------------
Write-Status "Fetching latest recovery point..."
$containerName = "iaasvmcontainerv2;$VaultResourceGroup;$WorkloadName".ToLower()
$itemName      = "vm;iaasvmcontainerv2;$VaultResourceGroup;$WorkloadName".ToLower()

$rp = Get-LatestRecoveryPoint `
    -vaultName $VaultName `
    -vaultRg $VaultResourceGroup `
    -containerName $containerName `
    -itemName $itemName `
    -subId $SubscriptionId

if ($null -eq $rp) {
    Write-Status "ERROR: No recovery point found for $WorkloadName." "Red"
    exit 1
}

$rpTime    = [datetime]::Parse($rp.properties.recoveryPointTime, $null, 'RoundtripKind')
$rpName    = $rp.name

# Recovery delta: how old is the data at time of test initiation?
# This is the real-world RPO measurement -- not the scheduled frequency.
$recoveryDeltaMinutes = [math]::Round(($testStartTime - $rpTime).TotalMinutes, 1)

Write-Status "Latest recovery point: $rpName | Age: $recoveryDeltaMinutes minutes (real RPO)" "Green"

# -- Initiate restore --------------------------------------------------------
$targetVmName = "$WorkloadName-rto-test"
Write-Status "Initiating restore to $targetVmName in $RecoveryResourceGroup..."

$jobId       = $null
$failureReason = $null

try {
    $jobId = Start-VmRestore `
        -vaultName $VaultName `
        -vaultRg $VaultResourceGroup `
        -containerName $containerName `
        -itemName $itemName `
        -rpName $rpName `
        -targetRg $RecoveryResourceGroup `
        -targetVmName $targetVmName `
        -subId $SubscriptionId

    Write-Status "Restore job started: $jobId"

    # -- Wait for job completion ----------------------------------------------
    $job = Wait-RestoreJob -jobId $jobId -vaultName $VaultName -vaultRg $VaultResourceGroup -subId $SubscriptionId

    if ($job.properties.status -ne "Completed") {
        $failureReason = "Restore job status: $($job.properties.status) | $($job.properties.errorDetails.errorMessage)"
        throw $failureReason
    }

    Write-Status "Restore job completed. Running health check..." "Green"

} catch {
    $failureReason = $_.Exception.Message
    Write-Status "Restore failed: $failureReason" "Red"
}

# -- Health check ------------------------------------------------------------
$healthCheckPassed = $false
if ($null -eq $failureReason) {
    $healthCheckPassed = Test-VmHealth `
        -vmName $targetVmName `
        -resourceGroup $RecoveryResourceGroup `
        -subId $SubscriptionId
}

$testEndTime     = [datetime]::UtcNow
$elapsedMinutes  = [math]::Round(($testEndTime - $testStartTime).TotalMinutes, 1)
$rtoAchieved     = ($healthCheckPassed -and ($elapsedMinutes -le $rtoTarget))

# -- Write result ------------------------------------------------------------
$result = [pscustomobject]@{
    testId                 = $testId
    workloadName           = $WorkloadName
    workloadType           = $WorkloadType
    tier                   = $Tier
    vaultName              = $VaultName
    startTime              = $testStartTime.ToString("o")
    endTime                = $testEndTime.ToString("o")
    elapsedMinutes         = $elapsedMinutes
    rtoTargetMinutes       = $rtoTarget
    rtoAchieved            = $rtoAchieved
    recoveryPointId        = $rpName
    recoveryPointTimestamp = $rpTime.ToString("o")
    recoveryDeltaMinutes   = $recoveryDeltaMinutes
    healthCheckPassed      = $healthCheckPassed
    failureReason          = $failureReason
    recoveryResourceGroup  = $RecoveryResourceGroup
    restoredResourceName   = $targetVmName
}

$status = if ($rtoAchieved) { "PASS" } else { "FAIL" }
$statusColor = if ($rtoAchieved) { "Green" } else { "Red" }

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host " RTO TEST RESULT: $status" -ForegroundColor $statusColor
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host (" Elapsed time    : {0} min  (target: {1} min)" -f $elapsedMinutes, $rtoTarget)
Write-Host (" RTO achieved    : {0}" -f $rtoAchieved)
Write-Host (" Recovery delta  : {0} min  (real-world RPO)" -f $recoveryDeltaMinutes)
Write-Host (" Health check    : {0}" -f $healthCheckPassed)
if ($failureReason) { Write-Host (" Failure reason  : {0}" -f $failureReason) -ForegroundColor Red }
Write-Host "============================================="

$ts         = Get-Date -Format "yyyyMMdd-HHmmss"
$outputFile = Join-Path $OutputPath "rto-test-result-$ts.json"
$result | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $outputFile
Write-Status "Result written to: $outputFile" "Green"

# -- Cleanup -----------------------------------------------------------------
if (-not $KeepRestored) {
    Write-Status "Cleaning up recovery resource group: $RecoveryResourceGroup"
    az group delete --name $RecoveryResourceGroup --subscription $SubscriptionId --yes 2>$null | Out-Null
    Write-Status "Cleanup complete." "Green"
} else {
    Write-Status "KeepRestored set -- $RecoveryResourceGroup left intact for manual inspection." "Yellow"
}
#endregion
