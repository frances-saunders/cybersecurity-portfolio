# CIS Benchmark Audit Checklist (Azure, Level 1/2 – Custom Coverage)

## 1) Scope & Inventory
- Subscriptions and resource groups mapped to CIS scope.
- Resource location restrictions aligned to approved regions list.

## 2) Representative CIS Sections
- 1.x: Identity & Access – MFA status, role assignments, break-glass accounts.
- 2.x: Storage – Secure transfer required; public access disabled; key rotation.
- 3.x: Compute – VM OS/Disk encryption; endpoint protection deployment status.
- 4.x: Logging & Monitoring – Diagnostic settings to Log Analytics; retention.
- 5.x: Networking – NSG baselines; public IP restrictions on NICs/VMs.

## 3) Evidence Collection (Automation-Ready)
- Compliance summaries per control; top drifting assignments.
- Drill-down on non-compliant resources with remediation notes.
- Exceptions register with business justification and expiration.

## 4) Sampling Strategy
- At least 10% sample across services; 100% for high-risk controls.
- Time-based sampling to show improvement trend.

## 5) Remediation Validation
- Before/after configuration snapshots.
- Terraform plan/apply logs for infrastructure changes.
- Re-test results reflected in dashboards.
