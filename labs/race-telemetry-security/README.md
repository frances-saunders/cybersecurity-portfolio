# Race Telemetry Security Lab

## Overview

This lab demonstrates how to secure **race telemetry systems** by protecting the ingestion, processing, and storage of high-frequency car sensor data.  
The pipeline is recreated using **Azure Event Hubs**, **encrypted SaaS analytics pipelines**, and **Azure Storage** — with layered security controls to enforce confidentiality, integrity, and availability.

The artifacts showcase how to build a Zero Trust data streaming architecture suitable for motorsports environments where **low latency, high throughput, and strict data protection** are mission critical.

---

## Lab Objectives

* Deploy an **Event Hubs namespace** with **private endpoints** for secure telemetry ingestion.  
* Enforce **Azure Policy** to require encryption in transit and at rest.  
* Integrate **Azure Key Vault** for key management across Event Hubs and Storage.  
* Implement **NSG and Firewall rules** to isolate telemetry flows from external networks.  
* Secure an **Azure Data Explorer (ADX) / SaaS analytics pipeline** with **managed identities** and **encrypted pipelines**.  
* Enable **diagnostic logs** for auditing and detection of anomalous telemetry ingestion.  
* Build a **Sentinel workbook** to monitor ingestion volume, dropped events, and anomalous sources.  

---

## Directory Structure

```plaintext
labs/race-telemetry-security/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
│
├── policies/
│   └── enforce-encryption-eventhubs.json
│
├── pipelines/
│   └── telemetry-encrypted-pipeline.yml
│
├── kql/
│   ├── anomalous-ingestion-attempts.kql
│   └── dropped-events-trend.kql
│
└── workbooks/
    └── telemetry-security-overview.jsonc
````

---

## Deployment Steps

### 1. Infrastructure (Terraform)

Deploy the Event Hubs namespace, VNet, subnets, private endpoints, and storage accounts via `terraform/`.
All resources are encrypted with **customer-managed keys** from Key Vault.

### 2. Policy Enforcement

Apply the policy in `policies/enforce-encryption-eventhubs.json` to ensure telemetry ingestion is **always encrypted at rest and in transit**.
Any attempt to deploy insecure Event Hub namespaces will be denied.

### 3. Secure Pipeline

Use the `pipelines/telemetry-encrypted-pipeline.yml` definition to simulate a SaaS analytics pipeline:

* Secrets retrieved dynamically from **Key Vault**.
* Telemetry streamed from Event Hub → Analytics → Storage.
* Encryption enforced for every hop.

### 4. Monitoring

Deploy the workbook in `workbooks/telemetry-security-overview.jsonc` to Microsoft Sentinel.
It visualizes telemetry flow, anomalous sources, and dropped events.

Run the detection queries in `kql/` to identify:

* Suspicious ingestion attempts from unauthorized IPs.
* Unusual drops in event throughput (potential DoS or misconfig).

---

## Skills Demonstrated

* **Event-Driven Security** – protecting high-volume telemetry with Event Hubs and Azure Policy.
* **Key Management** – enforcing customer-managed keys and secretless pipelines with Key Vault.
* **Zero Trust Networking** – private endpoints, NSGs, and firewall isolation.
* **DevSecOps Integration** – secure SaaS pipelines with managed identities and YAML-based definitions.
* **Threat Detection & Monitoring** – Sentinel KQL queries and workbooks for real-time telemetry security.
* **Portfolio Impact** – demonstrates ability to secure **mission-critical, latency-sensitive telemetry systems**, bridging motorsports operations and enterprise security engineering.

```
