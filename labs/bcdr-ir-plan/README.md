# BCDR and Incident Response Plan Lab

**Lab Type:** Enterprise Architecture — Business Continuity and Disaster Recovery  
**Environment:** Azure (greenfield — no pre-existing BCDR infrastructure)  
**Author:** Frances Saunders — Cloud Security Architect  
**Frameworks:** NIST SP 800-34 Rev. 1, NIST SP 800-61 Rev. 2, ISO 27001 Annex A.17, SOC 2 Availability

---

## Overview

This lab demonstrates a full-lifecycle BCDR and Incident Response program built from zero — discovery, architecture, implementation, testing, and validated results — for a multi-workload Azure environment that had no backup policies, no disaster recovery architecture, and no formal incident response plan in place.

The program is deliberately cost-optimized rather than "vendor-recommended." Two explicit deviations from Azure defaults are documented with business risk acceptance: tiered vault redundancy (not universal GRS) and selective ASR enrollment (Tier 1 only, not all VMs). Both decisions reduce BCDR infrastructure cost by approximately 40% while maintaining documented, tested, and auditable recovery capability against defined business RTO/RPO targets.

This is not a checkbox exercise. Every artifact in this lab was built to be deployed, tested, and handed to an auditor.

---

## Problem Statement

The organization operated active production workloads in Azure with:

- No backup coverage across any resource type — VMs, SQL databases, Cosmos DB, Azure Files, Blob Storage, AKS
- No disaster recovery or failover architecture
- No incident response plan, playbooks, or defined escalation paths
- No defined RPO or RTO targets — the business had never formally quantified acceptable data loss or downtime
- Undocumented compliance gaps under SOC 2, ISO 27001, and NIST SP 800-34

Risk was existential. The absence of controls had been silently accepted without informed consent from leadership.

---

## Tools and Technologies

Azure Backup, Azure Site Recovery (ASR), Azure Recovery Services Vault, Azure Monitor, Microsoft Sentinel, Logic Apps (Azure), Terraform, PowerShell, KQL, Azure Policy, Velero (AKS backup)

---

## Directory Structure

```
labs/bcdr-ir-plan/
├── README.md                          <- This file
├── docs/
│   ├── bcdr-policy.md                 <- Governance policy (RTO/RPO definitions, testing requirements)
│   ├── options-analysis-and-architecture-decision.md  <- ADR with cost deviation rationale
│   ├── workload-classification.md     <- Authoritative tier register (all in-scope workloads)
│   ├── test-results.md                <- Backup restore, ASR failover, and tabletop exercise log
│   └── ir-playbooks/
│       ├── ransomware-encryption-event.md         <- IR-001
│       ├── accidental-bulk-deletion.md            <- IR-002
│       ├── region-outage-tier1-failover.md        <- IR-003
│       ├── credential-compromise-unauthorized-access.md  <- IR-004
│       └── post-incident-review-and-evidence-packaging.md  <- IR-005
├── kql/
│   ├── backup-job-failures.kql        <- Backup failure detection + coverage gap variant
│   ├── asr-replication-health.kql     <- Replication lag monitor + RPO breach predictor
│   ├── vault-tamper-detection.kql     <- Soft-delete disable + vault destruction precursor detection
│   ├── soft-delete-timeline.kql       <- Burn-rate query for active bulk deletion incidents
│   └── backup-coverage-gaps.kql       <- Ghost resource detector (enrolled but not protecting)
├── terraform/
│   ├── main.tf                        <- Recovery Services Vaults (per tier), backup policies, alerts
│   ├── asr-replication.tf             <- ASR fabric, containers, policies, recovery VNet + DNS zones
│   ├── azure-policy.tf                <- DeployIfNotExists, Deny, and Audit policy definitions
│   ├── outputs.tf                     <- Vault IDs, resource group names, alert action group
│   ├── variables.tf                   <- All input variables
│   └── terraform.tfvars               <- Sample values (no secrets)
└── automation/
    └── playbooks/
        ├── notify-on-backup-failure.jsonc    <- Alert -> Sentinel incident + Teams/email notify
        ├── isolate-on-ransomware.jsonc       <- Snapshot THEN isolate (critical sequencing)
        └── asr-failover-trigger.jsonc        <- Pre-validation + human approval gate (no auto-failover)
```

---

## Key Architecture Decisions

### Decision 1: Tiered Vault Redundancy (Not Universal GRS)

