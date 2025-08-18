# Cisco Meraki Zero Trust Firewall Lab

## Overview

This lab demonstrates how to design and implement **Zero Trust segmentation and adaptive firewall controls** using Cisco Meraki MX firewalls in a hybrid enterprise environment. The goal is to showcase **network security engineering skills** that bridge cloud and on-prem environments, with a focus on:

* **Zero Trust segmentation** between corporate, guest, and IoT networks.
* **Adaptive policies** driven by tags, identity, and posture — not just IP addresses.
* **Advanced logging & monitoring** exported into a SIEM (Azure Sentinel) for threat hunting.
* **Automated failover & resilience** across multiple WAN uplinks.

---

## Lab Objectives

* Configure **VLAN-based segmentation** with Meraki MX firewalls.
* Enforce **role-based policies** using Meraki group policies (tying into Active Directory / SAML).
* Integrate with **Azure Sentinel** for log forwarding and real-time visibility.
* Demonstrate **SD-WAN resiliency** and traffic shaping for critical workloads.
* Document firewall rules and policy enforcement aligned with **Zero Trust** principles.

---

## Directory Structure

```plaintext
labs/meraki-zero-trust-firewall/
├── configs/
│   ├── vlan-segmentation.json
│   ├── firewall-rules.json
│   ├── sdwan-failover.json
│   └── group-policies.json
│
├── integration/
│   └── sentinel-syslog-forwarding.md
│
├── diagrams/
│   ├── zero-trust-segmentation.png
│   └── sdwan-failover-architecture.png
│
└── case-study.md
```

---

## Artifacts

**Configs**

* **VLAN Segmentation** – defines corporate, guest, IoT, and management VLANs.
* **Firewall Rules** – deny-all baseline, with explicit allow rules for business-critical services.
* **SD-WAN Failover** – dual uplink config for automatic failover and traffic shaping.
* **Group Policies** – role-based access mapped to AD/SAML (e.g., developers, contractors, IoT devices).

**Integration**

* **Sentinel Syslog Forwarding Guide** – details how Meraki logs are normalized and ingested into Sentinel for centralized SOC monitoring.
