# Tuning Analysis

## Summary
After initial deployment with strict rules, false positives (FPs) clustered around:
- Legitimate SSH management bursts from CI/CD workers
- Developers' load test traffic triggering SQLi heuristics
- Long subdomain labels from telemetry services

## Actions
1. **SSH Brute Force**  
   - Added `detection_filter` threshold from 10→20 in 60s for known CI/CD ranges.  
   - Excluded bastion CIDR via `EXCLUDED_NET` variable, revised HOME_NET.

2. **SQL Injection**
   - Anchored URI patterns and required presence in specific paths (`/search.php`, `/login`, `/api/*`) via `http_uri` content + `within`.
   - Added body-based PCRE to minimize matches on parameter names.

3. **DNS Exfil**
   - Raised label length threshold from 45→50 bytes; added allowlist for observability vendors.

## Metrics
- FP reduction: **~42%** week-over-week
- True positive (TP) retention: **>95%**
- Mean time to confirm (SOC runbook): **12 minutes → 6 minutes** post SIEM correlation

## Next Steps
- Integrate JA3-/TLS FP heuristics in Suricata companion ruleset (Snort 2.x lacks native JA3).
- SOC feedback loop every sprint; demote noisy indicators automatically via SIEM job.