Azure recommends geo-redundant storage for all Recovery Services Vaults. This lab applies GRS only to Tier 1 and Tier 2 vaults. Tier 3 uses LRS.

Rationale: Tier 3 workloads have a 72-hour RTO. Regional recovery via backup restore is acceptable within that window. The marginal risk of LRS for these workloads is proportionate to their defined recovery window. Applying GRS uniformly adds approximately 40% cost without proportionate risk reduction. Full analysis in docs/options-analysis-and-architecture-decision.md.

### Decision 2: ASR Enrollment for Tier 1 Only (Not All VMs)

Azure Advisor and Microsoft documentation recommend enabling ASR for all production VMs. This lab enables ASR only for Tier 1 workloads.

Rationale: Per-VM ASR replication cost at scale exceeds the cost of accepting a longer RTO for Tier 2 and Tier 3 workloads. Both tiers have defined recovery windows (24h and 72h) achievable via backup restore. Applying ASR to every VM would have doubled the BCDR infrastructure cost without reducing risk for workloads whose business owners had accepted those recovery windows.

### Decision 3: No Fully Automated Failover

The asr-failover-trigger.jsonc playbook stops at a human approval gate before initiating any failover. A false positive Service Health alert triggering automated failover would cause unnecessary disruption and data loss equal to the replication lag. The approval adds minimal time (< 5 minutes) while preventing a category of incident that is worse than the outage itself.

---

## Deployment Order

1. Deploy Terraform — run terraform apply from labs/bcdr-ir-plan/terraform/. Deploy main.tf first, then asr-replication.tf (depends on vault resources), then azure-policy.tf.
2. Enroll workloads — assign backup policies to each in-scope resource per docs/workload-classification.md. Azure Policy DeployIfNotExists handles new resources automatically.
3. Deploy Logic App playbooks — import automation/playbooks/ via Azure portal or ARM template. Assign managed identity permissions per playbook header comments.
4. Validate coverage — run scripts/automation/backup-coverage-reporter.ps1 and kql/backup-coverage-gaps.kql. Confirm 100% enrollment before declaring the program live.
5. Execute test program — per the schedule in docs/test-results.md. Document all results including gaps found.

---

## Test Results Summary

| Test | Date | Result | RTO Achieved | RPO Achieved |
|---|---|---|---|---|
| Backup coverage audit (initial) | 2025-01-15 | Partial pass — 2 shadow workloads found | N/A | N/A |
| Backup restore — Tier 1 and Tier 2 | 2025-01-18 | Pass — all 6 workloads | 2.5h avg (target: 4h) | 52m max (target: 1h) |
| ASR test failover — all Tier 1 | 2025-01-20 | Pass with 1 gap (DNS — remediated) | Within target | Within target |
| IR tabletop — ransomware scenario | 2025-01-22 | Pass — 3 gaps found and closed | N/A | N/A |

Full results with gap analysis and remediation details: docs/test-results.md

---

## Compliance Coverage

| Control | Framework | Status |
|---|---|---|
| Backup and recovery controls | NIST SP 800-34 section 3.4, ISO 27001 A.17.1, SOC 2 CC9.1 | Implemented and tested |
| RTO/RPO definition and testing | NIST SP 800-34 section 3.3, ISO 27001 A.17.2 | Defined, tested, results documented |
| Incident response plan | NIST SP 800-61 Rev. 2, ISO 27001 A.16.1 | 5 playbooks authored and tabletop-tested |
| Evidence retention | SOC 2 CC7.3, ISO 27001 A.12.4 | Immutable storage enforced, 3-year retention |
| Policy enforcement | SOC 2 CC2.1, ISO 27001 A.18.1 | Azure Policy initiative deployed at subscription scope |

---

## Key Takeaways

This project demonstrates the ability to:

- Lead a full-lifecycle BCDR and IR program from zero with no pre-existing infrastructure
- Conduct structured options analysis that weighs cost, risk, capability, and organizational fit rather than defaulting to vendor recommendations
- Translate technical risk into executive-level language — quantifying compliance exposure and delivering governance artifacts that give leadership informed visibility into continuity posture
- Enforce compliance durably through policy-as-code, ensuring controls cannot be silently eroded by future infrastructure changes
- Validate solutions against defined targets through structured testing — and document gaps found (not just successes)

The result: a fully implemented, tested, and policy-enforced business continuity and incident response program with documented RTO/RPO attainment, regulatory compliance, and automated protection that scales with the workload.
