# Replace with your real subscription (no secrets required).
subscription_id  = "00000000-0000-0000-0000-000000000000"

# Optional: create definitions at MG-level. Otherwise leave empty.
management_group_id = ""

# Recommend assigning at subscription scope for broad coverage.
assignment_scope = "/subscriptions/00000000-0000-0000-0000-000000000000"

# Resource ID of your Log Analytics workspace, if using diagnostics policy.
# Example: "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.OperationalInsights/workspaces/<law>"
log_analytics_workspace_id = ""

owner_tag   = "SecurityTeam"
environment = "prod"

allowed_locations = ["eastus", "eastus2", "centralus", "westus3"]

additional_tags = {
  costCenter = "SEC-001"
  dataClass  = "Internal"
}

# Default effects can be tuned here (audit / deny / auditIfNotExists)
policy_effects = {
  deny_public_ip_on_vm                = "deny"
  require_disk_encryption             = "auditIfNotExists"
  require_secure_transfer_on_storage  = "deny"
  require_diagnostics_to_law          = "audit"
  restrict_approved_locations         = "deny"
  require_resource_tags               = "audit"
}
