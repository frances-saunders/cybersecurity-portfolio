<#
Baseline OS hardening for Windows/Linux.
Includes firewall, secure services, and logging.
#>

# Enable Windows Defender
Set-MpPreference -DisableRealtimeMonitoring $false

# Configure firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Ensure logging
wevtutil set-log Security /enabled:true
