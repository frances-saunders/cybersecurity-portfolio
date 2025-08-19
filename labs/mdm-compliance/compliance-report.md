# Device Compliance Report – Before vs After MDM Policies

This report demonstrates how the Android, iOS, and Windows compliance policies improved overall security posture in the demo lab.  
Devices were enrolled in Intune with no policies applied (baseline), then re-evaluated after compliance policies were enforced.  

---

## Android (Before vs After)

| Device ID | Encryption | Authentication Method | OS Version | Root/Jailbreak | Status Before   | Status After |
|-----------|------------|-----------------------|------------|----------------|-----------------|--------------|
| AND-001   | No         | 4-digit PIN           | 11.0       | Rooted         | Noncompliant    | Compliant    |
| AND-002   | Yes (AES)  | Biometric + PIN       | 13.0       | Clean          | Compliant       | Compliant    |

- **Devices evaluated:** 623  
- **Compliance before policies:** 38%  
- **Compliance after policies:** 100%  

---

## iOS/iPadOS (Before vs After)

| Device ID | Encryption | Authentication Method | OS Version | Jailbreak  | Status Before   | Status After |
|-----------|------------|-----------------------|------------|------------|-----------------|--------------|
| IOS-101   | No         | Simple 4-digit PIN    | 15.4       | Jailbroken | Noncompliant    | Compliant    |
| IOS-102   | Yes (AES)  | Biometric + Passcode  | 16.1       | Clean      | Compliant       | Compliant    |

- **Devices evaluated:** 747  
- **Compliance before policies:** 44%  
- **Compliance after policies:** 100%  

---

## Windows 11 (Before vs After)

| Device ID | BitLocker | Secure Boot | TPM | Defender AV    | Authentication Method | Status Before   | Status After |
|-----------|-----------|-------------|-----|----------------|-----------------------|-----------------|--------------|
| WIN-501   | No        | Disabled    | Absent | Outdated    | Password only         | Noncompliant    | Compliant    |
| WIN-502   | Yes       | Enabled     | TPM 2.0 | Up-to-date | Biometric + PIN       | Compliant       | Compliant    |

- **Devices evaluated:** 1,370 (equal to Android + iOS total)  
- **Compliance before policies:** 52%  
- **Compliance after policies:** 100%  

---

## Compliance Summary

| Platform    | Devices Evaluated | Compliance Rate (Before) | Compliance Rate (After)  |
|-------------|-------------------|--------------------------|--------------------------|
| Android     | 623               | 38%                      | 100%                     |
| iOS         | 747               | 44%                      | 100%                     |
| Windows     | 1,370             | 52%                      | 100%                     |
| **Overall** | **2,740**         | **45%**                    | **100%**                 |

---

**Result:** Applying Intune MDM policies closed critical security gaps by enforcing encryption, strong authentication (PIN + biometrics), OS version controls, and jailbreak/root detection.  
The environment moved from **45% baseline compliance** to **100% full compliance** across 2,740 devices.  
