# BCDR Test Results and Validation Log

**Classification:** Internal — Security Operations  
**Owner:** Cloud Security Architecture  
**Retention:** Minimum 3 years (per BCDR Policy §5)  
**Reference:** [BCDR Policy](./bcdr-policy.md) §5 — Testing Requirements

---

## Purpose

This document is the authoritative log of all BCDR test activities. Every backup restore test, ASR test failover, IR tabletop exercise, and backup coverage audit must produce an entry here. Results are retained for a minimum of three years to satisfy SOC 2 Availability, ISO 27001 A.17.2, and NIST SP 800-34 evidence requirements.

A result that surfaces a gap — and shows how the gap was closed — is more valuable as a compliance artifact than a result that shows no issues. All failures, deviations, and remediations are documented fully.

---

## Testing Schedule

| Test Type | Frequency | Scope | Next Due |
|---|---|---|---|
| Backup restore test | Quarterly | Tier 1 and Tier 2 | 2025-04-15 |
| ASR test failover | Semi-annual | All Tier 1 workloads | 2025-07-15 |
| IR tabletop exercise | Annual | All five IR scenarios | 2026-01-15 |
| Backup coverage audit | Monthly | All in-scope workloads | 2025-02-15 |

---

## Cycle 1 — January 2025 (Initial Validation)

### 1.1 Backup Coverage Audit — 2025-01-15

**Conducted by:** Cloud Security Architect  
**Tool:** `scripts/automation/backup-coverage-reporter.ps1` + `kql/backup-coverage-gaps.kql`  
**Scope:** All 20 in-scope workloads per `docs/workload-classification.md`

**Result:** PARTIAL PASS

| Finding | Detail |
|---|---|
| Protected resources (enrolled and healthy) | 18 of 20 |
| Unprotected resources | 2 (shadow workloads — see Section 4 of workload-classification.md) |
| Ghost resources detected | 1 — `legacy-vm-batch-proc` had a policy assignment but the backup agent reported no successful job in 48 hours |
| Resources with stale last-success (>25h) | 1 — `legacy-vm-batch-proc` |

**Root cause:** `legacy-vm-batch-proc` was discovered as a shadow workload. The Azure Policy `DeployIfNotExists` had triggered and created the enrollment, but the backup extension failed to install silently — the VM was running an OS version (Windows Server 2012 R2) that requires the legacy MARS agent, not the IaaS extension. Extension deployment succeeded without error but the agent was non-functional.

**Remediation:** MARS agent manually installed and validated. Backup job ran successfully 2025-01-16. Ghost-resource detection logic in `backup-coverage-reporter.ps1` confirmed this case and added it to the report — demonstrating the value of checking active job success, not just policy assignment status.

**Closure date:** 2025-01-16  
**Closed by:** Cloud Security Architect

---

### 1.2 Backup Restore Test — Tier 1 and Tier 2 — 2025-01-18

**Conducted by:** Cloud Security Architect + Platform Engineering  
**Tool:** `scripts/automation/restore-rto-tester.ps1`  
**Scope:** 2 Tier 1 VMs, 1 Tier 1 SQL Database, 2 Tier 2 VMs, 1 Tier 2 Storage Account  
**Recovery point used:** Most recent application-consistent snapshot prior to test window

| Workload | Tier | RTO Target | Actual RTO | RPO Target | Actual RPO | Result |
|---|---|---|---|---|---|---|
| prod-api-vm-01 | 1 | 4h | 2h 22m | 1h | 47m | PASS |
| prod-api-vm-02 | 1 | 4h | 2h 31m | 1h | 52m | PASS |
| prod-sqldb-orders | 1 | 4h | 1h 58m | 1h | 38m | PASS |
| staging-api-vm-01 | 2 | 24h | 3h 15m | 4h | 1h 22m | PASS |
| prod-vm-jumpbox | 2 | 24h | 2h 44m | 4h | 1h 08m | PASS |
| prod-storage-uploads | 2 | 24h | 1h 02m | 4h | 0h 51m | PASS |

**Observations:**
- All workloads met or exceeded RTO and RPO targets on first attempt.
- `prod-api-vm-02` took 9 minutes longer than `prod-api-vm-01` due to a larger OS disk. No action required.
- Instant restore was used for all VM restores (within the 5-day instant restore retention window), which accounts for the sub-3-hour RTOs well within the 4-hour target.

**Result:** PASS — all 6 workloads  
**Evidence artifact:** `restore-rto-tester` JSON output archived to immutable evidence storage container `bcdr-evidence-[date]`

---

### 1.3 ASR Test Failover — Tier 1 Workloads — 2025-01-20

**Conducted by:** Cloud Security Architect + Platform Engineering + Network Engineering  
**Scope:** All 6 ASR-enrolled Tier 1 workloads (prod-api-vm-01, prod-api-vm-02, prod-sqldb-orders, prod-sqldb-customers, prod-cosmos-transactions, prod-aks-cluster stateful nodes)  
**Recovery region:** westus2  
**Test type:** Non-disruptive test failover (production replication uninterrupted)

