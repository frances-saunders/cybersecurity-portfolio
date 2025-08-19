# Mobile Device Management (MDM) Compliance Lab

### Objective

Demonstrate **enterprise-grade mobile device management (MDM)** best practices using Microsoft Intune (or 42Gears), including **before-and-after compliance reporting** to highlight the impact of security baselines and policy enforcement.

---

### Scenario

In this lab, a demo environment was configured to simulate a **bring-your-own-device (BYOD)** and **corporate-owned device** setup. Initial compliance reports highlighted insecure configurations such as:

* Devices lacking encryption
* Outdated OS versions
* No enforced PIN/biometric requirement
* Jailbroken or rooted devices not flagged

Policies were then deployed using **Intune MDM profiles** (or 42Gears equivalents) to enforce:

* Device encryption (BitLocker/FileVault/Android encryption)
* Minimum OS versions
* Strong password/PIN policies with biometrics
* Jailbreak/root detection with conditional access blocks
* App protection policies to sandbox corporate data

---

### Implementation Steps

1. **Provision Demo Environment**

   * Created a dedicated Azure tenant (Intune) or 42Gears trial instance.
   * Registered test mobile devices (iOS & Android emulators + physical test device).

2. **Baseline Reporting (Before)**

   * Pulled compliance reports showing existing device posture.
   * Highlighted gaps in security, such as unencrypted storage or weak authentication.

3. **Policy Deployment**

   * Applied Intune Device Compliance Policies (or 42Gears equivalents).
   * Configured Conditional Access in Azure AD to block noncompliant devices from accessing corporate apps (e.g., Outlook, Teams).

4. **Post-Policy Reporting (After)**

   * Re-ran compliance reporting.
   * Confirmed that noncompliant devices were quarantined.
   * Showed improved compliance percentages with visuals (charts/tables).

---

### Artifacts Produced

* **Terraform/ARM template** (for Azure Intune setup) to auto-provision MDM lab environment.
* **Sample Intune JSON policy files** for device restrictions.
* **Before/After Compliance Reports** (screenshots or CSV exports).
* **Demo Pipeline** showing automated compliance check and export of reporting data to Log Analytics.

---

### Value Highlight

This lab demonstrates:
- How **MDM baselines** directly improve compliance and reduce risk.
- The use of **conditional access + MDM** for Zero Trust enforcement.
- Automation of compliance **reporting and visualization** for executive dashboards.
- Real-world alignment with **CIS benchmarks** and **NIST SP 800-124** for mobile device security.
