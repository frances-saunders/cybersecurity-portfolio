# Cyber Surety Compliance & AIS Monitoring Lab

## Overview

This lab demonstrates **how Air Force Cyber Surety operations were enforced on classified systems** between 2015–2018.
It highlights **AIS monitoring, encryption enforcement, and CCRI audit readiness**, while staying sanitized for portfolio presentation.

The project includes:

* A **sanitized playbook excerpt** showing AIS monitoring and compliance checklists.
* Example **STIG compliance tracking artifacts**.
* **Sample HBSS/ACAS reporting outputs** (sanitized JSON/CSV).
* A mock **SIEM correlation rule** (Splunk/ArcSight syntax).
* Example **audit prep documentation** reflecting CCRI readiness procedures.

---

## Problem / Challenge

The Cyber Surety team needed to:

* Ensure **classified AIS systems were encrypted** and compliant with DoD cryptographic requirements.
* Maintain **HBSS (McAfee ePO) monitoring** across thousands of endpoints.
* Perform **ACAS (Nessus/SecurityCenter) vulnerability scans** on a recurring basis.
* Be ready for **CCRI and IG inspections**, with zero tolerance for deficiencies.
* Correlate events in **SIEM platforms (ArcSight/Splunk)** for actionable intelligence.

---

## Tools & Technologies (2015–2018)

* **HBSS (McAfee ePO + ESM)** – endpoint enforcement & removable media control
* **ACAS (Nessus + SecurityCenter)** – vulnerability scanning & compliance validation
* **DISA STIGs** – configuration hardening standards
* **ArcSight / Splunk** – centralized SIEM log collection & correlation
* **BitLocker** – disk encryption on classified endpoints
* **PKI Certificates** – authentication & secure comms
* **CCRI / DIACAP-to-RMF** frameworks – audit & accreditation

---

## Actions Taken

1. **AIS Monitoring & Enforcement**

   * Configured **HBSS dashboards and alerts** to track non-compliant endpoints.
   * Tuned detection policies to reduce noise while surfacing critical events.
   * Integrated HBSS/ACAS logs into SIEM for cross-correlation.

2. **Encryption & Media Controls**

   * Verified 100% **BitLocker disk encryption** across classified systems.
   * Enforced **removable media restrictions** through HBSS and random audits.
   * Ensured PKI integration for access and encrypted communications.

3. **Compliance Auditing & CCRI Prep**

   * Ran **weekly ACAS scans**, tracked findings against STIG checklists.
   * Conducted **mock CCRIs**, identifying and remediating deficiencies early.
   * Documented **risk acceptance and mitigation plans** for leadership.

---

## Artifacts

```
labs/
└── cyber-surety-ais/
    ├── README.md                     # Lab documentation
    ├── playbooks/
    │   └── compliance-checklist.md   # Sanitized DR/CCRI checklist
    ├── reports/
    │   ├── hbss-sample-report.json   # Sample HBSS dashboard output
    │   └── acas-scan-results.csv     # Sanitized ACAS scan results
    ├── siem/
    │   └── anomalous-logons.rule     # Example ArcSight/Splunk correlation rule
    └── audits/
        └── ccri-prep-doc.md          # Mock CCRI inspection readiness doc
```

---

## Results / Impact

* Achieved **zero critical CCRI findings** across multiple inspections.
* Validated **100% encryption compliance** for classified AIS.
* Cut **false positives in HBSS alerts by 30%**, improving analyst efficiency.
* Reduced inspection prep effort by **standardizing compliance playbooks**.

---

## Key Takeaways

This lab demonstrates my ability to:

* Enforce **cybersecurity compliance on classified systems**.
* Manage **enterprise-scale monitoring and vulnerability scanning**.
* Prepare and pass **rigorous DoD audits** (CCRI, IG).
* Apply lessons from **2015–2018 military cyber defense** to modern enterprise and cloud environments.
