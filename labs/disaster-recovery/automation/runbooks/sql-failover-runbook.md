# SQL Database Failover (Sanitized Example)

**Objective:** Fail over an Azure SQL database to its secondary region.

---

## Prerequisites
- Azure CLI and SQL tools installed
- Failover group configured between primary and secondary servers
- Access to Key Vault for SQL admin credentials

---

## Procedure

1. Authenticate to Azure:
   ```powershell
   az login --identity
   ```

2. Retrieve SQL Admin password securely from Key Vault:

   ```powershell
   $sqlPassword = az keyvault secret show `
     --vault-name dr-lab-keyvault `
     --name sql-admin-password `
     --query value -o tsv
   ```

3. Initiate failover:

   ```powershell
   az sql failover-group set-primary `
     --name dr-fog `
     --resource-group rg-dr-lab `
     --server dr-sql-secondary
   ```

4. Validate connection to the new primary:

   ```powershell
   sqlcmd -S dr-sql-secondary.database.windows.net `
     -U telemetryadmin `
     -P $sqlPassword `
     -Q "SELECT name, create_date FROM sys.databases"
   ```

---

**Notes:**

* SQL password is never stored in plaintext.
* Document elapsed RTO/RPO for compliance reporting.


