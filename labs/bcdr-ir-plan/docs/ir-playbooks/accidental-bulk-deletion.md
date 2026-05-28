# IR Playbook: Accidental Bulk Deletion

**Classification:** Internal — Security Operations  
**Playbook ID:** IR-002  
**Version:** 1.0  
**Owner:** Cloud Security Architecture  
**Last Tested:** 2025-01-18 (backup restore test) — see `docs/test-results.md` §1.2  
**Frameworks:** NIST SP 800-61 Rev. 2, ISO 27001 A.17.1

---

## Scenario Description

A bulk deletion event has occurred — either through an accidental script execution, misconfigured automation, an authorized user making an error at scale, or a malicious insider. Resources affected may include virtual machines, Azure Files shares, Blob Storage containers, SQL databases, Cosmos DB collections, or any combination. The deletion may have triggered cascading effects (e.g., deleting a VM that was being backed up cancels the backup job).

A critical variable in this scenario is time: Azure soft-delete provides a 14-day protection window for most resource types, but this window begins counting down at the moment of deletion. The burn rate matters — knowing how much of the window remains is essential to choosing the right recovery path.

---

## Detection Triggers

| Trigger | Source | Sentinel Rule / Monitor Alert |
|---|---|---|
| Bulk resource delete operations by a single identity | Azure Activity Log | `BCDR-BulkDelete-ActivityLog` |
| Azure Files share deletion | Storage Analytics / Activity Log | `BCDR-BulkDelete-AzureFiles` |
| Blob container mass deletion | Azure Monitor Storage Metrics | `BCDR-BulkDelete-BlobContainer` |
| SQL database delete operation | Azure Activity Log | `BCDR-SQLDelete-ActivityLog` |
| Cosmos DB collection delete | Azure Activity Log | `BCDR-CosmosDelete-ActivityLog` |
| Backup vault item delete or stop-protection with delete data | Azure Activity Log | `BCDR-VaultTamper-BackupItemDelete` |
| Manual escalation (user reports missing data) | Helpdesk / direct | N/A |

---

## Roles and Responsibilities

| Role | Responsibility |
|---|---|
| **Incident Commander** | Cloud Security Architect — scopes damage, authorizes recovery, communicates to leadership |
| **Investigation Lead** | Security Operations — identifies the identity responsible, determines whether deliberate or accidental |
| **Recovery Lead** | Platform Engineering — executes restore operations |
| **Communications Lead** | Engineering Lead — notifies affected business teams |

---

## Phase 1: Stop and Scope (T+0 to T+15)

### Step 1.1 — Immediately Check Soft-Delete Window Burn Rate

> **This is the most time-sensitive action in this playbook.** Soft-delete gives you 14 days, but the clock is already running. Run the burn-rate query immediately to understand your recovery window.

```kql
// Run in Log Analytics Workspace linked to Azure Monitor
// This query surfaces remaining soft-delete window for all deleted backup items
// Full query: kql/soft-delete-timeline.kql
AzureDiagnostics
| where Category == "AzureBackupReport"
| where OperationName == "DeleteBackupItem"
| extend DaysElapsed = datetime_diff('day', now(), TimeGenerated)
| extend DaysRemaining = 14 - DaysElapsed
| where DaysRemaining >= 0
| project TimeGenerated, BackupItemUniqueId, DaysElapsed, DaysRemaining, ProtectedContainerUniqueId
| order by DaysRemaining asc
```

> **Alert threshold:** If any item shows fewer than 3 days remaining, escalate immediately to the Incident Commander. The 14-day window is the only automated protection layer. After it expires, data is permanently gone without an alternate copy.

### Step 1.2 — Enumerate All Deleted Resources

