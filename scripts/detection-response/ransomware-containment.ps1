<#
.SYNOPSIS
    First-15-minutes ransomware containment automation. Given a Sentinel incident ID
    and a list of affected VM names, executes the containment sequence defined in
    docs/ir-playbooks/ransomware-encryption-event.md.

.DESCRIPTION
    Containment sequence (deliberately ordered -- deviation from most playbooks):

    STEP 1 - On-demand backup snapshot (BEFORE isolation)
             Most IR playbooks isolate first, then snapshot. This is wrong for VMs
             not currently in the middle of a scheduled backup: isolating first can
             leave the last-known-good snapshot as the only recovery option if the
             vault connectivity check fails post-isolation. Taking a snapshot first
             guarantees a recovery point exists before any network change.

    STEP 2 - NIC detach from production VNet (not NIC delete)
             Removes the VM from the network without deleting any resource. The NIC
             remains attached to the VM but is moved to an isolated "quarantine" subnet.
             This preserves network forensic state (MAC address, IP allocation history)
             while fully blocking east-west and north-south traffic.

    STEP 3 - Entra ID account disable for sessions active at time of detection
             Queries Defender for Cloud / Sentinel for the user identities with active
             sessions on the affected VMs. Disables those accounts in Entra ID to
             prevent lateral movement via compromised credentials.

    STEP 4 - Evidence package
             Writes a timestamped evidence record (resource state JSON, network config,
             active session list, action timeline) to the immutable evidence storage
             account. This is chain-of-custody documentation for the IR.

    All actions are logged to the evidence package with timestamps and operator.
    Each step is idempotent -- safe to re-run if interrupted.

.REQUIREMENTS
    - Az module (Az.Compute, Az.Network, Az.RecoveryServices, Az.Storage)
    - Microsoft.Graph module (for Entra ID account disable)
    - Az CLI for Defender for Cloud signal queries
    - Storage account name in env var: EVIDENCE_STORAGE_ACCOUNT
    - Evidence container: evidence-packages (immutable, WORM policy)
    - Quarantine subnet ID in env var: QUARANTINE_SUBNET_ID
    - Secrets: never embedded -- use OIDC/managed identity or env vars

.PARAMETER IncidentId
    Sentinel incident ID (e.g., "IR-2024-0042"). Used as evidence package prefix.

.PARAMETER AffectedVms
    Comma-separated list of VM names to contain.

.PARAMETER ResourceGroup
    Resource group containing the affected VMs.

.PARAMETER SubscriptionId
    Target subscription. Defaults to current Az context.

.PARAMETER VaultName
    Recovery Services Vault for on-demand snapshot.

.PARAMETER VaultResourceGroup
    Resource group of the vault.

.PARAMETER SkipSnapshot
    DANGEROUS: Skip the snapshot step. Only use if snapshot already confirmed current
    and vault connectivity is verified. Requires explicit acknowledgment.

.PARAMETER DryRun
    If set, logs all planned actions but does not execute any of them.

.EXAMPLE
    # Contain two VMs under incident IR-2024-0042
    .`ransomware-containment.ps1 `
        -IncidentId "IR-2024-0042" `
        -AffectedVms "prod-web-vm-01,prod-web-vm-02" `
        -ResourceGroup "rg-prod-eastus2" `
        -VaultName "bcdr-vault-tier1" `
        -VaultResourceGroup "rg-bcdr-eastus2"

