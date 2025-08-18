# Case Study: Cisco Meraki Zero Trust Firewall Integration with Microsoft Sentinel

## Problem / Challenge

Traditional firewall deployments often lack visibility once traffic is allowed through, creating blind spots for SOC teams. Cisco Meraki MX appliances enforce security at the network edge, but without integration into a SIEM like Microsoft Sentinel, it is difficult to:

* **Correlate Meraki firewall logs** with identity, endpoint, and cloud telemetry.
* Detect **lateral movement attempts** across VLANs or IoT segments.
* Investigate **VPN misuse** and anomalous remote access.
* Operationalize **Zero Trust policies** (verify, monitor, adapt) beyond static firewall rules.

The challenge was to design a **repeatable, automated pipeline** where Cisco Meraki logs are ingested, parsed, and correlated in Sentinel, enabling both enforcement and observability under a Zero Trust model.

---

## Tools

**Tools & Technologies:** Cisco Meraki MX, Syslog, Rsyslog, Ubuntu, Azure Monitor Agent (AMA), Microsoft Sentinel (Log Analytics, KQL, Workbooks, Analytics Rules)

---

## Actions Taken

### Firewall Configuration

* Configured **Cisco Meraki MX syslog exports** for flows, security events, content filtering, and VPN.
* Enforced **Zero Trust segmentation** on the MX:

  * Deny-all inter-VLAN by default.
  * Allow explicit business flows only (e.g., IoT → Internet, Corp → SQL).
  * Applied IDS/IPS with balanced ruleset, URL filtering, and malware prevention.

### Syslog Relay Deployment

* Deployed a hardened **Ubuntu syslog relay** in Azure.
* Configured **rsyslog** to:

  * Accept UDP 514 traffic from Meraki appliances.
  * Tag and forward logs securely to the Azure Monitor Agent.
* Hardened the relay with NSGs and just-in-time SSH access.

### Sentinel Integration

* Deployed **Azure Monitor Agent** to forward Meraki logs into Sentinel.
* Authored a **custom KQL parser** to extract key Meraki fields: `SrcIp`, `DstIp`, `DstPort`, `Action`, `VLAN`, `Policy`.
* Built **detection queries** for:

  * High-volume lateral movement attempts.
  * VPN logins from unusual geolocations (impossible travel).
  * Policy bypass attempts (blocked → allowed).

### Automation & Analytics

* Implemented **Sentinel playbooks** to automatically:

  * Tag high-risk firewall events with MITRE ATT\&CK techniques.
  * Notify SOC channels in Teams when suspicious Meraki activity occurs.
* Built a **Sentinel Workbook** to visualize:

  * Top blocked IPs by volume.
  * Deny/Allow ratio per VLAN.
  * VPN login anomalies over time.
  * Firewall events correlated with identity and endpoint incidents.

---

## Results / Impact

* Achieved **end-to-end visibility** from network perimeter → SIEM → SOC response.
* Reduced **incident investigation time** by correlating Meraki firewall data with Sentinel incidents.
* Exposed **misconfigured IoT devices** attempting unauthorized lateral communication.
* Improved SOC detection coverage with **custom KQL parsers and rules** for firewall-specific telemetry.
* Created a **scalable blueprint** for integrating Cisco Meraki into enterprise Zero Trust architectures.

---

## Artifacts

**Firewall Configurations**

* Zero Trust VLAN segmentation policies.
* IDS/IPS, URL filtering, and VPN enforcement.

**Integration**

* Syslog relay (`rsyslog.conf`).
* Azure Monitor Agent configuration.
* `sentinel-syslog-forwarding.md` integration guide.

**Sentinel Content**

* KQL Parser (`MerakiFirewall_CL`).
* Detection queries (lateral movement, VPN anomalies, high-volume deny).
* Workbook for Meraki visibility.
* Automation playbooks for SOC enrichment.

---

## Key Takeaways

This project highlights my ability to:

* Design **Zero Trust firewall rules** with Cisco Meraki.
* Build **syslog ingestion pipelines** that bridge network appliances with cloud SIEM.
* Write **advanced KQL parsers and detections** tailored to firewall telemetry.
* Integrate firewall telemetry into **SOC operations** (alerts, playbooks, workbooks).
* Demonstrate **cross-domain expertise** in networking, cloud security, and incident response.

The outcome was a **Meraki–Sentinel integration** that transformed isolated firewall logs into actionable insights for the SOC, enabling **proactive threat detection** and **continuous Zero Trust validation**.
