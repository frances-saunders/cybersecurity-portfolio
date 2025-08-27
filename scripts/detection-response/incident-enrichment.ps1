<#
.SYNOPSIS
    Enriches an IP address or domain with WHOIS and GeoIP and prints a JSON object.

.PARAMETER Indicator
    IP or FQDN

.PARAMETER GeoIpApi
    Base URL for GeoIP API (expects ?q=<indicator>)

.PARAMETER WhoisApi
    Base URL for WHOIS API

.EXAMPLE
    .\incident-enrichment.ps1 -Indicator 8.8.8.8 -GeoIpApi https://geo/api -WhoisApi https://whois/api
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Indicator,
    [Parameter(Mandatory)][string]$GeoIpApi,
    [Parameter(Mandatory)][string]$WhoisApi
)

$ErrorActionPreference = "Stop"
try {
    $geo = Invoke-RestMethod -Method Get -Uri "$GeoIpApi?q=$Indicator" -TimeoutSec 10
    $who = Invoke-RestMethod -Method Get -Uri "$WhoisApi?q=$Indicator" -TimeoutSec 10
    [pscustomobject]@{
        indicator = $Indicator
        geo       = $geo
        whois     = $who
        ts        = (Get-Date).ToString("o")
    } | ConvertTo-Json -Depth 6
}
catch {
    Write-Error "Enrichment failed: $($_.Exception.Message)"
    exit 1
}
