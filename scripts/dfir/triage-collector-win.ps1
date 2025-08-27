<#
.SYNOPSIS
  Windows live response triage (no memory dump). Gathers autoruns, network, services, tasks, persistence hints.
  Produces a ZIP with a SHA256 manifest for integrity.

.NOTES
  Run as Admin. Avoids touching user data beyond metadata. Redacts common PII patterns in text outputs.

.OUTPUTS
  triage-YYYYmmddHHMMSS.zip
#>

[CmdletBinding()]
param(
  [string]$OutDir = ".\triage",
  [switch]$NoRedact
)

$ErrorActionPreference = "Stop"
$ts = Get-Date -Format "yyyyMMddHHmmss"
$root = Join-Path $OutDir "win-$ts"
New-Item -ItemType Directory -Force -Path $root | Out-Null

function Save-Text($name, $content) {
  $path = Join-Path $root $name
  $content | Out-File -FilePath $path -Encoding utf8 -Width 500
}

Write-Host "[*] Collecting basic system info..."
systeminfo | Save-Text "systeminfo.txt"
Get-ComputerInfo | ConvertTo-Json -Depth 4 | Save-Text "computerinfo.json"
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" | ConvertTo-Json | Save-Text "os-version.json"

Write-Host "[*] Processes & services..."
Get-Process | Sort-Object CPU -Descending | Select-Object Id,ProcessName,Path,CPU,StartTime | Export-Csv (Join-Path $root "processes.csv") -NoTypeInformation
Get-Service | Select-Object Name,DisplayName,Status,StartType | Export-Csv (Join-Path $root "services.csv") -NoTypeInformation

Write-Host "[*] Network..."
Get-NetTCPConnection | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess | Export-Csv (Join-Path $root "net-tcp.csv") -NoTypeInformation
Get-NetUDPEndpoint | Select-Object LocalAddress,LocalPort,OwningProcess | Export-Csv (Join-Path $root "net-udp.csv") -NoTypeInformation
ipconfig /all | Save-Text "ipconfig.txt"
arp -a | Save-Text "arp.txt"
route print | Save-Text "route.txt"
netstat -abno | Save-Text "netstat-abno.txt"

Write-Host "[*] Scheduled tasks..."
schtasks /query /fo LIST /v | Save-Text "scheduled-tasks.txt"

Write-Host "[*] Autoruns & persistence (registry run keys, services, WMI subscriptions)..."
reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /s | Save-Text "reg-run-hklm.txt"
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /s | Save-Text "reg-run-hkcu.txt"
Get-WmiObject -Namespace root\subscription -Class __EventFilter,CommandLineEventConsumer,ActiveScriptEventConsumer,Binding | Out-File (Join-Path $root "wmi-persistence.txt")

Write-Host "[*] Users & logons..."
query user | Save-Text "logged-on-users.txt"
Get-LocalUser | Select-Object Name,Enabled,LastLogon | Export-Csv (Join-Path $root "local-users.csv") -NoTypeInformation

# Redaction (simple patterns)
if (-not $NoRedact) {
  Write-Host "[*] Redacting common PII patterns in text files..."
  Get-ChildItem $root -Recurse -File -Include *.txt,*.json,*.csv | ForEach-Object {
    (Get-Content $_.FullName -Raw) `
      -replace '\b\d{3}-\d{2}-\d{4}\b','[REDACTED-SSN]' `
      -replace '(?i)password\s*[:=]\s*\S+','password:[REDACTED]' `
      -replace '(?i)api[_-]?key\s*[:=]\s*\S+','api_key:[REDACTED]' | Set-Content $_.FullName -Encoding utf8
  }
}

# Hash manifest
$manifest = @()
Get-ChildItem $root -Recurse -File | ForEach-Object {
  $bytes = Get-FileHash -Algorithm SHA256 -Path $_.FullName
  $manifest += [pscustomobject]@{ path = $_.FullName.Substring($root.Length+1); sha256 = $bytes.Hash }
}
$manifest | ConvertTo-Json -Depth 4 | Out-File (Join-Path $root "manifest.json") -Encoding utf8

# Zip
$zip = "triage-$ts.zip"
Compress-Archive -Path $root -DestinationPath (Join-Path $OutDir $zip) -Force
Write-Host "[+] Wrote $(Join-Path $OutDir $zip)"
