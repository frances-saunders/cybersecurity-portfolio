# Continuous Compliance & Audit Readiness Lab

## Overview

This lab demonstrates how to achieve **continuous compliance** in cloud environments by embedding compliance-as-code, real-time dashboards, and automated evidence collection.  

The lab aligns with major frameworks including **NIST 800-53**, **CIS Benchmarks**, and **SOC 2 Trust Principles**.  

---

## Lab Structure

```
labs/continuous-compliance/
│
├── terraform/ # Compliance-as-Code policies
│ ├── main.tf
│ ├── variables.tf
│ ├── outputs.tf
│ └── terraform.tfvars
│
├── dashboards/ # Compliance visualization workbooks
│ ├── nist-compliance-workbook.json
│ ├── cis-compliance-workbook.json
│ └── soc2-compliance-workbook.json
│
├── checklists/ # Audit preparation materials
│ ├── nist-audit-checklist.md
│ ├── cis-audit-checklist.md
│ └── soc2-audit-checklist.md
│
├── scripts/ # Evidence collection automation
│ ├── collect-nist-evidence.ps1
│ ├── collect-cis-evidence.sh
│ └── package-audit-evidence.ps1
│
└── README.md
```


---

## Tools & Technologies

* **Terraform** – Compliance-as-code policy deployment.  
* **Azure Policy / AWS Config / GCP Config Validator** – Control enforcement.  
* **PowerShell & Bash** – Evidence automation.  
* **Workbooks & Dashboards** – Executive compliance visualization.  
* **NIST, CIS, SOC 2** – Mapped control frameworks.  

---

## Setup & Deployment

1. Navigate to the `terraform/` directory.  
2. Configure variables in `terraform.tfvars` (subscription, org, resource groups, etc.).  
3. Run `terraform init && terraform apply` to deploy baseline compliance policies.  
4. Import JSON workbook templates into your cloud-native dashboard service.  
5. Run evidence collection scripts before an audit to generate packaged artifacts.  

---

## Artifacts

* **Terraform Policies** – Enforce encryption, deny public access, require monitoring.  
* **Dashboards** – NIST, CIS, SOC 2 compliance visualization.  
* **Audit Checklists** – Evidence mapping by framework.  
* **Automation Scripts** – Rapid evidence collection for audit readiness.  

---

## Learning Outcomes

By completing this lab, I was able to:

* Engineer compliance-as-code for automated assurance.  
* Align cloud controls to regulatory frameworks.  
* Build executive-ready dashboards for compliance visibility.  
* Automate evidence collection for audit readiness.  
