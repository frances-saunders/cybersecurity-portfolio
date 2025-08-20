<#
.SYNOPSIS
    Collects Microsoft Defender alerts and forwards to Log Analytics.
#>

param (
    [string]$WorkspaceId,
    [string]$SharedKey
)

$LogType = "DefenderAlerts"

# Get latest alerts
$alerts = Get-MdatpAlert | Select-Object Id, Title, Category, Severity, DetectionSource, CreatedTime

# Convert to JSON
$json = $alerts | ConvertTo-Json -Depth 3

# Write to file
$json | Out-File -FilePath alerts.json -Encoding utf8

# Call Python forwarder
python3 post-to-law.py $WorkspaceId $SharedKey $LogType alerts.json
