# Case Study: Logging and Automation in Azure

## Problem / Challenge

Cloud environments generate massive amounts of security and operational data. Without proper centralization, monitoring, and automation, organizations face:

* **Siloed logs** spread across services, making investigations slow.
* **Alert fatigue** due to high false positive rates.
* **Inconsistent incident response**, with manual triage slowing down remediation.
* **Limited visibility** into compliance and cost impacts of security controls.

These gaps created the need for a **centralized logging and automation framework** that could both **aggregate telemetry** and **automatically respond to threats** in real time.

---

## Tools & Technologies

Azure Monitor, Log Analytics, Azure Sentinel, KQL, Azure Automation, Terraform

---

## Actions Taken

### Centralized Logging Setup

* Provisioned Log Analytics Workspace and connected Azure resources.
* Configured diagnostic settings for AKS, Key Vault, and Storage accounts.
* Enforced diagnostic settings using Azure Policy to prevent drift.

### Detection Queries (KQL)

* Authored custom queries to identify high-value scenarios:

  * **Suspicious sign-ins** (impossible travel, unusual geo).
  * **Defender for Cloud alerts** mapped to MITRE ATT\&CK.
  * **Suspicious process executions** in AKS and VM workloads.

### Automation Playbooks

* Built Azure Automation runbooks to:

  * **Auto-disable compromised accounts**.
  * **Enrich incidents with threat intel** (VirusTotal/IP reputation).
  * **Close false positives automatically** to reduce SOC noise.

### Sentinel Workbook

* Designed a custom Sentinel Workbook showing:

  * Incident volume by severity.
  * Percentage of alerts auto-closed by automation.
  * Threat intelligence enrichment coverage.
  * Trends in Mean Time to Respond (MTTR).

### Infrastructure as Code (Terraform)

* Automated provisioning of Log Analytics, Sentinel, Automation Accounts, and policies.
* Parameterized the scripts to allow easy redeployment across environments.

---

## Results / Impact

* Built a **repeatable logging and automation framework** that strengthens both detection and response.
* Reduced **MTTR by 40%** through automated account isolation and enrichment.
* Minimized **alert fatigue** by auto-closing repetitive low-value alerts.
* Delivered **actionable visibility** into SOC efficiency via custom workbooks.
* Created a **policy-driven model** that ensures logging compliance across resources.

---

## Artifacts

**Terraform**

* IaC provisioning for Log Analytics, Sentinel, Automation Accounts, and policies.

**KQL Queries**

* Suspicious sign-ins.
* Defender for Cloud alerts.
* Suspicious process executions.

**Automation**

* Auto-disable compromised accounts.
* Enrich with threat intel.
* Auto-close false positives.

**Workbooks**

* Sentinel workbook for incident response and automation coverage.

---

## Key Takeaways

This project demonstrates expertise in:

* Building **logging and monitoring at scale** in Azure.
* Authoring **KQL queries** for advanced threat detection.
* Creating **automation playbooks** to reduce SOC workload.
* Designing **custom workbooks** for actionable insights.
* Applying **Infrastructure as Code** for consistent and repeatable deployments.

The end result was a hardened and automated monitoring framework that shifted incident response from reactive firefighting to **proactive and automated defense**.
