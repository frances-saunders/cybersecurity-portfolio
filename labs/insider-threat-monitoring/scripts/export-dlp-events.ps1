<#
.SYNOPSIS
  Exports recent Microsoft Purview DLP events and posts to Log Analytics.

.DESCRIPTION
  Uses app-only auth with certificate from Azure Key Vault (no plaintext secrets).
  Falls back to env vars if needed. Writes audit to custom table 'DlpEvents_CL'.

.REQUIRES
  - Az.Accounts, Az.KeyVault, ExchangeOnlineManagement (for Unified Audit Log), or Graph API.
#>

[CmdletBinding()]
param(
  [string]$WorkspaceId = $env:LOGANALYTICS_WORKSPACE_ID,
  [string]$KeyVaultName,
  [string]$SharedKey = $env:LOGANALYTICS_SHARED_KEY,
  [int]$Hours = 24,
  [string]$Tenant = $env:AZURE_TENANT_ID,
  [string]$AppId = $env:APP_ID,                 # Entra app with audit read permissions
  [string]$CertName = "PurviewDlpReaderCert"    # Cert stored in Key Vault
)

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.KeyVault -ErrorAction Stop

function Get-SharedKey {
  if ($SharedKey) { return $SharedKey }
  if ($KeyVaultName) {
    $s = az keyvault secret show --vault-name $KeyVaultName --name "LogAnalyticsSharedKey" --query value -o tsv 2>$null
    if ($LASTEXITCODE -eq 0 -and $s) { return $s }
  }
  throw "Shared key not found."
}

function New-AuthHeader {
  param([string]$Tenant,[string]$AppId,[System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert)
  $thumb = $Cert.Thumbprint
  Connect-ExchangeOnline -AppId $AppId -CertificateThumbprint $thumb -Organization $Tenant -ShowBanner:$false
}

function Get-CertFromKeyVault {
  param([string]$Kv,[string]$Name)
  $tmp = Join-Path $env:TEMP "$Name.pfx"
  az keyvault certificate download --vault-name $Kv --name $Name --file $tmp --encoding Pkcs12 | Out-Null
  $pfxPwd = Read-Host -AsSecureString -Prompt "Enter PFX password (or press Enter if none)"
  if (-not (Test-Path $tmp)) { throw "Certificate download failed." }
  $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
  $cert.Import($tmp, $pfxPwd, 'Exportable,PersistKeySet,MachineKeySet')
  Remove-Item $tmp -Force
  return $cert
}

function Build-Signature {
  param($workspaceId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
  $xHeaders = "x-ms-date:" + $date
  $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
  $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
  $keyBytes = [Convert]::FromBase64String($sharedKey)
  $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
  $hmacsha256.Key = $keyBytes
  $hash = $hmacsha256.ComputeHash($bytesToHash)
  "SharedKey $workspaceId:" + [Convert]::ToBase64String($hash)
}

function Post-LA {
  param([string]$WorkspaceId,[string]$SharedKey,[object]$Body,[string]$LogType)
  $json = ($Body | ConvertTo-Json -Depth 6)
  $rfc1123date = [DateTime]::UtcNow.ToString("r")
  $sig = Build-Signature -workspaceId $WorkspaceId -sharedKey $SharedKey -date $rfc1123date -contentLength ($json.Length) -method "POST" -contentType "application/json" -resource "/api/logs"
  $uri = "https://$WorkspaceId.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
  Invoke-RestMethod -Method Post -Uri $uri -Headers @{
    "Authorization"=$sig; "Log-Type"=$LogType; "x-ms-date"=$rfc1123date
  } -Body $json -ContentType "application/json" | Out-Null
}

$SharedKey = Get-SharedKey
if (-not $WorkspaceId) { throw "WorkspaceId required." }

$cert = if ($KeyVaultName) { Get-CertFromKeyVault -Kv $KeyVaultName -Name $CertName } else { $null }
if ($cert) { New-AuthHeader -Tenant $Tenant -AppId $AppId -Cert $cert } else { Write-Warning "No cert; ensure you have a valid session for Search-UnifiedAuditLog." }

$start = (Get-Date).ToUniversalTime().AddHours(-1 * $Hours)
$end   = (Get-Date).ToUniversalTime()

Write-Host "Querying Unified Audit Log for DLP events from $start to $end..."
$records = Search-UnifiedAuditLog -StartDate $start -EndDate $end -Operations DlpRuleMatch,DLPRuleUndo,SupervisoryReviewPolicyHit -SessionId "DLP_$(Get-Random)" -SessionCommand ReturnLargeSet -ResultSize 5000

$events = @()
foreach ($r in $records) {
  $d = $r.AuditData | ConvertFrom-Json
  $events += [pscustomobject]@{
    TimeGenerated = $r.CreationDate
    User          = $d.UserId
    Policy        = $d.DlpPolicy
    Rule          = $d.DlpRule
    Action        = $d.Action
    File          = $d.ObjectId
    Workload      = $d.Workload
    Severity      = if ($d.Action -eq 'Block') { 'High' } else { 'Medium' }
  }
}
if ($events.Count -gt 0) {
  Post-LA -WorkspaceId $WorkspaceId -SharedKey $SharedKey -Body $events -LogType "DlpEvents_CL"
  Write-Host "Posted $($events.Count) DLP events to Log Analytics (DlpEvents_CL)."
} else {
  Write-Host "No DLP events found."
}
