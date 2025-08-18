# Case Study: Logging & Automation in Azure

## Context & Challenge

Organizations often rely on Azure Policy to enforce security baselines, but enforcement alone is not enough. Without visibility into **when and where violations occur** and without **automation to fix them**, environments can remain non-compliant for extended periods.

In my environment reviews, I discovered key challenges:

* No centralized visibility into AKS policy compliance across subscriptions.
* Developers often unaware of policy drift until audits flagged issues.
* Manual remediation of violations created bottlenecks.
* Compliance status reporting lacked consistency and transparency.

The challenge was to design and implement a **closed-loop governance system** that would detect policy drift, visualize compliance, and automatically remediate non-compliance in real time.

---

## Solution Approach

I designed and delivered a **Logging & Automation framework** that integrated Azure Policy, Azure Monitor Logs, KQL, Workbooks, and Azure Automation into one cohesive system.

1. **Terraform Foundation**

   * Deployed a Log Analytics Workspace.
   * Configured diagnostic settings for AKS to send compliance logs.
   * Automated reproducibility of the setup across environments.

2. **KQL Queries for Insights**

   * Developed queries against `PolicyResources` to surface non-compliant AKS clusters.
   * Created severity-based filters and compliance trend aggregation.
   * Mapped queries to policy initiatives for traceability.

3. **Custom Workbook Dashboards**

   * Built visual dashboards in Azure Workbooks showing:
     – Non-compliant resources grouped by severity.
     – Compliance drift trends over time.
     – Assignment breakdowns across environments.
   * Provided drill-down capability for cluster-level investigation.

4. **Automation Runbooks for Remediation**

   * Authenticated securely using managed identity.
   * Queried policy state and triggered remediation tasks automatically.
   * Logged every remediation action for auditability.

---

## Results & Business Impact

* **End-to-end compliance loop** established — detect, visualize, remediate.
* Reduced remediation timelines from **days to minutes**, minimizing compliance exposure.
* Provided clear, actionable dashboards for leadership and auditors.
* Standardized compliance monitoring across subscriptions, improving governance maturity.
* Delivered reusable automation patterns applicable beyond AKS, extending to IAM, storage, and Defender policies.

---

## Key Artifacts

* **Terraform** – Infrastructure provisioning for Log Analytics and diagnostic pipelines.
* **KQL Queries** – Policy non-compliance detection and trend reporting.
* **Azure Workbook** – Visual dashboards for compliance monitoring.
* **Automation Runbook** – PowerShell remediation logic integrated with Policy.

---

## Lessons Learned

This project highlighted the importance of pairing **policy enforcement** with **operational intelligence**. Policies alone only block or audit — true governance requires **visibility** and **automated correction**. By embedding logs, dashboards, and runbooks into the compliance framework, I demonstrated how to transform Azure Policy into a **living system of control** rather than a static rulebook.
