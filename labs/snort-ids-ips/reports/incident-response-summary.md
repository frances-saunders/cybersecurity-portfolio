# Incident Response Summary – Snort Detections → SIEM

## Executive Summary
Snort detected multiple brute force attempts and C2-like web beacons over a 24-hour period. Alerts were ingested into Splunk and Microsoft Sentinel, enabling correlation with endpoint telemetry. No confirmed compromise; mitigations applied.

## Timeline (UTC)
- 2025-08-17 02:11: SSH brute force threshold exceeded (src 203.0.113.45 → bastion)
- 2025-08-17 02:14: Auto block applied (IPS inline drop, firewall rule added)
- 2025-08-17 09:28: HTTP `gate.php` beacon with suspicious UA (dev workstation)
- 2025-08-17 09:35: EDR shows no persistence; user downloaded testing tool; case closed as FP after education

## Containment & Eradication
- Inline drop maintained for SSH storming IPs.
- Web proxy policy updated to block suspicious UA from dev subnets.

## Lessons Learned
- Developer tooling mimicked commodity malware UA; added awareness banner.
- Bastion moved behind VPN; public RDP disabled; SSH keys enforced.

## Artifacts
- Snort alerts → `Snort_CL` table (Sentinel) & `index=ids` (Splunk)
- Wireshark verification captures checked into `simulations/`
