# SDLC Security Lab

## Overview

This lab demonstrates how **security was embedded across the Software Development Lifecycle (SDLC)** using cloud-native tooling and automation. It highlights how security guardrails, secret management, and compliance validation were integrated directly into developer workflows to ensure **“shift-left” security** without slowing down delivery velocity.

The focus was on building a **repeatable, enterprise-ready model** where every code commit, infrastructure change, and deployment was automatically validated against cloud security policies and compliance standards.

---

## Problem / Challenge

Large organizations face significant challenges when securing the SDLC:

* **Policy Drift** – developers unintentionally provisioning resources with insecure defaults (e.g., public IPs, unencrypted storage).
* **Manual Secret Handling** – sensitive credentials being embedded in pipelines or code, increasing risk of leaks.
* **Lack of Visibility** – no centralized dashboards showing compliance state across environments.
* **Slow Remediation Cycles** – security feedback arriving late in production instead of early in the pipeline.

The challenge was to deliver **frictionless security controls** that worked across CI/CD pipelines, infrastructure deployments, and cloud-native services.

---

## Tools & Technologies

* **Azure DevOps Pipelines (YAML)** – secure CI/CD automation
* **Azure Policy** – enterprise guardrails for cloud compliance
* **Terraform** – policy-as-code modules and IAM hardening
* **Azure Key Vault** – centralized secret storage and pipeline integration
* **Azure Workbooks (Dashboards)** – real-time compliance and drift monitoring

---

## Actions Taken

### 1. Policy-as-Code Guardrails

* Authored **Terraform modules** to enforce **IAM baselines, NSG restrictions, encryption requirements, and approved SKUs**.
* Applied Azure Policy **deny effects** for high-risk misconfigurations (e.g., public IP exposure).
* Created modular policy initiatives aligned with **CIS** and **NIST 800-53**.

### 2. Secure CI/CD Pipelines

* Developed reusable **pipeline templates** with embedded:

  * Infrastructure-as-Code scanning
  * Container image scanning
  * Compliance validation checks
* Integrated **Azure Key Vault** into pipelines to eliminate plaintext secrets.
* Implemented **scripted Key Vault retrieval** (YAML + Bash) for cross-platform compatibility.

### 3. Compliance Dashboards

* Built **Azure Workbook dashboards** to visualize compliance drift.
* Added focused visualization on **encryption enforcement**, tracking real-time adoption of storage encryption controls.
* Enabled developer-friendly reporting to give engineers direct visibility into compliance gaps.

---

## Results / Impact

* **Zero plaintext secrets** in pipelines – all credentials securely retrieved from Key Vault.
* **Automated security validation** at every stage of the SDLC – preventing misconfigurations before production.
* **Reduced compliance drift by 70%**, as shown in Azure Workbook dashboards.
* **Improved developer confidence** by embedding security feedback directly into CI/CD workflows.
* Established a **repeatable enterprise model** for secure DevSecOps pipelines.

---

## Lab Directory Structure

```plaintext
labs/sdlc-security/
├── README.md
├── pipelines/
│   ├── secure-pipeline-template.yml
│   └── keyvault-integration.yml
├── policies/
│   └── deny-public-ip.jsonc
├── terraform/
│   └── iam-baseline.tf
├── scripts/
│   └── keyvault-integration.sh
└── dashboards/
    ├── compliance-drift.jsonc
    └── encryption-compliance.jsonc
```

---

## Artifacts

* **Terraform Modules** – [`terraform/iam-baseline.tf`](./terraform/iam-baseline.tf)
* **Pipeline Templates** – [`pipelines/secure-pipeline-template.yml`](./pipelines/secure-pipeline-template.yml), [`pipelines/keyvault-integration.yml`](./pipelines/keyvault-integration.yml)
* **Azure Policy Definitions** – [`policies/deny-public-ip.jsonc`](./policies/deny-public-ip.jsonc)
* **Key Vault Integration Scripts** – [`scripts/keyvault-integration.sh`](./scripts/keyvault-integration.sh)
* **Dashboards** – [`dashboards/compliance-drift.jsonc`](./dashboards/compliance-drift.jsonc), [`dashboards/encryption-compliance.jsonc`](./dashboards/encryption-compliance.jsonc)

---

## Key Takeaways

This project demonstrates my ability to deliver **enterprise-grade SDLC security** by:

* Embedding **policy-as-code guardrails** into infrastructure deployments.
* Building **secure, reusable CI/CD pipelines** that integrate with **Key Vault**.
* Delivering **real-time compliance dashboards** for both developers and executives.
* Enabling **DevSecOps at scale**, where security becomes a continuous, automated process.

The lab showcases how security can be **baked into every stage of the SDLC** without slowing delivery, reinforcing resilience and compliance across the enterprise.
