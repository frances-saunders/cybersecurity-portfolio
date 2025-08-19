# Case Study: Disaster Recovery Playbook & RTO Improvement

## Problem / Challenge

Disaster recovery (DR) gaps were identified across the enterprise environment supporting thousands of users and mission-critical workloads. The challenges included:

* **Undefined RTO/RPO baselines** — inconsistent recovery expectations across business units.
* **Manual failover procedures** — increasing the risk of errors during outages.
* **Incomplete documentation** — fragmented runbooks led to confusion during incident response.
* **Unvalidated DR plans** — no formal test cycles or simulation exercises to prove recovery effectiveness.

The challenge was to deliver a **repeatable, well-documented DR playbook** that reduced recovery times, standardized procedures, and provided evidence of tested readiness.

---

## Tools & Technologies

Azure Site Recovery, Azure Backup, VMware SRM, Microsoft SQL Always On, Terraform, PowerShell, ServiceNow (for runbook integration)

---

## Actions Taken

### DR Playbook Development

* Authored a **sanitized but enterprise-ready Disaster Recovery Playbook** covering:

  * Infrastructure recovery (compute, storage, networking).
  * Application-specific recovery (databases, middleware, critical SaaS integrations).
  * Communication workflows (incident command, business unit notifications).
  * Escalation matrix and DR decision authority.

### Automation & Orchestration

* Automated failover using **Azure Site Recovery** and **VMware SRM**, reducing reliance on manual intervention.
* Integrated **Terraform + PowerShell runbooks** for infrastructure redeployment and DNS updates.
* Standardized database recovery via **SQL Always On replicas** and **automated restore validation scripts**.

### RTO/RPO Baseline & Testing

* Established **tiered RTO/RPO objectives**:

  * Tier 1 apps: RTO 1 hour, RPO 15 minutes.
  * Tier 2 apps: RTO 4 hours, RPO 1 hour.
  * Tier 3 apps: RTO 24 hours, RPO 24 hours.
* Conducted **quarterly DR simulation exercises** with business stakeholders.
* Validated success through **full failover tests** and **data integrity checks** post-recovery.

### Continuous Improvement

* Updated the playbook after each test to refine procedures.
* Integrated DR readiness into **ServiceNow change management** workflows.
* Created a **dashboard in Log Analytics** to track DR test success, recovery times, and SLA compliance.

---

## Results / Impact

* Reduced **Tier 1 RTO from 4 hours → 55 minutes**, exceeding business SLA.
* Improved **overall DR readiness from 62% → 100% validated coverage** across 3 simulation cycles.
* Automated infrastructure failover and DNS cutover reduced manual steps by **40%**.
* Delivered a **clear, repeatable playbook** that executive stakeholders approved and auditors accepted.
* Established a **culture of continuous DR validation** through quarterly exercises.

---

## Artifacts (Sanitized Examples)

* **Disaster Recovery Playbook (Sanitized Excerpt)**

  * Incident response workflow diagrams
  * Failover step-by-step instructions (infrastructure + application layers)
  * Escalation and communications templates
* **Runbooks & Scripts**

  * PowerShell automation for SQL restore validation
  * Terraform IaC modules for DR redeployment
* **Reports**

  * RTO/RPO compliance summary dashboards
  * Post-test reports with lessons learned

---

## Key Takeaways

This project demonstrates my ability to deliver **enterprise-scale disaster recovery readiness**. By combining **playbook documentation, automation, and testing discipline**, I successfully:

* Reduced recovery times for critical applications from hours to under one hour.
* Standardized recovery expectations with tiered RTO/RPO baselines.
* Validated procedures through regular failover exercises with measurable improvements.
* Embedded DR into governance workflows to ensure continuous improvement.

The Disaster Recovery Playbook project strengthened the **resilience of enterprise operations**, ensuring that critical services could be restored quickly and consistently in the face of outages.
