# Microsoft Defender for Cloud Security Baseline

## Problem / Challenge

The enterprise Azure environment had inconsistent Defender for Cloud coverage across subscriptions. Security contacts were missing in some subscriptions, Defender plans were only partially enabled, and auto-provisioning of agents was not standardized.
During security audits, the following recurring issues were identified:

* Lack of centralized security contact information, delaying incident escalation.
* Gaps in Defender plan coverage across VMs, Storage, App Services, and Kubernetes.
* Inconsistent auto-provisioning of security agents.
* No standardized integration with Log Analytics, leading to fragmented visibility.

The challenge was to enforce a **Defender for Cloud baseline** that guaranteed consistent configuration, automated provisioning, and auditable compliance across all subscriptions.

---

## Role & Tools

**Role:** Cloud Admin / Security Lead (solo project)  
**Tools & Technologies:** Azure Policy, Microsoft Defender for Cloud, Terraform, PowerShell

---

## Actions Taken

### Broad Policy Authoring (Defender Baseline)

Designed and implemented Azure JSONC policies to enforce:

* Required **security contact email and phone** per subscription.
* Auto-provisioning of Defender agents across compute and PaaS resources.
* Standardized **Defender plan enablement** for SQL, Storage, App Services, and AKS.
* Integration of Defender data into a centralized Log Analytics workspace.

These policies were mapped to **CIS Azure Foundations Benchmark** and **NIST SP 800-53** controls.

### Initiative (Policy Set) for Compliance

Grouped individual policies into the **Defender for Cloud Security Baseline initiative**:

* Centralized parameters for contacts and workspace IDs.
* Metadata mapped controls to CIS and NIST standards.
* Created modular structure for selective plan enforcement.

### Assignments Across Subscriptions

Applied the initiative assignment at subscription scope:

* **Deny** for critical controls like missing contacts.
* **Audit** for phased rollout of Log Analytics integration.
* Scoped exclusions for sandbox and test subscriptions.

### Automation & DevSecOps Integration

* Embedded initiative assignment into Terraform for automated provisioning.
* Integrated policies into Git workflows for version control and peer review.
* Surfaced compliance status directly in Defender for Cloud dashboards.

---

## Results / Impact

* Achieved consistent Defender configuration across all subscriptions.
* Improved incident response readiness through enforced security contacts.
* Closed Defender plan gaps, improving compliance scores.
* Enhanced visibility with centralized Log Analytics integration.
* Reduced audit preparation effort by standardizing Defender deployment.

---

## Artifacts (Defender Example Only)

While this portfolio only demonstrates **Defender for Cloud–specific policies** for brevity and NDA compliance, the actual project included additional governance and compliance artifacts.

**Policy Definitions (Defender Examples)**

* Require Security Contact Email and Phone
* Enforce Auto-Provisioning of Agents
* Require Defender Plans for Core Services
* Integrate Defender with Log Analytics Workspace

**Initiative (Defender Example)**

* Defender for Cloud Security Baseline Initiative

**Assignment (Defender Example)**

* Defender for Cloud Security Baseline Assignment

---

## Key Takeaways

This project demonstrates my ability to standardize **Defender for Cloud coverage through Azure Policy-as-Code**. While only Defender-specific artifacts are shown here, the complete implementation enforced policies across networking, IAM, and compliance as well.

Key results included:

* Uniform Defender configuration across subscriptions.
* Compliance alignment with CIS and NIST.
* Automated and auditable provisioning via Terraform.
* Faster response readiness with standardized contact details and agent deployment.

This initiative established a **repeatable Defender for Cloud baseline model** that embedded native Azure security into enterprise operations.
