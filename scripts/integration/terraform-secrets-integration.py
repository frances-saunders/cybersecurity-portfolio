#!/usr/bin/env python3
"""
Helper to inject secrets from Key Vault into Terraform variables.
"""

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import os, json

vault_url = os.getenv("KEYVAULT_URL")
credential = DefaultAzureCredential()
client = SecretClient(vault_url=vault_url, credential=credential)

secret = client.get_secret("terraform-sp-client-secret").value

with open("terraform.tfvars.json", "w") as f:
    json.dump({"client_secret": secret}, f)
