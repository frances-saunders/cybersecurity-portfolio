# IAM Hardening in Azure

## Problem / Challenge

Identity and Access Management (IAM) is the foundation of cloud security, yet misconfigurations are among the most common causes of breaches.  
During audits, several risks were identified:

* Excessive privileged role assignments and lack of least-privilege enforcement.  
* Guest accounts allowed without proper domain restrictions.  
* Managed identities created without governance or scope control.  
* Limited visibility into IAM activity, with insufficient logging into a centralized workspace.  

The challenge was to design and enforce an **IAM Hardening baseline** that ensured privileged access was minimized, guest access was controlled, managed identities were governed, and identity activities were auditable across the enterprise.

---

## Role & Tools

**Role:** Cloud Admin / Security Lead (solo project)  
**Tools & Technologies:** Azure Policy, Azure Active Directory, Log Analytics, Terraform

---

## Actions Taken

### Policy Authoring (IAM Controls)

Developed Azure JSONC policy definitions targeting IAM governance, including:

* **Privileged Role Restrictions** – blocking direct assignment of high-risk roles (e.g., Owner, Contributor) without justification.  
* **Guest Account Governance** – restricting guest access to trusted domains only.  
* **Managed Identity Controls** – limiting creation of system-assigned and user-assigned managed identities to approved scopes.  
* **IAM Logging Enforcement** – requiring all identity-related activity logs to be routed to Log Analytics for monitoring.  
* **Inactive Account Review** – flagging accounts inactive for 90+ days to reduce attack surface.  

These policies aligned with **NIST SP 800-53 AC (Access Control) family**, **ISO 27001 A.9**, and **CIS Azure Foundations** benchmarks.

### Initiative (IAM Hardening Baseline)

Grouped policies into the **IAM Hardening Initiative**, which:  

* Bundled IAM controls into a single, reusable policy set.  
* Centralized parameters (e.g., allowed guest domains, inactivity thresholds).  
* Mapped controls to compliance standards (NIST, ISO, CIS).  
* Allowed modular use of IAM governance controls across subscriptions.

### Assignment at Scope

Assigned the **IAM Hardening Initiative** at the subscription level:

* Critical violations (e.g., Owner assignment) set to `Deny`.  
* Guest restrictions scoped to enterprise-trusted domains.  
* Exclusions supported for dev/test environments.  
* Centralized logging enforced into a dedicated Log Analytics workspace.

### Automation with Terraform

* IAM policy definitions, initiative, and assignment integrated into Terraform for repeatable deployment.  
* Parameters such as trusted domains, workspace IDs, and thresholds version-controlled in code.  
* Enabled governance-as-code for IAM, reducing drift and manual errors.

---

## Results / Impact

* Reduced privileged role sprawl across subscriptions.  
* Restricted guest access to approved domains only, cutting supply chain risk.  
* Centralized logging of IAM activities improved audit readiness and insider threat detection.  
* Standardized IAM governance across environments through automation.  
* Established a reusable IAM hardening blueprint to onboard future subscriptions quickly.

---

## Artifacts

While this portfolio only shows IAM-related definitions, initiatives, and assignments, the actual project included broader integration with compliance dashboards and incident response pipelines.

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

This project demonstrates my ability to implement **identity-focused governance** in Azure at scale. Through **policy-driven IAM controls, initiative bundling, and Terraform automation**, I was able to enforce least-privilege access, secure guest account usage, centralize IAM monitoring, and embed governance into CI/CD workflows.  

The initiative hardened the **enterprise IAM layer**, a critical defense against insider threats, misconfigurations, and external breaches.
