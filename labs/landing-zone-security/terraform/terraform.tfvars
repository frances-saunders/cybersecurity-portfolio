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
# Governance Parameters
# -----------------------------
initiative_id  = "/providers/Microsoft.Authorization/policySetDefinitions/<initiative_id>"
name_pattern   = "^[a-z]{2,5}-[a-z0-9]{2,8}-[a-z]{2,5}$"
required_tags  = ["Owner", "Environment", "CostCenter"]
allowed_skus   = ["Standard_B1s", "Standard_B2s", "Standard_D2s_v3"]
