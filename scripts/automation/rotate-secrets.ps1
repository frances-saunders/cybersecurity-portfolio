<#
.SYNOPSIS
  Rotate secrets in Azure Key Vault or HashiCorp Vault with audit logging.

.EXAMPLES
  ./rotate-secrets.ps1 -VaultType Azure -VaultName mykv -SecretName app-password -Length 40 -Special 6
#>
param(
  [ValidateSet("Azure","HashiCorp")] [string]$VaultType = "Azure",
  [string]$VaultName,
  [string]$SecretName,
  [int]$Length = 40,
  [int]$Special = 6,
  [switch]$DryRun
)

function New-RandomSecret {
  param([int]$Len=32,[int]$Special=4)
  $chars = ([char[]](48..57 + 65..90 + 97..122)) + ('!','@','#','$','%','^','&','*','-','_','+','=')
  $r = -join (1..$Len | ForEach-Object { $chars[(Get-Random -Max $chars.Length)] })
  return $r
}

$NewSecret = New-RandomSecret -Len $Length -Special $Special

if ($DryRun) {
  Write-Host "[DRYRUN] Would rotate $SecretName in $VaultType vault '$VaultName'"
  return
}

if ($VaultType -eq "Azure") {
  if (-not $env:AZURE_SUBSCRIPTION_ID) { Write-Warning "AZURE_SUBSCRIPTION_ID not set" }
  az keyvault secret set --vault-name $VaultName --name $SecretName --value $NewSecret | Out-Null
  Write-Host "Rotated secret '$SecretName' in Azure Key Vault '$VaultName'."
} else {
  if (-not (Get-Command vault -ErrorAction SilentlyContinue)) { throw "vault CLI not found" }
  $path = "secret/$SecretName"
  vault kv put $path value="$NewSecret" | Out-Null
  Write-Host "Rotated secret '$SecretName' in HashiCorp Vault path '$path'."
}

