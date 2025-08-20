<#
.SYNOPSIS
    Enrich Sentinel incidents with threat intelligence context.
.DESCRIPTION
    Queries an external threat intel API for suspicious IPs/domains and
    appends enrichment data back into Sentinel incidents.
#>

param (
    [string]$IncidentId,
    [string]$Indicator
)

# Example: Threat Intelligence API call (sanitized for lab use)
$response = Invoke-RestMethod -Uri "https://threat-intel-api/labquery?ioc=$Indicator"

Write-Output "Enrichment for Incident $IncidentId"
Write-Output "Indicator: $Indicator"
Write-Output "Threat Intel Data: $($response.data)"
