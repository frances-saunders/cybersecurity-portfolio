#############################################
# terraform.tfvars - Example values
# NOTE: Do not store secrets here in real use.
# Provide sensitive values via environment variables:
#   export TF_VAR_sql_admin_password="your-password"
#############################################

# -----------------------------
# General Settings
# -----------------------------
resource_group_name = "rg-telemetry-lab"
location            = "eastus"

# -----------------------------
# Identity Settings
# -----------------------------
tenant_id       = "<your-tenant-guid>"
admin_object_id = "<your-user-object-id>"

# -----------------------------
# SQL Authentication
# -----------------------------
# Do NOT define sql_admin_password here.
# It must be supplied securely via environment variable.
# Example:
#   export TF_VAR_sql_admin_password="your-password"
