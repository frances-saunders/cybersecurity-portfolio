# SIEM Lab (Microsoft Sentinel)

## Overview

This lab provides a **hands-on demonstration of SIEM engineering and automation** using Microsoft Sentinel.
It includes infrastructure provisioning, custom detections, automated SOAR playbooks, and executive dashboards.

The lab is structured to highlight:

* Deployment of Sentinel and Log Analytics via **Terraform modules**.
* Authoring and testing of **KQL-based detections**.
* Integration of **SOAR playbooks** for automated incident response.
* A **sanitized executive dashboard** showing detection coverage and response metrics.

---

## Lab Structure

```
labs/siem/
│
├── detections/                         # KQL detection rules
│   ├── anomalous-logons.kql
│   ├── lateral-movement.kql
│   └── privilege-escalation.kql
│
├── playbooks/                          # SOAR playbooks (JSONC format)
│   ├── credential-leak-response.jsonc
│   ├── oauth-app-playbook.jsonc
│   └── ransomware-isolation.jsonc
│
├── scripts/                            # Automation & ingestion scripts
│   ├── bulk-disable-users.ps1          # Remediate compromised accounts
│   ├── enrich-threat-intel.ps1         # Threat intel enrichment (PowerShell)
│   ├── enrich-threat-intel.sh          # Threat intel enrichment (Bash)
│   ├── ingest-azure-activity.sh        # Push Azure Activity Logs to LAW
│   ├── ingest-custom-telemetry.sh      # Ingest custom app telemetry
│   ├── ingest-defender-alerts.ps1      # Collect Microsoft Defender alerts
│   └── post-to-law.py                  # Generic script to send logs to LAW
│
├── terraform/                          # Terraform IaC for Sentinel + connectors
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── variables.tf
│
└── README.md

```

---

## Tools & Technologies

* **Microsoft Sentinel** – SIEM platform
* **Azure Log Analytics** – centralized log collection
* **Terraform** – infrastructure provisioning
* **KQL (Kusto Query Language)** – detection rules
* **Azure Logic Apps** – SOAR playbooks
* **Sentinel Workbooks** – visualization and dashboards

---

## Setup & Deployment

1. Navigate to the [`terraform/`](./terraform) directory.
2. Configure variables in `terraform.tfvars` (subscription, resource group, workspace, etc.).
3. Run `terraform init && terraform apply` to provision Sentinel and connectors.
4. Import detection rules from [`detections/`](./detections) into Sentinel Analytics Rules.
5. Deploy playbooks from [`playbooks/`](./playbooks) into Logic Apps.
6. Open the workbook in Sentinel and customize for your environment.

---

## Artifacts

* **Terraform modules** – reproducible Sentinel deployment.
* **KQL detections** – custom analytics aligned with MITRE ATT\&CK.
* **SOAR playbooks** – automated workflows for credential leaks, ransomware, and OAuth abuse.
* **Executive dashboard** – sanitized screenshot showing incident metrics.

---

## Learning Outcomes

By completing this lab, I was able to:
* Deploy Microsoft Sentinel with Infrastructure-as-Code for repeatable provisioning.
* Write advanced KQL detections aligned to MITRE ATT&CK techniques.
* Automate SOC response workflows with Logic Apps playbooks.
* Build and present Sentinel workbooks to visualize incidents, compliance, and response metrics.
