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
├── terraform/                  # Terraform IaC for Sentinel + connectors
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── detections/                 # KQL detection rules
│   ├── lateral-movement.kql
│   ├── privilege-escalation.kql
│   └── anomalous-logons.kql
│
├── playbooks/                  # SOAR playbooks (JSONC format)
│   ├── credential-leak-playbook.jsonc
│   ├── ransomware-isolation-playbook.jsonc
│   └── oauth-app-playbook.jsonc
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
