#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
terraform-secrets-integration.py
--------------------------------
Fetches secrets from Azure Key Vault and writes a Terraform tfvars.json file
without logging the secret values. Use in CI to keep plans secret-free.

Example:
  python terraform-secrets-integration.py --vault-url https://kv.vault.azure.net \
      --secret terraform-sp-client-secret --out terraform.tfvars.json
"""

import argparse, json, os, sys
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--vault-url", default=os.getenv("KEYVAULT_URL"), required=not os.getenv("KEYVAULT_URL"))
    ap.add_argument("--secret", action="append", required=True, help="Secret name to fetch; can repeat")
    ap.add_argument("--out", default="terraform.tfvars.json")
    args = ap.parse_args()

    try:
        client = SecretClient(vault_url=args.vault_url, credential=DefaultAzureCredential())
        data = {}
        for name in args.secret:
            data[name] = client.get_secret(name).value
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(data, f)
        print(f"Wrote tfvars -> {args.out} (keys: {', '.join(data.keys())})")
    except Exception as e:
        print(f"ERROR: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
