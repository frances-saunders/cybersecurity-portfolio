# Storage Account Failover (Sanitized Example)

**Objective:** Fail over a primary storage account to its paired region.

---

## Prerequisites
- Azure CLI installed, or Azure Automation Runbook worker
- Permissions to initiate failover
- Access to Azure Key Vault for secrets

---

## Procedure

1. Authenticate to Azure with managed identity:
   ```bash
   az login --identity
   ```

2. Retrieve storage account key securely from Key Vault:

   ```bash
   STORAGE_KEY=$(az keyvault secret show \
     --vault-name dr-lab-keyvault \
     --name storage-account-key \
     --query value -o tsv)
   ```

3. Trigger the failover:

   ```bash
   az storage account failover \
     --name mystorageacct \
     --resource-group rg-dr-lab
   ```

4. Validate failover status:

   ```bash
   az storage account show \
     --name mystorageacct \
     --resource-group rg-dr-lab \
     --query "statusOfPrimary"
   ```

---

**Notes:**

* No credentials are stored in the script; all secrets come from Key Vault at runtime.
* Update DR dashboards with RTO/RPO values immediately after validation.

