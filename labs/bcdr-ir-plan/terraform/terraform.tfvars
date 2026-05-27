# terraform.tfvars — BCDR/IR Plan Lab
# Replace placeholder values before applying.
# Do NOT commit real subscription IDs or email addresses to version control.

prefix                = "bcdr"
resource_group_name   = "rg-bcdr-prod"
primary_location      = "eastus2"
recovery_location     = "westus2"

# alert_email is marked sensitive in variables.tf.
# Pass via environment variable: export TF_VAR_alert_email="soc@company.com"
# alert_email = "soc@company.com"

tags = {
  environment = "production"
  owner       = "security"
  project     = "bcdr-ir-plan"
  cost-center = "security-ops"
}
