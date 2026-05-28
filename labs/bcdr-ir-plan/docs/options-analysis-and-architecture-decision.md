# BCDR Options Analysis and Architecture Decision Record

**Date:** [Date of analysis]
**Author:** Frances Saunders — Cloud Security Architect
**Status:** Approved and implemented

---

## Context

The organization's Azure environment had no backup, disaster recovery, or incident response infrastructure in place. This document records the structured evaluation of all credible options, the reasoning behind each decision, and the deliberate deviations from vendor-recommended defaults.

---

## Evaluation Criteria

Options were scored against five dimensions: recovery capability (RTO/RPO attainment), cost, operational complexity, vendor lock-in risk, and organizational fit (team maturity, existing tooling familiarity).

---

## Options Evaluated

### Option 1 — Azure Backup + Recovery Services Vault (Native)

**Recovery capability:** High for VM, SQL, Files, Blob. Policy-driven, application-consistent snapshots. Cross-region restore available with GRS vaults.
**Cost:** Usage-based and predictable. LRS vaults approximately 40% cheaper than GRS for equivalent workload coverage.
**Operational complexity:** Low. Native integration, familiar tooling, no additional licensing.
**Vendor lock-in:** Medium. Azure-specific but portable via export if needed.
**Organizational fit:** High. Team already operates in Azure; no onboarding cost.

**Assessment:** Selected as the primary mechanism for Tier 2 and Tier 3 workloads.

### Option 2 — Azure Site Recovery (ASR)

**Recovery capability:** Highest available for VM workloads. Continuous replication, automated failover, recovery plans with dependency ordering.
**Cost:** Per-VM replication cost. Viable for a targeted subset; prohibitively expensive if applied universally.
**Operational complexity:** Medium. Requires pre-staged network configuration (VNet, NSG, private DNS) in recovery region.
**Vendor lock-in:** Medium-high.
**Organizational fit:** High for Tier 1 only.

**Assessment:** Selected for Tier 1 workloads only. Explicitly not applied uniformly — see Decision 2 below.

### Option 3 — Third-Party (Veeam, Zerto, Commvault)

**Recovery capability:** Richer feature set including application-consistent cross-cloud replication, granular object-level restore, and built-in orchestration.
**Cost:** High. Licensing cost plus operational overhead. Estimated 3–5x the cost of Azure-native solution for equivalent coverage.
**Operational complexity:** High. Requires separate deployment, maintenance, and skill set.
**Vendor lock-in:** Lower (cross-cloud portability).
**Organizational fit:** Low. Team has no existing experience; onboarding time not available.

**Assessment:** Evaluated and rejected for this engagement. Noted as a future consideration if multi-cloud DR requirements emerge.

### Option 4 — Snapshot-Only Approach

**Recovery capability:** Low. Snapshots reside in the same failure domain as the source resource. Not geo-redundant. Not application-consistent for databases. Does not satisfy any compliance framework requirement.
**Cost:** Low.

**Assessment:** Explicitly rejected as a primary backup mechanism. Snapshots are not backup. This option was evaluated because it was implicitly in use (as the default state) and needed to be formally retired.

### Option 5 — Cold Storage Archive + Manual Restore

**Recovery capability:** Low for primary recovery; appropriate for non-critical, high-volume data with long recovery windows.
**Cost:** Very low (archive tier pricing).

**Assessment:** Accepted as a cost-optimization layer for Tier 3 data beyond 30-day retention. Not a primary recovery mechanism.

---

## Architecture Decisions

### Decision 1 — Reject uniform GRS for all vaults

**Default recommendation:** Azure recommends geo-redundant storage for all Recovery Services Vaults.
**Decision:** Apply GRS only to Tier 1 and Tier 2 vaults. Use LRS for Tier 3.
**Rationale:** Tier 3 workloads have a 72-hour RTO and tolerate regional recovery via backup restore. The marginal risk of LRS for these workloads is acceptable given their defined recovery window and the approximate 40% cost reduction. Applying GRS uniformly would have added cost without proportionate risk reduction.
**Risk accepted by:** [Approver name and date]

### Decision 2 — Reject universal ASR replication

**Default recommendation:** Microsoft documentation and Azure Advisor recommend enabling ASR for all production VMs.
**Decision:** Enable ASR only for Tier 1 workloads.
**Rationale:** Per-VM ASR replication cost at scale exceeds the cost of accepting a longer RTO for Tier 2 and Tier 3 workloads, which have defined recovery windows (24h and 72h respectively) that are achievable via backup restore. Applying ASR to every VM would have doubled the BCDR infrastructure cost without reducing risk for workloads whose business owners had accepted 24-hour recovery windows.
**Risk accepted by:** [Approver name and date]

---

## Cost Comparison Summary

| Configuration | Estimated Monthly Cost | Notes |
|--------------|----------------------|-------|
| Azure-recommended (GRS + ASR for all) | [Baseline] | All vaults GRS, all VMs in ASR |
| Selected architecture | ~40% below baseline | Tiered redundancy, ASR for Tier 1 only |
| Third-party (Veeam/Zerto) | ~300–500% above baseline | Licensing + ops overhead |

> Cost estimates are environment-specific. Replace with actual Azure cost calculator outputs.
