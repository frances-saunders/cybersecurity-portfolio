# Workload Classification Register

**Classification:** Internal — Security Operations  
**Owner:** Cloud Security Architecture  
**Review Cycle:** Annual or within 30 days of any material workload change  
**Last Reviewed:** 2025-01-15  
**Reference:** [BCDR Policy](./bcdr-policy.md) §3 — Workload Criticality Tiers

---

## Purpose

This register is the authoritative source of tier assignments for all in-scope workloads. It drives vault selection, backup policy assignment, ASR enrollment decisions, and IR playbook routing. Every workload in this register must have a backup policy assigned before entering production.

Tier definitions and RTO/RPO targets are defined in the BCDR Policy. This register records the *applied* classification per workload — not the definition.

---

## How to Use This Register

- **New workloads:** Classify before go-live. Submit tier assignment for review via the change management process. Policy enforcement (DeployIfNotExists) will flag unprotected resources within 24 hours.
- **Tier changes:** Require written approval from Cloud Security Architect. Update this register within 30 days of the triggering change.
- **Shadow workloads:** Resources discovered during environment scans that were not in the CMDB at discovery time. Listed in Section 3. All shadow workloads must be classified within 14 days of discovery.

---

## Section 1 — Tier 1: Mission-Critical Workloads

> RTO ≤ 4 hours | RPO ≤ 1 hour | Backup: Hourly application-consistent | Vault: GRS + Immutability (Locked) | ASR: Required

| Workload Name | Resource Type | Resource Group | Vault Name | Backup Policy | ASR Enabled | Data Classification | Business Owner | Tier Assigned | Last Reviewed |
|---|---|---|---|---|---|---|---|---|---|
| prod-api-vm-01 | Virtual Machine | rg-prod-api | bcdr-vault-tier1 | bcdr-vm-policy-tier1 | Yes | Confidential | Engineering Lead | Tier 1 | 2025-01-15 |
| prod-api-vm-02 | Virtual Machine | rg-prod-api | bcdr-vault-tier1 | bcdr-vm-policy-tier1 | Yes | Confidential | Engineering Lead | Tier 1 | 2025-01-15 |
| prod-sqldb-orders | Azure SQL Database | rg-prod-data | bcdr-vault-tier1 | bcdr-sql-policy-tier1 | Yes (via geo-replication) | Restricted | Data Engineering | Tier 1 | 2025-01-15 |
| prod-sqldb-customers | Azure SQL Database | rg-prod-data | bcdr-vault-tier1 | bcdr-sql-policy-tier1 | Yes (via geo-replication) | Restricted | Data Engineering | Tier 1 | 2025-01-15 |
| prod-cosmos-transactions | Cosmos DB Account | rg-prod-data | bcdr-vault-tier1 | bcdr-cosmos-policy-tier1 | Yes | Restricted | Data Engineering | Tier 1 | 2025-01-15 |
| prod-aks-cluster | AKS Cluster | rg-prod-aks | bcdr-vault-tier1 | bcdr-aks-velero-tier1 | Yes (stateful workloads) | Confidential | Platform Engineering | Tier 1 | 2025-01-15 |
| prod-keyvault-primary | Azure Key Vault | rg-prod-secrets | N/A (soft-delete + purge protection enforced natively) | N/A | N/A | Restricted | Security Ops | Tier 1 | 2025-01-15 |

**Tier 1 count:** 7 workloads

---

## Section 2 — Tier 2: Business-Important Workloads

> RTO ≤ 24 hours | RPO ≤ 4 hours | Backup: Daily | Vault: GRS + Soft-delete | ASR: Not required

| Workload Name | Resource Type | Resource Group | Vault Name | Backup Policy | ASR Enabled | Data Classification | Business Owner | Tier Assigned | Last Reviewed |
|---|---|---|---|---|---|---|---|---|---|
| staging-api-vm-01 | Virtual Machine | rg-staging | bcdr-vault-tier2 | bcdr-vm-policy-tier2 | No | Internal | Engineering Lead | Tier 2 | 2025-01-15 |
| prod-appservice-portal | App Service | rg-prod-web | bcdr-vault-tier2 | bcdr-appservice-policy-tier2 | No | Internal | Product | Tier 2 | 2025-01-15 |
| prod-sqldb-analytics | Azure SQL Database | rg-prod-data | bcdr-vault-tier2 | bcdr-sql-policy-tier2 | No | Internal | Data Engineering | Tier 2 | 2025-01-15 |
| prod-storage-uploads | Storage Account (Blob) | rg-prod-storage | bcdr-vault-tier2 | bcdr-blob-policy-tier2 | No | Confidential | Product | Tier 2 | 2025-01-15 |
| prod-storage-fileshare | Azure Files | rg-prod-storage | bcdr-vault-tier2 | bcdr-files-policy-tier2 | No | Internal | Operations | Tier 2 | 2025-01-15 |
| prod-vm-jumpbox | Virtual Machine | rg-prod-infra | bcdr-vault-tier2 | bcdr-vm-policy-tier2 | No | Confidential | Security Ops | Tier 2 | 2025-01-15 |

