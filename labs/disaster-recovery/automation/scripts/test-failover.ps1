<#
.SYNOPSIS
  Simulates disaster recovery failover for Azure SQL.

.DESCRIPTION
  Forces failover of SQL failover group to secondary region,
  validates connectivity, and reports recovery time.
#>

param(
  [string]$FailoverGroup = "TelemetryDB-fog",
  [string]$ResourceGroup = "rg-dr-lab"
)

$start = Get-Date
Write-Host "Initiating failover for $FailoverGroup..."

az sql failover-group set-primary `
  --name $FailoverGroup `
  --resource-group $ResourceGroup `
  --server $FailoverGroup-secondary

$end = Get-Date
$duration = ($end - $start).TotalSeconds
Write-Host "Failover complete. RTO: $duration seconds"

# Validate connectivity
try {
    sqlcmd -S "$FailoverGroup-secondary.database.windows.net" -d "TelemetryDB" -U telemetryadmin -P $env:SQL_ADMIN_PASSWORD -Q "SELECT TOP 1 GETDATE();"
    Write-Host "Database connectivity validated post-failover."
} catch {
    Write-Error "Connectivity validation failed!"
}
