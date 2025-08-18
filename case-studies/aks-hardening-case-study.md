# Case Study: AKS Hardening in Azure

## Problem / Challenge

Kubernetes provides flexibility and scalability, but by default it is not secure enough for enterprise workloads. Azure Kubernetes Service (AKS), if deployed without guardrails, leaves organizations vulnerable to:

* **Privileged containers** with escalated access.
* **Unrestricted image pulls** from unapproved registries.
* **Lack of NetworkPolicies**, allowing lateral movement.
* **Inconsistent RBAC enforcement**, risking excessive access.
* **Use of host namespaces** (`hostNetwork`, `hostPID`, `hostIPC`), which could lead to privilege escalation.

During audits, these risks were identified as high-priority gaps that required a **repeatable security baseline** for AKS.

---

## Tools

**Tools & Technologies:** Azure Policy, Kubernetes RBAC, Kubernetes Network Policies, Terraform, kubectl

---

## Actions Taken

### Policy Authoring

I authored custom Azure Policies to cover container runtime and networking security:

* Block privileged containers.
* Restrict workloads to approved registries.
* Require namespace-level NetworkPolicies.
* Enforce pod security standards (baseline/restricted profiles).
* Restrict host namespaces (hostNetwork, hostPID, hostIPC).

### Initiative Development

I bundled the policies into an **AKS Security Baseline Initiative** that:

* Centralized parameters for flexible enforcement.
* Mapped to **CIS Kubernetes Benchmark**, **NIST SP 800-53**, and **ISO 27001**.
* Allowed modular assignment of networking, container, and RBAC controls.

### Policy Assignments

The initiative was assigned at the subscription level:

* **Deny** mode for high-risk settings (privileged containers, host namespaces).
* **Audit** mode for phased rollout of lower-risk controls.
* Scoped exclusions for dev/test clusters.

### Workload Security (Kubernetes Manifests)

I implemented YAML manifests to enforce workload controls:

* **Network Policies:** deny-all baseline, allow DNS egress, allow ACR egress, allow frontend–backend communication.
* **RBAC Roles:** developer role, role bindings, pod-reader role.

### Infrastructure as Code (Terraform)

Using Terraform, I automated cluster provisioning with embedded security:

* Defined AKS with secure defaults (`main.tf`, `variables.tf`, `outputs.tf`, `terraform.tfvars`).
* Integrated policy assignments into Terraform.
* Linked monitoring with Log Analytics for compliance visibility.

---

## Results / Impact

* Built an **end-to-end AKS hardening model** covering governance and workloads.
* Eliminated insecure practices like privileged containers and unapproved registries.
* Reduced attack surface by requiring deny-by-default networking.
* Embedded CIS benchmark and NIST controls into AKS operations.
* Delivered a **reusable Terraform-driven blueprint** for secure cluster deployments.

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

* AKS Security Baseline Subscription Assignment

**Kubernetes Manifests**

* Network Policies (deny-all, DNS egress, ACR egress, frontend-backend)
* RBAC Roles (developer, role binding, pod reader)

**Terraform**

* IaC for secure AKS provisioning and policy enforcement

---

## Key Takeaways

This project highlights my ability to:

* Apply **Policy as Code** to secure container platforms.
* Enforce **pod-level and cluster-level security standards**.
* Automate provisioning with **Infrastructure as Code**.
* Align enterprise Kubernetes deployments with **CIS, NIST, and ISO 27001** benchmarks.

The end result was a hardened, automated, and auditable AKS deployment model — transforming AKS from a flexible but exposed platform into a secure foundation for enterprise workloads.
