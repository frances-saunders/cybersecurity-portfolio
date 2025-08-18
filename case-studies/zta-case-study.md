# Zero Trust Network Segmentation in Azure

## Problem / Challenge

Enterprises migrating to Azure often rely on **flat network designs** that lack proper segmentation. This creates several security risks:

* **Overly permissive NSG rules** allow broad inbound/outbound access.
* **Public endpoints** on sensitive services (e.g., Storage, SQL) increase exposure to the internet.
* **Lack of firewall inspection** limits visibility into east-west and outbound traffic.
* **Unenforced private endpoints** allow workloads to bypass secure routing.
* **Inconsistent subnet policies** weaken Zero Trust principles.

These weaknesses violate the **Zero Trust principle of least privilege** and leave critical data and workloads exposed to lateral movement, exfiltration, and internet-based threats.

---

## Tools & Technologies
Azure Firewall, Network Security Groups (NSGs), Azure Policy, Private Endpoints, Terraform, Microsoft Sentinel

---

## Actions Taken

### Network Segmentation Design

I implemented a **hub-and-spoke VNet model** with strict segmentation:

* **Hub:** contained Azure Firewall for centralized control.
* **Spokes:** hosted application tiers, each isolated by NSGs.
* Subnets defaulted to **deny-all inbound/outbound**, with explicit allow rules only for required flows.

### Policy Enforcement

Custom **Azure Policies** were authored to enforce Zero Trust standards:

* Deny subnets with public IPs.
* Restrict NSG rules (no `*` wildcards, no overly broad ranges).
* Require private endpoints for sensitive services.
* Bundled into a **Zero Trust Segmentation Initiative** mapped to **NIST 800-207 (Zero Trust Architecture)**.

### Firewall Integration

* Deployed **Azure Firewall Premium** in the hub.
* Configured DNAT/SNAT for inbound access where strictly required.
* Integrated threat intelligence filtering for malicious IP/domain blocking.
* Logged traffic to Sentinel for analytics.

### Automation & Detection

* Authored KQL queries to detect:

  * Overly permissive NSGs.
  * Subnets without compliant NSG rules.
  * Public endpoints on sensitive services.
* Built **Sentinel playbooks** to:

  * Auto-remediate NSG misconfigurations.
  * Alert on public endpoint exposure.
  * Enrich firewall alerts with threat intelligence.

### Infrastructure as Code (Terraform)

* Automated provisioning of:

  * Hub-and-spoke VNet with subnets.
  * NSGs and rules with explicit least-privilege policies.
  * Azure Firewall with logging enabled.
  * Policy assignments and initiatives.
  * Private endpoints for Storage and SQL.

---

## Results / Impact

* Reduced attack surface by **eliminating public endpoints** on sensitive services.
* Prevented lateral movement with **deny-by-default NSGs** and subnet isolation.
* Increased visibility through centralized **Azure Firewall logging and threat intel integration**.
* Embedded **Zero Trust Architecture** principles into core network design.
* Delivered a **Terraform-driven blueprint** for repeatable Zero Trust segmentation in Azure.

---

## Artifacts

**Policy Definitions**

* Deny Public Subnets
* Restrict NSG Rules
* Enforce Private Endpoints
* Zero Trust Segmentation Initiative

**KQL Queries**

* Detect NSG Non-Compliance
* Detect Overly Permissive Rules
* Detect Public Endpoints

**Automation Playbooks**

* Auto-Remediate NSG Rules
* Public Endpoint Alerting
* Firewall Threat Intel Enrichment

**Terraform**

* Hub-and-spoke VNet with Firewall
* NSGs and policies
* Private Endpoints
* Policy Initiative Assignments

**Workbook**

* Zero Trust Segmentation Overview (traffic visibility, non-compliance trends, endpoint posture)

---

## Key Takeaways

This project highlights my ability to:

* Apply **Zero Trust principles** to Azure networking.
* Enforce segmentation with **Policy as Code**.
* Automate provisioning and compliance with **Terraform**.
* Build **detections, automation, and visualizations** in Sentinel.
* Deliver a secure, scalable, and auditable **network segmentation blueprint** for enterprise workloads.

The end result was a **defensible Zero Trust architecture** that reduced exposure, enforced least privilege, and integrated security into daily operations.
