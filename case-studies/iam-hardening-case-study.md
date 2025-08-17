# IAM Hardening in Azure

## Problem / Challenge

Identity and Access Management (IAM) misconfigurations are a leading cause of cloud security breaches. In the enterprise environment, recurring issues were identified:

* Excessive assignment of high-privilege roles (e.g., Owner, Contributor) without justification.
* Guest accounts allowed from untrusted domains, increasing supply chain risk.
* Managed identities provisioned without governance, leading to sprawl and untracked usage.
* Insufficient centralized logging of identity activities, limiting audit and incident response capability.

The challenge was to establish a **repeatable IAM governance baseline** that minimized privileged access, controlled guest accounts, governed managed identities, and ensured auditable identity activity across all subscriptions.

---

## Role & Tools

**Role:** Cloud Admin / Security Lead (solo project)
**Tools & Technologies:** Azure Policy, Azure Active Directory, Log Analytics, Terraform

---

## Actions Taken

### Broad Policy Authoring (IAM Security Controls)

Designed and implemented Azure policy definitions to enforce IAM best practices, including:

* **Privileged Role Restrictions** – blocked Owner/Contributor assignments at subscription scope.
* **Guest Access Governance** – restricted guest accounts to enterprise-trusted domains only.
* **Managed Identity Controls** – enforced scope limitations for system-assigned and user-assigned identities.
* **IAM Logging Enforcement** – required all identity-related logs to flow into Log Analytics.
* **Inactive Account Monitoring** – flagged accounts unused for 90+ days for review and remediation.

These controls were aligned with **NIST SP 800-53 AC**, **ISO 27001 A.9**, and the **CIS Microsoft Azure Foundations Benchmark**.

### Initiative (IAM Hardening Baseline)

* Bundled IAM policies into the **IAM Hardening Initiative** for standardized enforcement.
* Centralized parameters (e.g., inactivity thresholds, trusted domains).
* Explicit metadata mapping to compliance frameworks.
* Modular design enabling targeted rollout (guest access vs. privileged roles).

### Assignments Across Subscriptions

* Applied the IAM Hardening Initiative at subscription level.
* Deny effect for critical misconfigurations (e.g., Owner assignment).
* Scoped exclusions for dev/test subscriptions.
* Logging assignments directed to enterprise Log Analytics workspaces.

### Automation & Governance-as-Code

* Integrated IAM definitions, initiative, and assignments into Terraform.
* Version-controlled parameters for repeatability and auditability.
* Embedded governance-as-code practices to eliminate manual role management errors.

---

## Results / Impact

* Reduced **privileged role sprawl** and enforced least privilege across subscriptions.
* Restricted **guest access to trusted domains only**, reducing external attack surface.
* Centralized **identity activity logging** improved audit readiness and detection of anomalous behavior.
* Automated IAM governance with Terraform eliminated drift and manual misconfigurations.
* Established a reusable, scalable IAM hardening model for onboarding future subscriptions.

---

## Artifacts (IAM Examples Only)

While this portfolio demonstrates IAM-focused artifacts for brevity and NDA compliance, the actual implementation included additional governance integrations with compliance dashboards and incident response pipelines.

**Policy Definitions (IAM Examples)**

* Restrict Privileged Role Assignments
* Restrict Guest Accounts to Approved Domains
* Restrict Managed Identity Creation to Approved Scopes
* Enforce IAM Activity Logging
* Flag Inactive Accounts

**Initiative**

* IAM Hardening Initiative

**Assignment**

* IAM Hardening Assignment

**Terraform**

* IaC modules for definitions, initiatives, and assignments

---

## Key Takeaways

This project demonstrates my ability to deliver **enterprise-scale IAM governance** in Azure. Through a combination of **policy-driven enforcement, initiative bundling, and Terraform automation**, I successfully:

* Standardized least-privilege access controls.
* Controlled guest account usage with domain restrictions.
* Centralized IAM monitoring for compliance and audit readiness.
* Embedded IAM governance into DevSecOps workflows for repeatable enforcement.

The IAM Hardening initiative strengthened the **identity security foundation** of the enterprise cloud, addressing one of the most critical vectors of cloud compromise.
