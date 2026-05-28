# IR Playbook: Credential Compromise and Unauthorized Access

**Classification:** Internal — Security Operations
**Playbook ID:** IR-004 | **Version:** 1.0
**Owner:** Cloud Security Architecture
**Last Tested:** 2025-01-22 (tabletop exercise) — see docs/test-results.md
**Frameworks:** NIST SP 800-61 Rev. 2, ISO 27001 A.16.1, ISO 27001 A.9.4

---

## Scenario Description

A credential — user account, service principal, managed identity, or API key — has been compromised. An unauthorized actor may have active or recent access to Azure resources, the Entra ID directory, the backup vault, or production data. The compromise may have been discovered via a Sentinel alert, anomalous sign-in notification, external threat intel, or self-reported by a user.

---

## Detection Triggers

| Trigger | Source | Sentinel Rule |
|---|---|---|
| Sign-in from impossible travel location | Entra ID Identity Protection | IdentityProtection-ImpossibleTravel |
| Credential spray or brute-force attack | Entra ID Sign-in Logs | BCDR-CredentialSpray |
| Service principal accessing backup vault outside normal hours | Azure Activity Log | BCDR-AnomalousBackupAPICall |
| MFA bypass or legacy auth sign-in | Entra ID Conditional Access | BCDR-LegacyAuthSignIn |
| Key Vault secret access by unexpected identity | Key Vault Audit Log | BCDR-UnexpectedSecretAccess |
| User self-reports phishing or credential theft | Helpdesk | N/A |

---

## Roles and Responsibilities

| Role | Responsibility |
|---|---|
| **Incident Commander** | Cloud Security Architect — scopes impact, authorizes containment, communicates to leadership |
| **Identity Lead** | Security Operations — executes all Entra ID and RBAC actions |
| **Investigation Lead** | Security Operations — conducts sign-in log analysis and access timeline reconstruction |
| **Infrastructure Lead** | Platform Engineering — audits resource-level access and rotates secrets |

---

## Phase 1: Immediate Containment (T+0 to T+15)

### Step 1.1 — Identify the Compromised Identity

From the Sentinel incident, identify:
- The UPN or service principal AppId
- The last known good sign-in (before the anomalous activity)
- All resources accessed by the identity in the last 24-72 hours
- Whether the identity has backup vault contributor or Key Vault access

### Step 1.2 — Disable the Identity Immediately

For a user account:

```powershell
# Disable the account and revoke all active sessions
Update-MgUser -UserId "compromised-user@company.com" -AccountEnabled:$false
Revoke-MgUserSignInSession -UserId "compromised-user@company.com"

# Verify MFA methods haven't been added by the attacker
Get-MgUserAuthenticationMethod -UserId "compromised-user@company.com"
```

For a service principal:

```powershell
# Disable the service principal and remove all credentials
Update-MgServicePrincipal -ServicePrincipalId "<SP_OBJECT_ID>" -AccountEnabled:$false
Get-MgApplicationPasswordCredential -ApplicationId "<APP_ID>" | ForEach-Object {
    Remove-MgApplicationPassword -ApplicationId "<APP_ID>" -KeyId $_.KeyId
}
```

### Step 1.3 — Remove Privileged Role Assignments

If the compromised identity holds any privileged roles (Owner, Contributor, Backup Contributor, Key Vault Administrator), remove them immediately:

```bash
az role assignment list --assignee "compromised-user@company.com" --output table
az role assignment delete   --assignee "compromised-user@company.com"   --role "Backup Contributor"   --scope "/subscriptions/<SUB_ID>"
```

### Step 1.4 — Monitor Vault for In-Flight Actions

```kql
AzureActivity
| where TimeGenerated > ago(30m)
| where Caller =~ "compromised-user@company.com"
| where ResourceType contains "RecoveryServices" or ResourceType contains "KeyVault"
| project TimeGenerated, OperationName, ActivityStatus, ResourceId
| order by TimeGenerated desc
```

If any delete or modify vault operations appear, escalate to the Incident Commander immediately.

---

