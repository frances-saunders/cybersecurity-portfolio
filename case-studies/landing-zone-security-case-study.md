# Landing Zone Baseline in Azure

## Problem / Challenge

The organization’s Azure environment lacked a standardized landing zone framework, which resulted in:

* Inconsistent resource naming across subscriptions.
* Missing or incomplete tags, leading to poor cost allocation and visibility.
* Developers deploying unapproved VM SKUs and services.
* Workloads provisioned in non-compliant Azure regions.
* Manual landing zone builds that drifted quickly from compliance requirements.

The challenge was to design and implement a **governance baseline** that enforced **naming, tagging, region, and SKU controls** across landing zones in a repeatable, automated, and auditable way.

---

## Tools & Technologies
Azure Policy, Terraform, Azure CLI, Microsoft Defender for Cloud

---

## Actions Taken

### Broad Policy Authoring (Landing Zone Governance Baseline)

Designed and implemented Azure JSONC policy definitions for:

* **Naming conventions** – enforced regex-based standards across all resource types.
* **Required tagging** – enforced `Owner`, `Environment`, and `CostCenter` tags.
* **SKU restrictions** – blocked creation of non-approved VM SKUs.
* **Region restrictions** – limited deployments to approved Azure regions.

These policies aligned with CIS Azure Benchmarks, ISO 27001, and NIST SP 800-53.

### Initiative (Landing Zone Baseline Policy Set)

Grouped individual policies into a **Landing Zone Baseline initiative**.

* Centralized parameters for consistent naming regex, tag values, allowed regions, and approved SKUs.
* Metadata mapped controls to CIS, ISO 27001, and NIST standards.
* Created modular bundles so policies could be assigned as a full baseline or by control area.

### Assignments at Scope (Terraform Deployment)

Applied the **Landing Zone Baseline initiative assignment** at subscription and management group levels.

* Used `Deny` for critical violations (e.g., unapproved SKUs).
* Allowed `Audit` mode for phased rollout of naming and tagging enforcement.
* Scoped exclusions for specific dev/test environments.
* Automated assignments directly in Terraform workflows.

### Infrastructure as Code (Terraform)

Automated landing zone provisioning and baseline enforcement using Terraform.

* `main.tf`, `variables.tf`, `outputs.tf`, and `terraform.tfvars` deployed compliant landing zones.
* Integrated initiative assignments into Terraform to ensure every new landing zone was baseline-enforced.
* Enabled repeatable, consistent deployments without manual policy application.

### Visibility & Reporting

* Linked policy assignments to Microsoft Defender for Cloud for posture scoring.
* Built Azure dashboards showing compliance by subscription, focusing on naming/tagging gaps and SKU violations.
* Partnered with Finance to ensure enforced tagging directly supported cost reporting and chargeback models.

---

## Results / Impact

* Implemented a **repeatable landing zone governance baseline** enforced by policy.
* Standardized naming and tagging across 100+ subscriptions.
* Prevented non-compliant VM SKUs and deployments in unapproved regions.
* Reduced audit preparation time by 60% through automated policy enforcement.
* Improved cost transparency by ensuring complete and accurate tagging.

---

## Artifacts (Baseline Examples Only)

While this portfolio only demonstrates naming, tagging, SKU, and region policies for brevity and NDA compliance, the actual project included dozens of additional governance and compliance controls.

**Policy Definitions (Baseline Examples)**

* Enforce Naming Conventions
* Require Resource Tags
* Restrict Allowed VM SKUs
* Restrict Allowed Regions

**Initiative (Baseline Example)**

* Landing Zone Baseline Initiative

**Assignment (Baseline Example)**

* Landing Zone Baseline Assignment (Terraform)

**Terraform**

* IaC for landing zone provisioning and initiative assignment

---

## Key Takeaways

This project demonstrates my ability to implement **enterprise landing zone governance** with Azure Policy and Terraform. While the portfolio shows representative artifacts, the full implementation enforced 100+ controls across identity, compliance, and cost governance, resulting in:

* Consistent landing zone deployments across subscriptions.
* Audit-ready environments aligned with CIS, ISO 27001, and NIST.
* Automated and scalable enforcement of naming, tagging, SKU, and region standards.
* Seamless integration into Terraform for **automation-first governance**.

This initiative established a **repeatable landing zone baseline model** that eliminated drift, streamlined audits, and aligned compliance with financial accountability across the enterprise.
