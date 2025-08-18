# Cisco Meraki – Zero Trust Firewall Lab

## Overview

This lab demonstrates the design and implementation of a **Zero Trust firewall architecture** using Cisco Meraki MX appliances. The focus is on enforcing **least-privilege network access**, isolating high-risk segments (IoT, guest), and maintaining **business continuity** through SD-WAN failover and application-aware traffic shaping.

The artifacts are written in an **API-friendly, version-controlled format** to highlight automation skills and operational maturity. This mirrors how modern enterprises integrate **network security with DevSecOps practices**.

---

## Lab Objectives

* Apply **Zero Trust segmentation** across corporate, IoT, guest, and management networks.
* Enforce **deny-all by default**, with explicit, auditable allow-rules.
* Configure **identity-aware access controls** using Meraki Group Policies tied to AD/SAML roles.
* Implement **SD-WAN failover** with performance-based thresholds for redundancy.
* Apply **application-aware QoS** for critical collaboration tools (O365, Teams, VoIP).
* Showcase **API-driven network automation** for repeatable and scalable deployments.

---

## Directory Structure

```plaintext
labs/cisco-meraki-zero-trust-firewall/
├── configs/
│   ├── vlan-segmentation.jsonc         # VLANs and subnet design
│   ├── firewall-rules.jsonc            # L3/L7 firewall rules with Zero Trust model
│   ├── sdwan-failover.jsonc            # Dual WAN failover + traffic shaping
│   └── group-policies.jsonc            # Identity-based access controls
│
├── readme.md

````

---

## Deployment Steps

1. **VLAN Segmentation**
   Import `configs/vlan-segmentation.jsonc` to define secure subnets for Corporate, IoT, Guest, and Management zones.

2. **Firewall Rules**
   Apply `configs/firewall-rules.jsonc` to enforce **deny-by-default** and explicitly allow only necessary traffic flows.

3. **SD-WAN Failover**
   Configure dual-WAN redundancy with `configs/sdwan-failover.jsonc`, ensuring performance-based failover and application-aware shaping.

4. **Identity-Based Policies**
   Assign `configs/group-policies.jsonc` to map AD/SAML groups to appropriate VLANs and enforce tailored access levels.

---

## Skills Demonstrated

* **Zero Trust Network Design** – segmentation, deny-all policies, and explicit allow-lists.
* **Cisco Meraki Security Engineering** – VLANs, firewall rules, SD-WAN, and group policies.
* **Identity-Aware Controls** – access tied to user/device identity via SAML/AD.
* **Automation & Version Control** – configs designed for API integration and repeatable deployments.
* **Operational Maturity** – balancing security with usability, performance, and business continuity.

---

## Portfolio Impact

This lab demonstrates **10+ years of experience** in enterprise network security by showing not just the configs, but the **design rationale, Zero Trust alignment, and operational excellence** behind them. It highlights the ability to deliver **secure, automated, and auditable network architectures** that meet both technical and business objectives.

```
