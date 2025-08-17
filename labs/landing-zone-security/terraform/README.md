# Landing Zone Baseline – Terraform Deployment

## Overview
This Terraform configuration demonstrates how to deploy a resource group and assign the **Landing Zone Baseline Initiative** to enforce governance controls.  
The assignment applies policies for naming conventions, required tags, allowed VM SKUs, and region restrictions, ensuring consistency across landing zone resources.

## Prerequisites
- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) v1.5+
- Azure CLI installed and authenticated (`az login`)
- Contributor or Policy Contributor permissions in the target subscription

## Files
- `main.tf` – Declares the resource group and policy assignment  
- `variables.tf` – Defines input variables such as location, tags, and initiative parameters  
- `outputs.tf` – Displays outputs for validation after deployment  

## Usage
1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the plan:

   ```bash
   terraform plan -var "initiative_id=<your_initiative_resource_id>"
   ```
3. Apply the configuration:

   ```bash
   terraform apply -var "initiative_id=<your_initiative_resource_id>"
   ```

   Confirm with `yes` when prompted.

## Parameters

The assignment accepts several parameters to enforce governance controls:

* **location** – Target Azure region (default: `eastus`)
* **tags** – Required tags applied to all resources (default includes `Owner`, `Environment`, `CostCenter`)
* **initiative\_id** – Resource ID of the Landing Zone Baseline initiative
* **name\_pattern** – Regex for naming standards (default: `^[a-z]{2,5}-[a-z0-9]{2,8}-[a-z]{2,5}$`)
* **required\_tags** – List of mandatory tags for resource compliance
* **allowed\_skus** – Approved VM SKUs for deployment

## Validation

After deployment, validate compliance:

```bash
az policy state list --query "[?policyAssignmentId=='<assignment_id>']"
```

Outputs are also available via:

```bash
terraform output
```

This will display:

* Resource Group ID
* Policy Assignment ID

## Cleanup

To remove resources created by this demo:

```bash
terraform destroy -var "initiative_id=<your_initiative_resource_id>"
```

