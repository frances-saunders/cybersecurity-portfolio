# Cisco Meraki → Microsoft Sentinel Syslog Forwarding Integration

## Overview

This integration guide demonstrates how to forward **Cisco Meraki MX firewall and security appliance logs** to **Microsoft Sentinel** for advanced correlation, detection, and response. By integrating Meraki logs into Sentinel, Zero Trust policies can be continuously monitored, audited, and enforced.

This integration highlights:

* **Zero Trust visibility** – monitor lateral movement attempts, denied flows, and segmentation effectiveness.
* **Threat detection** – feed Meraki IDS/IPS, malware blocking, and content filtering logs into Sentinel for correlation with endpoint and identity signals.
* **Operational readiness** – ensure SOC teams can investigate Meraki activity alongside cloud and endpoint telemetry.

---

## Integration Architecture

1. **Cisco Meraki Dashboard → Syslog Export**

   * Configure Meraki MX appliances to forward syslog events (flows, security, content filtering, VPN).
   * Define a syslog server IP pointing to the **Linux-based syslog relay**.

2. **Syslog Relay (Linux VM)**

   * Acts as a controlled ingress point for Meraki syslog traffic.
   * Parses and normalizes logs using rsyslog.
   * Forwards logs securely to the Sentinel Log Analytics workspace via the **Azure Monitor Agent (AMA)** or OMS Agent.

3. **Microsoft Sentinel (Log Analytics Workspace)**

   * Ingests syslog data into the `Syslog` table.
   * Custom KQL parsers normalize Meraki log fields (src/dst IP, ports, VLAN, policy action, rule hit).
   * Detection rules, workbooks, and automation playbooks are built on top of parsed logs.

---

## Configuration Steps

### Step 1 – Meraki Dashboard Syslog Setup

* Navigate to **Network-wide → Configure → General → Reporting**.
* Add a new syslog server with:

  * **IP Address:** `<relay-server-IP>`
  * **Port:** `514`
  * **Roles:** `Flows`, `Security Events`, `URLs`, `VPN`
* Save configuration.

### Step 2 – Syslog Relay VM

* Deploy Ubuntu VM in Azure (same VNet as Log Analytics agent).
* Install and configure **rsyslog**:

  ```bash
  sudo apt update
  sudo apt install rsyslog -y
  ```
* Configure `/etc/rsyslog.d/meraki.conf`:

  ```conf
  # Listen on UDP 514 for Meraki syslogs
  module(load="imudp")
  input(type="imudp" port="514")

  # Tag Meraki logs
  if $fromhost-ip startswith '10.10.' then {
      action(type="omfwd" target="127.0.0.1" port="25226" protocol="udp")
  }
  ```
* Restart service:

  ```bash
  sudo systemctl restart rsyslog
  ```

### Step 3 – Azure Monitor Agent (AMA) / OMS Agent

* Install agent on the relay VM.
* Configure it to collect facility/priority logs tagged as **Meraki**.
* Verify ingestion into Log Analytics via Sentinel’s **Syslog table**.

### Step 4 – Sentinel Parser & Detection

* Create a custom KQL parser function `MerakiFirewall_CL`:

  ```kql
  Syslog
  | where Facility == "local4"
  | extend SrcIp = extract("src=([0-9.]+)", 1, SyslogMessage)
  | extend DstIp = extract("dst=([0-9.]+)", 1, SyslogMessage)
  | extend DstPort = extract("dpt=([0-9]+)", 1, SyslogMessage)
  | extend Action = extract("action=(\\w+)", 1, SyslogMessage)
  ```
* Build detection queries:

  * **Blocked lateral movement**: look for IoT → Corporate VLAN denies.
  * **High-volume deny**: repeated drops from a single IP.
  * **VPN anomalies**: failed auth followed by success from new country.

---

## Skills Demonstrated

* **Firewall / Network Security** – advanced Cisco Meraki MX rule design and logging.
* **SIEM Integration** – Sentinel log ingestion pipeline (syslog → agent → Log Analytics).
* **KQL Expertise** – parsing raw syslog into structured fields.
* **Threat Detection** – custom detection queries tied to Zero Trust segmentation.
* **Cross-Domain Knowledge** – blending **network engineering** and **cloud SOC workflows**.

---

## Key Takeaways

This integration showcases how a senior security engineer can:

* Bridge **network perimeter enforcement** with **cloud-native SIEM** visibility.
* Translate raw Meraki firewall telemetry into actionable detection content.
* Operationalize Zero Trust by making segmentation policies **observable and auditable** in Sentinel.

The end result is a **defensible Zero Trust architecture** where Cisco Meraki enforces, and Microsoft Sentinel validates, monitors, and responds.
