# IR Playbook: Region Outage — Tier 1 Failover

**Classification:** Internal — Security Operations
**Playbook ID:** IR-003 | **Version:** 1.1
**Owner:** Cloud Security Architecture
**Last Tested:** 2025-01-20 (ASR test failover) — see docs/test-results.md section 1.3
**Frameworks:** NIST SP 800-34 Rev. 1, ISO 27001 A.17.2

---

## Scenario Description

The primary Azure region (eastus2) is experiencing a service-impacting outage. ASR-replicated Tier 1 workloads must be failed over to the designated recovery region (westus2). Tier 2 and Tier 3 workloads are recovered via backup restore after Tier 1 is stable.

**Critical design decision:** Failover is NOT fully automated. A human approval gate is required before initiating ASR failover. This is intentional — a false outage declaration triggering automated failover would cause unnecessary disruption. The automation/playbooks/asr-failover-trigger.jsonc Logic App handles notification and pre-validation but stops at the approval gate.

---

## Detection Triggers

| Trigger | Source | Action |
|---|---|---|
| Azure Service Health alert — eastus2 outage | Azure Service Health | Activates playbook (confirmation required) |
| ASR replication health degraded | Azure Monitor | Alert only — does not auto-failover |
| All Tier 1 health probes failing | Azure Load Balancer | Page on-call — confirm regional scope |
| Manual escalation from stakeholder | N/A | Confirm before activating failover |

---

## Roles and Responsibilities

| Role | Responsibility |
|---|---|
| **Incident Commander** | Cloud Security Architect — authorizes failover, owns stakeholder communication |
| **Failover Lead** | Platform Engineering — executes ASR failover and validates recovery |
| **Network Lead** | Network Engineering — validates DNS, VNet, private endpoint connectivity |
| **Application Lead** | Engineering Lead — validates application health post-failover |

---

## Pre-Failover Decision Framework

Before executing failover the Incident Commander must confirm:
- Azure Service Health shows an active incident in eastus2
- All Tier 1 health probes are failing (not a subset)
- At least 10 minutes have elapsed — do not failover for a transient blip
- ASR last recovery point is less than 1 hour old
- Leadership has been notified

---

## Phase 1: Pre-Failover Validation (T+0 to T+30)

### Step 1.1 — Check ASR Replication Health

Run kql/asr-replication-health.kql to confirm replication lag across all Tier 1 workloads. Document the last recovery point timestamp — this is the actual RPO at time of failover.

### Step 1.2 — Verify Recovery Region Pre-Staging

All of the following must exist in westus2 (provisioned by terraform/asr-replication.tf):

- Recovery Resource Group: rg-bcdr-prod-recovery (westus2)
- Recovery VNet with matching subnet CIDRs and NSGs
- Private DNS zones linked to recovery VNet (privatelink.database.windows.net, privatelink.blob.core.windows.net)
- Recovery Services Vault in westus2 with cross-region restore enabled
- Key Vault in westus2 with replicated secrets

Gap closed 2025-01-21: Private DNS zone for privatelink.database.windows.net was not initially linked to the recovery VNet, causing 18 minutes of DNS failure during the test failover. Terraform updated. See docs/test-results.md section 1.3.

### Step 1.3 — Confirm Failover Authorization

Incident Commander confirms in War Room: "Failover to westus2 is authorized." Document the timestamp. This is the human approval gate.

---

## Phase 2: Execute Failover (T+30 to T+120)

Execute in dependency order: databases first, then application servers, then AKS.

### Step 2.1 — ASR Failover for VM Workloads

```bash
az site-recovery protected-item failover \
  --resource-group rg-bcdr-prod --vault-name bcdr-vault-tier1 \
  --fabric-name "asr-fabric-eastus2" \
  --protection-container "asr-container-eastus2" \
  --replicated-item-name "prod-api-vm-01" \
  --failover-direction "PrimaryToRecovery" \
  --recovery-point-type "Latest"
```

Repeat for prod-api-vm-02.

### Step 2.2 — SQL Database Geo-Replication Failover

```bash
az sql db replica set-primary \
  --resource-group rg-prod-data \
  --server prod-sql-server-recovery \
  --name prod-sqldb-orders
```

A forced failover may result in data loss equal to the replication lag. Document as actual RPO.

### Step 2.3 — Cosmos DB (Multi-Region Write — No Action Required)

Cosmos DB is configured with multi-region writes. westus2 serves traffic automatically. Verify writeLocations includes westus2 as active.

### Step 2.4 — AKS Workload Failover via Velero

```bash
velero restore create prod-aks-restore \
  --from-schedule prod-aks-backup \
  --include-namespaces production
kubectl get pods -n production
```

### Step 2.5 — DNS Cutover via Traffic Manager

```bash
az network traffic-manager endpoint update \
  --resource-group rg-prod-infra --profile-name prod-traffic-manager \
  --name eastus2-endpoint --type azureEndpoints --endpoint-status Disabled
az network traffic-manager endpoint update \
  --resource-group rg-prod-infra --profile-name prod-traffic-manager \
  --name westus2-endpoint --type azureEndpoints --endpoint-status Enabled
```

---

## Phase 3: Post-Failover Validation Checklist

- VM and application service is running and health probe is passing
- Database connections are healthy (tested with non-production credentials)
- Private endpoint DNS resolves correctly in the recovery VNet
- Backup enrollment is active in the recovery region vault
- Monitoring and alerting is operational (Sentinel, Azure Monitor)

Application Lead performs end-to-end smoke test and confirms in War Room before traffic cutover is declared complete.

---

## Phase 4: Stakeholder Notification

**Failover declaration (T+30):**
Subject: [ACTIVE INCIDENT] Azure Region Outage — Failover to westus2 Initiated
Body: An outage in eastus2 is impacting Tier 1 services. Failover to westus2 has been authorized and is in progress. Estimated restoration: [RTO target]. Tier 2 and Tier 3 services restored after Tier 1 is stable. Updates every 30 minutes.

**Resolution:**
Subject: [RESOLVED] IR-003 — Services Restored in Recovery Region
Body: All Tier 1 services are operational in westus2. Tier 2/3 recovery underway. Failback to eastus2 scheduled once primary region is confirmed stable.

---

## Phase 5: Failback Planning

Do not rush failback. Operating from the recovery region for days or weeks is acceptable and preferable to a rushed failback.

1. Confirm eastus2 is healthy per Azure Service Health.
2. Verify ASR replication from westus2 back to eastus2 is established (reprotect VMs).
3. Test failback in non-production first if time permits.
4. Schedule failback during a low-traffic window with full team availability.
5. Repeat all Phase 3 validation steps after failback.

---

## Compliance Mapping

| Requirement | Framework Reference |
|---|---|
| Recovery time and point objectives | NIST SP 800-34 section 3.3, ISO 27001 A.17.2 |
| Failover testing and validation | NIST SP 800-34 section 4, ISO 27001 A.17.1 |
| Business continuity plan activation | ISO 27001 A.17.1.2, SOC 2 A1.2 |
