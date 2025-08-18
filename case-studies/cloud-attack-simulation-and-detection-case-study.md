# Case Study: Cloud Attack Simulation & Detection in Azure

## Problem / Challenge

Cloud environments are a prime target for adversaries. While tools like Microsoft Sentinel and Defender for Cloud offer strong monitoring, organizations often fall short in **simulating real-world attacks** and validating that:

* Detections trigger as expected.
* Automation accelerates incident response.
* SOC analysts have the right enrichment data to make fast decisions.

Without proactive simulations, teams risk **blind spots** in impossible travel sign-ins, brute-force logins, and malicious container activity. Leadership identified the need for a **repeatable attack simulation and detection framework** to validate defenses and demonstrate SOC effectiveness.

---

## Tools & Technologies
Microsoft Sentinel, KQL, Azure Policy, Logic Apps, Terraform, Azure Firewall, Azure AD Identity Protection

---

## Actions Taken

### Attack Simulation

I designed and executed adversary-style attack simulations in Azure:

* **Impossible Travel** – simulated logins from geographically impossible locations.
* **Brute-Force Logins** – scripted repeated login failures against a test account.
* **Malicious Container Deployment** – deployed an intentionally misconfigured container workload with privilege escalation.

### Detection Engineering (KQL)

I authored custom Sentinel detection queries to identify malicious behaviors:

* **Impossible Travel:** flagged anomalous location changes based on sign-in telemetry.
* **Brute-Force Logins:** correlated multiple failed attempts with subsequent successful login.
* **Malicious Container:** alerted on suspicious Docker/Kubernetes runtime activity.

### Automation (Logic Apps Playbooks)

I developed and deployed Sentinel automation playbooks:

* **Auto-Respond High Severity:** triggered isolation and notifications for confirmed high-risk events.
* **Auto-Close False Positives:** suppressed common noise (e.g., test accounts, known safe IPs).
* **Enrich with Threat Intelligence:** integrated with external feeds to add context directly into Sentinel incidents.

### Preventive Controls (Azure Policy)

* Enforced **location-based sign-in restrictions**.
* Hardened container configurations via **policy definitions**.

### Workbook Development

I built a **Sentinel Workbook** to visualize:

* Detections by attack scenario.
* Automation coverage and enrichment rates.
* Mean Time to Respond (MTTR) for automated vs manual handling.

---

## Results / Impact

* Validated **real-world attack scenarios** against cloud workloads.
* Closed visibility gaps by engineering **custom detections in KQL**.
* Reduced **false positive fatigue** with automated suppression playbooks.
* Achieved measurable SOC efficiency:

  * MTTR reduced by **70%** on high-severity alerts.
  * Enrichment increased analyst decision speed by **50%**.
* Delivered a **repeatable framework** for attack simulation, detection, and response validation.

---

## Artifacts

**KQL Queries**

* impossible-travel.kql
* brute-force-logins.kql
* malicious-container.kql

**Automation (Playbooks)**

* auto-respond-high-severity.jsonc
* auto-close-false-positives.jsonc
* enrich-with-threat-intel.jsonc

**Policies**

* restrict-risky-locations.json
* enforce-container-security.json

**Workbook**

* attack-detection-overview\.jsonc

**Terraform**

* IaC for provisioning Sentinel, resources, and workloads for simulation

---

## Key Takeaways

This project highlights my ability to:

* Think like an **adversary** to strengthen detections.
* Engineer **KQL queries** that capture subtle attack behaviors.
* Automate incident response with **Logic Apps** to reduce analyst load.
* Apply **Policy as Code** for proactive controls.
* Translate SOC improvements into **metrics leadership understands**.

The end result was a **blue team playbook** that merged simulation, detection, automation, and analytics — proving the resilience of cloud defenses against real-world attack scenarios.
