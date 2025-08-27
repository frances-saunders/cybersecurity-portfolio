<#
Enrich incidents with WHOIS and GeoIP context.
#>

param(
    [string]$IPAddress = "8.8.8.8"
)

# Example WHOIS lookup
Invoke-RestMethod "https://whois.example.com/$IPAddress"
