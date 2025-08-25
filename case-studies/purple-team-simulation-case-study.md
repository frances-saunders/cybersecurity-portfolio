# Case Study: Purple Team Simulation

## Problem / Challenge
Organizations face increasingly sophisticated APTs that blend stealthy credential theft, lateral movement, and data exfiltration.  
Traditional red or blue team exercises alone **fail to validate end-to-end detection and response capability**.  

The challenge: **simulate an advanced adversary (APT29) across the full kill chain and validate SOC visibility and automated response**.

---

## Tools & Technologies
Atomic Red Team, Microsoft Sentinel, Splunk, MITRE ATT&CK Navigator, Azure Logic Apps (SOAR), PowerShell, Python

---

## Actions Taken

### Adversary Playbook
* Developed an **APT29 simulation** with credential dumping, persistence, and C2 traffic.  
* Executed controlled attacks in a lab environment using Atomic Red Team.

### Threat Hunting Queries
* Authored **KQL** (Sentinel) and **SPL** (Splunk) queries for credential access, lateral movement, and persistence.  
* Validated queries against live simulation telemetry.

### MITRE ATT&CK Mapping
* Built an **ATT&CK coverage matrix** mapping all simulated TTPs.  
* Highlighted detection gaps and prioritized improvements.

### Automated SOAR Response
* Built Logic App playbooks for:  
  * Host isolation upon credential theft  
  * Blocking outbound C2 traffic  
  * Revoking compromised credentials  

### Automation
* Created scripts to **trigger red team simulations** and automate IOC enrichment.  
* Built Python automation to run hunts on schedule and log findings.

---

## Results / Impact
* Delivered a **realistic Purple Team exercise framework** replicable across enterprises.  
* Validated SOC coverage against **MITRE ATT&CK tactics**.  
* Reduced mean-time-to-detect (MTTD) and mean-time-to-respond (MTTR) with automated playbooks.  
* Produced an **executive-ready ATT&CK heatmap** showing detection maturity.  
* Established a **reusable blueprint** for advanced Purple Teaming engagements.

---

## Artifacts
* Adversary Playbook (APT29)  
* KQL & SPL Detection Queries  
* ATT&CK Coverage Matrix  
* SOAR Playbooks  
* Automation Scripts  

---

## Key Takeaways
This project highlights my ability to:
* Lead **end-to-end Purple Team operations**.  
* Engineer **detections mapped to MITRE ATT&CK**.  
* Automate adversary simulations and SOC response.  
* Communicate results effectively to **executive leadership and SOC teams**.  

The outcome demonstrates expertise in both **offensive tradecraft and defensive engineering**, aligning with enterprise detection and response maturity goals.
