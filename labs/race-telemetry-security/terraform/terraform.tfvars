#############################################
# terraform.tfvars - Example values
# NOTE: Do not store secrets here in real use.
# Instead, set TF_VAR_sql_admin_password as an
# environment variable, or let Key Vault generate it.
#############################################

resource_group_name = "rg-telemetry-lab"
location            = "eastus"

tenant_id        = "<your-tenant-guid>"
admin_object_id  = "<your-user-object-id>"

# Example ONLY - in real use, supply via env var:
# export TF_VAR_sql_admin_password="SuperSecure123!"
sql_admin_password = "SuperSecure123!"
