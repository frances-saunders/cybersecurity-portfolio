# Monitoring & Incident Response Integration Lab

## Overview

This lab demonstrates how I engineered a **simulation of Zabbix monitoring integrated with SIEM (Azure Sentinel)** to provide **end-to-end visibility, automated correlation, and incident response capabilities**.

The scenario highlights how monitoring telemetry can be **enriched and correlated with security events**, allowing faster threat detection and reduced mean time to response (MTTR).

---

## Problem / Challenge

Enterprises often suffer from **fragmented monitoring**:

* IT Ops teams use Zabbix for infrastructure monitoring.
* Security teams rely on SIEMs like Sentinel for cyber defense.
* Alerts lack **context** when not shared between systems.
* Security teams waste time triaging performance issues vs. genuine threats.

The challenge was to **integrate Zabbix monitoring with Sentinel** to:

* Centralize visibility into infrastructure + security events.
* Automate enrichment of Sentinel incidents with Zabbix data.
* Demonstrate measurable MTTR reduction in a simulated ransomware attack and system outage.

---

## Tools & Technologies

* **Zabbix** – open-source infrastructure monitoring (Linux agents, SNMP traps, triggers).
* **Azure Sentinel** – SIEM/SOAR platform for alert correlation & incident response.
* **Azure Log Analytics** – data ingestion pipeline for Zabbix alerts.
* **Custom Scripts (Python, Bash)** – event forwarding & enrichment.
* **Power Automate / Sentinel Playbooks** – automated response actions.

---

## Actions Taken

### Zabbix → Sentinel Integration

* Configured Zabbix to forward **trigger alerts via webhook** → Azure Function.
* Azure Function transformed alert payloads into **Log Analytics custom logs** (`Zabbix_Events_CL`).
* Sentinel ingested Zabbix alerts and mapped them to **MITRE ATT\&CK techniques** (e.g., `T1499 – Endpoint Denial of Service`).

### Alert Correlation Rules

* Authored **KQL analytics rules** in Sentinel to correlate:

  * **Zabbix CPU/memory spikes** + **unusual logon activity** = potential malware execution.
  * **Network device down** + **failed VPN logins** = possible DoS or network intrusion.

### SOAR Playbooks

* **Auto-Isolate Host** – If Zabbix detects CPU pegged at 100% and Sentinel sees abnormal PowerShell execution, trigger an **Azure Automation runbook** to quarantine VM.
* **Tiered Notification** – Forward correlated incidents to **Ops + Security Teams in MS Teams** channels with enriched context.

### Simulation Scenarios

* **Ransomware Drill**:

  * Zabbix detects abnormal disk I/O and high CPU on endpoints.
  * Sentinel correlates with Windows Security Logs → suspicious encryption pattern.
  * Automated playbook isolated the endpoint, notified IR team, and enriched incident ticket.

* **Network Device Outage**:

  * Zabbix detects switch down via SNMP.
  * Sentinel correlates with multiple failed VPN logins from that region.
  * Incident escalated to Tier-2 security, auto-created in ServiceNow via API.

---

## Results / Impact

* **Reduced MTTR by \~45%** through automated enrichment and SOAR playbooks.
* **Improved signal-to-noise ratio** – security team only received alerts when infrastructure + security signals correlated.
* **Enhanced cross-team visibility** – Ops + Security teams shared the same dashboard for incidents.
* **Validated resilience** through tabletop exercises simulating ransomware and outages.

---

## Artifacts

* **Integration Script** – `zabbix-sentinel-forwarder.py` (Python webhook handler).
* **Terraform Modules** – deploy Log Analytics + Sentinel workspace.
* **Analytics Rule** – `correlated-zabbix-anomalies.kql`.
* **SOAR Playbooks** – JSONC workflows for auto-isolation and enriched notifications.
* **Sample Incident Report** – shows before/after MTTR improvements.

---

## Key Takeaways

This project demonstrates my ability to:

* Design and implement **cross-platform monitoring integrations** at enterprise scale.
* Leverage **automation and correlation** to reduce alert fatigue.
* Translate monitoring data into **actionable security incidents**.
* Drive measurable improvements in **incident response maturity**.

By simulating this integration, I demonstrated how **Zabbix monitoring can be elevated from IT ops tool to a critical cybersecurity signal**, strengthening enterprise resilience.
