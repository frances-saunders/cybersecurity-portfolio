# README.md

# Zero Trust Network Segmentation Lab

## Overview
This lab demonstrates how to design, deploy, and enforce **Zero Trust network segmentation** in Azure using Terraform, Azure Firewall, Network Security Groups (NSGs), and Private Endpoints. The goal is to show how segmentation can minimize lateral movement and protect sensitive workloads, even if an attacker breaches the environment.
---
## Lab Goals
- Deploy hub-and-spoke architecture with Terraform.
- Configure **NSGs** with deny-by-default and explicit allow rules.
- Deploy **Azure Firewall** for central traffic inspection and control.
- Enforce **Private Endpoints** and **Service Endpoints** for sensitive services.
- Detect segmentation violations with KQL queries in Microsoft Sentinel.
- Automate remediation, escalation, and enrichment using Sentinel playbooks.
- Visualize compliance and network security posture in a Sentinel Workbook.
---
## Lab Structure
```

labs/
zero-trust-network-segmentation/
terraform/       # Terraform scripts for core deployment
kql/             # Detection queries
workbook/        # Sentinel workbook JSON
automation/      # Sentinel response playbooks
README.md        # Lab instructions and overview
CASE\_STUDY.md    # Business-oriented case study

```
---
## Tools & Technologies
- Terraform  
- Azure Firewall  
- Network Security Groups (NSGs)  
- Azure Private Endpoints + Service Endpoints  
- Microsoft Sentinel (KQL, Playbooks, Workbooks)
---
## Deployment Steps
1. Navigate to `terraform/` and update `terraform.tfvars` with your subscription details.  
2. Run `terraform init`, `terraform plan`, and `terraform apply` to provision hub, spokes, firewall, and NSGs.  
3. Deploy KQL queries in `kql/` into Microsoft Sentinel.  
4. Import automation playbooks in `automation/` to enable incident response.  
5. Import the workbook in `workbook/` to visualize compliance and segmentation posture.  
---
## Learning Outcomes
By completing this lab, you will:
- Understand Zero Trust segmentation in cloud-native environments.  
- Apply **least privilege networking** using NSGs and firewall rules.  
- Integrate **policy enforcement**, **detection**, and **automation** into a single workflow.  
- Demonstrate practical expertise in balancing security, usability, and governance.

