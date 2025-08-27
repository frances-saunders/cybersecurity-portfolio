<#
.SYNOPSIS
    Configures HashiCorp Vault (dev/test or external) and seeds secrets.

.DESCRIPTION
    - Enables KV v2 at secret/
    - Creates initial secrets from an input JSON file
    - Never writes secret values to console

.PARAMETER SeedFile
    Path to JSON: {"db":{"password":"..."}}

.EXAMPLE
    .\vault_setup.ps1 -SeedFile .\seed.json
#>
[CmdletBinding()]
param(
    [string]$Address = "http://127.0.0.1:8200",
    [Parameter(Mandatory)][string]$Token,
    [string]$SeedFile
)

$env:VAULT_ADDR = $Address
$env:VAULT_TOKEN = $Token

vault secrets enable -path=secret kv-v2 2>$null | Out-Null

if ($SeedFile) {
    $json = Get-Content $SeedFile -Raw | ConvertFrom-Json
    $json.PSObject.Properties | ForEach-Object {
        $path = "secret/$($_.Name)"
        $payload = $_.Value | ConvertTo-Json -Depth 6
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $tmp = [System.IO.Path]::GetTempFileName()
        [System.IO.File]::WriteAllBytes($tmp, $bytes)
        try {
            vault kv put $path @"$tmp" | Out-Null
        } finally {
            Remove-Item $tmp -Force
        }
    }
}

Write-Output "Vault initialized and secrets seeded."