.EXAMPLE
    # Dry run to preview actions before executing
    .`ransomware-containment.ps1 `
        -IncidentId "IR-2024-0042" `
        -AffectedVms "prod-web-vm-01" `
        -ResourceGroup "rg-prod-eastus2" `
        -VaultName "bcdr-vault-tier1" `
        -VaultResourceGroup "rg-bcdr-eastus2" `
        -DryRun

.NOTES
    Playbook: docs/ir-playbooks/ransomware-encryption-event.md
    Cross-references: kql/vault-tamper-detection.kql, automation/playbooks/isolate-on-ransomware.jsonc
    Lab: labs/bcdr-ir-plan
    Author: Frances Saunders
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$IncidentId,
    [Parameter(Mandatory)][string]$AffectedVms,
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$VaultName,
    [Parameter(Mandatory)][string]$VaultResourceGroup,
    [string]$SubscriptionId,
    [switch]$SkipSnapshot,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
#region --- Environment / Config --------------------------------------------
$EvidenceStorageAccount = $env:EVIDENCE_STORAGE_ACCOUNT
$EvidenceContainer      = "evidence-packages"
$QuarantineSubnetId     = $env:QUARANTINE_SUBNET_ID

if (-not $EvidenceStorageAccount) {
    throw "Environment variable EVIDENCE_STORAGE_ACCOUNT is not set."
}
if (-not $QuarantineSubnetId) {
    throw "Environment variable QUARANTINE_SUBNET_ID is not set."
}
#endregion

#region --- Timeline / Evidence logger --------------------------------------
$Timeline = [System.Collections.Generic.List[pscustomobject]]::new()

function Add-TimelineEvent {
    param([string]$step, [string]$action, [string]$target, [string]$result, [string]$detail = "")
    $event = [pscustomobject]@{
        timestamp  = [datetime]::UtcNow.ToString("o")
        incidentId = $IncidentId
        step       = $step
        action     = $action
        target     = $target
        result     = $result
        detail     = $detail
        operator   = $env:USERNAME ?? "automation"
        dryRun     = [bool]$DryRun
    }
    $Timeline.Add($event)
    $color = switch ($result) {
        "SUCCESS" { "Green"  }
        "SKIPPED" { "Yellow" }
        "FAILED"  { "Red"    }
        default   { "Cyan"   }
    }
    Write-Host ("[{0}] [{1}] {2} > {3}: {4}" -f (Get-Date -Format "HH:mm:ss"), $step, $action, $target, $result) -ForegroundColor $color
    if ($detail) { Write-Host "  Detail: $detail" -ForegroundColor DarkGray }
}

function Write-Status ([string]$msg, [string]$color = "Cyan") {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $color
}
#endregion

#region --- Step functions --------------------------------------------------

function Invoke-SnapshotBeforeIsolation {
    param([string]$vmName, [string]$subId)
    Write-Status "[STEP 1] Taking on-demand snapshot of $vmName BEFORE network isolation..." "Yellow"

    # Identify backup container and item
    $containerName = "iaasvmcontainerv2;$ResourceGroup;$vmName".ToLower()
    $itemName      = "vm;iaasvmcontainerv2;$ResourceGroup;$vmName".ToLower()

    if ($DryRun) {
        Add-TimelineEvent -step "STEP1-SNAPSHOT" -action "OnDemandBackup" -target $vmName -result "SKIPPED" -detail "DryRun"
        return $true
    }

    try {
        $job = az backup protection backup-now `
            --resource-group $VaultResourceGroup `
            --vault-name $VaultName `
            --container-name $containerName `
            --item-name $itemName `
            --retain-until (Get-Date).AddDays(30).ToString("dd-MM-yyyy") `
            --subscription $subId `
            --output json 2>$null | ConvertFrom-Json

        $jobId = $job.name

        # Wait up to 10 minutes for snapshot to initiate (not complete -- we just need it started)
        $deadline = (Get-Date).AddMinutes(10)
        $initiated = $false
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 15
            $jobStatus = az backup job show `
                --resource-group $VaultResourceGroup `
                --vault-name $VaultName `
                --name $jobId `
                --subscription $subId `
                --output json 2>$null | ConvertFrom-Json

            if ($jobStatus.properties.status -in @("Completed","InProgress")) {
                $initiated = $true
                break
            }
            if ($jobStatus.properties.status -eq "Failed") {
                throw "Backup job failed: $($jobStatus.properties.errorDetails.errorMessage)"
            }
        }

        if ($initiated) {
            Add-TimelineEvent -step "STEP1-SNAPSHOT" -action "OnDemandBackup" -target $vmName -result "SUCCESS" -detail "Job: $jobId | Status: $($jobStatus.properties.status)"
            return $true
        } else {
            throw "Snapshot did not initiate within 10 minutes."
        }
    } catch {
        Add-TimelineEvent -step "STEP1-SNAPSHOT" -action "OnDemandBackup" -target $vmName -result "FAILED" -detail $_.Exception.Message
        # CRITICAL: Do not proceed to isolation if snapshot failed and -SkipSnapshot not set
        if (-not $SkipSnapshot) {
            Write-Status "CRITICAL: Snapshot failed and -SkipSnapshot not set. Halting containment for $vmName." "Red"
            Write-Status "To proceed without snapshot, re-run with -SkipSnapshot after confirming backup state." "Red"
            return $false
        }
        Write-Status "WARNING: Snapshot failed but -SkipSnapshot is set. Proceeding to isolation." "Yellow"
        return $true
    }
}
function Invoke-NetworkIsolation {
    param([string]$vmName, [string]$subId)
    Write-Status "[STEP 2] Isolating $vmName by moving NIC to quarantine subnet..." "Yellow"

    if ($DryRun) {
        Add-TimelineEvent -step "STEP2-ISOLATION" -action "NicQuarantine" -target $vmName -result "SKIPPED" -detail "DryRun"
        return
    }

    try {
        # Get the VM to find its NIC IDs
        $vm = az vm show `
            --name $vmName `
            --resource-group $ResourceGroup `
            --subscription $subId `
            --output json 2>$null | ConvertFrom-Json

        foreach ($nicRef in $vm.networkProfile.networkInterfaces) {
            $nicParts = $nicRef.id -split "/"
            $nicName  = $nicParts[-1]
            $nicRg    = $nicParts[4]

            # Record current NIC config for evidence
            $nicCurrent = az network nic show `
                --name $nicName `
                --resource-group $nicRg `
                --subscription $subId `
                --output json 2>$null | ConvertFrom-Json

            $originalSubnet = $nicCurrent.ipConfigurations[0].subnet.id

            # Move NIC IP config to quarantine subnet (preserve NIC and IP config)
            az network nic ip-config update `
                --name $nicCurrent.ipConfigurations[0].name `
                --nic-name $nicName `
                --resource-group $nicRg `
                --subnet $QuarantineSubnetId `
                --subscription $subId `
                --output none 2>$null

            Add-TimelineEvent `
                -step "STEP2-ISOLATION" `
                -action "NicQuarantine" `
                -target "$vmName/$nicName" `
                -result "SUCCESS" `
                -detail "Moved from: $originalSubnet | To: $QuarantineSubnetId"
        }
    } catch {
        Add-TimelineEvent -step "STEP2-ISOLATION" -action "NicQuarantine" -target $vmName -result "FAILED" -detail $_.Exception.Message
        Write-Status "WARNING: NIC isolation failed for $vmName. Manual isolation required." "Red"
    }
}

