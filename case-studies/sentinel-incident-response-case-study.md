# Case Study: Sentinel Incident Response in Azure

## Problem / Challenge

Security Operations Centers (SOCs) face major challenges when handling alerts at scale in Microsoft Sentinel. Common issues include:

* **Excessive false positives** that waste analyst time.
* **Delayed response** to high-severity incidents due to manual triage.
* **Lack of enrichment** for alerts, forcing analysts to pivot across tools.
* **Limited visibility** into automation effectiveness and SOC performance.

These challenges increase attacker dwell time, reduce analyst efficiency, and leave organizations at greater risk. A solution was needed to demonstrate **automated, measurable, and repeatable incident response workflows** in Sentinel.

---

## Tools & Technologies
Microsoft Sentinel, KQL, Logic Apps (Playbooks), Terraform, Azure Workbooks

---

## Actions Taken

### Detection Engineering (KQL Rules)

I authored custom Sentinel analytics rules using KQL queries:

* **Defender Alerts** – surfaced endpoint and cloud alerts in Sentinel.
* **Impossible Travel** – detected risky logins from geographically improbable locations.
* **Suspicious Sign-ins** – highlighted anomalous authentication activity.

### Automation Playbooks (Logic Apps)

I developed playbooks to streamline incident handling:

* **Auto-Close False Positives** – reduced noise by closing known benign alerts.
* **Auto-Respond to High-Severity Incidents** – escalated, notified, and applied containment steps automatically.
* **Enrich with Threat Intelligence** – pulled context from TI feeds for faster triage.

### Workbook Development

I created a Sentinel workbook that provided SOC visibility into:

* Incident volumes by severity and type.
* Automation effectiveness (auto-closed vs. manual incidents).
* Enrichment coverage from threat intelligence.
* Mean Time to Close (MTTC) trends.

### Infrastructure as Code (Terraform)

Using Terraform, I automated the Sentinel deployment:

* Provisioned Sentinel and linked to a Log Analytics workspace.
* Deployed analytics rules and playbooks consistently.
* Managed parameters for environment-specific flexibility.

---

## Results / Impact

* **Reduced alert fatigue** by automatically closing false positives.
* **Accelerated SOC response** to critical incidents with automated containment.
* **Improved investigation speed** through integrated threat intelligence enrichment.
* **Delivered visibility** into SOC efficiency with real-time dashboards.
* Established a **repeatable IaC-driven model** for deploying Sentinel controls.

---

## Artifacts

**Analytics Rules (KQL)**

* Defender Alerts
* Impossible Travel
* Suspicious Sign-ins

**Automation Playbooks (Logic Apps)**

* Auto-Close False Positives
* Auto-Respond to High-Severity Incidents
* Enrich with Threat Intelligence

**Workbook**

* Incident Response Overview Workbook

**Terraform**

* IaC for Sentinel deployment, analytics rules, and playbook automation

---

## Key Takeaways

This project highlights my ability to:

* Build **detection engineering rules with KQL**.
* Automate SOC workflows with **Logic Apps playbooks**.
* Visualize operations with **Sentinel workbooks**.
* Use **Terraform IaC** to deliver repeatable, scalable security infrastructure.

The end result was a **fully automated, measurable, and auditable incident response framework** that transforms Sentinel from a monitoring tool into a **proactive SOC platform aligned with NIST 800-61 and MITRE ATT\&CK**.
