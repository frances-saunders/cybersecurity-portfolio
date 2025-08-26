terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.112.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ---------------------------------------------
# Locals: Framework-tagged custom policies
# ---------------------------------------------
locals {
  # Common metadata tags applied to all resources
  common_tags = merge(
    {
      "owner"        = var.owner_tag
      "environment"  = var.environment
      "frameworks"   = "NIST,CIS,SOC2"
      "deployedBy"   = "terraform"
    },
    var.additional_tags
  )

  # A compact library of custom policies that are broadly applicable
  # and easily mapped to NIST 800-53, CIS Level 1/2, and SOC 2 CC.
  custom_policies = [
    {
      name        = "deny-public-ip-on-vm"
      display     = "Deny Public IP on Virtual Machines"
      description = "Prevents creation of network interfaces with public IPs on virtual machines."
      category    = "Network Security"
      mode        = "Indexed"
      # NIST: SC-7, AC-4; CIS: 3.11; SOC2: CC6.6
      frameworks  = ["NIST:SC-7", "NIST:AC-4", "CIS:3.11", "SOC2:CC6.6"]
      policy_rule = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Network/networkInterfaces" },
            { field = "Microsoft.Network/networkInterfaces/ipconfigurations[*].publicIpAddress.id", exists = true }
          ]
        }
        then = {
          effect = var.policy_effects.deny_public_ip_on_vm
        }
      })
      parameters = null
    },
    {
      name        = "require-disk-encryption"
      display     = "Require VM Disk Encryption At Rest"
      description = "Audits or denies virtual machines without OS disk encryption enabled."
      category    = "Data Protection"
      mode        = "All"
      # NIST: SC-28; CIS: 3.4; SOC2: CC6.1
      frameworks  = ["NIST:SC-28", "CIS:3.4", "SOC2:CC6.1"]
      policy_rule = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Compute/virtualMachines" },
            { anyOf = [
                { field = "Microsoft.Compute/virtualMachines/storageProfile.osDisk.encryptionSettings.enabled", equals = "false" },
                { field = "Microsoft.Compute/virtualMachines/storageProfile.osDisk.managedDisk.id", exists = "false" }
            ]}
          ]
        }
        then = {
          effect = var.policy_effects.require_disk_encryption
        }
      })
      parameters = null
    },
    {
      name        = "require-secure-transfer-on-storage"
      display     = "Require Secure Transfer on Storage Accounts"
      description = "Ensures 'secure transfer required' is enabled on Storage Accounts."
      category    = "Storage Security"
      mode        = "All"
      # NIST: SC-8; CIS: 3.1; SOC2: CC6.7
      frameworks  = ["NIST:SC-8", "CIS:3.1", "SOC2:CC6.7"]
      policy_rule = jsonencode({
        if = {
          allOf = [
            { field = "type", equals = "Microsoft.Storage/storageAccounts" },
            { field = "Microsoft.Storage/storageAccounts/supportsHttpsTrafficOnly", equals = "false" }
          ]
        }
        then = {
          effect = var.policy_effects.require_secure_transfer_on_storage
        }
      })
      parameters = null
    },
    {
      name        = "require-diagnostics-to-law"
      display     = "Require Diagnostics to Log Analytics"
      description = "Audits resources without Diagnostic Settings streaming to Log Analytics."
      category    = "Logging & Monitoring"
      mode        = "Indexed"
      # NIST: AU-2, AU-12; CIS: 4.1; SOC2: CC7.2
      frameworks  = ["NIST:AU-2", "NIST:AU-12", "CIS:4.1", "SOC2:CC7.2"]
      policy_rule = jsonencode({
        if = {
          field = "type"
          in    = [
            "Microsoft.Compute/virtualMachines",
            "Microsoft.KeyVault/vaults",
            "Microsoft.Network/networkSecurityGroups",
            "Microsoft.Storage/storageAccounts"
          ]
        }
        then = {
          effect = var.policy_effects.require_diagnostics_to_law
        }
      })
      # Parameter-based policy (workspaceId) for broader applicability
      parameters = jsonencode({
        workspaceId = {
          type        = "String"
          metadata    = { displayName = "Log Analytics Workspace Resource ID" }
          default     = var.log_analytics_workspace_id
        }
      })
    },
    {
      name        = "restrict-approved-locations"
      display     = "Restrict Resource Locations"
      description = "Restricts deployments to approved Azure regions."
      category    = "Governance"
      mode        = "All"
      # NIST: AC-3, CM-2; CIS: 1.1; SOC2: CC1.4
      frameworks  = ["NIST:AC-3", "NIST:CM-2", "CIS:1.1", "SOC2:CC1.4"]
      policy_rule = jsonencode({
        if = {
          not = {
            field  = "location"
            in     = "[parameters('listOfAllowedLocations')]"
          }
        }
        then = {
          effect = var.policy_effects.restrict_approved_locations
        }
      })
      parameters = jsonencode({
        listOfAllowedLocations = {
          type     = "Array"
          metadata = { displayName = "Allowed Locations" }
          default  = var.allowed_locations
        }
      })
    },
    {
      name        = "require-resource-tags"
      display     = "Require Standard Resource Tags"
      description = "Ensures required tags are present on resources."
      category    = "Governance"
      mode        = "Indexed"
      # NIST: CM-8; CIS: 1.5; SOC2: CC1.2
      frameworks  = ["NIST:CM-8", "CIS:1.5", "SOC2:CC1.2"]
      policy_rule = jsonencode({
        if = {
          anyOf = [
            { allOf = [
                { field = "tags['owner']", exists = "false" }
            ]},
            { allOf = [
                { field = "tags['environment']", exists = "false" }
            ]}
          ]
        }
        then = {
          effect = var.policy_effects.require_resource_tags
        }
      })
      parameters = null
    }
  ]

  # Build initiative members referencing the custom policy definitions created below.
  # Each initiative packs policies aligned to the named framework.
  initiatives = {
    nist = {
      display_name = "Enterprise NIST 800-53 Baseline (Custom)"
      description  = "Custom initiative mapping core controls to NIST 800-53 families."
      members      = [for p in local.custom_policies : p if length([for f in p.frameworks : f if startswith(f, "NIST")]) > 0]
    }
    cis = {
      display_name = "Enterprise CIS Baseline (Custom)"
      description  = "Custom initiative mapping core controls to CIS Level 1/2."
      members      = [for p in local.custom_policies : p if length([for f in p.frameworks : f if startswith(f, "CIS")]) > 0]
    }
    soc2 = {
      display_name = "Enterprise SOC 2 Baseline (Custom)"
      description  = "Custom initiative mapping core controls to SOC 2 Common Criteria."
      members      = [for p in local.custom_policies : p if length([for f in p.frameworks : f if startswith(f, "SOC2")]) > 0]
    }
  }
}