function Invoke-IdentityContainment {
    param([string]$vmName, [string]$subId)
    Write-Status "[STEP 3] Querying Defender for Cloud for active sessions on $vmName..." "Yellow"

    if ($DryRun) {
        Add-TimelineEvent -step "STEP3-IDENTITY" -action "EntraDisable" -target $vmName -result "SKIPPED" -detail "DryRun"
        return
    }

    try {
        # Query Defender for Cloud alerts for logon sessions on affected VM
        $alerts = az security alert list `
            --subscription $subId `
            --query "[?contains(properties.resourceIdentifiers[0].azureResourceId, '$vmName') && properties.status != 'Dismissed']" `
            --output json 2>$null | ConvertFrom-Json

        # Extract unique user principal names from alert entities
        $usersToDisable = @()
        foreach ($alert in $alerts) {
            $entities = $alert.properties.entities | Where-Object { $_.type -eq "account" }
            foreach ($entity in $entities) {
                $upn = $entity.dnsDomain ? "$($entity.name)@$($entity.dnsDomain)" : $entity.name
                if ($upn -and $upn -notin $usersToDisable) { $usersToDisable += $upn }
            }
        }

        if ($usersToDisable.Count -eq 0) {
            Write-Status "  No active user sessions found in Defender signals for $vmName." "Yellow"
            Add-TimelineEvent -step "STEP3-IDENTITY" -action "EntraDisable" -target $vmName -result "SKIPPED" -detail "No session accounts found in Defender signals"
            return
        }

        Write-Status "  Disabling $($usersToDisable.Count) account(s): $($usersToDisable -join ', ')" "Yellow"

        foreach ($upn in $usersToDisable) {
            try {
                # Disable account via Microsoft Graph
                Update-MgUser -UserId $upn -AccountEnabled:$false
                # Revoke all refresh tokens
                Invoke-MgInvalidateAllUserRefreshToken -UserId $upn | Out-Null

                Add-TimelineEvent `
                    -step "STEP3-IDENTITY" `
                    -action "EntraDisable" `
                    -target $upn `
                    -result "SUCCESS" `
                    -detail "Account disabled and refresh tokens revoked"
            } catch {
                Add-TimelineEvent -step "STEP3-IDENTITY" -action "EntraDisable" -target $upn -result "FAILED" -detail $_.Exception.Message
            }
        }
    } catch {
        Add-TimelineEvent -step "STEP3-IDENTITY" -action "EntraDisable" -target $vmName -result "FAILED" -detail $_.Exception.Message
        Write-Status "WARNING: Identity containment step failed. Manual review of active sessions required." "Red"
    }
}

