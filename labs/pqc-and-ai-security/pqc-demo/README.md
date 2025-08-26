# PQC Demo (Kyber KEM)

## What This Shows
- A lattice-based KEM (Kyber) handshake that derives a shared session key.
- Optional symmetric encryption using AES-GCM if the library is available.
- No plaintext secrets. The script pulls an HKDF salt from a vault service or falls back to environment variables.

## Files
- `pqc_key_exchange.py` – Runs the Kyber key exchange and derives a session key.

## Dependencies
- Python 3.10+
- `pqcrypto` for Kyber KEM
- Optional: `cryptography` for AES-GCM
- Optional: `azure-identity` and `azure-keyvault-secrets` for Azure Key Vault
- Optional: `hvac` for HashiCorp Vault

## Configuration (No Plaintext Secrets)
- For Azure Key Vault, set `AZURE_KEY_VAULT_URI` and authorize with managed identity or a secure credential chain.
- For HashiCorp Vault, set `VAULT_ADDR` and `VAULT_TOKEN` (token must be injected securely).
- Optionally define `HKDF_SALT` as a secret in your vault. If absent, a random salt is used.

## Run
```
python3 pqc_key_exchange.py --message "test"
```
