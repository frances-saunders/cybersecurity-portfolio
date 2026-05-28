# IR Playbook: Post-Incident Review and Evidence Packaging

**Classification:** Internal — Security Operations
**Playbook ID:** IR-005 | **Version:** 1.0
**Owner:** Cloud Security Architecture
**Frameworks:** NIST SP 800-61 Rev. 2, ISO 27001 A.16.1.6, SOC 2 CC7.3

---

## Purpose

Every incident that activates any BCDR or IR playbook (IR-001 through IR-004) requires a post-incident review. This playbook defines the standard process for conducting that review, documenting findings, preserving evidence with chain of custody, and implementing remediations. It is not optional — it is the mechanism by which the BCDR program learns and improves.

---

## Timeline Requirements

| Activity | Deadline | Owner |
|---|---|---|
| Post-incident report skeleton submitted | Within 24 hours of resolution | Incident Commander |
| Post-incident review meeting held | Within 5 business days of resolution | Incident Commander (facilitator) |
| Remediation items assigned and tracked | Within 5 business days of review | Incident Commander |
| Evidence package finalized and archived | Within 7 days of resolution | Evidence Lead |
| Playbook updates applied | Within 30 days of resolution | Cloud Security Architect |
| Regulatory notification (if required) | Per applicable regulation | Incident Commander + Legal |

---

## Phase 1: Evidence Collection and Packaging

Evidence must be collected BEFORE the environment is restored to normal and BEFORE any cleanup actions are taken. The Evidence Lead owns this phase.

### Step 1.1 — Run the Evidence Packager

```bash
scripts/dfir/bcdr-evidence-packager.sh   --incident-id <INCIDENT_ID>   --affected-resources "<RESOURCE_LIST>"   --lookback-hours 72
```

The packager collects and archives:
- Sentinel incident timeline and all associated alerts and bookmarks
- Azure Activity Log export for all affected resource groups (72-hour window)
- Sign-in logs for all affected and potentially affected identities
- Backup job logs from the Recovery Services Vault (AddonAzureBackupJobs table)
- ASR replication health logs (if applicable)
- Point-in-time export of vault protected item state and soft-delete status
- SHA-256 hash manifest for all artifacts (chain of custody)

### Step 1.2 — Verify Evidence Package Integrity

```bash
# Verify the hash manifest
sha256sum -c evidence-<INCIDENT_ID>/manifest.sha256
echo "Exit code: $?"
```

Exit code 0 = all files match the manifest. Any non-zero exit code must be investigated before the package is submitted for retention.

### Step 1.3 — Upload to Immutable Evidence Storage

```bash
az storage blob upload-batch   --source evidence-<INCIDENT_ID>/   --destination bcdr-evidence   --account-name <EVIDENCE_STORAGE_ACCOUNT>   --destination-path "incidents/<INCIDENT_ID>"
```

The evidence storage account is configured with immutability policy (delete locked, 3-year retention). Once uploaded, files cannot be deleted or modified by any identity, including Owner-level accounts.

---

## Phase 2: Post-Incident Review Meeting

### Attendees (Required)

- Incident Commander (facilitator)
- All role holders who participated in the incident response
- Engineering Lead
- Relevant business stakeholder (if data or service impact occurred)

### Agenda

The review must cover each of the following in order:

**1. Timeline reconstruction (30 minutes)**
Walk through the incident timeline from first detection signal to resolution. Use the Sentinel incident timeline and Activity Log export as the authoritative source. Identify any gaps between the first observable signal and the time the playbook was activated.

**2. What went well (15 minutes)**
Explicitly identify what worked — detection was fast, a specific step in the playbook was well-written, coordination was smooth. These should be reinforced, not overlooked.

**3. What did not go well (30 minutes)**
Identify every gap, delay, unclear step, missing permission, or process failure. Be specific. "Communication was slow" is not actionable. "The on-call analyst did not have read access to the canary storage account, causing a 17-minute delay at Step 1.3" is actionable.

**4. Contributing factors (15 minutes)**
Identify root causes, not symptoms. Use the Five Whys technique for each gap: ask "why did this happen?" at least five times before declaring a root cause.

**5. Remediation items (30 minutes)**
For each gap, assign:
- A specific remediation action (not "improve communication" — "add a CLI command block to the playbook at Step 1.2")
- A DRI (directly responsible individual)
- A due date (all items default to 30 days unless otherwise agreed)

---

## Phase 3: Post-Incident Report

The Incident Commander drafts the report. It must contain all of the following sections. It is not optional to omit any section.

### Required Sections

**Executive Summary (1 page maximum)**
- Incident ID, date, and duration
- One-sentence description of what happened
- Business impact: what services were affected, for how long, and what data (if any) was at risk
- Recovery outcome: was RTO/RPO met? If not, by how much?

**Technical Timeline**
- Full chronological timeline from first signal to resolution, with timestamps
- Each step labeled with which playbook phase it corresponds to
- Any deviations from the playbook documented with reason

**Impact Assessment**
- Data affected: type, volume, classification
- Services affected: names, tier, duration of impact
- Recovery points used: which backup or ASR recovery point was restored, and what is the actual RPO gap
- Regulatory exposure: does this incident trigger any notification obligations?

**Root Cause Analysis**
- Immediate cause (what directly caused the incident)
- Contributing factors (what conditions allowed the immediate cause to occur)
- Systemic factors (what about the environment, process, or architecture made this possible)

**Remediation Register**

| Item | Action | DRI | Due Date | Status |
|---|---|---|---|---|
| [Item 1] | [Specific action] | [Name] | [Date] | Open |

**Control Validation**
- Confirm that backup soft-delete and vault immutability are intact post-incident
- Confirm that all affected workloads are back under active backup policy coverage
- Confirm that ASR replication is healthy (if applicable)

---

## Phase 4: Remediation Tracking

All remediation items from the post-incident review are tracked in this document until closed. Closure requires:

1. Evidence that the action was taken (Terraform PR merged, policy deployed, playbook updated, access granted)
2. Verification that the action is effective (re-test or peer review)
3. Sign-off from the Incident Commander

Remediations that affect the BCDR policy, workload classification register, or any IR playbook must be applied to those documents within the 30-day window and committed to the repository.

---

## Phase 5: Lessons Learned Integration

After all remediations are closed:

1. Update the relevant IR playbook with any step corrections, new command blocks, or clarifications.
2. Update docs/test-results.md with the incident entry and the gaps it revealed.
3. If the incident exposed a coverage gap (unprotected workload, missing alert, silent failure), update docs/workload-classification.md.
4. If the incident revealed that an RTO or RPO target was unrealistic, escalate to the Cloud Security Architect for a policy review.
5. Add a synthetic test case to the next tabletop exercise that specifically tests the gap that was found.

---

## Compliance Mapping

| Requirement | Framework Reference |
|---|---|
| Post-incident review requirement | NIST SP 800-61 Rev. 2 section 3.4, ISO 27001 A.16.1.6 |
| Evidence retention (minimum 3 years) | SOC 2 CC7.3, ISO 27001 A.12.4 |
| Chain of custody | NIST SP 800-61 Rev. 2, ISO 27001 A.16.1.7 |
| Regulatory notification obligations | GDPR Article 33, applicable sector regulations |
