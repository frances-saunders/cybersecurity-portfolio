# Azure Policy-as-Code Lab – Network Control

## Overview
This lab demonstrates how Azure **Policy-as-Code (EPaC)** can be used to enforce networking security controls at scale. The project includes **policy definitions**, a bundled **initiative (policy set)**, and an **assignment** that applies the initiative across a subscription with optional exclusions.

The goal of this lab is to showcase end-to-end governance automation, aligned with **NIST, ISO 27001, and CIS Azure Benchmarks**, using Azure-native tooling and Infrastructure-as-Code principles.

---

## Lab Structure
```
azure-epac-lab/
│
├── policies/
│ ├── definitions/ # Individual policies
│ │ ├── block-dnspr-creation.json
│ │ └── restrict-public-ip.json
│ │
│ ├── initiatives/ # Bundled policies under a compliance set
│ │ └── network-control-initiative.json
│ │
│ └── assignments/ # Applied to scope (subscription/resource group)
│ └── network-control-assignment.json
```
## Step 1 – Policy Definitions
Individual JSON files that enforce specific security rules.  
Examples in this lab:
- **Block DNS Private Resolver Creation** – prevents unauthorized deployment of `Microsoft.Network/dnsResolvers`.  
- **Restrict Public IP Assignment** – blocks VMs and NICs from being provisioned with public IP addresses.  

These are parameterized for flexibility (`Audit`, `Deny`, or `Disabled`) and allow exclusions via resource group.

---

## Step 2 – Initiative (Policy Set)
Policies are grouped into an initiative for easier management and compliance alignment.  

- **Network Control Initiative**  
  - Bundles DNS, Private DNS Zone, Virtual Network Manager, and Public IP restrictions.  
  - Parameters are centralized so enforcement can be tuned without modifying the underlying definitions.  
  - Metadata explicitly maps to **NIST SP 800-53**, **ISO 27001**, and **CIS Benchmarks**.

---

## Step 3 – Assignment
The initiative is then **assigned at the subscription level**, enforcing consistent controls across the environment.  

Key features:
- **Scope** → Subscription-wide application.  
- **Parameter binding** → Allows tuning per control (e.g., DNS = Deny, VNM = Audit for phased rollout).  
- **Exclusions** → Jump boxes or bastion hosts can be exempted via `notScopes`.  

---

## Key Takeaways
- **Scalability** – moving from ad hoc manual governance to automated, reusable controls.  
- **Flexibility** – parameters and exclusions allow controlled rollout and exceptions.  
- **Compliance Alignment** – every control is mapped to a recognized framework.  
- **End-to-End Governance** – complete lifecycle from definition → initiative → assignment.  

---

## Next Steps
- Expand the initiative with additional networking and compute policies.  
- Integrate with **Azure DevOps pipelines** to deploy via Infrastructure-as-Code.  
- Visualize compliance state in **Azure Dashboards** for executive reporting.  

---

*Author: Frances Saunders – Cloud Security Architect Portfolio*
