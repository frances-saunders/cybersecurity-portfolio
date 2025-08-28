# Threat Intelligence Integration for Snort

## Objectives
- Enrich Snort with up-to-date IP/domain indicators **without** plaintext secrets.
- Generate **rules dynamically** from approved feeds.
- Apply safety controls (signature validation, ETag caching, allowlists).

## Sources (examples; configure in Vault/Key Vault as needed)
- Internal MISP export (preferred)
- Organization-approved blocklists (internal)
- Sanitized public feeds (reviewed by security team)
  - IPv4 CIDRs for known botnets
  - FQDN lists of malware distribution

## Workflow
1. A scheduler (cron/systemd timer) runs `scripts/intel-updater.sh`.
2. The script:
   - Retrieves feed URLs from **environment or Key Vault**.
   - Validates source (TLS pinning optional), applies ETag/If-None-Match.
   - Applies allow/deny filters and normalizes to **Snort rule stubs**.
   - Writes to `rules/generated-ti.rules` and reloads Snort safely.

## Rule Strategy
- **DNS domain matches** → `alert udp $HOME_NET any -> $EXTERNAL_NET 53`
- **IP/CIDR matches** → reputation or simple IP match rules
- **Rate limits** to avoid alert storms (detection_filter / threshold)

## False Positive Controls
- Maintain `allowlist.txt` for business-critical domains/IPs.
- Keep hit counters in SIEM; auto-demote noisy indicators after review.

## Security
- No tokens in plaintext. Fetch from Azure Key Vault (managed identity) or HashiCorp Vault AppRole.
- Store feed hashes; reject unexpected file type/size.
