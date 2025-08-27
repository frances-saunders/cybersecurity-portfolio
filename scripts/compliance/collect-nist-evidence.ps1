<#
Automated collection of NIST SP 800-53 evidence from Azure.
#>

Get-AzPolicyState | Export-Csv nist-evidence.csv -NoTypeInformation
