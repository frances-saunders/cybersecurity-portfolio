// -----------------------------
// Zero Trust Policy Definitions
// -----------------------------

// Deny subnets without NSG
resource "azurerm_policy_definition" "deny_public_subnet" {
  name         = "deny-public-subnet"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Subnets Without NSG"

  policy_rule = <<POLICY
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Network/virtualNetworks/subnets"
      },
      {
        "field": "Microsoft.Network/virtualNetworks/subnets/networkSecurityGroup.id",
        "exists": "false"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY
}

// Enforce Private Endpoints
resource "azurerm_policy_definition" "enforce_private_endpoints" {
  name         = "enforce-private-endpoints"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce Private Endpoints for Storage & SQL"

  policy_rule = <<POLICY
{
  "if": {
    "anyOf": [
      {
        "field": "type",
        "equals": "Microsoft.Storage/storageAccounts"
      },
      {
        "field": "type",
        "equals": "Microsoft.Sql/servers"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY
}

// Restrict overly permissive NSG rules
resource "azurerm_policy_definition" "restrict_nsg_rules" {
  name         = "restrict-nsg-rules"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Restrict NSG Rules"

  policy_rule = <<POLICY
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Network/networkSecurityGroups/securityRules"
      },
      {
        "field": "Microsoft.Network/networkSecurityGroups/securityRules/sourceAddressPrefix",
        "equals": "*"
      },
      {
        "field": "Microsoft.Network/networkSecurityGroups/securityRules/destinationAddressPrefix",
        "equals": "*"
      },
      {
        "field": "Microsoft.Network/networkSecurityGroups/securityRules/destinationPortRange",
        "equals": "*"
      },
      {
        "field": "Microsoft.Network/networkSecurityGroups/securityRules/access",
        "equals": "Allow"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY
}

// -----------------------------
// Initiative
// -----------------------------
resource "azurerm_policy_set_definition" "zt_network_segmentation" {
  name         = "zero-trust-network-segmentation"
  policy_type  = "Custom"
  display_name = "Zero Trust Network Segmentation Initiative"
  description  = "Bundle of custom policies enforcing subnet-level NSG, private endpoints, and restrictive NSG rules."

  policy_definitions = <<DEF
[
  {
    "policyDefinitionId": "${azurerm_policy_definition.deny_public_subnet.id}",
    "policyDefinitionReferenceId": "Deny-Subnet-Without-NSG"
  },
  {
    "policyDefinitionId": "${azurerm_policy_definition.enforce_private_endpoints.id}",
    "policyDefinitionReferenceId": "Enforce-Private-Endpoints"
  },
  {
    "policyDefinitionId": "${azurerm_policy_definition.restrict_nsg_rules.id}",
    "policyDefinitionReferenceId": "Restrict-NSG-Rules"
  }
]
DEF
}

// -----------------------------
// Assignment (subscription-wide)
// -----------------------------
resource "azurerm_subscription_policy_assignment" "zt_assignment" {
  name                 = "zt-network-segmentation-assignment"
  display_name         = "Zero Trust Network Segmentation Assignment"
  subscription_id      = data.azurerm_subscription.primary.id
  policy_definition_id = azurerm_policy_set_definition.zt_network_segmentation.id

  // Apply tags for traceability
  metadata = <<META
{
  "assignedBy": "Frances Saunders Portfolio Lab"
}
META
}

data "azurerm_subscription" "primary" {}
