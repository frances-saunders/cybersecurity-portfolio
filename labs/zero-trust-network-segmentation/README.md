Perfect — thanks for sharing that example. Here’s the **Zero Trust Network Segmentation Lab README** rewritten to follow the exact same format and tone as your other labs (with Overview → Objectives → Directory Structure → Deployment Steps → Skills Demonstrated).

---

# Zero Trust Network Segmentation Lab

## Overview

This lab demonstrates how to apply **Zero Trust principles** in Azure through **network segmentation**, enforced with **Terraform**, **Azure Firewall**, **NSGs**, and **Private Endpoints**. It also integrates **Sentinel detections, playbooks, and workbooks** to monitor and enforce segmentation compliance.

The artifacts showcase how segmentation reduces lateral movement, prevents public exposure of sensitive services, and provides automated detection and remediation of violations.

---

## Lab Objectives

* Deploy **hub-and-spoke architecture** with Terraform.
* Configure **deny-by-default NSGs** with explicit allow rules.
* Centralize inspection with **Azure Firewall DNAT/SNAT rules**.
* Enforce **Private Endpoints** and **Service Endpoints** for sensitive services (e.g., SQL, Storage).
* Detect misconfigurations or violations (public endpoints, overly permissive NSGs).
* Automate remediation and escalation with **Sentinel playbooks**.
* Visualize segmentation posture with a **Sentinel workbook**.

---

## Directory Structure

```plaintext
labs/zero-trust-network-segmentation/
├── automation/
│   ├── auto-remediate-nsg.jsonc
│   ├── firewall-threat-intel-enrichment.jsonc
│   └── public-endpoint-alert.jsonc
│
├── kql/
│   ├── detect-nsg-non-compliant-subnets.kql
│   ├── detect-overly-permissive-nsg.kql
│   └── detect-public-endpoints.kql
│
├── policies/
│   ├── deny-public-subnet.json
│   ├── enforce-private-endpoints.json
│   ├── initiative.json
│   └── restrict-nsg-rules.json
│
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── policies.tf
│   ├── terraform.tfvars
│   └── variables.tf
│
├── workbook/
│   └── zero-trust-segmentation-overview.jsonc
│
└── README.md
```

---

## Deployment Steps

### 1. Terraform (Core Setup)

1. Navigate to `labs/zero-trust-network-segmentation/terraform/`.
2. Update `terraform.tfvars` with subscription details.
3. Run `terraform init`, `terraform plan`, and `terraform apply` to deploy:

   * Hub-and-spoke VNets with subnets.
   * NSGs (deny-by-default).
   * Azure Firewall with DNAT/SNAT.
   * Private Endpoints for SQL and Storage.

### 2. KQL Queries (Detection)

1. Navigate to `labs/zero-trust-network-segmentation/kql/`.
2. Import queries into Microsoft Sentinel:

   * `detect-public-endpoints.kql` – identifies public endpoints on sensitive services.
   * `detect-any-to-any-nsg.kql` – flags NSG rules with overly permissive traffic.
   * `detect-firewall-bypass.kql` – detects attempts to circumvent firewall inspection.

### 3. Automation (Playbooks)

1. Navigate to `labs/zero-trust-network-segmentation/automation/`.
2. Deploy playbooks as **Azure Logic Apps**:

   * `auto-remediate-nsg.jsonc` → Removes overly permissive NSG rules.
   * `escalate-violation.jsonc` → Notifies SOC via Teams and creates ServiceNow ticket.
   * `firewall-threat-intel-enrichment.jsonc` → Tags malicious IPs on Azure Firewall.

### 4. Workbook (Visualization)

1. Navigate to `labs/zero-trust-network-segmentation/workbooks/`.
2. Import `zero-trust-segmentation-overview.jsonc` into Sentinel Workbooks.
3. Verify visualization of:

   * Subnets enforcing deny-by-default.
   * Violations detected over time.
   * Sensitive services accessed via private vs public endpoints.

---

## Skills Demonstrated

* **Zero Trust Network Design** – hub-and-spoke topology with segmentation.
* **Terraform Automation** – IaC for networking, firewall, and private endpoints.
* **Threat Detection with Sentinel** – custom KQL rules for segmentation violations.
* **Incident Response Automation** – Logic Apps for remediation, escalation, enrichment.
* **Security Analytics** – workbooks for compliance, segmentation posture, and violation trends.
* **Portfolio Impact** – demonstrates ability to enforce **least privilege networking** and integrate detection, response, and visualization into a single Zero Trust workflow.

