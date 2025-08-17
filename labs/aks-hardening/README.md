# AKS Hardening Lab

This lab demonstrates the implementation of the **Azure Kubernetes Service (AKS) Security Baseline** using a combination of Azure Policies, Terraform infrastructure as code, and Kubernetes best practices. It is designed to showcase applied security skills in cloud-native environments while maintaining compliance with enterprise requirements.

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

---

## Objectives

- Deploy a hardened AKS cluster aligned with Microsoft’s security baseline.  
- Enforce compliance and security controls using Azure Policy assignments.  
- Validate cluster networking restrictions through Kubernetes Network Policies.  
- Implement RBAC policies for least-privilege access control.  
- Demonstrate infrastructure-as-code practices with Terraform.  

---

## Prerequisites

- **Azure CLI** installed and authenticated (`az login`).  
- **kubectl** installed and configured.  
- **Terraform CLI** v1.3 or later.  
- Permissions to create and manage:
  - Resource Groups  
  - AKS Clusters  
  - Networking resources (VNets, Subnets, NSGs)  
  - Azure Policy definitions and assignments  

---

## Deployment Workflow

1. **Provision Infrastructure (Terraform)**  
   Navigate to the `terraform/` directory and deploy the AKS cluster:

   ```bash
   terraform init
   terraform plan -out aks-hardening.plan
   terraform apply "aks-hardening.plan"
    ```

Once complete, retrieve cluster credentials:

```bash
az aks get-credentials --resource-group <rg_name> --name <cluster_name>
kubectl get nodes
```

2. **Apply Security Policies (Azure Policy)**
   The following are enforced through policy definitions, initiatives, and assignments:

   * Restricting public IPs on AKS nodes
   * Enforcing Azure Monitor integration
   * Enabling diagnostic logging
   * Restricting insecure configurations

   Policy artifacts are located in the `policies/` directory.

3. **Validate Networking Controls (Kubernetes Manifests)**
   Deploy the sample workloads located in the `manifests/` folder:

   ```bash
   kubectl apply -f manifests/
   ```

   Then review the `manifests/network/README.md` for validation steps.
   Example verification commands:

   ```bash
   kubectl -n <namespace> get pods -l tier=frontend
   kubectl -n <namespace> get pods -l tier=backend
   kubectl get networkpolicy
   ```

4. **Validate RBAC Controls (Kubernetes Manifests)**
   Apply RBAC configuration:

   ```bash
   kubectl apply -f manifests/rbac/
   ```

   Test access restrictions by attempting to perform unauthorized actions using a service account bound by the rolebinding.

---

## Teardown

To clean up all resources:

```bash
terraform destroy
```

Ensure that no test workloads remain:

```bash
kubectl delete -f manifests/
```

---

## Security Considerations

* All configurations align with the AKS Security Baseline reference architecture.
* Policies are parameterized to support customization of effects (Audit, Deny, Disabled).
* Network Policies restrict pod-to-pod communication to enforce least-privilege.
* RBAC enforces least-privilege access across cluster roles and service accounts.
* Integration with Log Analytics enables centralized monitoring and auditing.

---

## References

* [Azure Kubernetes Service (AKS) Baseline Architecture](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/secure-baseline-aks)
* [Azure Policy for Kubernetes](https://learn.microsoft.com/azure/governance/policy/concepts/policy-for-kubernetes)
* [Terraform AKS Resource Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)

