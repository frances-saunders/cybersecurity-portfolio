# IR Playbook: Ransomware / Encryption Event

**Classification:** Internal — Security Operations  
**Playbook ID:** IR-001  
**Version:** 1.1 (updated post-tabletop exercise 2025-01-22)  
**Owner:** Cloud Security Architecture  
**Last Tested:** 2025-01-22 (tabletop) — see `docs/test-results.md` §1.4  
**Frameworks:** NIST SP 800-61 Rev. 2, ISO 27001 A.16.1

---

## Scenario Description

A ransomware actor has gained execution capability on one or more Azure VMs and is actively encrypting files. The actor may also be attempting to delete backup vault contents or disable soft-delete protection using a compromised identity to prevent recovery. The encryption event may be in progress or complete at the time of detection.

This playbook covers the full response lifecycle: detection through containment, backup integrity validation, recovery sequencing, evidence preservation, and post-incident review.

---

## Detection Triggers

This playbook is activated by any of the following:

| Trigger | Source | Sentinel Rule |
|---|---|---|
| Anomalous file encryption activity (high write rate to unusual file extensions) | Defender for Endpoint | `Ransomware-FileEncryption-VM` |
| Backup vault soft-delete disable attempt | Azure Activity Log | `BCDR-VaultTamper-SoftDeleteDisable` |
| Vault immutability override attempt | Azure Activity Log | `BCDR-VaultTamper-ImmutabilityOverride` |
| Bulk file deletion on Azure Files share | Azure Monitor / Storage Analytics | `BCDR-BulkDelete-AzureFiles` |
| Service principal making anomalous Recovery Services API calls | AAD Sign-in / Audit Log | `BCDR-AnomalousBackupAPICall` |
| Manual escalation from SOC analyst | N/A | N/A |

---

## Roles and Responsibilities

| Role | Responsibility |
|---|---|
| **Incident Commander** | Cloud Security Architect — owns all decisions, authorizes recovery actions, communicates to leadership |
| **Containment Lead** | Platform Engineering — executes VM isolation, snapshot actions, and identity actions |
| **Recovery Lead** | Platform Engineering — executes restore sequence and validates application health |
| **Evidence Lead** | Security Operations — runs evidence packager, maintains chain of custody |
| **Communications Lead** | Engineering Lead — drafts and sends all stakeholder notifications |

---

## Phase 1: Immediate Containment (T+0 to T+15 minutes)

**Goal:** Stop active encryption, preserve recovery capability, and prevent vault destruction. All steps in this phase must be completed within 15 minutes of playbook activation.

### Step 1.1 — Acknowledge and Scope (T+0 to T+5)

1. Acknowledge the Sentinel incident and assign to yourself.
2. Identify the affected VM(s) from the alert entity list.
3. Check `docs/workload-classification.md` to confirm the tier and data classification of each affected workload.
4. Open a War Room communication channel (Teams channel or bridge) and notify all role holders listed above.
5. **Do not attempt remediation before scoping.** Verify whether the encryption is still in progress (Defender for Endpoint timeline) or complete.

### Step 1.2 — Initiate On-Demand Snapshot BEFORE Isolation (T+5 to T+8)

> **Critical sequencing:** Snapshot must be taken before NIC detach. Isolating a VM that has an in-progress backup job will abort the job. An on-demand snapshot taken immediately captures the most recent state — even an encrypted state — which preserves the recovery point timeline and may be useful for forensics.

