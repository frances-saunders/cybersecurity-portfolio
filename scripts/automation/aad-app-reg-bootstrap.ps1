<#
.SYNOPSIS
  Bootstraps an Azure AD application for certificate-based auth, stores the cert in Key Vault,
  adds the public cert to the app's credentials, creates the service principal, and optionally assigns least-privileged RBAC.

.DESCRIPTION
  - Generates a short-lived self-signed certificate locally (exportable, ephemeral PFX on disk)
  - Imports the PFX into Azure Key Vault (so the private key is escrowed centrally)
  - Adds the PUBLIC cert to the Azure AD Application keyCredentials (no secrets stored in code or logs)
  - Creates the Service Principal
  - Optionally assigns RBAC role(s) at a provided scope (e.g., Reader on a RG) following least-privilege
  - Supports -WhatIf/-Confirm and structured output

.REQUIREMENTS
  - Az.Accounts, Az.KeyVault, Microsoft.Graph PowerShell modules
  - Azure login with privileges: Application.ReadWrite.All, Directory.ReadWrite.All, Key Vault import, and RBAC assignment if used

.EXAMPLE
  .\aad-app-reg-bootstrap.ps1 -AppDisplayName "contoso-ci" -VaultName "corp-kv" -CertName "contoso-ci-auth" `
    -RoleDefinitionName "Reader" -Scope "/subscriptions/<subId>/resourceGroups/rg-app" -Years 1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [Parameter(Mandatory)][string]$AppDisplayName,
  [Parameter(Mandatory)][string]$VaultName,
  [Parameter(Mandatory)][string]$CertName,
  [string]$Scope,                                   # e.g., /subscriptions/<id> or /subscriptions/<id>/resourceGroups/<rg>
  [string[]]$RoleDefinitionName = @(),              # e.g., "Reader","Monitoring Reader" (least-privileged roles)
  [int]$Years = 1,                                  # cert lifetime
  [switch]$CreateIfExists                           # if app exists, add new cert & rotate (no duplicate names)
)

# --- Helper: structured output emitter (no secrets) ---
function Write-Json { param($obj) $obj | ConvertTo-Json -Depth 8 }

# --- Connect to Graph for App/SP operations (scopes documented above) ---
try {
  if (-not (Get-Module Microsoft.Graph -ListAvailable)) { Import-Module Microsoft.Graph -ErrorAction Stop }
  if (-not (Get-Module Az.Accounts -ListAvailable)) { Import-Module Az.Accounts -ErrorAction Stop }
  if (-not (Get-Module Az.KeyVault -ListAvailable)) { Import-Module Az.KeyVault -ErrorAction Stop }
} catch { Write-Error "Missing required modules. $_"; exit 1 }

try {
  if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Application.ReadWrite.All","Directory.ReadWrite.All","RoleManagement.ReadWrite.Directory" | Out-Null
  }
  if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
} catch { Write-Error "Authentication failed. $_"; exit 1 }

# --- 1) Find or create the AAD Application ---
$app = Get-MgApplication -Filter "displayName eq '$AppDisplayName'" -ConsistencyLevel eventual -CountVariable c -ErrorAction SilentlyContinue
if ($app) {
  if (-not $CreateIfExists) {
    Write-Error "Application '$AppDisplayName' already exists. Use -CreateIfExists to rotate/add a new cert."
    exit 2
  }
} else {
  if ($PSCmdlet.ShouldProcess($AppDisplayName, "Create AAD Application")) {
    $app = New-MgApplication -DisplayName $AppDisplayName
  }
}

# --- 2) Generate self-signed cert (ephemeral) ---
# NOTE: For production, consider generating in Key Vault directly with a cert policy; here we generate locally then import PFX to KV.
$cert = New-SelfSignedCertificate -Subject "CN=$AppDisplayName" `
  -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 `
  -NotAfter (Get-Date).AddYears($Years)

# Export PFX to a temp path with a random strong password (never logged)
$pfxPath = [System.IO.Path]::GetTempFileName() + ".pfx"
$pemPath = [System.IO.Path]::GetTempFileName() + ".cer"
Add-Type -AssemblyName System.Web
$pfxPass = [System.Web.Security.Membership]::GeneratePassword(32,4) | ConvertTo-SecureString -AsPlainText -Force
Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $pfxPass | Out-Null
Export-Certificate -Cert $cert -FilePath $pemPath | Out-Null

# --- 3) Import certificate into Key Vault (escrow private key) ---
if ($PSCmdlet.ShouldProcess("$VaultName/$CertName","Import PFX into Key Vault")) {
  az keyvault certificate import --vault-name $VaultName --name $CertName --file $pfxPath --password (New-Object System.Net.NetworkCredential("", $pfxPass).Password) | Out-Null
}

# --- 4) Add PUBLIC cert to App keyCredentials (used for app auth) ---
#    Use Add-MgApplicationKey with AsymmetricX509Cert (public only). Do NOT upload private key to the app.
$pubBytes = [System.IO.File]::ReadAllBytes($pemPath)
if ($PSCmdlet.ShouldProcess($AppDisplayName, "Attach public key credential")) {
  Add-MgApplicationKey -ApplicationId $app.Id -KeyCredential @{
    type = "AsymmetricX509Cert"
    usage = "Verify"
    key = $pubBytes
    displayName = "$CertName"
  } | Out-Null
}

# --- 5) Create Service Principal if missing ---
$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
if (-not $sp) {
  if ($PSCmdlet.ShouldProcess($AppDisplayName, "Create Service Principal")) {
    $sp = New-MgServicePrincipal -AppId $app.AppId
  }
}

# --- 6) Optional RBAC role assignment(s) at scope (least-privilege) ---
if ($Scope -and $RoleDefinitionName.Count -gt 0) {
  foreach ($role in $RoleDefinitionName) {
    if ($PSCmdlet.ShouldProcess("$($sp.Id)", "Assign RBAC role '$role' at $Scope")) {
      try {
        New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $role -Scope $Scope | Out-Null
      } catch {
        Write-Warning "Role assignment failed for '$role' at '$Scope': $($_.Exception.Message)"
      }
    }
  }
}

# --- Cleanup local files ---
Remove-Item $pfxPath,$pemPath -Force -ErrorAction SilentlyContinue

# --- Emit structured summary (no secrets) ---
Write-Json @{
  application = @{ id = $app.Id; appId = $app.AppId; displayName = $app.DisplayName }
  servicePrincipal = @{ id = $sp.Id; appId = $sp.AppId }
  keyVault = @{ vault = $VaultName; certificateName = $CertName }
  rolesAssigned = $RoleDefinitionName
}
