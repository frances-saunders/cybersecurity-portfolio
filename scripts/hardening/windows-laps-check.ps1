<#
.SYNOPSIS
  Verifies Windows LAPS (modern, built-in) configuration: password policy, backup target, auditing.

.DESCRIPTION
  - Reads LAPS policy from registry (HKLM\SOFTWARE\Policies\Microsoft\LAPS)
  - Checks: BackupDirectory (AD/Local/None), PasswordLength, Complexity, AgeDays, PostAuthActions, Auditing
  - Emits a PASS/FAIL summary and a JSON detail object for ingestion

.NOTES
  Requires admin. Test keys may vary by OS build; adjust if your environment uses legacy LAPS (AdmPwd GPO).
#>

$RegPath = "HKLM:\SOFTWARE\Policies\Microsoft\LAPS"
$result = @{
  present = $false
  checks = @{}
}

if (Test-Path $RegPath) {
  $result.present = $true
  $props = Get-ItemProperty -Path $RegPath
  $result.checks.BackupDirectory   = $props.BackupDirectory   # 1=AD, 2=Local, 0=None
  $result.checks.PasswordLength    = $props.PasswordLength
  $result.checks.PasswordAgeDays   = $props.PasswordAgeDays
  $result.checks.PasswordComplexity= $props.PasswordComplexity # 1=Alphanumeric + symbols recommended
  $result.checks.PostAuthenticationActions = $props.PostAuthenticationActions
} else {
  Write-Output "LAPS policy not found."
}

# Basic policy validation (adjust thresholds to your standard)
$fail = 0
function Check { param($name,$cond) if ($cond) { Write-Output "[PASS] $name" } else { Write-Output "[FAIL] $name"; $global:fail++ } }

if ($result.present) {
  Check "BackupDirectory configured (not None)" ($result.checks.BackupDirectory -in 1,2)
  Check "PasswordLength >= 16" ($result.checks.PasswordLength -ge 16)
  Check "PasswordAgeDays <= 30" ($result.checks.PasswordAgeDays -le 30)
  Check "PasswordComplexity set (>=1)" ($result.checks.PasswordComplexity -ge 1)
  # Optional: confirm event logging (LAPS operational channel enabled)
  $log = wevtutil el | Select-String -Pattern "Microsoft-Windows-LAPS/Operational"
  Check "Event logging channel present" ($null -ne $log)
}

Write-Output "Failures: $fail"
$result | ConvertTo-Json -Depth 6
exit $fail
