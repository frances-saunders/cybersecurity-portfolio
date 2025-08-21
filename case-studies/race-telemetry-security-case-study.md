# Case Study: Race Telemetry Security Lab

## Problem / Challenge

In a motorsports environment, telemetry data from vehicles is both **mission-critical** and **highly sensitive**. The telemetry feeds provide real-time insights into engine performance, tire wear, fuel consumption, and driver behavior. However, the telemetry systems faced significant risks:

* **Unencrypted data streams** between trackside sensors, pit-wall systems, and cloud analytics created exposure to interception.
* **Flat network architecture** allowed lateral movement risk if a single endpoint was compromised.
* **Insufficient access controls** meant developers and engineers had more visibility than necessary.
* **No telemetry anomaly detection**, limiting ability to catch tampering or suspicious data injection.

The challenge was to build a **Zero Trust–aligned telemetry security model** that ensured confidentiality, integrity, and availability of racing telemetry, while still enabling real-time analytics required by engineering teams.

---

## Tools & Technologies

* **Azure Event Hubs + IoT Hub** – secure ingestion of telemetry data streams
* **Azure Private Link + NSGs** – network segmentation and private data channels
* **Azure Key Vault** – secure storage of API keys and credentials
* **Azure Monitor & Sentinel** – anomaly detection, alerting, and SIEM integration
* **Terraform** – infrastructure automation for repeatable deployment
* **Custom scripts (PowerShell, Bash, Python)** – telemetry ingestion and automated security responses

---

## Actions Taken

### Secure Data Ingestion

* Deployed **Azure IoT Hub / Event Hubs** with enforced TLS 1.2 for telemetry feeds.
* Integrated **Private Endpoints** to ensure ingestion only from trusted VNETs.
* Configured **role-based access control (RBAC)** so only telemetry services could push data.

### Network Segmentation

* Created separate subnets for **Telemetry Ingestion**, **Engineering Analytics**, and **General IT** zones.
* Applied **NSG rules** to restrict east-west traffic, reducing risk of lateral compromise.

### Key & Identity Management

* Migrated hardcoded credentials into **Azure Key Vault** with managed identity access.
* Enforced **least privilege**: only telemetry ingestion service had write access, analytics teams had read-only.

### Detection & Response

* Authored **KQL queries** in Sentinel to detect:

  * **Anomalous logons** to telemetry services.
  * **Unexpected spikes or drops** in telemetry data.
  * **Suspicious data injection attempts**.
* Built **SOAR playbooks** to auto-isolate compromised IoT devices and alert engineers in real time.

### Governance-as-Code

* All infrastructure (Event Hub, Key Vault, networking, Sentinel connectors) codified in **Terraform modules**.
* Automated deployment allowed identical DR/test environments to be built on demand.

---

## Results / Impact

* **End-to-end encryption enforced** for all telemetry streams.
* **Zero Trust segmentation** reduced lateral attack surface across telemetry, analytics, and IT networks.
* **Telemetry tampering detection** enabled real-time response to suspicious data patterns.
* **Credential exposure eliminated** by moving secrets into Key Vault.
* **RTO for telemetry services improved by 40%**, validated in failover tests.
* Increased **executive confidence** by showing real-time dashboards proving telemetry integrity during races.

---

## Artifacts

* **Terraform Modules** – deployment of IoT Hub, Event Hub, Key Vault, segmented networking.
* **Detection Queries** – Sentinel KQL rules for anomalous telemetry patterns.
* **SOAR Playbooks** – automated responses for compromised IoT devices or credential leaks.
* **Scripts** – ingestion simulators, enrichment scripts, automated failover validation.

---

## Key Takeaways

This project demonstrates my ability to secure **mission-critical telemetry pipelines** in a high-stakes environment. Specifically, I:

* Applied **Zero Trust principles** to IoT and telemetry.
* Protected sensitive racing data with **network isolation, encryption, and RBAC**.
* Designed **real-time detection and automated playbooks** to stop threats mid-race.
* Delivered governance-as-code for repeatability and auditability.

By operationalizing telemetry security, I ensured that race-day engineering decisions were based on **trusted, uncompromised data** — strengthening both competitive advantage and resilience.
