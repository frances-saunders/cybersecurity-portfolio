
# AKS Hardening in Azure

## Problem / Challenge

Azure Kubernetes Service (AKS) provides agility and scalability, but by default exposes organizations to risks such as insecure networking, privilege escalation, and deployment of workloads from unapproved sources.

During audits and reviews, gaps were identified:

* Lack of enforced baseline **network restrictions** between pods and external services.
* Developers creating **privileged containers** and using unapproved registries.
* Inconsistent enforcement of **RBAC roles and pod-level security standards**.
* Use of **host namespaces** that could lead to privilege escalation.
* Minimal automation for cluster governance, creating drift from hardened standards.

The challenge was to design and implement a **compliance baseline** that enforced security controls across AKS in a repeatable, automated, and auditable way.

---

## Role & Tools

**Role:** Cloud Security Administrator (solo project)
**Tools & Technologies:** Azure Policy, Kubernetes RBAC & Network Policies, Terraform, kubectl

---

## Lab Structure

```
aks-hardening/
├── manifests/                         
│   ├── network/                       
│   │   ├── README.md
│   │   ├── allow-dns-egress.yaml
│   │   ├── allow-egress-to-acr.yaml
│   │   ├── allow-frontend-backend.yaml
│   │   └── default-deny-all.yaml
│   ├── rbac/                          
│   │   ├── dev-role.yaml
│   │   ├── dev-rolebinding.yaml
│   │   └── pod-reader-role.yaml
│   └── README.md
├── policies/                          
│   ├── assignments/
│   │   └── aks-security-baseline-assignment.jsonc
│   ├── definitions/
│   │   ├── block-privileged-containers.jsonc
│   │   ├── enforce-network-policy.jsonc
│   │   └── restrict-approved-registries.jsonc
│   └── initiatives/
│       └── aks-security-baseline-initiative.jsonc
├── terraform/                         
│   ├── README.md
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── variables.tf
└── README.md                  
````

## Actions Taken

### Policy Authoring (AKS Security Baseline)

Created Azure Policy definitions targeting AKS clusters to enforce:

* **Block privileged containers**.
* **Restrict unapproved registries**.
* **Require NetworkPolicies** for namespaces.
* **Enforce pod security standards** (baseline/restricted profiles).
* **Restrict host namespaces** (hostNetwork, hostPID, hostIPC).

### Initiative (Policy Bundling)

Bundled the above policies into a **AKS Security Baseline Initiative**.

* Centralized enforcement parameters for consistency.
* Mapped controls to **CIS Kubernetes Benchmark**, **NIST SP 800-53**, and **ISO 27001**.
* Enabled modular rollout by separating network, container, and RBAC controls.

### Assignments at Scope

Applied the initiative at the subscription/resource group level.

* **Deny** used for high-severity risks (privileged containers, host namespaces).
* **Audit** used for phased rollout of lower-risk controls.
* Scoped exclusions for non-production clusters.

### Kubernetes Workload Controls

Applied workload-level Kubernetes manifests:

* **Network policies** – deny-all baseline, allow DNS, allow ACR egress, allow frontend–backend traffic.
* **RBAC roles** – developer role, role bindings, and pod-reader role.

### Infrastructure as Code (Terraform)

Provisioned AKS clusters and security controls through Terraform.

* `main.tf`, `variables.tf`, `outputs.tf`, and `terraform.tfvars` deploy AKS with secure defaults.
* Automated policy set assignment at provisioning time.
* Integrated Log Analytics workspace for monitoring and audit.

---

## Results / Impact

* Hardened AKS workloads against **privilege escalation and insecure deployments**.
* Reduced risk of **lateral movement** through deny-by-default networking.
* Enforced pod-level security standards aligned with CIS benchmarks.
* Automated environment builds with Terraform for **consistency and auditability**.
* Delivered a reusable **AKS hardening blueprint** for enterprise workloads.

---

## Artifacts

**Policy Definitions**

* Block Privileged Containers
* Restrict Approved Registries
* Enforce NetworkPolicy
* Enforce Pod Security Standards
* Restrict Host Namespace

**Initiative**

* AKS Security Baseline Initiative

**Assignment**

* Subscription-level AKS Security Baseline Assignment

**Kubernetes Manifests**

* Network Policies (deny-all, DNS egress, ACR egress, frontend-backend)
* RBAC Roles (developer, role binding, pod reader)

**Terraform**

* IaC for AKS cluster provisioning and policy assignment

---

## Key Takeaways

This lab demonstrates advanced skills in **cloud-native security, Policy as Code, and Infrastructure as Code**. Key outcomes include:

* Deployment of an **end-to-end AKS hardening baseline**.
* Alignment with **industry benchmarks (CIS, NIST, ISO 27001)**.
* Integration of governance and workload-level security.
* Repeatable, automated, and auditable deployments.
