# Case Study: BCDR and Incident Response Plan — Greenfield Cloud Environment

## Problem / Challenge

The organization operated a multi-workload Azure environment with no backup policies, no disaster recovery architecture, and no formal incident response plan in place. There were no recovery vaults, no replication configurations, no tested runbooks, and no defined RPO or RTO targets — meaning that any ransomware event, accidental deletion, region outage, or infrastructure failure would result in unrecoverable data loss and extended, unplanned downtime. Specific gaps identified during initial discovery included:

* **No backup coverage** across virtual machines, managed databases, storage accounts, or file shares — leaving all production data unprotected with zero point-in-time recovery capability.
* **No disaster recovery or failover architecture**, meaning a region-level outage or hardware fault would result in full service loss with no automated or manual path to restoration.
* **No incident response plan or playbooks**, leaving the security and operations teams without defined roles, escalation paths, communication protocols, or technical response procedures for any failure scenario.
* **No RPO or RTO definitions**, meaning the business had never formally quantified how much data loss was acceptable or how long a service could be offline — creating both a compliance gap and an organizational risk that leadership was unaware of.
* **Undocumented compliance exposure** under SOC 2, ISO 27001, and NIST SP 800-34, all of which require demonstrable business continuity and incident response controls that were entirely absent.

This was not a gap in a secondary environment — these were live production workloads serving active users. The risk was existential, and the absence of any controls meant it had been silently accepted without informed consent from leadership.

---

## Tools & Technologies

Azure Backup, Azure Site Recovery (ASR), Azure Recovery Services Vault, Azure Monitor, Microsoft Sentinel, Logic Apps, Terraform, PowerShell, KQL, Azure Policy

---

## Actions Taken

### Phase 1 — Discovery and Gap Analysis

I conducted a full inventory of the Azure environment to establish a BCDR baseline:

* Enumerated all resource types across subscriptions — virtual machines, SQL databases, Cosmos DB, Azure Files, Blob Storage, App Services, and AKS workloads — and classified each by criticality and data sensitivity.
* Documented the complete absence of Recovery Services Vaults, backup policies, replication configurations, and IR runbooks across all subscriptions.
* Interviewed stakeholders across engineering, operations, and finance to elicit implicit RPO/RTO expectations that had never been formally documented — translating business language into quantifiable recovery targets per workload tier.
* Mapped regulatory obligations (SOC 2 Availability, ISO 27001 Annex A.17, NIST SP 800-34) to identify the specific control gaps that constituted compliance violations, and estimated the audit risk exposure if left unaddressed.
* Produced a structured gap report with a tiered risk matrix — distinguishing between workloads that required near-zero RPO and those where a 24-hour recovery window was acceptable — which formed the foundation for the options analysis.

### Phase 2 — Options Analysis and Architecture Decision

Rather than defaulting to Azure-native recommendations, I conducted a structured evaluation of every credible option across five dimensions: recovery capability, cost, operational complexity, vendor lock-in, and organizational fit. Options evaluated included:

* **Azure Backup + Recovery Services Vault (native)** — Lowest operational overhead, deep Azure integration, policy-driven automation, and familiar tooling for the team. Costs are usage-based and predictable. Trade-off: limited flexibility for cross-cloud or hybrid workloads.
* **Azure Site Recovery (ASR)** — Purpose-built for VM-level replication and orchestrated failover. Supports failover to a secondary Azure region and failback. Trade-off: per-VM replication costs accumulate at scale; requires careful network pre-staging in the target region.
* **Third-party solutions (Veeam, Zerto, Commvault)** — Richer feature sets including application-consistent replication, cross-cloud portability, and granular restore options. Trade-off: significantly higher licensing cost, additional operational surface, and onboarding time the team did not have.
* **Snapshot-only approach** — Low cost, fast restore for compute. Evaluated and explicitly rejected as a primary mechanism: snapshots are not backup — they live in the same failure domain, are not geo-redundant, and do not satisfy any compliance framework requirement.
* **Cold storage archive + manual restore** — Evaluated for non-critical, high-volume data tiers (e.g., audit logs, telemetry archives). Accepted as a cost-optimization layer, not as a primary recovery mechanism.
* **Cross-region paired replication with active-passive architecture** — Evaluated for Tier 1 workloads. Selected for a subset of critical databases and App Services where the cost of downtime exceeded the cost of maintaining a warm standby.

The final recommendation deliberately deviated from the Azure-suggested defaults in two ways: first, I rejected the recommended geo-redundant vault configuration for lower-tier workloads in favor of locally redundant storage with a defined manual escalation path — reducing cost by approximately 40% for non-critical tiers without materially increasing risk given their recovery windows. Second, I recommended against enabling ASR for all VMs, instead selecting only Tier 1 workloads for active replication and using policy-enforced daily backups with 90-day retention for Tier 2 and Tier 3 — a tiered architecture that balanced cost, recovery capability, and operational complexity against actual business risk rather than applying a uniform expensive solution to every workload.

### Phase 3 — BCDR Architecture Design

I designed a tiered BCDR architecture aligned to workload criticality:

* **Tier 1 (Mission-Critical)** — RTO ≤ 4 hours, RPO ≤ 1 hour. Azure Site Recovery with cross-region replication to a paired region, application-consistent snapshots every 60 minutes, automated failover with pre-staged network configuration (VNet, NSGs, private DNS) in the recovery region, and a Sentinel-integrated alert that triggers the IR playbook on replication health degradation.
* **Tier 2 (Business-Important)** — RTO ≤ 24 hours, RPO ≤ 4 hours. Azure Backup with geo-redundant vault, daily policy-enforced backups with 30-day instant restore and 90-day long-term retention, and soft-delete enabled to protect against ransomware-driven backup deletion.
* **Tier 3 (Operational/Non-Critical)** — RTO ≤ 72 hours, RPO ≤ 24 hours. Azure Backup with locally redundant vault, daily backups, 30-day retention, and archive-tier offload after 30 days to minimize storage cost.
* **IR Plan** — Formalized playbooks covering five scenarios: ransomware/encryption event, accidental bulk deletion, region outage, credential compromise and unauthorized access, and application-layer data corruption. Each playbook defines detection triggers (Sentinel analytics rules), immediate containment steps, recovery sequence, evidence preservation requirements, stakeholder notification templates, and post-incident review obligations.

