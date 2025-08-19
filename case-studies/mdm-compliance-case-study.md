# Case Study: Mobile Device Management (MDM) Compliance with Intune

## Problem / Challenge

Unmanaged or misconfigured devices present a significant risk to enterprise security. In the demo enterprise environment, recurring issues were identified:

* Many **Android devices** lacked encryption, allowed weak passcodes, or permitted rooted devices.
* **iOS/iPadOS devices** often used simple 4-digit passcodes, some were jailbroken, and several lagged behind on critical iOS updates.
* **Windows 11 laptops** (issued to all employees) had instances of BitLocker disabled, Secure Boot turned off, or outdated Defender signatures.
* Compliance was not enforced across the fleet, allowing noncompliant devices to access corporate resources.

The challenge was to establish a **repeatable MDM compliance baseline** that enforced secure configurations across Android, iOS, and Windows devices while demonstrating measurable compliance improvements.

---

## Tools & Technologies

Microsoft Intune, Azure Active Directory Conditional Access, Defender for Endpoint, Terraform (policy-as-code for Intune JSONC exports)

---

## Actions Taken

### Platform-Specific Compliance Policies

Designed and deployed Intune compliance policies tailored to each OS:

* **Android** – Required full-disk encryption, alphanumeric passcodes or biometric + PIN, blocked rooted devices, and enforced SafetyNet attestation.
* **iOS/iPadOS** – Required alphanumeric passcodes or FaceID/TouchID, blocked jailbroken devices, enforced iOS 16+ minimum, and integrated Defender for Endpoint iOS.
* **Windows 11** – Enforced BitLocker encryption, Secure Boot, TPM 2.0, Defender AV with up-to-date signatures, and Windows Hello for biometric login.

### Conditional Access Enforcement

* Linked Intune with Azure AD Conditional Access.
* Blocked noncompliant devices from accessing Outlook, Teams, and SharePoint until remediated.
* Ensured Zero Trust alignment by requiring device compliance as a precondition to resource access.

### Compliance Reporting & Governance-as-Code

* Exported **baseline compliance reports** to capture pre-policy state.
* Applied JSONC-based compliance policy definitions ([Android](policies/android-device-compliance-policy.jsonc), [iOS](policies/ios-device-compliance-policy.jsonc), [Windows](policies/windows-device-compliance-policy.jsonc)).
* Exported **post-policy reports** from Intune to show measurable improvements.
* Version-controlled all policies and reports in Terraform-style lab structure to ensure repeatability.

---

## Results / Impact

Compliance was improved across **2,740 devices** in the simulated enterprise:

| Platform    | Devices Evaluated | Compliance Before | Compliance After |
| ----------- | ----------------- | ----------------- | ---------------- |
| Android     | 623               | 38%               | 100%             |
| iOS         | 747               | 44%               | 100%             |
| Windows     | 1,370             | 52%               | 100%             |
| **Overall** | **2,740**         | **45%**           | **100%**         |

* Improved compliance from **45% to 100%**.
* Ensured only compliant devices could access enterprise resources.
* Demonstrated **cross-platform MDM governance** with measurable before/after evidence.
* Aligned with **NIST SP 800-53 CM**, **ISO 27001 A.12**, and **CIS Microsoft Intune Security Baseline**.

---

## Artifacts (MDM Examples Only)

* **Policies (JSONC)**

  * Android Device Compliance Policy
  * iOS/iPadOS Device Compliance Policy
  * Windows 11 Device Compliance Policy
* **Reports**

  * [Markdown Compliance Summary](compliance-report.md)
  * [Raw CSV Export](intune-compliance-report.csv) with device-level compliance states
* **Terraform Lab Structure**

  * Version-controlled policies and compliance exports under `labs/mdm-compliance/`

---

## Key Takeaways

This project demonstrates my ability to deliver **enterprise-scale MDM compliance governance**. Through a combination of **policy-driven enforcement, conditional access, and governance-as-code**, I successfully:

* Standardized compliance baselines across Android, iOS, and Windows.
* Blocked insecure devices from corporate resources using Conditional Access.
* Raised compliance from less than half of the fleet to 100%.
* Produced governance artifacts (reports + raw exports) to measure and communicate impact.

The MDM Compliance lab strengthened the **endpoint security foundation** of the enterprise, ensuring that every device — whether mobile or desktop — adhered to modern security standards before accessing sensitive resources.
