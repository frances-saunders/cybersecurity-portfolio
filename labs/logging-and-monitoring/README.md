# Logging & Automation in Azure

## Problem / Challenge

Enterprises often deploy strong governance and compliance controls, but enforcement alone is not enough. Without **visibility** into policy violations and **automated remediation**, environments drift from security baselines. During reviews, the following gaps were observed:

* Lack of centralized queries to track AKS policy compliance.
* No custom dashboards to visualize policy compliance trends across subscriptions.
* Manual response to policy violations, leading to extended non-compliance windows.
* Inconsistent enforcement across environments (dev, test, prod).

The challenge was to create an integrated approach combining **KQL queries, workbooks, and automation runbooks** to strengthen compliance monitoring and reduce remediation delays.

---

## Tools & Technologies
Azure Policy, Azure Monitor Logs (KQL), Azure Workbooks, Azure Automation (PowerShell), Terraform

---

## Actions Taken

### Terraform Deployment of Core Components

Provisioned baseline Azure Monitor and Policy integration with Terraform:

* Deployed Log Analytics Workspace with diagnostic settings for AKS.
* Connected AKS policy compliance logs into the workspace.
* Established a foundation for KQL queries and dashboards.

### KQL Queries for Compliance Monitoring

Developed custom queries in **Kusto Query Language (KQL)** to surface AKS compliance states:

* Queried `PolicyResources` for non-compliant AKS clusters.
* Aggregated non-compliance trends by policy, cluster, and subscription.
* Filtered by severity and compliance state for actionable insights.

### Workbooks for Visualization

Built a **custom Azure Workbook** to visualize compliance:

* Interactive graphs showing non-compliant clusters by severity.
* Trend charts of compliance drift over time.
* Policy assignment summaries for quick audit snapshots.

### Automation Runbook for Policy Remediation

Implemented a **PowerShell runbook** in Azure Automation:

* Connected securely via managed identity.
* Queried AKS policy states for non-compliance.
* Automatically triggered remediation tasks for affected clusters.
* Logged remediation actions for auditing and tracking.

---

## Results / Impact

* Created an **end-to-end compliance loop**: detect via logs, visualize in dashboards, remediate with automation.
* Reduced remediation time from **days to minutes** with runbook automation.
* Standardized compliance reporting for AKS across all subscriptions.
* Established reusable automation for future policy enforcement scenarios.

---

## Artifacts

**Terraform**

* Baseline deployment of Log Analytics and diagnostic integration.

**KQL**

* Queries to extract AKS non-compliance data from Azure Policy logs.

**Workbook**

* Interactive compliance dashboard for AKS clusters.

**Automation**

* PowerShell runbook to trigger AKS policy remediations automatically.

---

## Key Takeaways

This project demonstrates my ability to:

* Build **compliance pipelines** from raw logs to dashboards.
* Apply **KQL** for advanced security analytics.
* Integrate **automation** into governance workflows for proactive remediation.
* Use **Terraform** for reproducible deployment of monitoring components.

The outcome was a **repeatable compliance framework** that transformed Azure Policy from a static enforcement tool into a **dynamic governance system** with detection, visualization, and automated response.
