<#
.SYNOPSIS
    Rotates a secret in Azure Key Vault and optionally notifies a webhook.

.DESCRIPTION
    - Generates a strong secret (customizable)
    - Writes to Key Vault (versioned)
    - Supports WhatIf and Confirm impact
    - Emits structured console output (CI friendly)

.EXAMPLE
    .\rotate-secrets.ps1 -VaultName corp-kv -SecretName app-password -Length 48 -NotifyWebhook https://hooks/...

.NOTES
    Requires: Az.Accounts, Az.KeyVault modules; Azure login with rights to set secrets.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory)] [string]$VaultName,
    [Parameter(Mandatory)] [string]$SecretName,
    [ValidateRange(16,128)] [int]$Length = 32,
    [int]$NonAlphanumericChars = 4,
    [string]$NotifyWebhook
)

function New-StrongSecret {
    param([int]$L, [int]$N)
    Add-Type -AssemblyName System.Web
    [System.Web.Security.Membership]::GeneratePassword($L, $N)
}

try {
    Write-Verbose "Fetching current secret metadata..."
    $current = az keyvault secret show --vault-name $VaultName --name $SecretName 2>$null | ConvertFrom-Json

    $newSecret = New-StrongSecret -L $Length -N $NonAlphanumericChars

    if ($PSCmdlet.ShouldProcess("$VaultName/$SecretName","Rotate secret")) {
        az keyvault secret set --vault-name $VaultName --name $SecretName --value $newSecret | Out-Null
        Write-Output (@{
            action="rotate-secret"; vault=$VaultName; name=$SecretName; status="rotated";
            timestamp=(Get-Date).ToString("o")
        } | ConvertTo-Json)

        if ($NotifyWebhook) {
            try {
                Invoke-RestMethod -Method Post -Uri $NotifyWebhook -Body (@{secret=$SecretName; vault=$VaultName; status="rotated"}|ConvertTo-Json) -ContentType 'application/json' | Out-Null
            } catch {
                Write-Warning "Webhook notify failed: $($_.Exception.Message)"
            }
        }
    }
}
catch {
    Write-Error "Rotation failed: $($_.Exception.Message)"
    exit 1
}
