# Cloud Attack Simulation & Detection Lab

## Overview

This lab demonstrates how to simulate **adversary-style cloud attacks** and validate security detection and response capabilities using **Microsoft Sentinel**. By creating detection queries, automation playbooks, and a custom workbook, this lab highlights the ability to think like an attacker while engineering resilient defenses.

The focus is on bridging **red team insights** with **blue team operations** — showing how simulations lead to measurable SOC improvements.

---

## Lab Objectives

* Simulate cloud-based attack scenarios:

  * Impossible travel sign-ins.
  * Brute-force login attempts.
  * Malicious container execution.
* Develop **KQL detection queries** in Sentinel for each scenario.
* Deploy **automation playbooks** to:

  * Auto-close false positives.
  * Auto-respond to high-severity alerts.
  * Enrich incidents with external threat intelligence.
* Build a **Sentinel workbook** that visualizes:

  * Attack detections by scenario.
  * Automation coverage and enrichment rates.
  * Mean Time to Respond (MTTR) improvements.

---

## Directory Structure

```plaintext
labs/cloud-attack-simulation-and-detection/
├── automation/
│   ├── auto-close-false-positives.jsonc
│   ├── auto-respond-high-severity.jsonc
│   └── enrich-with-threat-intel.jsonc
│
├── kql/
│   ├── impossible-travel.kql
│   ├── brute-force-logins.kql
│   └── malicious-container.kql
│
├── policies/
│   ├── restrict-risky-locations.json
│   └── enforce-container-security.json
│
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── variables.tf
│
└── workbooks/
    └── attack-detection-overview.jsonc
```

---

## Deployment Steps

### 1. Terraform

1. Navigate to `labs/cloud-attack-simulation-and-detection/terraform/`.
2. Run `terraform init`, `terraform plan`, and `terraform apply` to provision:

   * Resource group, VNet, subnets.
   * Sentinel + Log Analytics workspace.
   * Sample workloads (Storage, AKS) for attack simulation.

### 2. Policies

1. Navigate to `labs/cloud-attack-simulation-and-detection/policies/`.
2. Deploy policies via **Azure Policy**:

   * `restrict-risky-locations.json` → Blocks risky sign-in locations.
   * `enforce-container-security.json` → Ensures hardened container runtime configs.

### 3. Detection (KQL Queries)

1. Navigate to `labs/cloud-attack-simulation-and-detection/kql/`.
2. Deploy queries in Sentinel Analytics Rules:

   * `impossible-travel.kql`
   * `brute-force-logins.kql`
   * `malicious-container.kql`

### 4. Automation (Playbooks)

1. Navigate to `labs/cloud-attack-simulation-and-detection/automation/`.
2. Import playbooks into **Azure Logic Apps**:

   * `auto-close-false-positives.jsonc`
   * `auto-respond-high-severity.jsonc`
   * `enrich-with-threat-intel.jsonc`
3. Attach playbooks to corresponding analytics rules in Sentinel.

### 5. Workbook

1. Navigate to `labs/cloud-attack-simulation-and-detection/workbooks/`.
2. Import `attack-detection-overview.jsonc` into Sentinel Workbooks.
3. Validate visualizations:

   * Detection timelines for impossible travel, brute force, and container attacks.
   * Automation coverage %.
   * Enrichment coverage %.
   * MTTR comparisons (automated vs manual).

---

## Skills Demonstrated

* **Threat Simulation** – thinking like an attacker to design detection use cases.
* **KQL Engineering** – custom queries for behavioral detections.
* **Policy as Code** – enforcing preventative controls with Azure Policy.
* **Security Automation** – automating SOC playbooks with Logic Apps.
* **SOC Metrics Analysis** – building a workbook to quantify detection & response impact.
* **Executive Reporting** – translating attack data into metrics leadership understands.
