# NIST 800-53 Audit Checklist (Custom Baseline)

## 1) Pre-Audit Preparation
- Inventory of in-scope subscriptions and resource groups is current.
- Policy assignment scopes validated against enterprise scoping matrix.
- Evidence retention window meets AU-11 and AU-9; log immutability controls documented.
- Control inheritance documented (shared responsibility matrix).

## 2) Control Families (Representative Samples)
### AC – Access Control
- AC-2: User account lifecycle evidence (creation, approval, deprovision).
- AC-3/AC-4: Network segmentation and egress filtering; deny public IP on VMs evidence.
- AC-6: Privileged access approvals; Just-In-Time elevation logs.

### AU – Audit and Accountability
- AU-2/AU-12: Diagnostic settings to Log Analytics enforced; sampling across services.
- AU-6: Alert triage and incident linkage; ticket references and timelines.

### CM – Configuration Management
- CM-2/CM-6: Baseline definitions; policy definitions and drift reports.
- CM-8: Tagging standards (“owner”, “environment”); exceptions register.

### SC – System & Communications Protection
- SC-7: Network boundary protections; NSGs and private access validations.
- SC-8: Secure transfer required on storage accounts (sampling results).
- SC-28: Encryption at rest; VM disk encryption and key management evidence.

## 3) Evidence Artifacts
- Terraform state and plan outputs for control provenance.
- Policy definitions, initiatives, and assignment JSON exports.
- Workbook screenshots and CSV exports of compliance summaries.
- Change management records for exceptions and waivers.

## 4) Interviews & Walkthroughs
- Control owners: Access, Logging, Vulnerability Management, Cloud Engineering.
- Demonstrate automated pipeline from non-compliance -> ticket -> remediation.
- Review exception lifecycle and risk acceptance approvals.

## 5) Findings & CAP (Corrective Action Plan)
- Rank by risk (High/Med/Low).
- Owner, due date, remediation steps; verification method and re-test date.