**Tier 2 count:** 6 workloads

---

## Section 3 — Tier 3: Operational / Non-Critical Workloads

> RTO ≤ 72 hours | RPO ≤ 24 hours | Backup: Daily | Vault: LRS + Soft-delete | ASR: Not required

| Workload Name | Resource Type | Resource Group | Vault Name | Backup Policy | ASR Enabled | Data Classification | Business Owner | Tier Assigned | Last Reviewed |
|---|---|---|---|---|---|---|---|---|---|
| dev-vm-01 | Virtual Machine | rg-dev | bcdr-vault-tier3 | bcdr-vm-policy-tier3 | No | Internal | Engineering Lead | Tier 3 | 2025-01-15 |
| dev-vm-02 | Virtual Machine | rg-dev | bcdr-vault-tier3 | bcdr-vm-policy-tier3 | No | Internal | Engineering Lead | Tier 3 | 2025-01-15 |
| prod-storage-telemetry | Storage Account (Blob) | rg-prod-logs | bcdr-vault-tier3 | bcdr-blob-policy-tier3 | No | Internal | Platform Engineering | Tier 3 | 2025-01-15 |
| prod-storage-audit-logs | Storage Account (Blob) | rg-prod-logs | bcdr-vault-tier3 | bcdr-blob-policy-tier3 | No | Internal | Security Ops | Tier 3 | 2025-01-15 |
| test-appservice-sandbox | App Service | rg-test | bcdr-vault-tier3 | bcdr-appservice-policy-tier3 | No | Internal | QA | Tier 3 | 2025-01-15 |

**Tier 3 count:** 5 workloads

---

## Section 4 — Shadow Workloads

> Resources discovered during environment scanning that were absent from the CMDB at time of discovery. All must be classified within 14 days of the discovery date.

Shadow workloads are identified by the `backup-coverage-reporter.ps1` script and the `kql/backup-coverage-gaps.kql` query, which cross-reference tagged in-scope resources against active backup job coverage and flag any resource with a `bcdr-tier` tag but no successful backup job in the last 25 hours.

| Workload Name | Resource Type | Resource Group | Discovery Date | Discovered By | Assigned Tier | Classification Status | Notes |
|---|---|---|---|---|---|---|---|
| legacy-vm-batch-proc | Virtual Machine | rg-legacy | 2025-01-10 | backup-coverage-reporter.ps1 | Tier 2 (pending approval) | In review | Found running without backup enrollment; predates BCDR program. Owner identified as Finance team. |
| orphaned-storage-acct | Storage Account | rg-prod-data | 2025-01-10 | backup-coverage-reporter.ps1 | Tier 3 (pending approval) | In review | No resource tags, no owner tag. Contains what appears to be archived report data. Escalated to Data Engineering for ownership confirmation. |

**Action required:** Both shadow workloads must be formally classified and enrolled before 2025-01-24.

---

## Section 5 — Out-of-Scope Workloads

> Workloads explicitly excluded from BCDR coverage with documented justification.

| Workload Name | Resource Type | Resource Group | Exclusion Justification | Approved By | Approval Date | Review Date |
|---|---|---|---|---|---|---|
| ci-runner-ephemeral-01 | Virtual Machine | rg-cicd | Ephemeral CI runner; stateless, no persistent data, rebuilt from pipeline on every run. Loss has zero data impact. | Cloud Security Architect | 2025-01-15 | 2026-01-15 |
| dev-cosmos-scratch | Cosmos DB Account | rg-dev | Developer scratch database; contains no production data. Rebuilt from seed scripts on demand. | Cloud Security Architect | 2025-01-15 | 2026-01-15 |

---

## Section 6 — Coverage Summary

| Tier | Workload Count | Backup Enrolled | ASR Enrolled | Coverage % |
|---|---|---|---|---|
| Tier 1 | 7 | 7 | 6 (Key Vault native) | 100% |
| Tier 2 | 6 | 6 | N/A | 100% |
| Tier 3 | 5 | 5 | N/A | 100% |
| Shadow (pending) | 2 | 0 | N/A | 0% — in remediation |
| **Total in-scope** | **20** | **18** | — | **90% (100% excluding shadow)** |

Coverage is validated monthly using `scripts/automation/backup-coverage-reporter.ps1` and the `kql/backup-coverage-gaps.kql` detection query. Results are logged in `docs/test-results.md`.

---

## Change Log

| Date | Change | Approved By |
|---|---|---|
| 2025-01-15 | Initial register created; all workloads classified from greenfield discovery | Cloud Security Architect |
| 2025-01-10 | Shadow workloads discovered and added to Section 4 pending classification | Cloud Security Architect |
