#!/bin/bash
# Provision Azure Key Vault securely

az keyvault create --name "MyKeyVault" --resource-group "rg-secure" --location "eastus"
az keyvault secret set --vault-name "MyKeyVault" --name "cosmos-db-key" --value "PLACEHOLDER"
