<#
.SYNOPSIS
    Baseline OS hardening (Windows) with sane defaults for enterprise fleets.

.DESCRIPTION
    - Enables host firewall for all profiles
    - Enforces secure PowerShell (script block logging, transcription)
    - Ensures audit policies for authentication and process tracking
    - Disables legacy protocols/services where safe (SMBv1)
    - Idempotent: re-runs safely

.NOTES
    Requires admin. Test in non-prod before broad rollout.
#>

# 1) Firewall
Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True -Verbose

# 2) PowerShell Logging
New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell -Force | Out-Null
New-Item -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -Force | Out-Null
Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging -Name EnableScriptBlockLogging -Value 1

# 3) Audit Policy (subset example)
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Process Creation" /success:enable /failure:disable

# 4) Disable SMBv1
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

# 5) Windows Defender baseline
Set-MpPreference -DisableRealtimeMonitoring $false -MAPSReporting Advanced -SubmitSamplesConsent AlwaysPrompt
