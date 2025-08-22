# Case Study: Cyber Surety Compliance & AIS Monitoring

## Problem / Challenge

Between 2015 and 2018, classified Air Force Information Systems (AIS) required **rigorous cybersecurity enforcement** in accordance with DoD directives and Air Force Instructions (AFIs). The environment faced several persistent challenges:

* **Audit log monitoring** was time-consuming and inconsistent across systems.
* **Encryption enforcement** for classified networks demanded strict control of removable media, key management, and data-at-rest protections.
* **Compliance inspections** such as **CCRIs (Command Cyber Readiness Inspections)** and IG (Inspector General) audits required flawless execution, with zero tolerance for deficiencies.
* Systems operated in a **highly regulated environment**, where small deviations from compliance could impact mission readiness and accreditation.

The challenge was to ensure classified systems were **continuously compliant**, with effective monitoring, encryption enforcement, and inspection readiness baked into daily operations.

---

## Tools & Technologies (2015–2018)

* **HBSS (Host Based Security System, McAfee ePO)** – endpoint protection and centralized policy enforcement
* **ACAS (Assured Compliance Assessment Solution, Nessus + SecurityCenter)** – vulnerability scanning and compliance validation
* **DISA STIGs (Security Technical Implementation Guides)** – hardening standards for servers, endpoints, and networks
* **SIEM Platforms (ArcSight / Splunk, depending on site)** – centralized log collection and correlation
* **BitLocker & PKI Certificates** – disk encryption and secure communications enforcement
* **Removable Media Control (Endpoint Security Module, DoD-approved tools)** – strict enforcement of USB and media usage policies
* **DoD Inspection Frameworks** – CCRI, DIACAP/RMF transition, FISMA audits

---

## Actions Taken

1. **AIS Monitoring & HBSS Enforcement**

   * Led daily reviews of HBSS dashboards, tracking unauthorized changes, malware alerts, and policy non-compliance.
   * Tuned McAfee ePO policies to reduce false positives and ensure consistent enforcement across thousands of endpoints.
   * Integrated monitoring results into SIEM correlation rules for improved threat visibility.

2. **Encryption & Media Control**

   * Validated full-disk encryption via **BitLocker** and ensured compliance with DoD-approved cryptographic standards.
   * Enforced **removable media restrictions**, using HBSS/ESM to log and block unauthorized devices.
   * Conducted random spot checks and validated that classified systems adhered to cryptographic key management policies.

3. **Compliance Audits & CCRI Readiness**

   * Coordinated with teams to ensure all systems were **hardened against STIGs**, with documented exceptions properly risk-accepted.
   * Executed pre-inspection “mock CCRIs” that uncovered and resolved deficiencies before formal audits.
   * Authored sanitized compliance reports that gave leadership a clear view of system posture and upcoming risks.

4. **Lessons Learned Integration**

   * Documented **best practices for HBSS/ACAS use**, reducing inspection findings in subsequent CCRIs.
   * Standardized system security checklists across units, ensuring repeatable compliance.
   * Trained administrators on “**audit-ready every day**” operations to avoid last-minute remediation scrambles.

---

## Results / Impact

* Achieved **zero critical findings** in multiple CCRIs and compliance inspections.
* Increased encryption compliance to **100% across all classified systems** under scope.
* Improved AIS monitoring effectiveness, cutting **false positives by 30%** while surfacing higher-value alerts.
* Strengthened command-level confidence in system security and readiness.
* Contributed to a **smooth transition from DIACAP to RMF**, mapping control enforcement to NIST frameworks.

---

## Key Takeaways

This experience reinforced several enduring principles that remain central to enterprise security today:

* **Compliance is continuous** – inspection readiness must be a daily practice, not a quarterly scramble.
* **Encryption and key management are foundational** – without strong cryptography, classified and enterprise systems alike remain vulnerable.
* **Visibility is critical** – AIS monitoring tools must be tuned to provide actionable intelligence, not noise.
* **Standardization is scalability** – codified procedures reduce variance and ensure consistent security enforcement across large organizations.
