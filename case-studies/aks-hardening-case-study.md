# AKS Hardening in Azure

## Problem / Challenge

The Azure Kubernetes Service (AKS) platform provides agility and scalability but by default leaves organizations exposed to risks such as overly permissive networking, privilege escalation, and deployment of insecure workloads.
During audits and security reviews, gaps were identified around:

* Lack of baseline network restrictions between pods and external services.
* Developers creating privileged containers and pulling images from unapproved registries.
* Inconsistent RBAC role enforcement across namespaces.
* Minimal automation for cluster provisioning, making environments drift away from hardened standards.

The challenge was to design and implement a security baseline that enforced **network, RBAC, and workload controls** across AKS clusters in a repeatable, automated, and auditable way.

---

## Role & Tools

**Role:** Cloud Admin / Security Lead (solo project)
**Tools & Technologies:** Azure Policy, Kubernetes RBAC & Network Policies, Terraform, kubectl

---

## Actions Taken

### Broad Policy Authoring (AKS Security Baseline)

Designed and implemented Azure JSONC policy definitions targeting AKS, including:

* **Networking controls** – enforced namespace-level network policies, blocked workloads without policies, and required deny-by-default rules.
* **Container security** – restricted privileged containers, enforced approved image registries, and required baseline pod security standards.
* **Governance & RBAC** – ensured least-privilege developer roles with namespace scoping.

These policies aligned with CIS Kubernetes Benchmarks, NIST SP 800-53, and Microsoft’s AKS Baseline reference architecture.

### Initiative (Policy Sets) for AKS Compliance

Grouped individual policies into an **AKS Security Baseline initiative**.

* Centralized parameters for consistent enforcement across clusters.
* Metadata mapped controls to CIS Kubernetes Benchmark and NIST standards.
* Created modular bundles so specific controls (e.g., network vs. container) could be assigned separately.

### Assignments at Scope

Applied the **AKS Security Baseline initiative assignment** at the subscription level.

* Used `Deny` for critical violations (e.g., privileged containers).
* Scoped exclusions for dev/test clusters.
* Allowed `Audit` mode in phased rollout for less critical policies.

### Kubernetes Manifests for Workload-Level Security

Developed manifests for:

* **Network Policies** – `default-deny-all.yaml`, `allow-dns-egress.yaml`, `allow-egress-to-acr.yaml`, `allow-frontend-backend.yaml`.
* **RBAC Roles** – `dev-role.yaml`, `dev-rolebinding.yaml`, `pod-reader-role.yaml`.

These were applied via kubectl and versioned in Git for traceability.

### Infrastructure as Code (Terraform)

Automated AKS provisioning and security integration using Terraform.

* `main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars` deployed AKS clusters with secure defaults.
* Integrated policy assignments and role bindings into Terraform workflow.
* Enabled consistent deployment across multiple environments.

---

## Results / Impact

* Implemented an **end-to-end AKS security baseline** with both policy-driven and manifest-level controls.
* Hardened workloads against privilege escalation and unapproved registries.
* Reduced risk of lateral movement through deny-by-default networking.
* Streamlined environment builds with repeatable Terraform automation.
* Established a reusable blueprint for AKS hardening that can be extended to other containerized workloads.

---

## Artifacts (Networking & RBAC Examples Only)

While this portfolio only demonstrates AKS networking, RBAC, and container policies for brevity and NDA compliance, the actual implementation included dozens of policies across governance, storage, and access controls.

**Policy Definitions (AKS Examples)**

* Block Privileged Containers
* Restrict Approved Registries
* Enforce Network Policy

**Initiative (AKS Example)**

* AKS Security Baseline Initiative

**Assignment (AKS Example)**

* AKS Security Baseline Assignment

**Kubernetes Manifests (Networking & RBAC)**

* Network policies (deny-all, DNS egress, ACR egress, frontend-backend)
* RBAC roles (developer, role binding, pod reader)

**Terraform**

* IaC for AKS cluster provisioning and policy assignments

---

## Key Takeaways

This project demonstrates my ability to secure containerized workloads through **policy-driven governance, Kubernetes workload controls, and IaC automation**. While the portfolio shows a subset of artifacts, the actual implementation enforced 100+ policies across multiple domains, resulting in:

* Consistent AKS hardening across clusters and environments.
* Compliance alignment with CIS Kubernetes Benchmarks and NIST controls.
* Automated, auditable, and repeatable deployments using Terraform.
* Integration of governance and workload controls for end-to-end security.

This initiative established a **repeatable AKS hardening model** that embedded security into both the cluster and workload layers, transforming AKS from a flexible but exposed platform into a secure foundation for enterprise workloads.
