# Defender for Cloud Security Baseline in Azure

## Problem / Challenge

Microsoft Defender for Cloud provides threat detection, vulnerability management, and compliance visibility for Azure environments. However, organizations often leave it partially configured or inconsistent across subscriptions.
During internal reviews, the following gaps were identified:

* No centralized security contact details, delaying incident response.
* Auto-provisioning of security agents not consistently enabled.
* Defender plans not uniformly deployed across resource types.
* Lack of standardized Log Analytics integration for visibility and auditing.

The challenge was to design and enforce a **Defender for Cloud baseline** that ensured consistent, automated, and auditable security coverage across all enterprise subscriptions.

---

## Tools & Technologies
Azure Policy, Microsoft Defender for Cloud, Log Analytics, Terraform, PowerShell

---

## Actions Taken

### Broad Policy Authoring (Defender for Cloud Baseline)

Created Azure JSONC policy definitions that enforced:

* **Security contacts** – required security email and phone for each subscription.
* **Auto-provisioning** – ensured agents were automatically deployed for VMs and PaaS resources.
* **Defender plans** – enforced enabling of Defender for App Services, Storage, SQL, and Kubernetes.
* **Log Analytics integration** – required Defender data to flow into a centralized workspace for analysis and retention.

These controls were aligned with CIS Azure Foundations Benchmark and NIST SP 800-53.

### Initiative (Policy Set)

Grouped these policies into the **Defender for Cloud Security Baseline initiative** with:

* Centralized parameters for contacts and workspace IDs.
* Metadata mapped to CIS and NIST standards.
* Modular structure for enabling resource-specific Defender plans.

### Assignment Across Subscriptions

Applied the initiative at subscription scope:

* Deny mode for critical gaps (e.g., missing security contact).
* Audit mode for phased rollout of workspace integration.
* Scoped exclusions for sandbox environments.

### Automation & Integration

* Embedded initiative assignment into Terraform for automated provisioning.
* Integrated policies with Microsoft Defender for Cloud compliance dashboards.
* Ensured version control and peer review through Git-based workflows.

---

## Results / Impact

* Standardized Defender for Cloud configuration across all subscriptions.
* Reduced mean time to detection and incident response through enforced security contact details.
* Increased enterprise compliance score by closing Defender coverage gaps.
* Improved visibility with centralized Log Analytics integration.
* Established a repeatable, automated security baseline for Defender.

---

## Artifacts

While this portfolio only demonstrates **Defender for Cloud–specific policies** for brevity, the actual project included broader enterprise governance artifacts.

**Policy Definitions (Defender Examples)**

* Require Security Contact Email and Phone
* Enforce Auto-Provisioning of Defender Agents
* Require Defender Plans for Core Services
* Integrate with Log Analytics Workspace

**Initiative (Defender Example)**

* Defender for Cloud Security Baseline Initiative

**Assignment (Defender Example)**

* Defender for Cloud Security Baseline Assignment

---

## Key Takeaways

This project demonstrates my ability to secure enterprise environments by leveraging **Azure Policy and Defender for Cloud together**. While only Defender-specific policies are shown here, the full implementation enforced over 100 policies across networking, IAM, and compliance.

The initiative delivered:

* Uniform Defender coverage across subscriptions.
* Compliance alignment with CIS and NIST.
* Automated, auditable, and repeatable deployment via Terraform.
* Faster detection and response readiness through enforced security contact details.

This established a **repeatable Defender baseline model**, embedding cloud-native security controls directly into day-to-day operations.

