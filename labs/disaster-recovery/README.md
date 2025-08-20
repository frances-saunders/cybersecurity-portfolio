# Disaster Recovery (DR) Lab

## Overview

This lab demonstrates enterprise-scale **Disaster Recovery (DR) strategy and execution** in a cloud-first environment.
It highlights how recovery procedures were documented, tested, and improved to meet strict **Recovery Time Objective (RTO)** and **Recovery Point Objective (RPO)** requirements.

The project includes:

* A **case study** documenting how DR posture was strengthened across the enterprise.
* A **sanitized DR playbook** showing how recovery procedures were standardized and automated.
* **Terraform modules** for provisioning DR-ready infrastructure (SQL geo-replication, storage redundancy, Key Vault).
* **Automation scripts** for running failover tests and rotating credentials.
* Evidence of how **RTO was reduced by 60%** through automation and testing.

---

## Problem / Challenge

Prior to this effort, the organization’s DR posture suffered from:

* Inconsistent recovery documentation across critical applications.
* Manual, error-prone failover procedures.
* Credentials stored insecurely in plaintext configurations.
* Lack of validated RTO/RPO metrics.
* Limited visibility into DR testing outcomes.

These gaps created unacceptable business risk in the event of a regional outage or ransomware event.

---

## Tools & Technologies

* **Azure Site Recovery (ASR)** – automated failover for critical workloads
* **Azure Backup & Recovery Vault** – point-in-time restore with RPO validation
* **Azure Key Vault** – secure storage and rotation of recovery credentials
* **Terraform** – DR infrastructure automation (modularized for RG, SQL DB, Storage, Key Vault)
* **Log Analytics & Workbooks** – RTO/RPO tracking and compliance dashboards
* **Runbooks (PowerShell, Bash)** – scripted recovery tasks and credential rotation

---

## Actions Taken

### 1. Playbook Standardization

* Authored a **centralized DR Playbook** with clear roles, runbooks, and escalation paths.
* Playbook linked to application tiers, SLAs, and RTO/RPO targets.
* Sanitized version provided here: [Disaster Recovery Playbook Excerpt](./reports/DR-Playbook-Excerpt.md).

### 2. Automation of Failover Procedures

* Integrated **Azure Site Recovery** for critical apps.
* Developed automation scripts to run **DNS failover, SQL geo-replication testing, and storage validation**.
* Created **PowerShell and Bash scripts** in [`automation/scripts`](./automation/scripts) for repeatable DR testing.

### 3. Secure Credential Management

* Eliminated plaintext admin passwords in Terraform.
* Implemented **Key Vault module** (`modules/keyvault`) to securely provision and manage SQL admin secrets.
* Added rotation scripts (`set-sql-password.ps1` / `.sh`) to automatically update Key Vault before failover.

### 4. Validation & Testing

* Conducted **quarterly failover tests** simulating regional outages.
* Measured and documented **RTO and RPO results** per application.
* Built compliance dashboards in Log Analytics: [RTO/RPO Dashboard](./reports/rto-rpo-dashboard.md).

### 5. Continuous Improvement

* Optimized automation to cut down manual recovery steps.
* Reduced RTO from **8 hours to under 3 hours**.
* Improved RPO validation to under **15 minutes for Tier-1 apps**.

---

## Results / Impact

* **Reduced RTO by 60%** through automation, secure credential management, and structured playbooks.
* **Validated RPO compliance** for all Tier-1 and Tier-2 workloads.
* Eliminated insecure password handling with **Key Vault integration**.
* Ensured **repeatable and auditable recovery** procedures for regulators and auditors.
* Increased **executive confidence** through quarterly DR testing reports.

---

## Artifacts

* **Case Study** – [Disaster Recovery Case Study](../../case-studies/disaster-recovery-case-study.md)
* **Sanitized DR Playbook** – [Playbook Excerpt](./reports/DR-Playbook-Excerpt.md)
* **Terraform Modules** –

  * [`modules/rg`](./modules/rg) – Resource Group provisioning
  * [`modules/sql-db`](./modules/sql-db) – SQL Server + Geo-replicated DB
  * [`modules/storage`](./modules/storage) – DR-ready storage
  * [`modules/keyvault`](./modules/keyvault) – Key Vault with secret management
* **Automation Scripts** – [`automation/scripts`](./automation/scripts)

  * `test-failover.ps1` / `test-failover.sh` – simulate DR failover
  * `set-sql-password.ps1` / `set-sql-password.sh` – rotate SQL admin credentials in Key Vault
* **Reports** –

  * [RTO/RPO Dashboard](./reports/rto-rpo-dashboard.md)
  * [DR Postmortem Template](./reports/dr-postmortem-template.md)

---

## Key Takeaways

This project demonstrates the ability to:

* Design and operationalize **enterprise-grade DR strategy**.
* Improve resilience by **automating recovery steps and credential rotation**.
* Translate DR from a theoretical plan to **validated, repeatable procedures**.
* Provide **executive-ready reports and compliance dashboards**.

By implementing this lab, I demonstrated how a **large-scale organization can strengthen business continuity** and ensure mission-critical applications survive major outages or cyberattacks.
