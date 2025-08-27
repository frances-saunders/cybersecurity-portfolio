<#
.SYNOPSIS
  Fires synthetic events to validate Sentinel playbooks and incident pipeline.

.DESCRIPTION
  - Sends a minimal custom log to Log Analytics via HTTP Data Collector (HMAC signature).
  - Optionally triggers a Logic App HTTP endpoint to ensure playbook connectivity.
  - Produces pass/fail JSON suitable for CI.

.PARAMETER WorkspaceId
.PARAMETER SharedKey
.PARAMETER LogType
.PARAMETER LogicAppUrl
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$WorkspaceId,
  [Parameter(Mandatory)][string]$SharedKey,
  [string]$LogType = "PlaybookSmokeTest_CL",
  [string]$LogicAppUrl
)

function New-Signature {
  param($date, $contentLength, $method, $contentType, $resource, $key)
  $xHeaders = "x-ms-date:" + $date
  $stringToHash = "$method`n$contentLength`n$contentType`n$xHeaders`n$resource"
  $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
  $keyBytes = [Convert]::FromBase64String($key)
  $hmacSha256 = New-Object System.Security.Cryptography.HMACSHA256
  $hmacSha256.Key = $keyBytes
  $calculatedHash = $hmacSha256.ComputeHash($bytesToHash)
  "SharedKey $WorkspaceId:" + [Convert]::ToBase64String($calculatedHash)
}

$body = @(
  @{
    TestRun = (Get-Date).ToString("o")
    Source  = "playbook-smoke-test"
    Guid    = [guid]::NewGuid().ToString()
  }
) | ConvertTo-Json

$method = "POST"
$contentType = "application/json"
$resource = "/api/logs"
$rfc1123date = [DateTime]::UtcNow.ToString("r")
$signature = New-Signature -date $rfc1123date -contentLength $body.Length -method $method -contentType $contentType -resource $resource -key $SharedKey

$uri = "https://$WorkspaceId.ods.opinsights.azure.com$resource?api-version=2016-04-01"
$headers = @{
  "Authorization" = $signature
  "Log-Type"      = $LogType
  "x-ms-date"     = $rfc1123date
}

$result = @{ logIngested = $false; logicApp = $null; ts = (Get-Date).ToString("o") }

try {
  Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ContentType $contentType | Out-Null
  $result.logIngested = $true
} catch { $result.logIngested = $false }

if ($PSBoundParameters.ContainsKey("LogicAppUrl")) {
  try {
    Invoke-RestMethod -Method Post -Uri $LogicAppUrl -Body ($body) -ContentType $contentType | Out-Null
    $result.logicApp = "triggered"
  } catch {
    $result.logicApp = "error"
  }
}

$result | ConvertTo-Json -Depth 5
if (-not $result.logIngested) { exit 2 }
