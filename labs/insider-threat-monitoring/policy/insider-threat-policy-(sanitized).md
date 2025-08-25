# Insider Threat & Data Protection Policy (Sanitized)

## Purpose
Establish a risk-based framework to deter, detect, and respond to insider threats while protecting privacy and complying with applicable laws and contracts.

## Scope
All workforce members, contractors, and third-party service accounts with access to organizational systems or data.

## Definitions
- **Insider Threat**: The potential for an individual with authorized access to harm the organization’s mission, resources, or personnel.
- **DLP**: Data Loss Prevention controls preventing unauthorized disclosure of sensitive data.
- **UEBA**: User & Entity Behavior Analytics that baselines normal activity and identifies anomalies.

## Roles & Responsibilities
- **CISO**: Owns policy; ensures governance, technology, and process alignment.
- **SOC**: Monitors UEBA/DLP alerts; triages and escalates incidents.
- **HR & Legal**: Participate in response where personnel actions or legal holds are required.
- **Data Owners**: Classify data and approve protection requirements.

## Controls
- **Data Classification**: Public / Internal / Confidential / Restricted. Sensitivity labels applied via automated rules.
- **DLP**: Block or quarantine exfiltration of Restricted data via email, cloud storage, or removable media. Exceptions require data owner approval.
- **UEBA**: Baseline access patterns (logon geo, download/upload volumes, privileged actions). Alert on spikes, off-hours activity, and impossible travel.
- **Access Management**: Least privilege, just-in-time access for admins, MFA enforced.
- **Monitoring & Retention**: Centralized logging to SIEM with minimum 180-day hot retention.

## Incident Response (Insider)
1. **Detect**: SIEM raises UEBA/DLP alert.
2. **Triage**: SOC validates context (HR status, recent role change, device posture).
3. **Contain**: Revoke sessions, suspend account, quarantine files (per playbooks).
4. **Eradicate/Recover**: Reset credentials, re-image device if needed.
5. **Post-Incident**: Lessons learned; update use cases and training.

## Privacy & Transparency
Monitoring is for security and compliance only. Workforce members are notified via acceptable use and privacy notices. Monitoring is proportionate and auditable.

## Enforcement
Violations may result in disciplinary action up to and including termination and referral to authorities.

*(This sanitized policy omits environment-specific names, IDs, and contacts.)*
