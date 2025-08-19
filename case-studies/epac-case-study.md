# Case Study: Enterprise Policy-as-Code (EPaC) in Azure

## Problem / Challenge
The enterprise Azure environment was experiencing recurring **audit gaps and compliance drift** across hundreds of subscriptions. Security controls were being applied inconsistently, leading to manual remediation, slower audit readiness, and increased risk exposure.  

The challenge was to design and implement a **scalable governance framework** that enforced controls across multiple domains — networking, identity, access management, compliance, and resource management — in a repeatable, automated, and auditable way.

---

## Tools & Technologies
Azure Policy, Azure DevOps, Microsoft Defender for Cloud, Terraform, PowerShell  

---

## Actions Taken
1. **Broad Policy Authoring (100+ Policies Across Multiple Domains)**  
   Designed and implemented an extensive library of Azure **JSONC** policy definitions spanning:  
   - **Networking controls** – restrictions on DNS Private Resolvers, Private DNS zones, Virtual Network Manager, and Public IPs.  
   - **Resource management & governance** – enforced naming conventions, required tagging standards, and region restrictions.  
   - **Identity and access management** – restricted privileged role assignments, required MFA, and enforced Conditional Access policies.  
   - **Storage & compute** – ensured encryption at rest, blocked unapproved SKUs, and enforced managed disks.  

   These controls were designed to align with **NIST, ISO 27001, CIS Azure Benchmarks, and FedRAMP**.

2. **Initiative (Policy Sets) for Framework Alignment**  
   Grouped related policies into initiatives aligned to compliance domains (e.g., networking, IAM, storage).  
   - Centralized parameters for consistent enforcement.  
   - Metadata explicitly mapped controls to **NIST SP 800-53**, **ISO 27001**, and **FedRAMP Moderate**.  
   - Created a modular structure so initiatives could be assigned independently by compliance area.

3. **Assignments Across Enterprise Subscriptions**  
   Applied initiatives at subscription and management group levels to standardize enforcement across **120+ subscriptions**.  
   - Enforced strong defaults (`Deny` for high-risk violations, `Audit` for phased rollout).  
   - Scoped exclusions for specific environments (e.g., Bastion, Jump Host, or Dev test resource groups).  

4. **Automation & DevSecOps Integration**  
   - Integrated policy deployment into **Azure DevOps pipelines**, ensuring version control, peer review, and rollback.  
   - Developed **remediation scripts** (PowerShell and Bash) using `deployIfNotExists` to automatically fix noncompliant resources.  
   - Established “compliance as code” practices that embedded governance into CI/CD workflows.  

5. **Visibility & Reporting**  
   - Integrated with **Microsoft Defender for Cloud** to provide real-time compliance scoring and posture monitoring.  
   - Built **Azure dashboards/workbooks** with executive-level views of compliance metrics, violation trends, and remediation timelines.  
   - Partnered with compliance and audit teams to streamline evidence collection for ISO and FedRAMP audits.

---

## Results / Impact
- Authored and deployed **100+ policy definitions** across multiple compliance domains.  
- Improved overall enterprise compliance score from **68% → 96%** within six months.  
- Reduced recurring audit gaps by **90%** across subscriptions.  
- Cut average remediation time from **2 days → <30 minutes** through automation.  
- Saved **dozens of hours per audit cycle** by automating evidence collection.  
- Enabled leadership to make **faster, data-driven risk decisions** with real-time dashboards.  

---

## Artifacts (Networking Example Only)
While this portfolio only demonstrates networking-focused policies for brevity and NDA compliance, the actual project included policies across **identity, resource governance, storage, and compute**.  

- **Policy Definitions (Networking)**  
  - [Block DNS Private Resolver Creation](../labs/azure-epac-lab/policies/definitions/block-dnspr-creation.jsonc)  
  - [Restrict Public IP Assignment](../labs/azure-epac-lab/policies/definitions/restrict-public-ip.jsonc)  

- **Initiative (Networking Example)**  
  - [Network Control Initiative](../labs/azure-epac-lab/policies/initiatives/network-control-initiative.jsonc)  

- **Assignment (Networking Example)**  
  - [Network Control Assignment](../labs/azure-epac-lab/policies/assignments/network-control-assignment.jsonc)  

- **Lab Documentation**  
  - [Azure Policy-as-Code Lab Guide](../labs/azure-epac-lab/README.md)  

---

## Key Takeaways
This project demonstrates my ability to deliver **enterprise-scale governance automation** with Azure Policy-as-Code. While this portfolio highlights **networking controls** as representative examples, the actual implementation spanned **over 100 policies across identity, access, compliance, storage, and compute**, resulting in:  
- **Standardized compliance enforcement** across 120+ subscriptions.  
- **Audit-ready posture** aligned with NIST, ISO 27001, CIS, and FedRAMP.  
- **Automation-first governance** integrated into CI/CD pipelines.  
- **Executive visibility** into compliance through dashboards and reporting.  

This initiative established a **repeatable governance model** that embedded compliance into day-to-day cloud operations, transforming security from reactive to proactive.
