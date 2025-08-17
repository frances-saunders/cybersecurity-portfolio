<#
.SYNOPSIS
    Azure Automation Runbook to remediate AKS Policy non-compliance.

.DESCRIPTION
    This runbook identifies AKS resources marked as NonCompliant by Azure Policy
    and attempts remediation by triggering policy compliance evaluation and remediation tasks.
    Designed to showcase proactive security operations automation.

.NOTES
    Author: Frances Saunders Portfolio
    Last Updated: 2025-08-16
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName
)

Write-Output "Connecting to Azure..."
Connect-AzAccount -Identity

# Set subscription context
Set-AzContext -Subscription $SubscriptionId

Write-Output "Querying Policy compliance state for AKS resources..."
$aksResources = Get-AzPolicyState `
    -SubscriptionId $SubscriptionId `
    | Where-Object { $_.ComplianceState -eq "NonCompliant" -and $_.ResourceId -like "*Microsoft.ContainerService/managedClusters*" }

if (-not $aksResources) {
    Write-Output "No non-compliant AKS resources found."
    exit 0
}

foreach ($resource in $aksResources) {
    Write-Output "Found non-compliant AKS resource: $($resource.ResourceId)"
    
    # Trigger policy remediation
    try {
        $remediationName = "remediate-aks-" + (Get-Random)
        Write-Output "Starting remediation task: $remediationName"

        Start-AzPolicyRemediation `
            -Name $remediationName `
            -PolicyAssignmentId $resource.PolicyAssignmentId `
            -ResourceGroupName $ResourceGroupName `
            -ResourceId $resource.ResourceId

        Write-Output "Remediation task $remediationName started successfully."
    }
    catch {
        Write-Error "Failed to remediate $($resource.ResourceId): $_"
    }
}

Write-Output "AKS Policy remediation runbook complete."
