# CI/CD Pipeline Hardening Lab

## Overview

This lab demonstrates how to secure CI/CD pipelines in **GitHub** and **Azure DevOps** through a Zero Trust approach.  
It includes sanitized RBAC configurations, secure secret management flows, repository protection policies,  
Terraform-based guardrails, and Sentinel KQL detections for anomalous pipeline activity.

The artifacts reflect real-world DevSecOps practices for protecting source code, pipelines, and build infrastructure from insider threats, supply chain attacks, and misconfigurations.

---

## Lab Objectives

* Implement **least privilege RBAC** for GitHub and Azure DevOps.
* Integrate **Azure Key Vault** for secure secret handling in pipelines.
* Enforce **branch protections** and signed commits.
* Deploy **Terraform guardrails** to block insecure pipeline patterns.
* Create **KQL detections** for anomalous pipeline activity in Sentinel.
* Showcase end-to-end **CI/CD hardening** that meets compliance and enterprise security standards.

---

## Directory Structure

```plaintext
labs/cicd-pipeline-hardening/
├── rbac/
│   └── github-ado-rbac.json
│
├── pipelines/
│   └── azure-pipelines-with-keyvault.yml
│
├── repo-protection/
│   └── branch-protection.json
│
├── policies/
│   └── ci-cd-guardrails.tf
│
├── kql/
│   └── anomalous-pipeline-activity.kql
│
└── README.md
````

---

## Deployment Steps

### 1. RBAC

Review `rbac/github-ado-rbac.json` to understand **role mappings** between GitHub and Azure DevOps.
Apply least privilege by ensuring developers, reviewers, and release managers only hold the permissions they need.

### 2. Pipelines

Deploy the sample pipeline in `pipelines/azure-pipelines-with-keyvault.yml`.
This integrates **Azure Key Vault** secrets into runtime builds, preventing hardcoded credentials.

### 3. Repository Protections

Import `repo-protection/branch-protection.json` to enforce **branch security**:

* Require signed commits.
* Block force pushes.
* Require status checks for every PR (e.g., CodeQL, dependency scanning).

### 4. Policies

Use `policies/ci-cd-guardrails.tf` to enforce compliance:

* Deny pipelines with inline secrets.
* Require pipeline logs be exported to Log Analytics.

### 5. Monitoring

Deploy the KQL detection in `kql/anomalous-pipeline-activity.kql` to Sentinel.
It detects unusual pipeline runs (e.g., after-hours or by unexpected identities).

---

## Skills Demonstrated

* **DevSecOps Security Engineering** – CI/CD hardening across GitHub and Azure DevOps.
* **Infrastructure as Code (Terraform)** – codified guardrails for pipelines.
* **Secret Management** – secure flows with Azure Key Vault.
* **Supply Chain Protection** – enforcing signed commits, reviews, and dependency scans.
* **Threat Detection** – custom Sentinel queries for anomalous pipeline activity.
* **Portfolio Impact** – demonstrates how to secure build systems against insider threats and supply chain attacks while aligning with compliance benchmarks (NIST, CIS, ISO 27001).
