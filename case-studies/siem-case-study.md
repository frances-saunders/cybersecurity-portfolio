# Case Study: Enterprise SIEM Modernization & Threat Detection Enhancement

## Problem / Challenge

The enterprise SIEM solution was underperforming in both detection coverage and cost efficiency:

* **Siloed log sources** across Azure, AWS, and on-prem infrastructure led to blind spots.
* Alert fatigue overwhelmed analysts — **false positives consumed 70% of SOC effort**.
* No standardized correlation rules, leaving critical attack paths undetected.
* Executive stakeholders lacked clear visibility into SOC performance and business risk.
* Licensing costs were escalating without proportional security value.

The challenge was to **modernize SIEM capabilities, optimize cost, and establish executive-level threat visibility** while improving SOC analyst efficiency.

---

## Tools & Technologies

* **Microsoft Sentinel** (Azure-native SIEM) with Log Analytics
* **Splunk (Legacy SIEM)** – migrated use cases to Sentinel
* **Defender for Cloud / 365** – telemetry integration
* **Threat Intelligence Feeds** – MISP, Recorded Future
* **Terraform & KQL (Kusto Query Language)** – infrastructure-as-code for Sentinel setup and detection engineering
* **Power BI** – executive dashboards aligned to risk and MITRE ATT\&CK coverage

---

## Actions Taken

### 1. SIEM Strategy & Migration

* Conducted a **SIEM maturity assessment** across all business units.
* Designed a **hybrid ingestion strategy**, integrating **cloud (Azure, AWS, GCP), on-prem firewalls, EDR, and SaaS apps** into Sentinel.
* Migrated high-value Splunk detections to Sentinel with cost-optimized data ingestion rules.

### 2. Threat Detection Engineering

* Authored **50+ advanced KQL analytics rules** covering:

  * Lateral movement (e.g., Kerberos ticket abuse, pass-the-hash).
  * Cloud privilege escalation attempts.
  * Supply chain risks (OAuth app abuse, anomalous API activity).
* Implemented **fusion rules and UEBA** to correlate identity anomalies with endpoint + network telemetry.
* Tuned rules to cut **false positives by 45%**, improving SOC focus on high-fidelity alerts.

### 3. Automation & Response

* Built **SOAR playbooks** with Logic Apps to auto-respond to common incidents:

  * **Credential leak detection → Force password reset + conditional access block.**
  * **Suspicious OAuth app → Auto-disable + notify app owner.**
  * **Ransomware IOC detected → Isolate endpoint in Defender.**
* Reduced **MTTR (Mean Time to Respond) by 60%** through automation.

### 4. Executive Visibility & Risk Reporting

* Designed **Power BI dashboards** mapping alerts and incidents to:

  * **MITRE ATT\&CK tactics & techniques**.
  * **Business risk categories** (e.g., IP theft, ransomware, insider threat).
* Delivered **quarterly board-level reports** showing measurable risk reduction tied to SIEM investment.

### 5. Governance & Continuous Improvement

* Established a **detection engineering lifecycle** — version-controlled rules, peer reviews, and purple team validation.
* Embedded **threat intelligence enrichment** for prioritization.
* Optimized ingestion by tiering data into **hot/cold retention**, cutting annual SIEM spend by 30%.

---

## Results / Impact

* **Expanded visibility** across 100% of enterprise infrastructure (cloud + on-prem).
* Reduced **false positives by 45%**, saving 1,200+ analyst hours annually.
* Cut **MTTR by 60%** through automated playbooks.
* **30% cost reduction** in SIEM licensing via ingestion optimization.
* Provided executives with **risk-aligned dashboards**, bridging the gap between SOC metrics and business impact.
* Established a **scalable SIEM governance model** that is repeatable for future business acquisitions.

---

## Artifacts

* **Terraform Modules** – Sentinel provisioning with data connectors and workbooks.
* **Sample KQL Analytics Rules** – high-fidelity correlation queries for lateral movement and privilege escalation.
* **SOAR Playbooks** – Logic Apps automation for ransomware, credential leaks, and OAuth risk.
* **Executive Dashboard (Power BI)** – sanitized example mapping MITRE coverage to business risk.

---

## Key Takeaways

This project demonstrates my ability to deliver **executive-level SIEM modernization** by combining **technical depth in detection engineering** with **strategic risk communication to leadership**.

Through modernization, automation, and governance-as-code, I achieved:

* A **resilient, scalable, and cost-optimized SIEM**.
* A **SOC empowered to focus on real threats instead of noise**.
* A **leadership narrative that translated security telemetry into measurable business risk reduction**.

This case highlights my expertise in **SIEM transformation at enterprise scale** — uniting detection engineering, SOAR automation, and executive reporting into a cohesive security operations strategy.
