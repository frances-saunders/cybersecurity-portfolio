## Case Study: Cisco Meraki Zero Trust Firewall Implementation

### Problem / Challenge

Organizations often treat corporate firewalls as **flat network gateways**, exposing internal resources to lateral movement and insider threats. With the rise of IoT, guest access, and hybrid work, this model is insufficient. Leadership required a **Zero Trust approach** to segment critical networks, enforce least privilege, and integrate firewall telemetry with cloud-based SIEM platforms.

### Role & Tools

**Role:** Network Security Engineer  
**Tools:** Cisco Meraki MX, Active Directory/SAML, Azure Sentinel, Syslog, SD-WAN

### Actions Taken

* Designed **segmented VLAN architecture**:

  * Corporate VLAN (production workloads).
  * IoT VLAN (isolated with limited outbound).
  * Guest VLAN (internet-only, no east-west traffic).
  * Management VLAN (restricted admin access).

* Authored **deny-by-default firewall rules** with explicit allow-lists for critical services (DNS, HTTPS, application-specific).

* Implemented **identity-based group policies**:

  * Developers → access to dev/test resources.
  * Contractors → internet-only + restricted corporate SaaS.
  * IoT devices → isolated with cloud telemetry only.

* Built **SD-WAN policy-based routing** with automatic failover and application-aware traffic shaping for Teams, O365, and VoIP.

* Forwarded **Meraki logs into Azure Sentinel** for centralized detection of anomalies (e.g., excessive blocked traffic, rogue IoT activity).

### Results / Impact

* Eliminated flat network risks by enforcing **Zero Trust segmentation**.
* Improved SOC visibility by forwarding **Meraki firewall logs into Sentinel**.
* Reduced **mean time to detect anomalous activity** (MTTD) via enriched analytics.
* Delivered a **resilient SD-WAN design** that maintained availability even during primary uplink failures.

### Key Takeaways

* Showcased expertise in **enterprise firewall engineering** with Cisco Meraki.
* Demonstrated **Zero Trust principles** in practice with VLANs, group policies, and deny-by-default rules.
* Bridged **on-prem firewall telemetry** into a **cloud-native SIEM** for advanced analytics.
* Highlighted **10+ years of security maturity** by balancing security, identity, availability, and SOC visibility.

---

This lab would **stand out** in your portfolio because it’s:

1. Not just Azure — shows multi-vendor depth (Cisco + Microsoft).
2. Recruiters immediately recognize **Meraki MX** as enterprise-grade.
3. It demonstrates you understand **network + security + SOC integration**, not just configuration.
