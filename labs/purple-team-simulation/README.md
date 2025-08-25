# Purple Team Simulation Lab

## Overview
This lab demonstrates an **end-to-end Purple Team simulation** combining adversary emulation, threat hunting, and automated response.  
It showcases advanced skills in **APT simulation, MITRE ATT&CK mapping, SOC detection engineering, and SOAR orchestration**.

The lab replicates a **nation-state style intrusion (APT29-inspired)** including credential dumping, lateral movement, and data exfiltration.  
Detection queries and automated responses are developed to **validate SOC visibility and response readiness**.

---

## Lab Structure
labs/purple-team-simulation/
│
├── adversary-playbook/                 # Simulated APT attack steps (JSON / YAML)
│   ├── apt29_simulation.yaml
│   ├── credential_dumping.yaml
│   └── lateral_movement.yaml
│
├── detections/                         # Threat-hunting queries (KQL/Splunk SPL)
│   ├── credential-access.kql
│   ├── persistence-techniques.kql
│   └── lateral-movement.spl
│
├── mitre-mapping/                      # MITRE ATT&CK coverage mapping
│   ├── T1003-credential-dumping.json
│   ├── T1078-valid-accounts.json
│   └── ATTACK_Coverage_Matrix.xlsx
│
├── playbooks/                          # Automated SOAR response
│   ├── isolate-compromised-host.jsonc
│   ├── revoke-stolen-credentials.jsonc
│   └── c2-traffic-blocking.jsonc
│
├── scripts/                            # Automation scripts
│   ├── invoke-redteam-simulation.ps1   # Trigger APT simulation in controlled env
│   ├── enrich-threat-intel.sh          # Enrich IOCs with OSINT
│   └── hunt-automation.py              # Execute queries + log findings
│
└── README.md

---

## Tools & Technologies
* **Atomic Red Team** – adversary simulation framework  
* **MITRE ATT&CK Navigator** – mapping TTP coverage  
* **Microsoft Sentinel / Splunk** – threat-hunting queries  
* **Azure Logic Apps / SOAR** – automated playbooks  
* **PowerShell / Python / Bash** – attack automation and enrichment  

---

## Artifacts
* **Adversary Playbook:** step-by-step APT29 simulation in YAML  
* **Threat Hunting Queries:** KQL & SPL rules aligned to MITRE ATT&CK  
* **ATT&CK Coverage Matrix:** visual mapping of simulated TTPs to detections  
* **SOAR Playbooks:** automated containment for credential theft, host isolation, and C2 blocking  
* **Automation Scripts:** red team simulation triggers, IOC enrichment, hunt automation  

---

## Learning Outcomes
By completing this lab, I was able to:
* **Design and execute Purple Team exercises** that simulate real-world adversaries.  
* **Map detections to MITRE ATT&CK** ensuring comprehensive coverage.  
* **Author advanced hunting queries** in KQL and SPL.  
* **Automate SOC response** with SOAR playbooks and scripts.  
* Present findings in an **executive-level ATT&CK coverage dashboard**.