### Phase 4 — Implementation

I deployed the entire BCDR infrastructure as code using Terraform and enforced compliance through Azure Policy:

* Provisioned Recovery Services Vaults per tier with correct redundancy, soft-delete, and immutability settings.
* Authored and assigned Azure Backup policies for VMs, Azure SQL, Cosmos DB, Azure Files, and Blob Storage — parameterized by tier and aligned to defined RPO targets.
* Configured ASR replication for all Tier 1 VMs including network mapping, recovery plan ordering, and pre/post-failover automation scripts.
* Deployed Azure Policy definitions to enforce backup enrollment — any new resource of a covered type without a backup policy assignment triggers a Deny or DeployIfNotExists effect, preventing the gap from recurring.
* Integrated backup health alerts and replication status monitors into Azure Monitor and Sentinel, with Logic App playbooks for automated notification and triage ticket creation on backup job failure or replication lag.
* Authored the full IR plan document and distributed to stakeholders, including runbooks embedded in the lab as executable artifacts.

### Phase 5 — Testing and Validation

I conducted a structured test program to validate recovery capability against defined targets:

* Executed VM restore tests for Tier 1 and Tier 2 workloads, measuring actual RTO against targets and documenting any gaps.
* Performed an ASR test failover to the paired region for all Tier 1 workloads — validated application health, DNS resolution, and network connectivity post-failover without impacting production.
* Ran a simulated ransomware response tabletop exercise with engineering and operations leads, walking through the playbook step by step and capturing timing, gaps, and decision bottlenecks.
* Validated soft-delete protection by attempting to delete a backup vault with active items — confirming the 14-day retention window and immutability settings blocked permanent deletion.
* Verified backup policy compliance coverage using an automated script that queries all covered resource types and reports unprotected resources — confirming 100% enrollment across in-scope workloads.

---

## Results / Impact

* Achieved **100% backup coverage** across all in-scope production workloads — eliminating a total absence of data protection from a live environment serving active users.
* Delivered **validated RTO/RPO attainment** for Tier 1 workloads: 2.5-hour average RTO against a 4-hour target, and sub-60-minute RPO confirmed through ASR replication lag monitoring.
* Reduced BCDR infrastructure cost by approximately **40% against the Azure-recommended default configuration** by applying tiered redundancy aligned to business risk rather than uniform geo-redundancy across all workloads.
* Closed **all material BCDR-related compliance gaps** under SOC 2 Availability, ISO 27001 Annex A.17, and NIST SP 800-34 — converting previously undocumented audit risk into documented, testable, and evidenced controls.
* Delivered a **fully automated compliance enforcement posture** via Azure Policy — ensuring that new workloads cannot be deployed without backup enrollment, eliminating the operational risk of future coverage gaps.
* Produced an **executive-ready BCDR policy document and IR plan** that defined RTO/RPO commitments, escalation paths, communication obligations, and recovery ownership — giving leadership informed visibility into continuity posture for the first time.

## Artifacts

### Terraform Infrastructure

* Recovery Services Vault definitions (per tier, with redundancy and immutability settings)
* Azure Backup policy definitions for VMs, SQL, Cosmos DB, Azure Files, and Blob Storage
* ASR replication configuration and recovery plan for Tier 1 workloads
* Azure Monitor alert rules and Logic App notification playbooks

### Azure Policy

* DeployIfNotExists policy for backup enrollment enforcement (VM, SQL, Storage)
* Deny policy blocking vault soft-delete disablement and immutability removal
* Compliance initiative bundling all BCDR enforcement controls

### IR Playbooks

* Ransomware / encryption event response playbook
* Accidental bulk deletion response and recovery playbook
* Region outage failover runbook (Tier 1)
* Credential compromise and unauthorized access playbook
* Post-incident review and evidence packaging runbook

### Scripts

* Backup coverage compliance reporter (PowerShell / Python)
* ASR replication health and lag monitor
* Automated backup restore tester with RTO measurement
* Audit evidence packager for SOC 2 / ISO 27001 readiness

### Documentation

* BCDR Policy and Standards document (executive distribution)
* Tiered workload classification and RPO/RTO register
* Options analysis and architecture decision record
* Test results and validation report

## Key Takeaways

This project highlights my ability to:

* Lead a full-lifecycle BCDR and IR program from zero — discovery, design, implementation, and validated testing — with no pre-existing infrastructure or documentation to build from.
* Conduct structured options analysis that weighs cost, risk, capability, and organizational fit rather than defaulting to vendor recommendations or industry boilerplate.
* Translate technical risk into executive-level language — quantifying compliance exposure, defining RPO/RTO in business terms, and delivering a governance artifact that gave leadership informed visibility into continuity posture for the first time.
* Enforce compliance durably through policy-as-code, ensuring that the controls implemented cannot be silently eroded by future infrastructure changes.
* Validate solutions against defined targets through structured testing — demonstrating that BCDR capability was not just deployed, but proven.

The end result was a fully implemented, tested, and policy-enforced business continuity and incident response program — transforming an environment with zero recovery capability into one with documented RTO/RPO attainment, regulatory compliance, and automated protection that scales with the workload.
