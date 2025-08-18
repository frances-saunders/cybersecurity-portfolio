# Cost Optimization + Security Tradeoff Lab

## Overview

This lab demonstrates how to balance **cloud security effectiveness** with **cost efficiency** using Microsoft Sentinel, Defender for Cloud, and Azure Workbooks.

The focus is on **measuring the financial cost of security controls** (log ingestion, Defender plans, WAF) against the **risk reduction value** they provide. The artifacts highlight how to identify low-value spend, justify high-value controls, and communicate findings in a way that resonates with both **security teams** and **executive leadership**.

---

## Lab Objectives

* Build **KQL queries** to measure:

  * Sentinel log ingestion costs by data type.
  * Defender for Cloud plan costs by environment.
  * Unused or underutilized WAF instances.
* Develop a **Sentinel workbook** that visualizes:

  * Monthly cost trends for security services.
  * A **Cost vs. Risk Value Index Heatmap**.
  * Recommendations for optimizing spend without sacrificing risk coverage.
* Demonstrate the tradeoff decisions that security architects face when balancing protection and cost.

---

## Directory Structure

```plaintext
labs/cost-vs-security/
├── kql/
│   ├── sentinel-ingestion-costs.kql
│   ├── defender-plan-costs.kql
│   └── waf-unused.kql
│
├── workbook/
│   └── cost-security-tradeoff.jsonc
│
├── policies/
│   └── sentinel-data-retention.jsonc
│
└── README.md
```

---

## Deployment Steps

### 1. KQL Queries

1. Navigate to `labs/cost-vs-security/kql/`.
2. Run queries against:

   * **Cost Management + Billing tables** to analyze Sentinel log ingestion by type.
   * **Azure Resource Graph** for Defender for Cloud plan spend by environment tags.
   * **AzureDiagnostics** for WAF instances with no inbound traffic.

### 2. Workbook

1. Navigate to `labs/cost-vs-security/workbook/`.
2. Import `cost-security-tradeoff.jsonc` into Azure Sentinel Workbooks.
3. Validate visuals:

   * Sentinel ingestion costs by log type.
   * Defender plan spend by environment.
   * Unused WAF deployments.
   * Cost vs. Risk Value Index Heatmap.
   * Text-based recommendations.

### 3. Policy

1. Navigate to `labs/cost-vs-security/policies/`.
2. Deploy `sentinel-data-retention.jsonc` to enforce cost-conscious retention policies.

---

## Skills Demonstrated

* **KQL Analytics** – building cross-service queries integrating Cost Management, Resource Graph, and Sentinel logs.
* **Security ROI Modeling** – mapping financial cost to risk reduction value.
* **Azure Sentinel Workbooks** – translating raw telemetry into executive-ready dashboards.
* **Policy-as-Code** – enforcing cost-aware security governance through Azure Policy.
* **Leadership Thinking** – showing not just “can we secure it?” but “can we secure it efficiently?”.

---

This lab demonstrates the ability to bridge **technical engineering, financial awareness, and executive communication** — reflecting 10+ years of cybersecurity expertise.
