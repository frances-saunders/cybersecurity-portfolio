# Azure Sentinel – Incident Response Automation Lab

## Overview

This lab demonstrates how to integrate **Microsoft Sentinel** with **Azure Logic Apps (Playbooks)** to automate incident response workflows. It also includes a **Sentinel Workbook** to visualize incident metrics and measure the impact of automation on security operations.

The artifacts showcase how automation can reduce false positives, enrich alerts with external threat intelligence, and accelerate mean time to close (MTTC).

---

## Lab Objectives

* Deploy **Sentinel playbooks** for automated incident handling.
* Implement three core automation scenarios:

  * Auto-assigning incidents to an analyst.
  * Auto-closing false positives.
  * Enriching incidents with external threat intelligence.
* Build a **Sentinel workbook** to visualize incident volume, automation coverage, enrichment percentages, and MTTC.
* Demonstrate SOC efficiency improvements through automation and analytics.

---

## Directory Structure

```plaintext
labs/sentinel-incident-response/
├── automation/
│   ├── auto-close-false-positives.jsonc
│   ├── auto-respond-high-severity.jsonc
│   └── enrich-with-threat-intel.jsonc
│
├── kql/
│   ├── defender-alerts.kql
│   ├── impossible-travel.kql
│   └── suspicious-signins.kql
│
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── variables.tf
│
└── workbooks/
    └── incident-response-overview.jsonc
```

---

## Deployment Steps

### 1. Playbooks

1. Navigate to `labs/sentinel/playbooks/`.
2. Deploy playbooks via **Azure Logic Apps**:

   * `auto-assign-incident.jsonc` → Assigns new incidents to a default SOC analyst.
   * `auto-close-false-positives.jsonc` → Suppresses common false positives automatically.
   * `enrich-with-threat-intel.jsonc` → Pulls external threat intel data into incident comments.
3. Assign the playbooks to Sentinel incident rules as automation rules.

### 2. Workbook

1. Navigate to `labs/sentinel/workbooks/`.
2. Import `incident-response-overview.jsonc` into Sentinel Workbooks.
3. Verify visualization of:

   * Incident volume by severity.
   * Count of auto-closed false positives.
   * Threat intelligence enrichment coverage over time.
   * Mean Time to Close (MTTC) – automated vs manual.

---

## Skills Demonstrated

* **Azure Sentinel (SIEM) Engineering** – custom workbooks, KQL, and automation.
* **Incident Response Automation** – building and deploying playbooks with Logic Apps.
* **SOC Metrics Analysis** – tracking severity, false positives, enrichment coverage, and MTTC.
* **Portfolio Impact** – demonstrates ability to **operationalize Sentinel** with automation and analytics, reducing SOC workload and increasing efficiency.