```bash
# Query Activity Log for all delete operations in the last 24 hours
az monitor activity-log list \
  --start-time $(date -u -d "24 hours ago" +%Y-%m-%dT%H:%M:%SZ) \
    --filter "eventName.value eq 'Delete'" \
      --output table | grep -i "Succeeded"
      ```

      Document every deleted resource: name, type, resource group, time of deletion, and the identity (user or service principal) that performed the deletion.

      ### Step 1.3 — Scope Whether Deletion Was Accidental or Malicious

      Review the identity's recent Activity Log entries:

      - Did the identity perform other unusual actions in the same window?
      - Was this a service principal? If so, was it operating outside its normal schedule?
      - Was there any MFA challenge bypass or suspicious sign-in preceding the deletions?

      **If malicious:** Activate IR-004 (Credential Compromise) in parallel. Disable the identity immediately before proceeding to recovery.

      **If accidental:** Notify the identity's manager and document the root cause. No identity action required, but implement a resource lock policy review.

      ### Step 1.4 — Identify Whether Backup Vault Items Were Affected

      ```bash
      # Check for any backup items in "soft deleted" state
      az backup item list \
        --resource-group rg-bcdr-prod \
          --vault-name bcdr-vault-tier1 \
            --backup-management-type AzureIaasVM \
              --query "[?properties.deletionState=='ToBeDeleted']" \
                --output table
                ```

                If vault items are in soft-deleted state, they can be recovered within the retention window. Do not proceed to the next phase until you have a full list of affected vault items and their remaining window.

                ---

                ## Phase 2: Recovery Sequencing

                Recovery is performed in tier order — Tier 1 first, then Tier 2, then Tier 3. Within each tier, restore the most critical dependency first (e.g., databases before application servers).

                ### Step 2.1 — Recover Soft-Deleted Backup Items (Vault)

                ```bash
                # Undelete a soft-deleted backup item
                az backup item undelete \
                  --resource-group rg-bcdr-prod \
                    --vault-name bcdr-vault-tier1 \
                      --container-name "iaasvmcontainer;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
                        --item-name "vm;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
                          --backup-management-type AzureIaasVM \
                            --workload-type VM
                            ```

                            ### Step 2.2 — Recover Deleted Azure Files Shares

                            Azure Files shares in soft-deleted state can be recovered within the 14-day window:

                            ```bash
                            # Restore a soft-deleted file share
                            az storage share-rm restore \
                              --resource-group rg-prod-storage \
                                --storage-account <STORAGE_ACCOUNT_NAME> \
                                  --name <SHARE_NAME> \
                                    --deleted-version <DELETED_VERSION_ID>
                                    ```

                                    To find deleted shares and their version IDs:

                                    ```bash
                                    az storage share-rm list \
                                      --resource-group rg-prod-storage \
                                        --storage-account <STORAGE_ACCOUNT_NAME> \
                                          --include-deleted \
                                            --query "[?deleted==true].{name:name,version:version,deletedTime:properties.deletedTime}" \
                                              --output table
                                              ```

                                              ### Step 2.3 — Recover Deleted Blob Containers / Data

                                              If the storage account has versioning and soft-delete enabled:

                                              ```bash
                                              # List deleted containers
                                              az storage container list \
                                                --account-name <STORAGE_ACCOUNT> \
                                                  --include-deleted \
                                                    --query "[?deleted==true]" \
                                                      --output table

                                                      # Restore a deleted container (requires --restore flag)
                                                      az storage container restore \
                                                        --account-name <STORAGE_ACCOUNT> \
                                                          --name <CONTAINER_NAME> \
                                                            --deleted-version <VERSION>
                                                            ```

                                                            > **Note:** If the storage account itself was deleted and is within the Azure soft-delete window for storage accounts (default: 0 days unless configured), contact Microsoft Support immediately with the subscription ID and storage account name. This window is not enabled by default and may not be available.

                                                            ### Step 2.4 — Recover Deleted SQL Databases

                                                            Azure SQL databases deleted within the last 35 days can be recovered from a deleted database backup:

                                                            ```bash
                                                            az sql db restore \
                                                              --resource-group rg-prod-data \
                                                                --server prod-sql-server \
                                                                  --name prod-sqldb-orders-restored \
                                                                    --deleted-time "2025-01-18T10:30:00Z" \
                                                                      --time "2025-01-18T10:25:00Z" \
                                                                        --source-database-deletion-date "2025-01-18T10:30:00Z" \
                                                                          --dest-name prod-sqldb-orders-restored
                                                                          ```

                                                                          ### Step 2.5 — Recover Resources with No Soft-Delete Protection

                                                                          For resource types not covered by soft-delete (e.g., VMs that were not backup-enrolled, NSGs, VNets), use the most recent backup or ASR recovery point.

                                                                          If no backup exists, this is an unrecoverable loss for that resource. Document it and escalate to the Incident Commander for a business impact assessment.

                                                                          > **Lesson:** This scenario is why the Azure Policy `DeployIfNotExists` enforcement and the monthly coverage audit are non-negotiable. Resources without backup coverage have zero recovery options outside of soft-delete.

                                                                          ---

                                                                          ## Phase 3: Validation

                                                                          For each recovered resource:

                                                                          1. Verify the resource is healthy and responding (application health check or connectivity test).
                                                                          2. Verify data integrity — spot-check known records, file counts, or checksums where possible.
                                                                          3. Confirm backup enrollment is still active after recovery (recovery may require re-enrolling in the backup policy).
                                                                          4. Run `scripts/automation/backup-coverage-reporter.ps1` to confirm 100% coverage is restored.

                                                                          ---

                                                                          ## Phase 4: Stakeholder Notification

                                                                          **Initial notification (T+15):**

                                                                          > Subject: [ACTIVE INCIDENT] Bulk Resource Deletion — IR-002 Initiated  
                                                                          > Body: "[Data type / resource name] was deleted at [time] by [identity or 'an automated process under investigation']. Recovery is in progress. Estimated recovery time: [X hours based on tier]. We will update you at [time] or when recovery is complete."

                                                                          **Resolution notification:**

                                                                          > Subject: [RESOLVED] IR-002 — Resources Recovered  
                                                                          > Body: "All resources affected by the deletion event have been successfully recovered and validated. Services are operating normally. A post-incident review will be conducted within 5 business days. Root cause: [summary]."

                                                                          ---

                                                                          ## Phase 5: Post-Incident Requirements

                                                                          1. Within 24 hours: Document whether the deletion was caused by a missing resource lock, an over-permissioned identity, or a process error.
                                                                          2. Within 5 business days: Complete post-incident review using `docs/ir-playbooks/post-incident-review-and-evidence-packaging.md`.
                                                                          3. Immediate remediation for structural causes: apply Azure resource locks to all Tier 1 and Tier 2 resources if not already in place (`scripts/automation/resource-locks-guard.py`).
                                                                          4. Review and update the backup coverage audit results in `docs/test-results.md`.

                                                                          ---

                                                                          ## Compliance Mapping

                                                                          | Requirement | Framework Reference |
                                                                          |---|---|
                                                                          | Data recovery procedures | NIST SP 800-34 §3.4, ISO 27001 A.17.1 |
                                                                          | Incident documentation | NIST SP 800-61 Rev. 2 §3.4, ISO 27001 A.16.1.7 |
                                                                          | Backup integrity verification | SOC 2 CC9.1, ISO 27001 A.12.3 |
