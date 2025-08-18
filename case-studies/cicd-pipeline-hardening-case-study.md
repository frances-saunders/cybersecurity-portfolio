# Case Study: CI/CD Pipeline Hardening with GitHub & Azure DevOps

## Problem / Challenge

Continuous Integration/Continuous Deployment (CI/CD) pipelines accelerate software delivery but often introduce security risks if not properly secured. Common issues include:

* **Overprivileged service connections** granting unnecessary access.
* **Hardcoded secrets** in pipelines or repos.
* **Weak branch protections** allowing unreviewed or unsigned commits.
* **Insecure RBAC assignments** giving developers admin-level privileges.
* **Insufficient audit logging**, making it difficult to trace malicious changes.

These weaknesses could enable attackers to inject malicious code, exfiltrate secrets, or pivot laterally into production environments. A hardened pipeline was required to align with **Zero Trust principles** and reduce software supply chain risk.

---

## Tools & Technologies

GitHub, Azure DevOps, Terraform, Azure Key Vault, GitHub Advanced Security, Microsoft Defender for DevOps

---

## Actions Taken

### RBAC & Identity Controls

* Applied **least privilege RBAC** in both GitHub and Azure DevOps.

  * Scoped service principals to **specific resource groups**, not subscriptions.
  * Restricted pipeline execution to approved identities via conditional access.
  * Segregated roles for developers, reviewers, and release managers.

### Secret Management

* Migrated all pipeline secrets to **Azure Key Vault**.
* Configured pipelines to **pull secrets dynamically** at runtime via secure service connections.
* Enabled **rotation policies** for credentials and certificates.

### Repository & Branch Protections

* Enforced:

  * **Branch protection rules** requiring PR approvals and signed commits.
  * **Mandatory code scanning (SAST)** with GitHub Advanced Security.
  * **Mandatory dependency scanning (SCA)** for vulnerable libraries.
* Blocked direct pushes to `main` and `release/*` branches.

### Policy Enforcement

* Authored Azure Policies to:

  * Deny pipelines with hardcoded secrets.
  * Require pipeline logs to be stored in a centralized Log Analytics workspace.
* Integrated **Terraform guardrails** to validate IaC configurations before deployment.

### Monitoring & Alerts

* Enabled **Microsoft Defender for DevOps** to monitor repository activities, anomalous pipeline runs, and credential exposures.
* Forwarded CI/CD security logs to **Sentinel** for detection and correlation with runtime alerts.

---

## Results / Impact

* Eliminated **hardcoded secrets** across pipelines.
* Reduced **RBAC attack surface** by enforcing least privilege.
* Improved **supply chain security** with enforced branch protections, code scanning, and signed commits.
* Gained **end-to-end visibility** by integrating DevOps logs into Sentinel.
* Delivered a **repeatable hardening baseline** for CI/CD pipelines across both GitHub and Azure DevOps.

---

## Artifacts

**RBAC Configurations**

* Sanitized GitHub and Azure DevOps role mappings.
* Scoped service connections with minimal privileges.

**Secret Management Flows**

* Pipeline integration with Azure Key Vault.
* Automated secret rotation policies.

**Repository Protections**

* Branch protection rules.
* Signed commits and PR approvals.
* GitHub Advanced Security scans (SAST/SCA).

**Policy Enforcement**

* Azure Policies for CI/CD logging and secret handling.
* Terraform guardrails for IaC validation.

**Monitoring & Alerts**

* Defender for DevOps integration.
* Sentinel KQL detections for anomalous pipeline activity.

---

## Key Takeaways

This project demonstrates expertise in:

* Applying **Zero Trust principles** to CI/CD pipelines.
* Enforcing **RBAC and least privilege** in DevOps platforms.
* Implementing **secret management best practices** with Azure Key Vault.
* Hardening **repositories against supply chain attacks** with branch protections and signed commits.
* Integrating **pipeline telemetry into SIEM/SOAR** for proactive monitoring.

The result was a secure CI/CD ecosystem that not only accelerated deployments but also reduced risk exposure, aligning software delivery with enterprise-grade security standards.
