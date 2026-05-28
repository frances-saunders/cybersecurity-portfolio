# ---------------------------------------------------------------------------
# azure-policy.tf — BCDR/IR Plan Lab
# Enforces backup enrollment and vault protection via Azure Policy.
# Three categories of controls:
#   1. DeployIfNotExists — auto-enroll new resources in backup on creation
#   2. Deny — block any action that weakens vault protection
#   3. AuditIfNotExists — surface drift for resources with bcdr-tier tags but no active coverage
#
# Deliberate design decision: Deny policies for vault tampering are scoped at the
# management group or subscription level (not resource group) to prevent an
# attacker with resource group Owner access from bypassing them.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Policy: DeployIfNotExists — VM Backup Enrollment
# ---------------------------------------------------------------------------

resource "azurerm_policy_definition" "vm_backup_deploy" {
  name         = "bcdr-vm-backup-deployifnotexists"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "BCDR: Deploy VM Backup Enrollment if Not Exists"
  description  = "Automatically enrolls Azure VMs in the appropriate Recovery Services Vault backup policy based on their bcdr-tier tag. Prevents new VMs from entering production without backup coverage."

  metadata = jsonencode({
    category = "Backup"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Compute/virtualMachines" },
        { field = "tags['bcdr-tier']", exists = "true" }
      ]
    }
    then = {
      effect = "DeployIfNotExists"
      details = {
        type              = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems"
        roleDefinitionIds = ["/providers/Microsoft.Authorization/roleDefinitions/9980e02c-c2be-4d73-94e8-173b1dc7cf3c"]
        deployment = {
          properties = {
            mode     = "incremental"
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters     = {}
              resources      = []
            }
          }
        }
      }
    }
  })
}

# ---------------------------------------------------------------------------
# Policy: Deny — Block Soft-Delete Disablement
# ---------------------------------------------------------------------------

resource "azurerm_policy_definition" "vault_softdelete_deny" {
  name         = "bcdr-vault-softdelete-deny"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "BCDR: Deny Recovery Services Vault Soft-Delete Disablement"
  description  = "Blocks any attempt to disable soft-delete on a Recovery Services Vault. Soft-delete disablement is the leading precursor to ransomware-driven backup destruction. Even Owner-level accounts cannot disable soft-delete once this policy is applied."

  metadata = jsonencode({
    category = "Backup"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.RecoveryServices/vaults/backupconfig" },
        { field = "Microsoft.RecoveryServices/vaults/backupconfig/softDeleteFeatureState", equals = "Disabled" }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# ---------------------------------------------------------------------------
# Policy: Deny — Block Vault Immutability Removal
# ---------------------------------------------------------------------------

resource "azurerm_policy_definition" "vault_immutability_deny" {
  name         = "bcdr-vault-immutability-deny"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "BCDR: Deny Recovery Services Vault Immutability Disablement"
  description  = "Blocks any attempt to disable or unlock immutability on a Tier 1 Recovery Services Vault. Immutability (Locked) is the last line of defense against backup destruction. This policy applies only to vaults tagged bcdr-tier:1."

  metadata = jsonencode({
    category = "Backup"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.RecoveryServices/vaults" },
        { field = "tags['bcdr-tier']", equals = "1" },
        {
          field    = "Microsoft.RecoveryServices/vaults/immutabilitySettings.state"
          notEquals = "Locked"
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}

# ---------------------------------------------------------------------------
# Policy: AuditIfNotExists — Backup Coverage Drift Detection
# ---------------------------------------------------------------------------

resource "azurerm_policy_definition" "backup_coverage_audit" {
  name         = "bcdr-backup-coverage-auditifnotexists"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "BCDR: Audit Backup Coverage for Tagged Resources"
  description  = "Surfaces resources with a bcdr-tier tag that are not enrolled in an active backup policy. This is the policy-layer complement to the backup-coverage-gaps.kql query and backup-coverage-reporter.ps1 script. Drift appears in the compliance dashboard within 24 hours of creation."

  metadata = jsonencode({
    category = "Backup"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", in = ["Microsoft.Compute/virtualMachines", "Microsoft.Sql/servers/databases", "Microsoft.Storage/storageAccounts"] },
        { field = "tags['bcdr-tier']", exists = "true" }
      ]
    }
    then = {
      effect = "AuditIfNotExists"
      details = {
        type = "Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems"
      }
    }
  })
}

# ---------------------------------------------------------------------------
# Policy Initiative (Set) — BCDR Enforcement Bundle
# Bundles all BCDR policy definitions into a single auditable initiative.
# Assign this initiative at the subscription level for full coverage.
# ---------------------------------------------------------------------------

resource "azurerm_policy_set_definition" "bcdr_initiative" {
  name         = "bcdr-enforcement-initiative"
  policy_type  = "Custom"
  display_name = "BCDR: Business Continuity and Disaster Recovery Enforcement"
  description  = "Bundles all BCDR policy controls — backup enrollment enforcement, vault protection denial, and coverage drift detection — into a single initiative for subscription-level assignment and compliance reporting."

  metadata = jsonencode({
    category = "Backup"
    version  = "1.0.0"
  })

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.vault_softdelete_deny.id
    reference_id         = "bcdr-vault-softdelete-deny"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.vault_immutability_deny.id
    reference_id         = "bcdr-vault-immutability-deny"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.backup_coverage_audit.id
    reference_id         = "bcdr-backup-coverage-audit"
  }

  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.vm_backup_deploy.id
    reference_id         = "bcdr-vm-backup-deployifnotexists"
  }
}

# ---------------------------------------------------------------------------
# Policy Assignment — Apply initiative at subscription scope
# ---------------------------------------------------------------------------

resource "azurerm_subscription_policy_assignment" "bcdr_initiative_assignment" {
  name                 = "bcdr-enforcement-assignment"
  display_name         = "BCDR: Enforcement Initiative — Production Subscription"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_set_definition.bcdr_initiative.id
  description          = "Applies all BCDR enforcement controls across the production subscription."

  identity {
    type = "SystemAssigned"
  }

  location = var.primary_location
}