## Phase 2: Impact Assessment (T+15 to T+60)

### Step 2.1 — Reconstruct the Access Timeline

```kql
union AzureActivity, SigninLogs, AuditLogs
| where TimeGenerated > ago(72h)
| where (Caller =~ "compromised-user@company.com")
    or (UserPrincipalName =~ "compromised-user@company.com")
| project TimeGenerated, Type, OperationName, ResourceId, ResultType, IPAddress = tostring(CallerIpAddress)
| order by TimeGenerated asc
```

Export this timeline as evidence. It is the foundation of the impact assessment.

### Step 2.2 — Identify All Resources Accessed

From the timeline, catalog every resource the identity READ, MODIFIED, or CREATED, every secret accessed in Key Vault, and whether any backup vault contents or recovery points were touched.

### Step 2.3 — Assess Backup Infrastructure Impact

```bash
az backup vault backup-properties show   --resource-group rg-bcdr-prod   --vault-name bcdr-vault-tier1   --query "{softDelete: softDeleteFeatureState, immutability: immutabilitySettings}"
```

If soft-delete or immutability has been changed: treat as a ransomware precursor and activate IR-001 in parallel.

---

## Phase 3: Credential Rotation

### Step 3.1 — Rotate All Secrets the Compromised Identity Could Access

```bash
# Rotate each Key Vault secret that was accessed by the compromised identity
az keyvault secret set   --vault-name prod-keyvault-primary   --name "db-connection-string"   --value "<NEW_ROTATED_VALUE>"
```

### Step 3.2 — Rotate Storage Account Keys if Accessed

```bash
az storage account keys renew   --resource-group rg-prod-storage   --account-name <STORAGE_ACCOUNT>   --key primary
```

### Step 3.3 — Issue New Credentials for Service Principals

Add a new credential to the re-enabled service principal, update all consuming services, then remove the old credential. Never leave both old and new credentials active simultaneously for longer than the cutover window.

---

## Phase 4: Recovery Validation Checklist

- [ ] Backup vault soft-delete is still enabled (14-day window)
- [ ] Vault immutability is still locked (Tier 1 vault)
- [ ] All backup jobs have run successfully since containment
- [ ] No backup items are in unexpected soft-deleted state
- [ ] ASR replication is healthy for all Tier 1 workloads
- [ ] No production data was exfiltrated (check storage access logs)

If any backup or DR infrastructure was modified by the compromised identity, treat as a ransomware precursor and activate IR-001.

---

## Phase 5: Stakeholder Notification

**Initial notification (T+15):**
Subject: [ACTIVE INCIDENT] Credential Compromise — IR-004 Initiated
Body: A compromised credential has been identified and contained. Access has been suspended for the affected identity. An impact assessment is underway. No service disruption at this time. Next update in 60 minutes.

**Resolution:**
Subject: [RESOLVED] IR-004 — Credential Compromise Contained
Body: The compromised credential has been contained and rotated. All affected secrets have been renewed. Access review confirmed no unauthorized changes to production infrastructure or backup systems. Post-incident review within 5 business days.

---

## Phase 6: Post-Incident Hardening

Within 5 business days of resolution:

1. Review and tighten RBAC assignments for all service principals with backup vault or Key Vault access.
2. Enable Privileged Identity Management (PIM) for all privileged roles if not already in place.
3. Review Conditional Access policies — ensure no legacy auth exceptions exist for privileged accounts.
4. Add the compromised identity type to the high-risk sign-in watchlist in Sentinel.
5. Confirm the backup canary is still valid and update it if any vault configuration changed.

---

## Compliance Mapping

| Requirement | Framework Reference |
|---|---|
| Access control and identity management | ISO 27001 A.9.4, NIST SP 800-61 Rev. 2 |
| Incident detection and response | ISO 27001 A.16.1, NIST SP 800-61 Rev. 2 section 3.2 |
| Audit logging and evidence | SOC 2 CC7.3, ISO 27001 A.12.4 |
| Secret and credential management | ISO 27001 A.9.2, CIS Control 4 |
