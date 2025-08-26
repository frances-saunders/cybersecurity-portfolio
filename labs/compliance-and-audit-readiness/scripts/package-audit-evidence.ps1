<#
.SYNOPSIS
  Packages evidence for audit delivery with integrity metadata.

.OUTPUTS
  ./evidence/packages/<timestamp>-evidence.zip
  ./evidence/packages/<timestamp>-evidence.sha256
  ./evidence/packages/<timestamp>-manifest.json

.NOTES
  - No secrets are embedded.
  - If a local code signing certificate named 'AuditEvidenceSigner' exists,
    the manifest will be signed; otherwise, unsigned manifest is produced.
#>

param(
  [Parameter(Mandatory=$false)]
  [string] $EvidenceRoot = "./evidence"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EvidenceRoot)) {
  throw "Evidence directory not found: $EvidenceRoot"
}

$packages = Join-Path $EvidenceRoot "packages"
if (-not (Test-Path $packages)) { New-Item -Path $packages -ItemType Directory | Out-Null }

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zipPath = Join-Path $packages "$stamp-evidence.zip"
$hashPath = Join-Path $packages "$stamp-evidence.sha256"
$manifestPath = Join-Path $packages "$stamp-manifest.json"

# Build manifest of all files (excluding packages dir)
$files = Get-ChildItem -Path $EvidenceRoot -Recurse -File | Where-Object { $_.FullName -notlike "*\packages\*" }

$manifest = [ordered]@{
  createdAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  fileCount    = $files.Count
  files        = @()
}

# Compute file-level hashes for integrity
foreach ($f in $files) {
  $fileHash = Get-FileHash -Path $f.FullName -Algorithm SHA256
  $manifest.files += [ordered]@{
    path   = (Resolve-Path $f.FullName).Path
    sha256 = $fileHash.Hash.ToLower()
    bytes  = $f.Length
  }
}

# Write manifest (unsigned for now)
$manifest | ConvertTo-Json -Depth 6 | Out-File -FilePath $manifestPath -Encoding UTF8

# Optional signing if a certificate is available locally
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.FriendlyName -eq "AuditEvidenceSigner" } | Select-Object -First 1
if ($cert) {
  try {
    Set-AuthenticodeSignature -FilePath $manifestPath -Certificate $cert | Out-Null
    Write-Host "Manifest signed with local certificate 'AuditEvidenceSigner'."
  } catch {
    Write-Warning "Failed to sign manifest: $($_.Exception.Message)"
  }
}

# Create archive
Compress-Archive -Path ($files | ForEach-Object FullName) -DestinationPath $zipPath

# Compute package hash
(Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower() | Out-File -FilePath $hashPath -Encoding ASCII

Write-Host "Evidence packaged:"
Write-Host "  ZIP:      $zipPath"
Write-Host "  SHA256:   $hashPath"
Write-Host "  Manifest: $manifestPath"