# ---------------------------------------------
# Resource: Custom Policy Definitions
# ---------------------------------------------
resource "azurerm_policy_definition" "custom" {
  for_each     = { for p in local.custom_policies : p.name => p }
  name         = "custom-${each.value.name}"
  display_name = each.value.display
  policy_type  = "Custom"
  mode         = each.value.mode
  description  = each.value.description
  management_group_id = var.management_group_id != "" ? var.management_group_id : null
  metadata     = jsonencode({
    category  = each.value.category
    version   = "1.0.0"
    frameworks= each.value.frameworks
    owner     = var.owner_tag
  })
  policy_rule  = each.value.policy_rule
  parameters   = try(each.value.parameters, null)

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------
# Resource: Policy Set (Initiatives) per framework
# ---------------------------------------------
resource "azurerm_policy_set_definition" "initiative" {
  for_each            = local.initiatives
  name                = "initiative-${each.key}"
  display_name        = each.value.display_name
  policy_type         = "Custom"
  description         = each.value.description
  management_group_id = var.management_group_id != "" ? var.management_group_id : null
  metadata            = jsonencode({
    category   = "Compliance"
    version    = "1.0.0"
    frameworks = upper(each.key)
  })

  policy_definitions = jsonencode([
    for m in each.value.members : {
      policyDefinitionId = azurerm_policy_definition.custom[m.name].id
      # Provide stable reference IDs derived from policy names
      policyDefinitionReferenceId = "ref-${m.name}"
      # Auto-wire parameters if present in the underlying policy
      parameters = m.parameters != null ? {
        for k, v in jsondecode(m.parameters) : k => {
          value = v.default != null ? v.default : null
        }
      } : null
    }
  ])

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------
# Resource: Assign Initiatives at desired scope
# ---------------------------------------------
# Scope can be management group, subscription, or resource group (string form).
# Examples:
#   "/providers/Microsoft.Management/managementGroups/contoso-mg"
#   "/subscriptions/00000000-0000-0000-0000-000000000000"
#   "/subscriptions/..../resourceGroups/rg-security"
#
resource "azurerm_policy_assignment" "assign_initiatives" {
  for_each             = azurerm_policy_set_definition.initiative
  name                 = "assign-${each.key}"
  display_name         = "${each.value.display_name} Assignment"
  description          = "Assignment of ${each.value.display_name} at scope ${var.assignment_scope}"
  policy_definition_id = each.value.id
  location             = var.policy_assignment_location
  scope                = var.assignment_scope
  identity {
    type = "SystemAssigned"
  }
  metadata = jsonencode({
    assignedBy = var.owner_tag
    frameworks = upper(each.key)
  })

  # Pass-through parameters in case the initiative references parameterized policies
  parameters = jsonencode({
    workspaceId         = var.log_analytics_workspace_id != "" ? { value = var.log_analytics_workspace_id } : null
    listOfAllowedLocations = length(var.allowed_locations) > 0 ? { value = var.allowed_locations } : null
  })

  lifecycle {
    ignore_changes = [parameters]
  }

  tags = local.common_tags
}