```bash
# On-demand snapshot via Azure CLI — run for each affected VM
az backup protection backup-now \
  --resource-group rg-prod-api \
    --vault-name bcdr-vault-tier1 \
      --container-name "iaasvmcontainer;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
        --item-name "vm;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
          --retain-until $(date -d "+30 days" +%Y-%m-%dT%H:%M:%SZ) \
            --backup-management-type AzureIaasVM
            ```

            ### Step 1.3 — Validate Backup Canary Integrity (T+5 to T+10, parallel with 1.2)

            Before committing to a recovery path, validate that the backup vault contents have not been tampered with. The backup canary is a known-good file written to an immutable, read-only storage account at each backup completion. Its SHA-256 hash is stored out-of-band.

            ```powershell
            # Validate canary file integrity — run from evidence storage context
            $canaryUri = "https://bcdrcanary.blob.core.windows.net/canary/canary-latest.json"
            $expected  = (Get-Content .\canary-hash-manifest.json | ConvertFrom-Json).sha256
            $actual    = (Invoke-RestMethod -Uri $canaryUri -Headers @{Authorization = "Bearer $env:CANARY_TOKEN"}) | ConvertTo-Json | Get-FileHash -Algorithm SHA256
            if ($actual.Hash -ne $expected) {
                Write-Warning "CANARY MISMATCH — backup integrity cannot be confirmed. Escalate to Incident Commander before proceeding with recovery."
                } else {
                    Write-Host "Canary validated. Proceeding with containment."
                    }
                    ```

                    > **If canary mismatch is detected:** Do not proceed to recovery until the Incident Commander confirms an alternate recovery path. The vault may have been partially corrupted. Consider initiating a cross-region restore from the GRS vault copy or engaging Microsoft Support for vault integrity validation.

                    ### Step 1.4 — Isolate Affected VMs (NIC Detach) (T+8 to T+12)

                    ```bash
                    # Get the NIC ID for the affected VM
                    NIC_ID=$(az vm show \
                      --resource-group rg-prod-api \
                        --name prod-api-vm-01 \
                          --query "networkProfile.networkInterfaces[0].id" -o tsv)

                          # Detach NIC — this stops all network traffic without deallocating the VM
                          # This preserves in-memory forensic state while cutting off lateral movement
                          az network nic update \
                            --ids $NIC_ID \
                              --network-security-group ""
                              # Alternatively: apply a deny-all NSG to the NIC immediately
                              az network nic update \
                                --ids $NIC_ID \
                                  --network-security-group bcdr-deny-all-nsg
                                  ```

                                  > **Design note:** NIC detach (or deny-all NSG) is preferred over VM deallocation for Tier 1 workloads. Deallocation destroys volatile memory state that may be valuable for forensics. The VM remains powered on, isolated from the network, and can be imaged.

                                  ### Step 1.5 — Disable Compromised Identities (T+10 to T+15)

                                  Check Defender for Cloud and Entra ID sign-in logs for any identity that authenticated to the affected VM within the last 2 hours. Disable any non-service-account identity immediately.

                                  ```powershell
                                  # Disable a compromised Entra ID account
                                  $userId = "compromised-user@company.com"
                                  Update-MgUser -UserId $userId -AccountEnabled:$false

                                  # Revoke all active sessions
                                  Revoke-MgUserSignInSession -UserId $userId
                                  ```

                                  Also rotate the service principal secret for any service principal that had access to the Recovery Services vault:

                                  ```powershell
                                  # Identify and disable any service principal with backup contributor or vault contributor role
                                  # This is a precaution — do not assume the SP is clean until investigated
                                  az ad sp credential reset --id <SP_APP_ID> --credential-description "emergency-rotation"
                                  ```

                                  ---

                                  ## Phase 2: Evidence Preservation (T+15 to T+30)

                                  **Goal:** Capture and preserve forensic evidence before any recovery actions modify the environment.

                                  ### Step 2.1 — Run Evidence Packager

                                  ```bash
                                  # Package all relevant evidence — run from evidence lead's workstation
                                  scripts/dfir/bcdr-evidence-packager.sh \
                                    --incident-id IR-001-$(date +%Y%m%d) \
                                      --affected-vms "prod-api-vm-01,prod-api-vm-02" \
                                        --lookback-hours 72
                                        ```

                                        This script will:
                                        - Pull the Sentinel incident timeline and all associated alerts
                                        - Export the last 72 hours of backup job logs, Activity Log events, and sign-in logs for affected identities
                                        - Capture a point-in-time export of the vault's protected item state
                                        - Hash all artifacts and write a SHA-256 chain-of-custody manifest
                                        - Upload the package to the immutable evidence container `bcdr-evidence/IR-001-[date]`

                                        ### Step 2.2 — Do Not Delete or Modify Affected Resources

                                        Until the Evidence Lead confirms the package is uploaded and verified, no one is to delete, deallocate, or modify any affected VM, disk, NSG, or storage account. This is an explicit hold.

                                        ---

                                        ## Phase 3: Recovery Sequencing (T+30 onward)

                                        **Goal:** Restore affected Tier 1 workloads from the last known-good recovery point, validated against the backup canary.

                                        ### Step 3.1 — Identify the Last Clean Recovery Point

                                        ```bash
                                        # List recovery points for the affected VM — identify the last one BEFORE the encryption event
                                        az backup recoverypoint list \
                                          --resource-group rg-prod-api \
                                            --vault-name bcdr-vault-tier1 \
                                              --container-name "iaasvmcontainer;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
                                                --item-name "vm;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
                                                  --backup-management-type AzureIaasVM \
                                                    --output table
                                                    ```

                                                    Select the most recent recovery point that predates the earliest known encryption activity timestamp from the Defender for Endpoint timeline.

                                                    ### Step 3.2 — Restore to Alternate Location (Preferred) or In-Place

                                                    > **Default:** Restore to an alternate VM name in the same resource group. This preserves the original (isolated) VM for forensics and gives you a clean restored instance to validate before cutting over.

                                                    ```bash
                                                    az backup restore restore-disks \
                                                      --resource-group rg-prod-api \
                                                        --vault-name bcdr-vault-tier1 \
                                                          --container-name "iaasvmcontainer;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
                                                            --item-name "vm;iaasvmcontainerv2;rg-prod-api;prod-api-vm-01" \
                                                              --rp-name <RECOVERY_POINT_ID> \
                                                                --storage-account bcdr-restore-staging \
                                                                  --restore-to-staging-storage-account true
                                                                  ```

                                                                  ### Step 3.3 — Validate Application Health Before DNS Cutover

                                                                  1. Start the restored VM in an isolated VNet (no production connectivity).
                                                                  2. Run application health checks:
                                                                     - Can the web service start and respond to a health probe?
                                                                        - Does the database connection succeed (using a test credential, not production)?
                                                                           - Are filesystem contents as expected (spot-check known files against pre-incident checksums if available)?
                                                                           3. Only after health validation, update DNS / load balancer to route traffic to the restored VM.
                                                                           4. Monitor for 30 minutes before declaring recovery complete.

                                                                           ---

                                                                           ## Phase 4: Stakeholder Notification

                                                                           ### Notification Templates

                                                                           **Immediate notification (T+15) — Internal only:**

                                                                           > Subject: [ACTIVE INCIDENT] Ransomware Event — IR-001 Initiated  
                                                                           > To: Engineering Lead, Finance Stakeholder, CISO  
                                                                           > Body: "A ransomware event has been detected affecting [workload names]. The incident response playbook has been activated. Affected systems have been isolated. Recovery is in progress with an estimated RTO of [X hours] based on current Tier 1 targets. Next update in 60 minutes or when recovery status changes."

                                                                           **60-minute update (T+75):**

                                                                           > Subject: [INCIDENT UPDATE] IR-001 — Recovery in Progress  
                                                                           > Body: "Recovery for [workload names] is [in progress / complete]. Current status: [restored / validating / active]. Estimated time to full service restoration: [X]. Cause under investigation. No further action required from your teams at this time."

                                                                           **Resolution notification:**

                                                                           > Subject: [RESOLVED] IR-001 — Service Restored  
                                                                           > Body: "All affected workloads have been restored and validated. Services are operating normally. A post-incident review will be conducted within [5 business days]. A summary report will follow."

                                                                           ---

                                                                           ## Phase 5: Post-Incident Requirements

                                                                           1. **Within 24 hours:** Submit a post-incident report skeleton to `docs/ir-playbooks/post-incident-review-and-evidence-packaging.md` template.
                                                                           2. **Within 5 business days:** Complete the post-incident review with all role holders.
                                                                           3. **Within 30 days:** Implement all remediations identified in the post-incident review and update this playbook if any step proved incorrect or incomplete.
                                                                           4. Evidence package retention: minimum 3 years in immutable storage.
                                                                           5. Notify legal/compliance if any customer data was confirmed encrypted or exfiltrated — regulatory notification timelines may apply (GDPR: 72 hours).

                                                                           ---

                                                                           ## Compliance Mapping

                                                                           | Requirement | Framework Reference |
                                                                           |---|---|
                                                                           | Incident response plan | NIST SP 800-61 Rev. 2 §3.1 |
                                                                           | Evidence preservation | NIST SP 800-61 Rev. 2 §3.3, ISO 27001 A.16.1.7 |
                                                                           | Recovery from backup | ISO 27001 A.17.1, NIST SP 800-34 §3.4 |
                                                                           | Stakeholder notification | ISO 27001 A.16.1.6, SOC 2 CC7.4 |
