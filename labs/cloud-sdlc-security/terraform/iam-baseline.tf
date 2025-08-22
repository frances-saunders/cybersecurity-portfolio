// Terraform: IAM Baseline Policies for Cloud SDLC Security

resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Public IPs"
  description  = "Prevent developers from creating resources with public IP addresses."

  policy_rule = <<POLICY
{
  "if": {
    "anyOf": [
      {
        "field": "Microsoft.Network/publicIPAddresses/ipAddress",
        "exists": "true"
      },
      {
        "field": "Microsoft.Network/networkInterfaces/ipConfigurations.publicIpAddress.id",
        "exists": "true"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY
}

resource "azurerm_policy_set_definition" "iam_baseline" {
  name         = "iam-baseline"
  policy_type  = "Custom"
  display_name = "IAM Baseline Initiative"
  description  = "Baseline IAM and networking security policies for SDLC environments."

  policy_definitions = <<DEF
[
  {
    "policyDefinitionId": "${azurerm_policy_definition.deny_public_ip.id}",
    "policyDefinitionReferenceId": "Deny-Public-IP"
  }
]
DEF
}

resource "azurerm_subscription_policy_assignment" "assign_iam_baseline" {
  name                 = "assign-iam-baseline"
  display_name         = "Assign IAM Baseline"
  subscription_id      = data.azurerm_subscription.primary.id
  policy_definition_id = azurerm_policy_set_definition.iam_baseline.id
}

data "azurerm_subscription" "primary" {}
