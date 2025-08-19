# =======================================================
# Terraform tfvars for Landing Zone Security Lab
# Provides input values for variables.tf
# =======================================================

# -----------------------------
# General Settings
# -----------------------------
location = "eastus"

tags = {
  Owner       = "LandingZoneSecurity"
  Environment = "Lab"
  CostCenter  = "1234"
}

# -----------------------------
# Governance & Security Parameters
# -----------------------------

# Replace this with the actual Azure Policy initiative ID
initiative_id = "/providers/Microsoft.Authorization/policySetDefinitions/<security_initiative_id>"

# Enforced naming convention regex
name_pattern = "^[a-z]{2,5}-[a-z0-9]{2,8}-[a-z]{2,5}$"

# Required tags for compliance
required_tags = [
  "Owner",
  "Environment",
  "CostCenter"
]

# Allowed VM SKUs (restricts deployments to approved sizes)
allowed_skus = [
  "Standard_B1s",
  "Standard_B2s",
  "Standard_D2s_v3"
]
