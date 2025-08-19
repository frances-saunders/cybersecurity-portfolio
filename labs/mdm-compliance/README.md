# Mobile Device Management (MDM) Compliance Lab

## Objective
This lab demonstrates **mobile device management (MDM) best practices** using Microsoft Intune.  
The goal is to show how security baselines and compliance policies improve enterprise device security across **Android, iOS/iPadOS, and Windows 11** platforms.

## Scenario
A demo Intune environment was created to simulate a mixed device fleet:
- Employees choose **Android or iOS** for their personal/work phones.
- All employees are issued a **Windows 11 corporate laptop**.

Initial compliance reports highlighted issues such as:
- Devices without encryption.
- Weak or simple passcodes.
- Lack of biometric authentication.
- Jailbroken/rooted devices not being flagged.
- Windows machines without BitLocker, Secure Boot, or up-to-date Defender.

MDM policies were then applied to enforce:
- **Encryption** (BitLocker, FileVault, Android/iOS encryption).
- **Strong authentication** (PIN, alphanumeric passwords, biometrics).
- **OS version controls** to ensure patch levels.
- **Jailbreak/root detection**.
- **Threat protection integration** with Defender ATP / Play Protect.
- **Conditional Access** to block noncompliant devices from corporate apps.

## Implementation Steps
1. **Provision Intune MDM Environment**
   - Configured a demo Azure tenant with Intune enabled.
   - Registered Android, iOS, and Windows devices.

2. **Baseline Reporting (Before)**
   - Exported compliance data via Intune CSV.
   - Verified encryption gaps, weak passcodes, and missing security controls.

3. **Policy Deployment**
   - Applied platform-specific compliance policies:
     - [`policies/android-device-compliance-policy.jsonc`](policies/android-device-compliance-policy.jsonc)
     - [`policies/ios-device-compliance-policy.jsonc`](policies/ios-device-compliance-policy.jsonc)
     - [`policies/windows-device-compliance-policy.jsonc`](policies/windows-device-compliance-policy.jsonc)
   - Policies enforced encryption, strong authentication, OS version requirements, and threat detection.

4. **Post-Policy Reporting (After)**
   - Exported new compliance data and validated that **all noncompliant devices were remediated or blocked**.
   - Reports show improvement from partial compliance to **100% compliance across 2,740 devices**.

## Results
See detailed reporting artifacts:
- [Compliance Report (Markdown summary)](compliance-report.md)  
- [Raw Intune Export (CSV)](intune-compliance-report.csv)

### Compliance Summary
| Platform  | Devices Evaluated | Compliance Before | Compliance After |
|-----------|-------------------|-------------------|-----------------|
| Android   | 623               | 38%               | 100%            |
| iOS       | 747               | 44%               | 100%            |
| Windows   | 1,370             | 52%               | 100%            |
| **Overall** | **2,740**        | **45%**           | **100%**        |

## Value Demonstrated
- Shows ability to design and enforce **enterprise-grade MDM baselines**.
- Demonstrates **cross-platform security expertise** (Android, iOS, Windows).
- Includes **before/after compliance reporting** to measure impact.
- Highlights integration of **Zero Trust principles** (Conditional Access + MDM).
- Provides both **summarized reporting** and **raw CSV data** for realism.
