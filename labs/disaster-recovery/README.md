# Disaster Recovery (DR) Lab

## Overview

This lab demonstrates enterprise-scale **Disaster Recovery (DR) strategy and execution** in a cloud-first environment.  
It highlights how recovery procedures were documented, tested, and improved to meet strict **Recovery Time Objective (RTO)** and **Recovery Point Objective (RPO)** requirements.  

The project includes:  
* A **case study** documenting how DR posture was strengthened across the enterprise.  
* A **sanitized DR playbook** showing how recovery procedures were standardized and automated.  
* Evidence of how **RTO was reduced by 60%** through automation and testing.  

---

## Problem / Challenge

Prior to this effort, the organization’s DR posture suffered from:  
* Inconsistent recovery documentation across critical applications.  
* Manual, error-prone failover procedures.  
* Lack of validated RTO/RPO metrics.  
* Limited visibility into DR testing outcomes.  

These gaps created unacceptable business risk in the event of a regional outage or ransomware event.

---

## Tools & Technologies

* **Azure Site Recovery (ASR)** – automated failover for critical workloads  
* **Azure Backup & Recovery Vault** – point-in-time restore with RPO validation  
* **Terraform** – DR infrastructure automation  
* **Log Analytics & Workbooks** – RTO/RPO tracking and compliance dashboards  
* **Runbooks (PowerShell, Bash)** – scripted recovery tasks  

---

## Actions Taken

1. **Playbook Standardization**  
   * Authored a **centralized DR Playbook** with clear roles, runbooks, and escalation paths.  
   * Playbook linked to application tiers, SLAs, and RTO/RPO targets.  
   * Sanitized version provided in this repo: [`artifacts/disaster-recovery-playbook.md`](./artifacts/disaster-recovery-playbook.md).  

2. **Automation of Failover Procedures**  
   * Integrated **Azure Site Recovery** for critical apps.  
   * Developed scripts to automate DNS failover, app service warm-up, and storage replication checks.  

3. **Validation & Testing**  
   * Conducted **quarterly failover tests** simulating regional outages.  
   * Measured and documented **RTO and RPO results** per application.  
   * Built compliance dashboards in Log Analytics.  

4. **Continuous Improvement**  
   * Optimized automation to cut down manual recovery steps.  
   * Reduced RTO from 8 hours to under 3 hours.  
   * Improved RPO validation to under 15 minutes for Tier-1 apps.  

---

## Results / Impact

* **Reduced RTO by 60%** through automation and structured playbooks.  
* **Validated RPO compliance** for all Tier-1 and Tier-2 workloads.  
* Ensured **repeatable and auditable recovery** procedures for regulators and auditors.  
* Increased **executive confidence** through quarterly DR testing reports.  

---

## Artifacts

* **Case Study** – [Disaster Recovery Playbook Case Study](./case-study.md)  
* **Sanitized DR Playbook** – [Disaster Recovery Playbook Template](./artifacts/disaster-recovery-playbook.md)  
* **Terraform Modules** – Infrastructure-as-Code for recovery site deployment  
* **Automation Scripts** – PowerShell and Bash runbooks for failover/recovery  

---

## Key Takeaways

This project demonstrates the ability to:  
* Design and operationalize **enterprise-grade DR strategy**.  
* Improve resilience by **automating recovery steps**.  
* Translate DR from a theoretical plan to **validated, repeatable procedures**.  
* Provide executive-ready reports that quantify **measurable improvements in resilience**.  

By implementing this lab, I demonstrated how a **large-scale organization can strengthen business continuity** and ensure mission-critical applications survive major outages or cyberattacks.
