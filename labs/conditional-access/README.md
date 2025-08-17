# Conditional Access Baseline in Azure AD

## Problem / Challenge

Identity remains the primary attack vector in cloud environments. Audit findings revealed significant risks within Azure Active Directory (AAD):

* Users could sign in without multi-factor authentication (MFA).
* Legacy authentication protocols (e.g., IMAP, POP, SMTP) were still allowed.
* Sign-ins from untrusted geographic locations were not restricted.
* Device compliance was not enforced, allowing unmanaged endpoints to access corporate data.

The challenge was to design and enforce a **Conditional Access (CA) baseline** that reduced account takeover risk, enforced strong authentication, and aligned access controls with Zero Trust principles.

---

## Role & Tools

**Role:** Azure Administrator / Security Engineer (solo project)  
**Tools & Technologies:** Azure AD Conditional Access, Azure Policy (initiative + assignment), Microsoft Entra admin portal

---

## Actions Taken

### Broad Policy Authoring (Conditional Access Controls)

Designed JSONC-based policies for core identity protections:

* **Require MFA** – enforced MFA for all users except emergency break-glass accounts.
* **Block Legacy Authentication** – prevented usage of protocols bypassing MFA.
* **Require Compliant Devices** – ensured only Intune-managed or compliant devices could access cloud apps.
* **Restrict Sign-ins by Location** – denied authentication from countries outside the corporate region.
* **Require MFA for Azure Portal Access** – enforced stronger controls for administrative entry points.

### Initiative (Policy Set) for CA Baseline

Grouped individual Conditional Access policies into a **CA Baseline Initiative**.

* Standardized enforcement levels (Enforce / Audit).
* Mapped to **NIST 800-53 (IA-2, IA-5)** and **CIS Controls v8**.
* Provided a single baseline that could be assigned to management groups or tenants.

### Assignment at Scope

Applied the **CA Baseline Initiative Assignment** at the **management group** scope:

* Enforced all policies across production and lab tenants.
* Allowed exclusions for emergency accounts.
* Set effect = `Enforce` for high-impact controls.

---

## Results / Impact

* Reduced the attack surface by eliminating legacy protocols.
* Implemented **tenant-wide MFA** for privileged and standard users.
* Ensured only compliant, managed devices could access sensitive apps.
* Restricted unauthorized geographic access to corporate resources.
* Delivered a **repeatable, policy-driven Conditional Access baseline** for enterprise use.

---

## Artifacts

**Policy Definitions (Conditional Access Examples)**

* Require MFA
* Block Legacy Authentication
* Require Compliant Devices
* Restrict by Location
* Require MFA for Azure Portal

**Initiative**

* CA Baseline Initiative

**Assignment**

* CA Baseline Assignment

---

## Key Takeaways

This project demonstrates my ability to secure identities through **Conditional Access governance**, **Zero Trust enforcement**, and **policy-driven automation**. While the portfolio highlights a core baseline, the actual enterprise implementation extended to workload-specific CA policies (e.g., Exchange Online, SharePoint Online, Privileged Identity Management).

The CA Baseline initiative shows my expertise in:

* Designing **enterprise-ready identity security baselines**.
* Enforcing compliance with **NIST and CIS standards**.
* Delivering scalable, auditable IAM controls across tenants.
