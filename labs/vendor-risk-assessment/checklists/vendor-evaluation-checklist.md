# Vendor Evaluation Checklist

This checklist is used to perform a structured review of a vendor’s security, compliance, and governance maturity.

---

## 1. Security Program & Governance
- [ ] Written Information Security Policy maintained and reviewed annually
- [ ] Dedicated CISO or equivalent security leader
- [ ] Security program reviewed annually by executive leadership
- [ ] Security awareness training conducted at least annually
- [ ] Background checks performed on all employees with sensitive access

---

## 2. Identity & Access Management (IAM)
- [ ] Supports Single Sign-On (SSO) via SAML, OAuth, or OpenID Connect
- [ ] Role-based access control (RBAC) enforced
- [ ] Multi-factor authentication (MFA) enforced for all accounts
- [ ] Timely deprovisioning of terminated users
- [ ] Access reviews conducted quarterly

---

## 3. Data Protection
- [ ] Data encrypted at rest with AES-256 or stronger
- [ ] Data encrypted in transit with TLS 1.2+ (preferably TLS 1.3)
- [ ] Customer data logically segregated from other tenants
- [ ] Secure key management via HSM/KMS
- [ ] Documented data retention and deletion policies

---

## 4. Application & Infrastructure Security
- [ ] Secure Software Development Lifecycle (SDLC) documented
- [ ] Threat modeling performed for major releases
- [ ] Regular vulnerability scanning performed
- [ ] Independent penetration testing (annual or more frequent)
- [ ] Documented patch management and remediation SLA
- [ ] Cloud infrastructure aligned with CIS Benchmarks

---

## 5. Incident Response & Business Continuity
- [ ] Documented Incident Response (IR) plan
- [ ] Breach notification SLA defined (e.g., 72 hours)
- [ ] Disaster Recovery (DR) testing conducted annually
- [ ] Recovery Time Objective (RTO) defined and acceptable
- [ ] Recovery Point Objective (RPO) defined and acceptable
- [ ] Business Continuity Plan (BCP) tested annually

---

## 6. Third-Party & Supply Chain Management
- [ ] Vendor performs due diligence on subcontractors
- [ ] Right-to-audit clauses included in contracts
- [ ] Data residency and sovereignty requirements supported
- [ ] Supplier code of conduct in place
- [ ] Continuous monitoring of high-risk third parties

---

## 7. Privacy & Compliance
- [ ] GDPR compliance (Data Processing Agreement, SCCs if applicable)
- [ ] HIPAA compliance (if handling PHI)
- [ ] CCPA compliance (if handling California residents’ data)
- [ ] PCI DSS compliance (if handling payment card data)
- [ ] FedRAMP/StateRAMP authorization (if servicing government clients)
- [ ] ISO/IEC 27001 certification
- [ ] SOC 2 Type II report available
