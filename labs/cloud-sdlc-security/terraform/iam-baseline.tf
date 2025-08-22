// Terraform - IAM Baseline with Policy-as-Code
// Enforces Zero Trust guardrails: NSG restrictions, encryption requirements, approved SKUs

provider "azurerm" {
  features {}
}

data "azurerm_subscription" "primary" {}

# -----------------------------
# Policy Definitions
# -----------------------------

// Deny Public IPs on NICs
resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip-nic"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny NICs with Public IP"
  policy_rule  = file("${path.module}/../policies/deny-public-ip.jsonc")
}

// Require Encryption on Storage Accounts
resource "azurerm_policy_definition" "require_storage_encryption" {
  name         = "require-storage-encryption"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require Encryption on Storage Accounts"

  policy_rule = <<POLICY
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Storage/storageAccounts"
  },
  "then": {
    "effect": "auditIfNotExists",
    "details": {
      "type": "Microsoft.Storage/storageAccounts/encryption",
      "existenceCondition": {
        "field": "Microsoft.Storage/storageAccounts/encryption.services.blob.enabled",
        "equals": "true"
      }
    }
  }
}
POLICY
}

// Restrict VM SKUs to approved list
resource "azurerm_policy_definition" "restrict_vm_skus" {
  name         = "restrict-vm-skus"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Restrict VM SKUs to Approved List"

  policy_rule = <<POLICY
{
  "if": {
    "field": "Microsoft.Compute/virtualMachines/sku.name",
    "notIn": [
      "Standard_DS1_v2",
      "Standard_DS2_v2",
      "Standard_D4s_v3"
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY
}

# -----------------------------
# Initiative
# -----------------------------
resource "azurerm_policy_set_definition" "sdlc_initiative" {
  name         = "sdlc-security-baseline"
  policy_type  = "Custom"
  display_name = "SDLC Security Baseline Initiative"
  description  = "Enterprise guardrails for Public IPs, encryption, and approved SKUs."

  policy_definitions = <<DEF
[
  {
    "policyDefinitionId": "${azurerm_policy_definition.deny_public_ip.id}",
    "policyDefinitionReferenceId": "Deny-Public-IP"
  },
  {
    "policyDefinitionId": "${azurerm_policy_definition.require_storage_encryption.id}",
    "policyDefinitionReferenceId": "Require-Storage-Encryption"
  },
  {
    "policyDefinitionId": "${azurerm_policy_definition.restrict_vm_skus.id}",
    "policyDefinitionReferenceId": "Restrict-VM-SKUs"
  }
]
DEF
}

# -----------------------------
# Assignment
# -----------------------------
resource "azurerm_subscription_policy_assignment" "sdlc_assignment" {
  name                 = "sdlc-security-assignment"
  display_name         = "SDLC Security Baseline Assignment"
  subscription_id      = data.azurerm_subscription.primary.id
  policy_definition_id = azurerm_policy_set_definition.sdlc_initiative.id

  metadata = <<META
{
  "assignedBy": "Frances Saunders"
}
META
}
