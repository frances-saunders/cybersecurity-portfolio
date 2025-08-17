# Case Study: Conditional Access Baseline

## Problem / Challenge

Identity compromise is one of the most common attack vectors in cloud security. During internal audits and Microsoft Defender for Cloud Identity recommendations, several risks were identified in the organization’s Azure Active Directory (AAD):

* Users were authenticating without multi-factor authentication (MFA), leaving accounts exposed to phishing and credential theft.
* Legacy authentication protocols (IMAP, POP, SMTP) were still enabled, bypassing MFA and modern controls.
* Access from unmanaged devices was not restricted, allowing sensitive corporate data on endpoints outside IT control.
* Sign-ins from high-risk or untrusted geographic regions were not blocked.

The organization needed a **Conditional Access (CA) baseline** that reduced identity risk, aligned with Zero Trust, and was consistent, auditable, and scalable across multiple tenants.

---

## Role & Tools

**Role:** Azure Administrator / Security Engineer (solo project)
**Tools & Technologies:** Microsoft Entra ID (Azure AD) Conditional Access, Azure Policy (initiatives and assignments), Microsoft Security Benchmark, NIST SP 800-53, CIS Controls v8

---

## Actions Taken

### Policy Design

Developed JSONC-based Conditional Access policies to enforce enterprise identity protections:

* **Require MFA** – mandated MFA for all users, exempting only emergency break-glass accounts.
* **Block Legacy Authentication** – disabled insecure protocols like IMAP and POP.
* **Require Compliant or Hybrid-Joined Devices** – ensured that only Intune-managed or compliant devices could access applications.
* **Restrict Sign-ins by Location** – blocked authentication from unauthorized geographies.
* **Require MFA for Azure Portal Access** – protected administrative entry points with stricter controls.

### Initiative Development

Grouped these controls into a **CA Baseline Initiative**:

* Created standardized enforcement parameters (Audit vs. Enforce).
* Mapped each control to **NIST SP 800-53 IA-2, IA-5** and **CIS Controls v8 6.3, 6.7**.
* Documented metadata for compliance traceability.

### Assignment & Deployment

* Assigned the CA Baseline initiative at the **management group** scope.
* Configured exclusions for emergency access accounts to prevent tenant lockout.
* Phased rollout using Audit mode before moving to full Enforce.

---

## Results / Impact

* Eliminated insecure legacy authentication, reducing phishing-related risks.
* Enforced MFA tenant-wide, dramatically improving authentication strength.
* Restricted unauthorized geographic access, mitigating high-risk sign-ins.
* Ensured unmanaged devices could not access sensitive corporate applications.
* Established a **repeatable Conditional Access security baseline**, providing a reusable model for enterprise-wide Zero Trust adoption.

---

## Key Takeaways

This initiative demonstrated my ability to **design, enforce, and operationalize enterprise-scale identity protections**. The Conditional Access Baseline:

* Reduced identity risk across tenants by eliminating common attack vectors.
* Aligned with recognized frameworks (**NIST, CIS, Microsoft Security Benchmark**).
* Balanced **security and usability** through exclusions, phased rollout, and scoped enforcement.
* Delivered a scalable governance model that can be extended to app-specific or privileged access scenarios.

This project highlights my ability to **translate security frameworks into actionable, automated IAM controls** — a critical skill for securing modern cloud environments.

