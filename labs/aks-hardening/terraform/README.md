# Terraform Deployment – AKS Hardening Lab

This folder contains Terraform configurations to deploy a hardened AKS cluster that aligns with the **AKS Security Baseline**. The deployment is modular, parameterized, and reusable for testing and demonstration purposes.

---

## Structure

```

terraform/
├── main.tf              # Core infrastructure definitions (Resource Group, VNet, AKS, etc.)
├── variables.tf         # Input variable definitions
├── outputs.tf           # Key outputs (cluster name, kubeconfig path, etc.)
└── terraform.tfvars     # Sample variables file (customize as needed)

````

---

## Prerequisites

- Terraform CLI v1.3 or later  
- Azure CLI with a logged-in session (`az login`)  
- Sufficient permissions to create:
  - Resource Groups
  - Virtual Networks and Subnets
  - AKS Clusters
  - Log Analytics Workspaces

---

## Deployment Steps

1. Initialize the working directory:

   ```bash
   terraform init
````

2. Validate and review the plan:

   ```bash
   terraform plan -out aks-hardening.plan
   ```

3. Apply the configuration:

   ```bash
   terraform apply "aks-hardening.plan"
   ```

   The following resources are provisioned:

   * AKS cluster with hardened settings
   * Networking resources (VNet, Subnet, NSGs if included)
   * Monitoring integration (Log Analytics workspace)

4. Retrieve cluster credentials and test access:

   ```bash
   az aks get-credentials --resource-group <rg_name> --name <cluster_name>
   kubectl get nodes
   ```

---

## Teardown

To remove all deployed resources, run:

```bash
terraform destroy
```

---

## Security Considerations

* The sample `terraform.tfvars` file contains placeholder values. Replace them with environment-specific values before applying.
* API server access is restricted using `api_server_authorized_ip_ranges`.
* Integration with Log Analytics supports monitoring and auditing.
* Policy definitions and assignments from the `policies/` folder can be applied alongside this baseline for additional compliance enforcement.

---

## References

* [Azure Kubernetes Service Baseline](https://learn.microsoft.com/azure/architecture/reference-architectures/containers/aks/secure-baseline-aks)
* [Terraform AKS Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster)

