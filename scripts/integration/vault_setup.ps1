<#
Provision HashiCorp Vault and enable secret engines.
#>

vault server -config=config.hcl
vault secrets enable kv
vault kv put secret/db password="PLACEHOLDER"
