# Case Study: Monitoring Integration for Threat Visibility and Incident Response

## Problem / Challenge

The enterprise’s existing security posture relied heavily on **cloud-native telemetry** (Microsoft Sentinel, Defender for Cloud, and Azure-native logs). While effective, this created **blind spots** in visibility:

* On-premises monitoring via **Zabbix** was not integrated into the SIEM.
* Critical system alerts (CPU anomalies, service failures, network spikes) were siloed in Zabbix without correlation to threat intelligence.
* Incident responders had no unified dashboard, slowing mean-time-to-detect (MTTD) and mean-time-to-respond (MTTR).
* Executives lacked **end-to-end visibility** across hybrid workloads.

The challenge was to integrate **Zabbix monitoring telemetry into Sentinel** to unify alerts, enable correlation with threat intelligence, and improve incident response.

---

## Tools & Technologies

* **Microsoft Sentinel** – cloud-native SIEM and SOAR
* **Zabbix Monitoring** – on-premises and hybrid workload monitoring
* **Terraform** – automated deployment of data connectors and analytics rules
* **KQL (Kusto Query Language)** – parsing and correlation queries
* **PowerShell** – custom ingestion connector for Zabbix → Sentinel
* **Workbooks** – executive dashboards with MTTD/MTTR metrics

---

## Actions Taken

### 1. Integration of Zabbix with Sentinel

* Authored a **custom PowerShell ingestion connector** that parsed Zabbix alerts into Sentinel via Log Analytics API.
* Built a **KQL parser** to normalize alert formats, including system events, performance anomalies, and service downtime alerts.
* Extended Terraform modules to provision the **data connector pipeline** and related Sentinel analytic rules.

### 2. Correlation with Threat Intelligence

* Designed **KQL correlation rules** to enrich Zabbix alerts with threat intel (IP reputation, MITRE ATT\&CK mapping).
* Flagged Zabbix anomalies (e.g., unexpected CPU spikes) when aligned with known attack techniques.

### 3. Dashboards and Reporting

* Developed **Sentinel Workbooks** that visualized:

  * Hybrid alert sources (cloud + Zabbix)
  * Incident timelines and root cause correlation
  * Executive KPIs (MTTD, MTTR, incident volume trends)
* Provided real-time drilldowns for analysts while maintaining **executive summary dashboards**.

### 4. Incident Response Automation

* Configured **SOAR playbooks** to trigger when Zabbix alerts crossed severity thresholds.
* Automated responses included notifying SOC teams, creating incident tickets, and launching investigation queries.
* Integrated alert-to-ticket pipelines to reduce manual handoffs.

---

## Results / Impact

* **Unified Visibility** – Zabbix alerts were integrated into Sentinel, eliminating hybrid blind spots.
* **Improved MTTD/MTTR** – automation and correlation reduced detection and response times by \~40%.
* **Threat Intelligence Alignment** – enriched Zabbix data provided context for attacks leveraging system-level anomalies.
* **Executive Confidence** – dashboards delivered clear, real-time visibility into incident trends and resilience metrics.
* **Scalability** – Terraform-based automation enabled repeatable deployment across multiple business units.

---

## Artifacts

* **Terraform Modules** – automated provisioning of connectors and Sentinel rules
* **PowerShell Connector** – custom Zabbix → Sentinel ingestion script
* **KQL Parser** – normalizing Zabbix alerts for Sentinel queries
* **Workbooks** – executive dashboards (JSONc) for visibility metrics
* **SOAR Playbooks** – automated incident response workflows

---

## Key Takeaways

This project demonstrates my ability to:

* Design **hybrid SIEM integrations** that unify monitoring across cloud and on-premises.
* Use **Terraform and automation** to scale SIEM integrations consistently across the enterprise.
* Author **advanced KQL correlation rules** and align them to threat intelligence frameworks.
* Deliver **executive-ready dashboards** that translate technical data into business impact.
* Operationalize **SOAR playbooks** to accelerate response and reduce risk.

The monitoring integration initiative transformed security visibility from fragmented to **enterprise-wide**, strengthening both tactical SOC operations and executive-level decision making.
