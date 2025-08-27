<#
.SYNOPSIS
  Configure GitHub Actions OIDC federated credentials for Azure (no long-lived secrets).

.DESCRIPTION
  - Creates (or updates) an Azure AD App Registration + Service Principal.
  - Adds a Federated Identity Credential (FIC) that allows GitHub Actions OIDC to get an AAD token.
  - Supports scoping the credential to a specific GitHub org/repo and (optionally) branch/environment.
  - Optionally assigns least-privileged RBAC at a supplied scope.
  - Output is structured JSON; no secrets are created or stored.

.REQUIREMENTS
  - Microsoft.Graph PowerShell (Applications, ServicePrincipals)
  - Az.Accounts for RBAC assignment
  - AAD permissions: Application.ReadWrite.All, Directory.ReadWrite.All

.EXAMPLE
  .\github-oidc-azure-setup.ps1 `
      -AppDisplayName "contoso-gha" `
      -GithubOrg "contoso" -GithubRepo "infra" -SubjectFilter "ref:refs/heads/main" `
      -Audience "api://AzureADTokenExchange" `
      -Scope "/subscriptions/<subId>/resourceGroups/rg-ci" `
      -RoleDefinitionName @("Reader","Storage Blob Data Reader")
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
  [Parameter(Mandatory)][string]$AppDisplayName,
  [Parameter(Mandatory)][string]$GithubOrg,
  [Parameter(Mandatory)][string]$GithubRepo,
  [string]$SubjectFilter = "ref:refs/heads/main",  # limit to main branch
  [string]$Audience = "api://AzureADTokenExchange",
  [string]$Scope,                                   # e.g., /subscriptions/..../resourceGroups/rg
  [string[]]$RoleDefinitionName = @()
)

function Write-Json { param($o) $o | ConvertTo-Json -Depth 8 }

try {
  if (-not (Get-Module Microsoft.Graph -ListAvailable)) { Import-Module Microsoft.Graph -ErrorAction Stop }
  if (-not (Get-Module Az.Accounts -ListAvailable)) { Import-Module Az.Accounts -ErrorAction Stop }
  if (-not (Get-MgContext)) { Connect-MgGraph -Scopes "Application.ReadWrite.All","Directory.ReadWrite.All" | Out-Null }
  if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
} catch { Write-Error "Authentication/modules failed: $($_.Exception.Message)"; exit 1 }

# 1) App + SP
$app = Get-MgApplication -Filter "displayName eq '$AppDisplayName'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
if (-not $app) {
  if ($PSCmdlet.ShouldProcess($AppDisplayName,"Create AAD application")) {
    $app = New-MgApplication -DisplayName $AppDisplayName
  }
}
$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -ConsistencyLevel eventual -ErrorAction SilentlyContinue
if (-not $sp) {
  if ($PSCmdlet.ShouldProcess($AppDisplayName,"Create Service Principal")) {
    $sp = New-MgServicePrincipal -AppId $app.AppId
  }
}

# 2) Federated Identity Credential (FIC)
$issuer   = "https://token.actions.githubusercontent.com"
$subject  = "repo:$GithubOrg/$GithubRepo:$SubjectFilter"
$ficBody = @{
  Name        = "github-oidc-$($GithubOrg)-$($GithubRepo)"
  Issuer      = $issuer
  Subject     = $subject
  Description = "GitHub Actions OIDC: $GithubOrg/$GithubRepo"
  Audiences   = @($Audience)
}

# Remove any existing matching FIC to avoid duplicates
$existing = (Invoke-MgGraphRequest -Method GET -Uri "/applications/$($app.Id)/federatedIdentityCredentials").Value
$match = $existing | Where-Object { $_.Issuer -eq $issuer -and $_.Subject -eq $subject }
if ($match) {
  if ($PSCmdlet.ShouldProcess($match.Id,"Delete existing federated credential (replace)")) {
    Invoke-MgGraphRequest -Method DELETE -Uri "/applications/$($app.Id)/federatedIdentityCredentials/$($match.Id)" | Out-Null
  }
}

if ($PSCmdlet.ShouldProcess($AppDisplayName,"Create federated identity credential")) {
  Invoke-MgGraphRequest -Method POST -Uri "/applications/$($app.Id)/federatedIdentityCredentials" -Body ($ficBody | ConvertTo-Json) -ContentType "application/json" | Out-Null
}

# 3) Optional RBAC
$assigned = @()
if ($Scope -and $RoleDefinitionName.Count -gt 0) {
  foreach ($role in $RoleDefinitionName) {
    if ($PSCmdlet.ShouldProcess($sp.Id,"Assign role '$role' at $Scope")) {
      try {
        New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName $role -Scope $Scope | Out-Null
        $assigned += $role
      } catch { Write-Warning "RBAC assignment failed for $role: $($_.Exception.Message)" }
    }
  }
}

Write-Json @{
  application        = @{ id=$app.Id; appId=$app.AppId; displayName=$app.DisplayName }
  servicePrincipal   = @{ id=$sp.Id }
  github             = @{ org=$GithubOrg; repo=$GithubRepo; subject=$subject; issuer=$issuer; audience=$Audience }
  rbac               = @{ scope=$Scope; roles=$assigned }
}
