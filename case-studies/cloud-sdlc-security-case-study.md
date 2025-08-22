# Case Study: Cloud Security Integration into the SDLC

## Problem / Challenge

The organization’s software development lifecycle (SDLC) lacked **embedded cloud security controls**. Development teams deployed workloads into Azure without standardized guardrails, which led to:

* Inconsistent **infrastructure configurations** (e.g., open storage accounts, excessive IAM permissions).
* Limited **pre-deployment security testing** — vulnerabilities surfaced only in production.
* **Siloed responsibilities** between Dev, Sec, and Ops teams, causing friction and slow releases.
* Absence of **audit-ready compliance evidence** during internal and external assessments.

The challenge was to integrate **cloud security governance into every SDLC stage**, without slowing down developer productivity.

---

## Tools & Technologies

* **Azure DevOps & GitHub Actions** – CI/CD pipelines with integrated security stages
* **Terraform** – Infrastructure-as-Code (IaC) with policy enforcement
* **Azure Policy & Defender for Cloud** – automated compliance guardrails
* **Wiz & Microsoft Defender for Cloud** – vulnerability and misconfiguration scanning
* **Key Vault & Managed Identities** – secrets management and identity security
* **Custom Workbooks** – developer-facing dashboards for compliance visibility

---

## Actions Taken

### 1. Shift-Left Cloud Security in Pipelines

* Built **pipeline templates** that embedded static code analysis, IaC scanning (Terraform checks), and container image scanning.
* Enforced **mandatory pre-deployment checks** for misconfigured IAM, insecure networking, and open storage endpoints.
* Integrated **unit tests for cloud security baselines** — developers received feedback before merge.

### 2. Policy-as-Code & Governance-as-Code

* Authored **custom Azure Policy definitions** to enforce guardrails (no public IPs, mandatory encryption at rest, approved VM SKUs only).
* Packaged policies into **initiatives tied to compliance frameworks** (NIST, CIS, ISO 27001).
* Automated **subscription-wide assignments** using Terraform to ensure consistent enforcement across environments.

### 3. Secrets & Identity Security

* Eliminated plaintext credentials from pipelines by **integrating Key Vault** and **Azure AD managed identities**.
* Automated **key rotation policies** and integrated audit logs for compliance tracking.
* Reduced **secrets sprawl** by centralizing all pipeline secrets in a single vault.

### 4. Continuous Security Monitoring

* Wired **Wiz and Defender for Cloud** into CI/CD pipelines for pre-deployment vulnerability checks.
* Configured **alerts to feed into Sentinel**, enabling early threat detection aligned with application deployments.
* Built **dashboards** showing compliance drift, RPO/RTO alignment, and developer security KPIs.

### 5. DevSecOps Culture & Automation

* Rolled out **self-service security dashboards** in Azure Workbooks for development teams.
* Conducted **monthly reviews** of IaC scans, policy violations, and vulnerability reports with app teams.
* Embedded **governance-as-code** into GitHub repos, making security **version-controlled and auditable**.

---

## Results / Impact

* Reduced **cloud misconfigurations by 70%** in dev/test workloads.
* Achieved **95% pipeline adoption rate** for IaC security scans and container vulnerability checks.
* Decreased **secrets-related incidents to zero** through Key Vault and managed identity adoption.
* Passed **ISO 27001 and SOC 2 audits** with minimal findings due to auditable policy-as-code evidence.
* Improved **release velocity** by 30% — security checks were automated and no longer bottlenecks.
* Enhanced **executive visibility** with compliance dashboards directly tied to SDLC metrics.

---

## Artifacts

* **Terraform Modules** – Policy-as-Code enforcement (NSG restrictions, encryption requirements, approved SKUs)
* **Pipeline Templates (YAML)** – CI/CD workflows with embedded IaC scanning, container scanning, and compliance checks
* **Azure Policy Initiatives** – CIS/NIST-aligned guardrails deployed enterprise-wide
* **Key Vault Integration Scripts** – secure secret retrieval in pipelines
* **Dashboards** – Azure Workbook examples for compliance and developer visibility

---

## Key Takeaways

This project demonstrates my ability to:

* Embed **cloud security into the SDLC** without hindering developer agility.
* Lead **governance-as-code** initiatives to enforce compliance at scale.
* Drive **DevSecOps cultural adoption** by making security both automated and developer-friendly.
* Translate security into **measurable metrics** for executives and auditors.
* Build a **repeatable, auditable, enterprise-scale model** for secure software delivery in the cloud.

The initiative transformed cloud security from an afterthought into an **integral, automated part of the SDLC**, reducing risk while accelerating delivery.
