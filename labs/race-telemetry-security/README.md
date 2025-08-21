# Race Telemetry Security Lab

## Overview

This lab demonstrates how to securely ingest **live race telemetry data** into Azure using **Event Hubs**, with storage in **Cosmos DB** and **Azure SQL Database**, all protected by **Key Vault–integrated secret management**. The lab also includes **Terraform infrastructure-as-code**, **secure CI/CD pipelines**, **KQL queries for monitoring anomalies**, and **Azure Policies** to enforce encryption.

The goal is to showcase how sensitive telemetry can be ingested, stored, and monitored securely in Azure while adhering to **Zero Trust principles** and DevSecOps practices.

---

## Lab Objectives

* Deploy a **telemetry ingestion architecture** with Event Hubs, Cosmos DB, and SQL Database.  
* Ingest live data streams securely, ensuring all pipelines are encrypted.  
* Use **Azure Key Vault** for secret storage (no plaintext in scripts or Terraform).  
* Demonstrate **Terraform IaC** with secure defaults.  
* Provide **CI/CD pipelines** (GitHub Actions + Azure DevOps) that pull secrets from Key Vault.  
* Create **KQL detection queries** for anomaly detection and dropped events.  
* Apply **Azure Policies** to enforce encryption and endpoint protection.  

---

## Directory Structure

```plaintext
labs/race-telemetry-security/
├── ci/
│   ├── azure-pipelines.yml             # Secure Azure DevOps pipeline
│   └── github-actions.yml              # Secure GitHub Actions workflow
│
├── keyvault/
│   └── keyvault-setup.tf               # Key Vault provisioning & secrets
|
├── kql/
│   ├── anomalous-ingestion-attempts.kql
│   └── dropped-events-trend.kql
│
├── pipelines/
│   └── telemetry-encrypted-pipeline.jsonc
│
├── policies/
│   └── enforce-encryption-eventhub.json
│
├── scripts/
│   ├── get-sql-password.ps1            # PowerShell – fetch secrets at runtime
│   └── get-sql-password.sh             # Bash – fetch secrets at runtime
|   ├── auto-isolate-iot-device.jsonc            
│   └── telemetry-anomaly-alert.jsonc
│
├── terraform/
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── variables.tf
│
└── README.md
````

---

## Deployment Steps

### 1. Terraform Infrastructure

1. Navigate to `terraform/` and run:

   ```bash
   terraform init
   terraform apply -auto-approve
   ```
2. Resources created:

   * Event Hub Namespace + Event Hub
   * Cosmos DB + SQL Database
   * VNet, Subnets, NSGs
   * Key Vault

---

### 2. Key Vault Setup

1. Navigate to `keyvault/` and run:

   ```bash
   terraform init
   terraform apply -auto-approve
   ```
2. This will:

   * Create a Key Vault
   * Add access policies for the deploying identity
   * Store secrets (`sql-admin-password`, `cosmos-primary-key`)

---

### 3. Scripts

* `scripts/get-sql-password.ps1` → retrieves SQL password from Key Vault for Windows-based automation.
* `scripts/get-sql-password.sh` → retrieves SQL password from Key Vault for Linux-based automation.

---

### 4. CI/CD Pipelines

* `ci/github-actions.yml` – Secure workflow with Key Vault integration for GitHub.
* `ci/azure-pipelines.yml` – Secure Azure DevOps pipeline using service connections.

Both pipelines demonstrate **runtime retrieval of secrets** with no secrets in source control.

---

### 5. Policies

* `policies/enforce-encryption-eventhub.json` ensures Event Hub messages are encrypted in transit and at rest.

---

### 6. KQL Queries

* `anomalous-ingestion-attempts.kql` – Detects suspicious ingestion attempts.
* `dropped-events-trend.kql` – Identifies telemetry data loss patterns.

---

## Tools & Technologies Used

* **Azure Event Hubs** – high-volume telemetry ingestion
* **Cosmos DB / SQL Database** – secure data persistence
* **Azure Key Vault** – centralized secret storage
* **Terraform** – infrastructure automation with secure defaults
* **Azure Policies** – enforce encryption and secure configs
* **KQL** – advanced telemetry anomaly detection
* **GitHub Actions & Azure DevOps** – secure CI/CD with Key Vault integration

---

## Skills Demonstrated

* **Cloud Security Architecture** – Secure telemetry ingestion pipeline.
* **DevSecOps** – CI/CD with secure secret management.
* **Infrastructure as Code (IaC)** – Automated, repeatable deployments.
* **Detection Engineering** – Custom KQL queries for anomaly detection.
* **Zero Trust Security** – No plaintext secrets, enforced encryption, secure data flows.
