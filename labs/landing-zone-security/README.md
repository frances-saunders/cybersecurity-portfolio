# Landing Zone Baseline in Azure

## Overview

This lab demonstrates how to implement a **Landing Zone Baseline** in Azure using Azure Policy and Terraform. The baseline enforces consistent governance across subscriptions, including **naming standards, required tags, region restrictions, and SKU controls**.

The goal is to prevent configuration drift, ensure audit readiness, and align cloud resources with compliance and financial accountability requirements.

---

## Lab Objectives

By completing this lab, you will:

* Author and deploy Azure Policy **definitions** for naming, tagging, region, and SKU enforcement.
* Group policies into a **Landing Zone Baseline initiative** for centralized control.
* Create a **Landing Zone Baseline assignment** applied via Terraform.
* Provision compliant landing zones using **Infrastructure as Code (IaC)**.
* Validate enforcement through Microsoft Defender for Cloud and compliance dashboards.

---

## Prerequisites

* Azure subscription with Contributor and Policy Contributor roles.
* Azure CLI installed and authenticated.
* Terraform installed (v1.5+ recommended).
* Access to Microsoft Defender for Cloud for compliance scoring.

---

## Lab Structure

```plaintext
labs/landing-zone-baseline/
├── policies/
│   ├── definitions/
│   │   ├── enforce-naming.jsonc
│   │   ├── require-tags.jsonc
│   │   ├── restrict-regions.jsonc
│   │   └── restrict-skus.jsonc
│   ├── initiatives/
│   │   └── landing-zone-baseline-initiative.jsonc
│   └── assignments/
│       └── landing-zone-baseline-assignment.jsonc
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars
```

---

## Steps

### 1. Deploy Policy Definitions

Navigate to `policies/definitions` and deploy each JSONC policy definition:

```bash
az policy definition create --name enforce-naming --rules enforce-naming.jsonc
az policy definition create --name require-tags --rules require-tags.jsonc
az policy definition create --name restrict-regions --rules restrict-regions.jsonc
az policy definition create --name restrict-skus --rules restrict-skus.jsonc
```

### 2. Deploy Initiative

Navigate to `policies/initiatives` and deploy the **Landing Zone Baseline initiative**:

```bash
az policy set-definition create \
  --name landing-zone-baseline-initiative \
  --definitions landing-zone-baseline-initiative.jsonc
```

### 3. Deploy Assignment (Terraform-Integrated)

Navigate to `policies/assignments` and deploy the **Landing Zone Baseline assignment**:

```bash
az policy assignment create \
  --name landing-zone-baseline-assignment \
  --policy-set-definition landing-zone-baseline-initiative.jsonc \
  --params assignment-parameters.json
```

Or apply via Terraform in the `terraform/` directory:

```bash
terraform init
terraform apply
```

### 4. Validate Enforcement

* Deploy test resources with invalid names, missing tags, or unapproved SKUs/regions.
* Confirm they are denied or flagged.
* Check compliance results in Microsoft Defender for Cloud.

---

## Expected Outcomes

* Resources must comply with enforced naming, tagging, region, and SKU policies.
* Non-compliant deployments are denied or audited depending on assignment configuration.
* Compliance scores improve in Microsoft Defender for Cloud.
* Landing zone deployments become repeatable, auditable, and drift-resistant.

---

## Key Takeaways

This lab demonstrates how to use **Azure Policy and Terraform** to implement a **Landing Zone Baseline** that enforces governance at scale. With policy-driven controls applied automatically during provisioning, environments remain consistent, compliant, and ready for audit.

