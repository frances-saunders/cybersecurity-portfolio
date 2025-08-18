# Cost Optimization and Security Tradeoffs in Azure

## Problem / Challenge

Security leaders are under constant pressure to **balance protection with cost efficiency**. In Azure, even well-architected security programs can generate waste:

* **Sentinel ingestion bloat** from verbose logs that rarely lead to detections.
* **Defender for Cloud plan sprawl**, with costly coverage applied to non-critical or dev resources.
* **WAF deployments** in front of apps with little to no external exposure.
* No consistent framework to **quantify risk reduction per dollar spent**.

Leadership’s challenge: *“Show us where we are overspending on controls that don’t move the risk needle, and where we must invest more aggressively to reduce attack surface.”*

This required a solution that combined **technical rigor** (data pipelines, policy enforcement) with **executive-friendly reporting** (clear visualization of security ROI).

---

## Role & Tools

**Role:** Cloud Security Administrator (Strategic Advisor to CISO)  
**Tools & Technologies:** Microsoft Sentinel, KQL, Azure Cost Management APIs, Defender for Cloud, Azure Policy, Logic Apps, Azure Monitor Workbooks

---

## Actions Taken

### Step 1: Build a Security Control Cost Model

I programmatically extracted **Azure cost data** and **security telemetry** using:

* **KQL Queries** in Sentinel to calculate ingestion volume by log source and workspace.
* **Azure Cost Management REST API** to pull Defender and WAF resource-level spend.
* Normalization scripts (PowerShell + KQL) to unify cost and detection data into a single dataset.

### Step 2: Map Costs to Risks Mitigated

I created a **custom scoring framework**:

* Each control (e.g., Defender for SQL, Sentinel data connectors, WAF policies) was assigned a **Risk Coverage Score** based on MITRE ATT\&CK mappings.
* Example: Sentinel’s ingestion of `SecurityAlert` logs received a **High score** (covers privilege escalation, lateral movement), while ingestion of verbose `AuditLogs` received a **Low score**.
* The scoring allowed calculation of a **“Value Index” = Risk Coverage ÷ Monthly Cost**.

### Step 3: Develop the Workbook

I authored a **Sentinel Workbook** in JSON with advanced KQL queries:

* **Cost Breakdown Widgets** – Top 10 Sentinel log sources by monthly spend.
* **Value Index Heatmap** – Which controls deliver “high value per dollar” vs. “low value per dollar.”
* **Scenario Filters** – By environment tag (`Prod`, `Dev`, `Test`) and by workload type (SQL, VM, App Service).
* **Recommendations Panel** – Dynamic text blocks that update based on thresholds (e.g., highlight Defender plans with <2 detections/month but >\$500 spend).

### Step 4: Governance Enforcement

To operationalize findings:

* Authored **Azure Policies** that enforce Defender coverage only on production-tagged resources.
* Tuned Sentinel analytic rules to **reduce ingestion by 25%** without sacrificing detection quality.
* Automated alerts when WAF is deployed in front of apps without public exposure.

---

## Results / Impact

* Reduced **Sentinel ingestion costs by 25%** (\~\$8K/month savings).
* Scoped Defender for Cloud to production workloads only, cutting plan spend by **30%**.
* Eliminated low-value WAF instances, saving **\~\$5K monthly**.
* Delivered an **executive-ready Workbook** showing:

  * Cost vs. risk tradeoffs.
  * Security ROI (“\$ spent per MITRE technique covered”).
  * Actionable recommendations for leadership.

The biggest impact: shifting perception of security from a **black-box cost center** to a **measurable business enabler**, backed by hard data and defensible tradeoffs.

---

## Artifacts

**Workbook (JSON)**

* Cost vs. Risk Tradeoff Dashboard with cost APIs + KQL queries.

**KQL Queries**

* Sentinel ingestion cost per data type.
* Defender plan spend by resource tag.
* WAF spend anomalies (apps with zero inbound traffic).

**Policy Templates**

* Restrict Defender coverage to Prod.
* Require tagging for cost attribution.

---

## Key Takeaways

This project highlights **10 years of cumulative cybersecurity expertise**:

* **Technical Depth:** Custom KQL + API integration to merge cost and security datasets.
* **Coding & Automation:** JSON workbook authoring, PowerShell cost extractors, policy-as-code.
* **Strategic Thinking:** Translating detections and telemetry into **business-friendly ROI metrics**.
* **Executive Influence:** Providing CISOs and leadership with a **quantifiable tradeoff model** to guide security investment decisions.

The end result: a **security-financial analytics platform** that demonstrates my ability to combine **hands-on coding, architectural governance, and business acumen** into one deliverable — the exact skill set companies seek in senior/principal-level security roles.
