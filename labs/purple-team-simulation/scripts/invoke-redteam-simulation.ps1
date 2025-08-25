<# 
.SYNOPSIS
    Orchestrates Atomic Red Team simulations safely and logs evidence to Log Analytics.

.DESCRIPTION
    - Selects techniques (default: APT29 end-to-end set)
    - Pulls secrets from Azure Key Vault OR environment variables
    - Sends execution audit to Log Analytics via HTTP Data Collector API
    - Designed for isolated lab only

.PARAMETER Techniques
    Array of ATT&CK technique IDs (e.g., 'T1059.001','T1003.001','T1047','T1021.002')

.PARAMETER WorkspaceId
    Log Analytics Workspace ID (GUID). If omitted, read from env LOGANALYTICS_WORKSPACE_ID.

.PARAMETER KeyVaultName
    Optional Azure Key Vault name to fetch 'LogAnalyticsSharedKey' secret.

.PARAMETER SharedKey
    Optional LA shared key; if omitted, fetched from Key Vault or env LOGANALYTICS_SHARED_KEY.

.PARAMETER TargetHost
    Optional remote target for lateral movement tests.

#>

[CmdletBinding()]
param(
    [string[]]$Techniques = @('T1059.001','T1003.001','T1047','T1021.002','T1041'),
    [string]$WorkspaceId = $env:LOGANALYTICS_WORKSPACE_ID,
    [string]$KeyVaultName,
    [string]$SharedKey = $env:LOGANALYTICS_SHARED_KEY,
    [string]$TargetHost = "LAB-SRV01",
    [switch]$DryRun
)

function Get-SharedKey {
    param([string]$KvName,[string]$Existing)
    if ($Existing) { return $Existing }
    if ($KvName) {
        try {
            $value = (az keyvault secret show --vault-name $KvName --name "LogAnalyticsSharedKey" --query value -o tsv 2>$null)
            if ($LASTEXITCODE -eq 0 -and $value) { return $value }
        } catch { }
    }
    if ($env:LOGANALYTICS_SHARED_KEY) { return $env:LOGANALYTICS_SHARED_KEY }
    throw "Shared key not found. Set LOGANALYTICS_SHARED_KEY or store 'LogAnalyticsSharedKey' in Key Vault."
}

function New-AuthorizationSignature {
    param($workspaceId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = $keyBytes
    $calculatedHash = $hmacsha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    "SharedKey $workspaceId:$encodedHash"
}

function Send-Log {
    param([string]$WorkspaceId,[string]$SharedKey,[string]$LogType,[pscustomobject]$Payload)
    $json = $Payload | ConvertTo-Json -Depth 6
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $sig = New-AuthorizationSignature -workspaceId $WorkspaceId -sharedKey $SharedKey -date $rfc1123date -contentLength ($json.Length) -method $method -contentType $contentType -resource $resource
    $uri = "https://$WorkspaceId.ods.opinsights.azure.com$resource?api-version=2016-04-01"
    Invoke-RestMethod -Method $method -Uri $uri -Headers @{
        "Authorization"=$sig; "Log-Type"=$LogType; "x-ms-date"=$rfc1123date
    } -Body $json -ContentType $contentType | Out-Null
}

function Ensure-AtomicModule {
    if (-not (Get-Module -ListAvailable -Name Invoke-AtomicRedTeam)) {
        Write-Host "Installing Atomic Red Team module..."
        Install-Module -Name Invoke-AtomicRedTeam -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module Invoke-AtomicRedTeam -ErrorAction Stop
}

$SharedKey = Get-SharedKey -KvName $KeyVaultName -Existing $SharedKey
if (-not $WorkspaceId) { throw "WorkspaceId not provided and LOGANALYTICS_WORKSPACE_ID not set." }

$sessionId = [guid]::NewGuid().ToString()
$hostName  = $env:COMPUTERNAME

Write-Host "Session $sessionId starting on $hostName. DryRun: $DryRun"
Send-Log -WorkspaceId $WorkspaceId -SharedKey $SharedKey -LogType "PurpleTeamAudit" -Payload ([pscustomobject]@{
    SessionId=$sessionId; Host=$hostName; Event="Start"; Techniques=$Techniques; TargetHost=$TargetHost; User=$env:USERNAME
})

if (-not $DryRun) { Ensure-AtomicModule }

foreach ($t in $Techniques) {
    Write-Host "Executing technique $t ..."
    $result = @{
        SessionId=$sessionId; Technique=$t; Host=$hostName; TargetHost=$TargetHost; Status="Planned"; Time=(Get-Date).ToUniversalTime()
    }
    try {
        if (-not $DryRun) {
            if ($t -eq 'T1047' -or $t -eq 'T1021.002') {
                Invoke-AtomicTest $t -GetPrereqs
                Invoke-AtomicTest $t -InputArgs @{ remote_host=$TargetHost }
            } else {
                Invoke-AtomicTest $t -GetPrereqs
                Invoke-AtomicTest $t
            }
        }
        $result.Status = "Executed"
    } catch {
        $result.Status = "Error"
        $result.Error = $_.Exception.Message
    } finally {
        Send-Log -WorkspaceId $WorkspaceId -SharedKey $SharedKey -LogType "PurpleTeamAudit" -Payload ([pscustomobject]$result)
    }
}

Send-Log -WorkspaceId $WorkspaceId -SharedKey $SharedKey -LogType "PurpleTeamAudit" -Payload ([pscustomobject]@{
    SessionId=$sessionId; Host=$hostName; Event="Complete"; Time=(Get-Date).ToUniversalTime()
})
Write-Host "Simulation complete. Session $sessionId"
