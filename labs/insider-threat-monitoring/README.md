# Insider Threat Monitoring Lab

## Overview
This lab demonstrates an end-to-end **Insider Threat & Data Protection** program that blends **UEBA (User & Entity Behavior Analytics)**, **Data Loss Prevention (DLP)**, and **SIEM-driven hunts** to detect and contain abnormal data exfiltration. It showcases:
- **Behavior baselining** and anomaly detection (impossible travel, abnormal volume).
- **DLP enforcement** for M365 workloads (SharePoint/OneDrive/Exchange) with automated quarantine.
- **SOAR playbooks** that revoke sessions, suspend accounts, and notify HR/Legal.
- **MITRE ATT&CK coverage** summarized in an executive-ready matrix.

> Secrets are never stored in plaintext. Integrations prefer **Managed Identity**, **Azure Key Vault**, or environment variables.

---

## Lab Structure
```
labs/insider-threat-monitoring/
├── ueba-playbook/
│ ├── exfil_to_cloud_storage.yaml
│ ├── zip_and_email.yaml
│ └── impossible_travel_admin.yaml
│
├── detections/
│ ├── exfil-abnormal-volume.kql
│ ├── impossible-travel.kql
│ └── exfiltration.spl
│
├── mitre-mapping/
│ ├── T1567.002-exfil-to-cloud.json
│ ├── T1020-automated-exfiltration.json
│ └── T1030-data-transfer-size-limits.json
│ 
├── workbook/
│ └── insider-threat-workbook.jsonc
│
├── policy/
│ └── insider-threat-policy.md
│
├── playbooks/
│ ├── suspend-user-and-revoke-tokens.jsonc
│ ├── quarantine-sensitive-file.jsonc
│ └── alert-hr-legal.jsonc
│
└── scripts/
├── export-dlp-events.ps1
├── hunt-ueba.py
└── enrich-hr-context.sh
```

---

## Tools & Technologies
**Microsoft Sentinel**, **Microsoft Purview DLP**, **Defender for Cloud Apps (CloudAppEvents)**, **Azure Logic Apps (SOAR)**, **Entra ID Sign-in Logs**, **Splunk**, **PowerShell/Python/Bash**, **MITRE ATT&CK Navigator**.

---

## Setup & Deployment
1. **Sentinel:** Connect M365, SigninLogs, CloudAppEvents, and Purview DLP tables (InformationProtectionLogs_CL).
2. **Workbooks:** Import `workbook/insider-threat-workbook.jsonc` into Sentinel Workbooks.
3. **Detections/Hunts:**  
   - Import KQL files under `detections/` into Analytics Rules or run via `scripts/hunt-ueba.py`.  
   - Import `exfiltration.spl` into Splunk (adjust indexes/sourcetypes).
4. **SOAR:** Deploy Logic Apps from `playbooks/` (use Key Vault / managed connections).
5. **DLP Events Export (optional):** Use `scripts/export-dlp-events.ps1` to post DLP events to Log Analytics (custom table).
6. **HR Context:** Join hunt results with HR roster via `scripts/enrich-hr-context.sh`.

---

## Simulations
- `ueba-playbook/exfil_to_cloud_storage.yaml`: benign upload to generate telemetry for T1567.002.  
- `ueba-playbook/zip_and_email.yaml`: archive + email pattern to exercise DLP and collection behaviors.  
- `ueba-playbook/impossible_travel_admin.yaml`: geo-anomaly sign-ins for admin-class test account.

---

## Key Detections
- **Abnormal Exfil Volume (KQL):** `detections/exfil-abnormal-volume.kql` (spike vs 14-day baseline).  
- **Impossible Travel (KQL):** `detections/impossible-travel.kql` (speed threshold across sign-ins).  
- **Outbound to File-Sharing (SPL):** `detections/exfiltration.spl` (proxy/firewall to OneDrive/Dropbox/Box).

---

## Automated Response (SOAR)
- **Suspend+Revoke:** `playbooks/suspend-user-and-revoke-tokens.jsonc`  
- **Quarantine File:** `playbooks/quarantine-sensitive-file.jsonc`  
- **Notify HR/Legal:** `playbooks/alert-hr-legal.jsonc`

---

## Artifacts
- **Sanitized Insider Threat Policy:** `policy/insider-threat-policy.md`  
- **Sentinel Workbook:** `workbook/insider-threat-workbook.jsonc`  
- **ATT&CK Coverage Matrix:** `mitre-mapping/ATTACK_Coverage_Matrix.xlsx` (CSV available)

---

## Learning Outcomes
- Build **UEBA baselines** and detect anomalies across identity, device, and data layers.  
- Operationalize **Purview DLP** and integrate signals into SIEM/Workbooks.  
- Automate **containment actions** with Logic Apps and track outcomes.  
- Communicate **MITRE ATT&CK coverage** to executives and auditors.
