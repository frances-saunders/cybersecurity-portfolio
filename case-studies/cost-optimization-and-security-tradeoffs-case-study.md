# Cost Optimization and Security Tradeoffs in Azure

## Problem / Challenge

Security in the cloud is often perceived as a **cost center**, but organizations must balance **security coverage** with **budget efficiency**. During security reviews, leadership raised concerns about:

* **High ingestion costs** for Microsoft Sentinel, especially from noisy log sources.
* **Defender for Cloud plan costs** for services not considered mission-critical.
* **Web Application Firewall (WAF)** costs in front of lower-tier applications.
* Lack of a framework to demonstrate **ROI of security controls** vs. **risks mitigated**.

The challenge was to build a **data-driven approach** to show which controls deliver the most value, where costs can be optimized, and how tradeoffs impact overall security posture.

---

## Role & Tools

**Role:** Cloud Security Administrator  
**Tools & Technologies:** Microsoft Sentinel, Azure Monitor, Azure Cost Management, Azure Defender for Cloud, Azure Policy, KQL, Workbooks

---

## Actions Taken

### Security Control Inventory

I cataloged common Azure security controls and their costs:

* **Microsoft Sentinel:** data ingestion, retention, and analytic rules.
* **Defender for Cloud Plans:** per-resource pricing across VM, SQL, Storage.
* **WAF/Front Door:** per-hour instance costs + request inspection.
* **Private Endpoints:** added networking complexity and egress costs.

### Cost vs. Risk Matrix

I built a **tradeoff matrix** mapping costs to risks mitigated:

* Sentinel log ingestion of **Defender Alerts** → High cost, High value (detects advanced attacks).
* Sentinel ingestion of **AzureActivity logs** → Low cost, Medium value.
* Defender for SQL on dev workloads → Medium cost, Low value (considered downgrade).
* WAF for internal apps → Medium cost, Low value (removed).
* WAF for internet-facing apps → High cost, High value (retained).

### Workbook Development

I created a custom **Sentinel Workbook** that visualizes:

* Cost breakdown by control (Sentinel, Defender, WAF).
* Risk mitigation score (based on mapped threat coverage).
* “Value Index” = Risk Mitigated ÷ Monthly Cost.
* Recommendations for right-sizing or reallocation.

### Policy-Driven Governance

* Authored **Azure Policies** to require Defender coverage only on production workloads.
* Applied tagging (`Environment=Prod/Dev/Test`) to drive conditional cost enforcement.
* Tuned Sentinel analytic rules to reduce ingestion of redundant logs.

---

## Results / Impact

* Reduced Sentinel ingestion costs by **\~25%** by filtering redundant logs.
* Cut Defender plan spend on **non-production** resources by **30%** through policy-driven scoping.
* Retained WAF only where business risk justified it, saving **\~\$5K monthly**.
* Provided leadership with a **quantitative workbook** to evaluate costs vs. risks.
* Shifted perception of security from a **cost center** to a **value driver** with measurable tradeoffs.

---

## Artifacts

**Workbook**

* Cost vs. Risk Tradeoff Dashboard (Sentinel, Defender, WAF).

**KQL Queries**

* Sentinel cost by data type.
* Defender plan cost by resource tag.
* WAF cost trends.

**Policies**

* Restrict Defender for Cloud to Production workloads.
* Enforce tagging for cost visibility.

---

## Key Takeaways

This project demonstrates my ability to:

* Think like **both a security engineer and business leader**.
* Translate security coverage into **financial impact and value metrics**.
* Optimize security operations with **cost-aware policies and tuning**.
* Build workbooks that help leadership **visualize tradeoffs and ROI**.

The end result was a governance-driven approach where **security spend aligns with business risk**, improving both **financial efficiency** and **defensible security posture**.
