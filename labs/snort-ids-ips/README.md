# Snort Intrusion Detection & Prevention Lab

## Overview
This lab demonstrates **intrusion detection engineering and tuning** using **Snort** in both IDS and IPS modes.  
It highlights my ability to design custom detection logic, simulate realistic attacks, and integrate with enterprise SIEM platforms for correlation and visibility.  

The lab is structured to showcase:
* Deployment of Snort in IDS and IPS mode.
* Authoring and tuning **custom rules** for brute force, SQL injection, suspicious DNS, and malware traffic.
* **Attack simulations** using Nmap and Metasploit to validate detection.
* **SIEM integration** with Splunk and Sentinel for centralized alerting.
* **Threat intelligence enrichment** using automated blacklist and domain feeds.

---

## Lab Structure
```
labs/snort-ids-ips/
│
├── rules/                            # Custom and tuned Snort rules
│   ├── brute-force.rules
│   ├── sql-injection.rules
│   ├── suspicious-dns.rules
│   └── malware-signatures.rules
│
├── simulations/                      # Attack simulations & traffic captures
│   ├── nmap-portscan.pcap
│   ├── sql-injection-attack.pcap
│   ├── brute-force-ssh.pcap
│   └── metasploit-malware-traffic.pcap
│
├── integrations/                     # SIEM/Threat Intel integration examples
│   ├── splunk-snort-alerts.conf
│   ├── sentinel-connector.json
│   └── threat-intel-feed-integration.md
│
├── reports/                          # Outputs and analysis
│   ├── tuning-analysis.md
│   ├── detection-coverage-matrix.csv
│   └── incident-response-summary.md
│
├── scripts/                          # Automation & enrichment scripts
│   ├── log-forwarder.py              # Securely sends Snort logs to Splunk/Sentinel
│   └── intel-updater.sh              # Pulls threat intel feeds and updates rules
│
└── README.md                         # Lab overview

```
---

## Tools & Technologies
* **Snort** – IDS/IPS engine  
* **Splunk & Sentinel** – SIEM platforms for alert ingestion  
* **Nmap & Metasploit** – attack simulation tools  
* **Wireshark** – packet analysis and verification  
* **Threat Intel Feeds** – blacklist/domain enrichment  

---

## Learning Outcomes
By completing this lab, I was able to:
* Deploy Snort in **IDS and inline IPS** configurations.  
* Write **custom detection rules** beyond community signatures.  
* Minimize false positives with advanced rule options (`flow`, `content`, `pcre`, thresholds).  
* Simulate adversary techniques and validate detection accuracy.  
* Forward Snort alerts into **Splunk and Sentinel** for SIEM correlation.  
* Automate threat intel enrichment for proactive detection.  
