# Business Continuity and Disaster Recovery Policy

**Classification:** Internal — Security Operations
**Owner:** Cloud Security Architecture
**Review Cycle:** Annual or following any material infrastructure change
**Frameworks:** NIST SP 800-34 Rev. 1, ISO 27001 Annex A.17, SOC 2 Availability

---

## Purpose

This policy establishes the minimum requirements for business continuity, disaster recovery, and data protection across all cloud workloads operated by the organization. It defines workload criticality tiers, recovery objectives, backup standards, testing obligations, and incident response ownership — ensuring that recovery capability is consistent, auditable, and proportionate to business risk.

---

## Scope

This policy applies to all cloud-hosted workloads, data stores, and services managed within the organization's Azure environment, including virtual machines, managed databases, storage accounts, application services, and Kubernetes workloads. Third-party and hybrid workloads are subject to equivalent requirements as defined in applicable vendor agreements.

---

## Workload Criticality Tiers

| Tier | Definition | RTO Target | RPO Target | Backup Frequency | Vault Redundancy |
|------|-----------|------------|------------|-----------------|-----------------|
| Tier 1 | Mission-critical: loss causes direct revenue impact, safety risk, or regulatory violation | ≤ 4 hours | ≤ 1 hour | Hourly (application-consistent) | GRS + immutability |
| Tier 2 | Business-important: loss causes significant operational disruption | ≤ 24 hours | ≤ 4 hours | Daily | GRS + soft-delete |
| Tier 3 | Operational/non-critical: loss causes minor or recoverable disruption | ≤ 72 hours | ≤ 24 hours | Daily | LRS + soft-delete |

Workload tier assignments are documented and maintained in `docs/workload-classification.md`. Tier assignments require annual review and must be updated within 30 days of any material change to a workload's criticality or data classification.

---

## Backup Standards

All in-scope workloads must be enrolled in an approved Azure Backup policy aligned to their tier before entering production. Backup enrollment is enforced via Azure Policy (DeployIfNotExists) — workloads without backup coverage will be flagged in the compliance dashboard and escalated to the resource owner within 24 hours.

Recovery Services Vaults must be configured with:
- Soft-delete enabled with a minimum 14-day retention window.
- Immutability enabled (Locked) for Tier 1 vaults.
- Diagnostic settings forwarded to the central Log Analytics Workspace.
- Alert rules configured for backup job failures and vault tampering attempts.

---

## Disaster Recovery Standards

All Tier 1 workloads must be enrolled in Azure Site Recovery replication to the designated paired region. Replication health must be monitored continuously via the `kql/asr-replication-health.kql` query. Recovery plans must be documented, tested, and maintained for all Tier 1 workloads.

Tier 2 and Tier 3 workloads rely on backup-based recovery. Recovery procedures must be documented in the relevant IR playbook.

---

## Testing Requirements

| Test Type | Frequency | Scope | Documented? |
|-----------|-----------|-------|-------------|
| Backup restore test | Quarterly | Tier 1 and Tier 2 | Required |
| ASR test failover | Semi-annual | All Tier 1 workloads | Required |
| IR tabletop exercise | Annual | All five IR scenarios | Required |
| Backup coverage audit | Monthly | All in-scope workloads | Required |

Test results must be documented in `docs/test-results.md` and retained for a minimum of three years.

---

## Incident Response

Incident response playbooks are maintained in `automation/playbooks/` for five failure scenarios:

- Ransomware / encryption event
- Accidental bulk deletion
- Region outage (Tier 1 failover)
- Credential compromise and unauthorized access
- Post-incident review and evidence packaging

Each playbook defines: detection trigger, immediate containment steps, recovery sequence, evidence preservation requirements, stakeholder notification obligations, and post-incident review timeline.

---

## Policy Exceptions

Exceptions to this policy require written approval from the Cloud Security Architect and must document the compensating controls in place, the business justification, and a remediation timeline. Exceptions are reviewed quarterly.

---

## Compliance Mapping

| Requirement | Framework Reference |
|-------------|-------------------|
| Backup and recovery controls | NIST SP 800-34 §3.4, ISO 27001 A.17.1, SOC 2 CC9.1 |
| RTO/RPO definition and testing | NIST SP 800-34 §3.3, ISO 27001 A.17.2 |
| Incident response plan | NIST SP 800-61 Rev. 2, ISO 27001 A.16.1 |
| Evidence retention | SOC 2 CC7.3, ISO 27001 A.12.4 |