| Workload | Replication Lag at Test Start | Failover Initiated | VM/App Healthy in Recovery Region | DNS Validated | Network Connectivity | Result |
|---|---|---|---|---|---|---|
| prod-api-vm-01 | 4m | 10:02 | 10:41 | Yes | Yes | PASS |
| prod-api-vm-02 | 6m | 10:02 | 10:49 | Yes | Yes | PASS |
| prod-sqldb-orders | N/A (geo-replication) | N/A | Verified via secondary replica | Yes | Yes | PASS |
| prod-sqldb-customers | N/A (geo-replication) | N/A | Verified via secondary replica | Yes | Yes | PASS |
| prod-cosmos-transactions | N/A (multi-region write) | N/A | Verified via westus2 region endpoint | Yes | Yes | PASS |
| prod-aks-cluster | 11m | 10:05 | 11:22 | Yes | Yes | **SEE NOTE** |

**Note — prod-aks-cluster:** Application pods started successfully in the recovery region, but the cluster's internal DNS resolution for the `prod-sqldb-orders` private endpoint failed for approximately 18 minutes post-failover. Root cause: the private DNS zone for `privatelink.database.windows.net` was not linked to the recovery VNet. This was a gap in the ASR recovery plan network pre-staging.

**Remediation:** Private DNS zone link added to `terraform/asr-replication.tf` (deployed 2025-01-21). Recovery plan updated to include a DNS validation step as a pre-failover automation script. Re-tested in isolation on 2025-01-22 — DNS resolution confirmed healthy within 2 minutes of failover.

**Overall result:** PASS with one gap identified and closed. This is the expected output of a rigorous test — gaps found in a controlled test are far less costly than gaps discovered during an actual region outage.

**Closure date:** 2025-01-22  
**Closed by:** Cloud Security Architect

---

### 1.4 IR Tabletop Exercise — Ransomware Scenario — 2025-01-22

**Conducted by:** Cloud Security Architect (facilitator)  
**Participants:** Engineering Lead, Platform Engineering, Security Operations, Finance stakeholder  
**Scenario:** Ransomware encryption event — attacker has encrypted data on prod-api-vm-01 and prod-api-vm-02, and has attempted to delete backup vault contents using a compromised service principal  
**Playbook:** `docs/ir-playbooks/ransomware-encryption-event.md`

**Exercise timeline:**

| Time (simulated) | Action | Decision/Gap |
|---|---|---|
| T+0:00 | Sentinel alert fires — anomalous file encryption activity on prod-api-vm-01 | Playbook trigger confirmed |
| T+0:08 | On-call analyst acknowledges alert and initiates playbook | 8-minute acknowledge time — within 15-minute target |
| T+0:12 | Analyst attempts to isolate VM — confirms NIC detach procedure | **Gap:** Analyst was unfamiliar with NIC detach procedure; had to reference documentation. Decision: Add a pre-built Azure CLI command block to the playbook |
| T+0:18 | On-demand snapshot initiated on both VMs before isolation | Correct sequence — snapshot before isolation confirmed |
| T+0:22 | Backup canary validation initiated — checks backup hash against out-of-band store | **Gap:** Canary storage account read-only access was not pre-granted to the on-call analyst role; required escalation to Cloud Security Architect. Decision: Add canary read access to the on-call RBAC role |
| T+0:45 | Vault tamper attempt simulated — analyst identifies soft-delete prevented deletion | Immutability and soft-delete controls confirmed functional |
| T+1:10 | Recovery sequence initiated from last clean snapshot | Recovery within Tier 1 RTO |
| T+1:35 | Stakeholder notification drafted | **Gap:** No pre-written notification template for Finance stakeholder — analyst had to draft from scratch under simulated time pressure |

**Remediations from exercise:**
1. CLI command block added to ransomware playbook containment section (done 2025-01-23)
2. Canary read access added to on-call analyst role via `terraform/azure-policy.tf` RBAC module (done 2025-01-23)
3. Stakeholder notification templates added to all five IR playbooks (done 2025-01-24)

**Result:** PASS with 3 process gaps identified and remediated. No gaps remain open.  
**Closure date:** 2025-01-24

---

## Cycle 2 — April 2025 (Quarterly Backup Restore)

> Scheduled: 2025-04-15. Results to be documented here following test execution.

---

## Retention and Evidence Archiving

All test results are archived to the immutable evidence storage account (`bcdr-evidence`) using `scripts/dfir/bcdr-evidence-packager.sh`. Each archive includes:

- The raw output JSON from `restore-rto-tester.ps1`
- The coverage report from `backup-coverage-reporter.ps1`
- ASR replication health snapshots from `kql/asr-replication-health.kql`
- This document (versioned via Git commit hash)
- SHA-256 integrity manifest for all artifacts

Archives are retained for a minimum of 3 years and are protected by immutability policy (delete locked).