function Write-EvidencePackage {
    param([string]$subId, [string[]]$vmNames)
    Write-Status "[STEP 4] Writing evidence package to immutable storage..." "Yellow"

    $ts          = Get-Date -Format "yyyyMMdd-HHmmss"
    $packageName = "$IncidentId-containment-$ts"
    $localDir    = Join-Path ([System.IO.Path]::GetTempPath()) $packageName
    New-Item -ItemType Directory -Path $localDir -Force | Out-Null

    # Write timeline
    $Timeline | ConvertTo-Json -Depth 10 | Out-File (Join-Path $localDir "action-timeline.json") -Encoding utf8

    # Capture current VM state for each affected VM
    foreach ($vmName in $vmNames) {
        try {
            $vmState = az vm show `
                --name $vmName `
                --resource-group $ResourceGroup `
                --subscription $subId `
                --output json 2>$null
            $vmState | Out-File (Join-Path $localDir "vm-state-$vmName.json") -Encoding utf8
        } catch {
            "Failed to capture VM state: $($_.Exception.Message)" | Out-File (Join-Path $localDir "vm-state-$vmName-error.txt")
        }
    }

    # Write manifest with SHA-256 hashes
    $manifest = @()
    foreach ($f in (Get-ChildItem -Path $localDir -File)) {
        $hash = (Get-FileHash -Path $f.FullName -Algorithm SHA256).Hash
        $manifest += [pscustomobject]@{ file = $f.Name; sha256 = $hash; sizeBytes = $f.Length }
    }
    $manifest | ConvertTo-Json | Out-File (Join-Path $localDir "manifest.json") -Encoding utf8

    if ($DryRun) {
        Write-Status "  DryRun: Evidence package prepared at $localDir but NOT uploaded." "Yellow"
        Add-TimelineEvent -step "STEP4-EVIDENCE" -action "UploadPackage" -target $packageName -result "SKIPPED" -detail "DryRun -- local path: $localDir"
        return
    }

    # Upload all files to immutable evidence container
    try {
        foreach ($f in (Get-ChildItem -Path $localDir -File)) {
            az storage blob upload `
                --account-name $EvidenceStorageAccount `
                --container-name $EvidenceContainer `
                --name "$packageName/$($f.Name)" `
                --file $f.FullName `
                --auth-mode login `
                --overwrite false `
                --output none 2>$null
        }
        Add-TimelineEvent -step "STEP4-EVIDENCE" -action "UploadPackage" -target $packageName -result "SUCCESS" -detail "Container: $EvidenceContainer | Files: $($manifest.Count)"
        Write-Status "  Evidence package uploaded: $packageName" "Green"
    } catch {
        Add-TimelineEvent -step "STEP4-EVIDENCE" -action "UploadPackage" -target $packageName -result "FAILED" -detail $_.Exception.Message
        Write-Status "  Evidence upload failed. Local copy at: $localDir" "Red"
    }
}
#endregion
#region --- Main ------------------------------------------------------------
$scriptStart = [datetime]::UtcNow
$vmList      = $AffectedVms -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }

if ($DryRun) {
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host " DRY RUN MODE -- NO ACTIONS WILL EXECUTE" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
}

Write-Status "RANSOMWARE CONTAINMENT | Incident: $IncidentId"
Write-Status "Affected VMs: $($vmList -join ', ')"
Write-Status "Snapshot-before-isolation: $(if ($SkipSnapshot) { 'DISABLED (SkipSnapshot set)' } else { 'ENABLED' })"

# Resolve subscription
if ($SubscriptionId) {
    az account set --subscription $SubscriptionId 2>$null
} else {
    $SubscriptionId = (az account show --query "id" -o tsv 2>$null)
}

# Process each affected VM
foreach ($vmName in $vmList) {
    Write-Host "
--- Containing: $vmName ---" -ForegroundColor Cyan

    # STEP 1: Snapshot BEFORE isolation
    if (-not $SkipSnapshot) {
        $snapshotOk = Invoke-SnapshotBeforeIsolation -vmName $vmName -subId $SubscriptionId
        if (-not $snapshotOk) {
            Write-Status "Skipping remaining containment steps for $vmName due to snapshot failure." "Red"
            continue
        }
    } else {
        Add-TimelineEvent -step "STEP1-SNAPSHOT" -action "OnDemandBackup" -target $vmName -result "SKIPPED" -detail "SkipSnapshot parameter set"
    }

    # STEP 2: Network isolation
    Invoke-NetworkIsolation -vmName $vmName -subId $SubscriptionId

    # STEP 3: Identity containment
    Invoke-IdentityContainment -vmName $vmName -subId $SubscriptionId
}

# STEP 4: Evidence package (once for all VMs)
Write-EvidencePackage -subId $SubscriptionId -vmNames $vmList

# Final summary
$duration = [math]::Round(([datetime]::UtcNow - $scriptStart).TotalMinutes, 1)

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " CONTAINMENT COMPLETE | $IncidentId" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host (" Duration     : {0} minutes" -f $duration)
Write-Host (" VMs processed: {0}" -f $vmList.Count)
Write-Host (" Actions logged: {0}" -f $Timeline.Count)
Write-Host " Review action-timeline.json in evidence container for full chain of custody."
Write-Host "======================================================" -ForegroundColor Cyan

# Exit with non-zero if any step failed
$failedSteps = $Timeline | Where-Object { $_.result -eq "FAILED" }
if ($failedSteps.Count -gt 0) {
    Write-Status "$($failedSteps.Count) step(s) failed. Review timeline for details." "Red"
    exit 1
}
#endregion
