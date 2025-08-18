# Deny pipelines with hardcoded secrets
resource "azurerm_policy_definition" "deny_hardcoded_secrets" {
  name         = "deny-hardcoded-secrets"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Hardcoded Secrets in Pipelines"

  policy_rule = <<POLICY
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.DevOps/pipelines"
      },
      {
        "field": "Microsoft.DevOps/pipelines/secretsInlined",
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

# Require pipeline logs to be exported to Log Analytics
resource "azurerm_policy_definition" "require_pipeline_logs" {
  name         = "require-pipeline-logs"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require CI/CD Pipeline Logs in Log Analytics"

  policy_rule = <<POLICY
{
  "if": {
    "field": "type",
    "equals": "Microsoft.DevOps/pipelines"
  },
  "then": {
    "effect": "append",
    "details": {
      "field": "Microsoft.DevOps/pipelines/logAnalyticsEnabled",
      "value": "true"
    }
  }
}
POLICY
}
