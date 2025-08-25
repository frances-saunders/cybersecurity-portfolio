# Case Study: Insider Threat & Data Protection

## Problem / Challenge
Organizations increasingly face **insider-driven data loss**—malicious or negligent. Point detections (e.g., single DLP alerts) often miss **behavioral context** (volume spikes, geo anomalies, recent HR changes), leading to false positives and slow containment.

**Objective:** Deploy a cohesive Insider Threat program that merges **UEBA baselines**, **DLP enforcement**, and **SOAR** to detect and contain abnormal exfiltration without drowning analysts in noise.

---

## Tools & Technologies
Microsoft Sentinel (KQL, Workbooks), Microsoft Purview DLP (InformationProtectionLogs_CL), Defender for Cloud Apps (CloudAppEvents), Entra ID Sign-in Logs, Azure Logic Apps (SOAR), Splunk (SPL), PowerShell/Python/Bash.

---

## Actions Taken

### 1) UEBA & Baselines
- Built 14-day **per-user activity baselines** for downloads/uploads and sign-in geo telemetry.
- Implemented **impossible travel** logic and **exfil volume spikes** using KQL/SPL.

### 2) DLP Integration
- Surfaced **Purview DLP** events (SharePoint/OneDrive/Exchange) into Sentinel; exported via `export-dlp-events.ps1`.
- Added workbook tiles for **policy hits** and trends.

### 3) SOAR Orchestration
- Automated **suspend + revoke tokens**, **file quarantine**, and **HR/Legal** notifications via Logic Apps.
- Used **Key Vault** and managed connections—no plaintext secrets.

### 4) Simulation & Validation
- Executed benign **zip-and-upload/email** scenarios to generate telemetry (T1567.002, T1560, T1114).
- Validated detections and measured improvements in **MTTD/MTTR**.

### 5) Executive Reporting
- Produced a **MITRE ATT&CK coverage matrix** summarizing visibility, detection, and response automation for relevant techniques.

---

## Results / Impact
- Improved **signal-to-noise** by correlating DLP with UEBA baselines (fewer false positives).  
- Reduced **MTTD/MTTR** with automated containment and playbook-driven workflows.  
- Delivered a repeatable blueprint for **insider threat operations**, auditable via ATT&CK mapping.

---

## Artifacts
- **KQL/SPL Detections:** abnormal volume, impossible travel, outbound to file-sharing.  
- **SOAR Playbooks:** account suspension, token revocation, file quarantine, HR/Legal alerting.  
- **Sentinel Workbook:** real-time dashboarding of UEBA/DLP signals.  
- **ATT&CK Coverage Matrix (XLSX/CSV):** executive reporting and roadmap.

---

## Key Takeaways
- Effective insider threat programs require **behavioral context**, not just single-event alerts.  
- **DLP + UEBA + SOAR** provides a powerful triad for both prevention and rapid response.  
- Mapping to **MITRE ATT&CK** clarifies residual gaps and directs future engineering work.
