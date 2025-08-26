#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PQC Lattice KEM (Kyber) key exchange demo with optional hybrid AES-GCM encryption.
- No plaintext secrets in code.
- Secrets (like HKDF salt) are read from a vault (Azure Key Vault or HashiCorp Vault) or env vars.
- If Kyber isn't installed, the script exits with a clear message.

Usage:
  python3 pqc_key_exchange.py --message "hello quantum-safe world"
"""

import argparse
import base64
import os
import sys
import hmac
import hashlib
from typing import Optional

# ---------- Vault integration (no plaintext credentials) ----------
class VaultClient:
    """
    Priority order:
      1) Azure Key Vault via managed identity / DefaultAzureCredential (if AZURE_KEY_VAULT_URI is set)
      2) HashiCorp Vault via hvac (if VAULT_ADDR and VAULT_TOKEN are set in environment)
      3) Environment variable with the same name as the secret (for local dev)
    """
    def __init__(self):
        self.azure_uri = os.getenv("AZURE_KEY_VAULT_URI")  # e.g., "https://my-kv.vault.azure.net/"
        self.hvault_addr = os.getenv("VAULT_ADDR")         # e.g., "https://vault.internal:8200"
        self.hvault_token = os.getenv("VAULT_TOKEN")       # never hardcode; injected securely

        self._azure_client = None
        self._hvac_client = None

        # Lazy init
        if self.azure_uri:
            try:
                from azure.identity import DefaultAzureCredential
                from azure.keyvault.secrets import SecretClient
                self._azure_client = SecretClient(
                    vault_url=self.azure_uri,
                    credential=DefaultAzureCredential()
                )
            except Exception:
                self._azure_client = None  # missing SDK or not configured

        if self.hvault_addr and self.hvault_token:
            try:
                import hvac
                self._hvac_client = hvac.Client(url=self.hvault_addr, token=self.hvault_token, verify=True)
            except Exception:
                self._hvac_client = None

    def get_secret(self, name: str) -> Optional[bytes]:
        # 1) Azure KV
        if self._azure_client:
            try:
                v = self._azure_client.get_secret(name)
                if v and v.value is not None:
                    return v.value.encode("utf-8")
            except Exception:
                pass
        # 2) HashiCorp Vault (KV v2 recommended; using logical.read for simplicity)
        if self._hvac_client:
            try:
                # Expected path convention: secret/data/<name>
                # If you use a different mount, set env VAR "VAULT_KV_MOUNT" and adapt this path in your environment.
                mount = os.getenv("VAULT_KV_MOUNT", "secret")
                path = f"{mount}/data/{name}"
                resp = self._hvac_client.secrets.kv.v2.read_secret_version(path=name) if hasattr(self._hvac_client.secrets, "kv") else self._hvac_client.read(path)
                if resp:
                    data = resp["data"]["data"] if "data" in resp and "data" in resp["data"] else resp.get("data")
                    if data and name in data:
                        val = data[name]
                        if isinstance(val, str):
                            return val.encode("utf-8")
            except Exception:
                pass
        # 3) Environment variable fallback (for local dev only)
        env_val = os.getenv(name)
        if env_val:
            return env_val.encode("utf-8")
        return None


# ---------- HKDF (RFC 5869) minimal implementation (no external deps) ----------
def hkdf_extract(salt: bytes, ikm: bytes, hashmod=hashlib.sha256) -> bytes:
    return hmac.new(salt, ikm, hashmod).digest()

def hkdf_expand(prk: bytes, info: bytes, length: int, hashmod=hashlib.sha256) -> bytes:
    hash_len = hashmod().digest_size
    n = (length + hash_len - 1) // hash_len
    okm = b""
    t = b""
    for i in range(1, n + 1):
        t = hmac.new(prk, t + info + bytes([i]), hashmod).digest()
        okm += t
    return okm[:length]

def hkdf(ikm: bytes, salt: bytes, info: bytes, length: int = 32) -> bytes:
    prk = hkdf_extract(salt, ikm)
    return hkdf_expand(prk, info, length)


# ---------- Optional AES-GCM (if 'cryptography' is available) ----------
def try_encrypt_with_aesgcm(key: bytes, plaintext: bytes, aad: bytes = b"pqc-ai-security-lab"):
    try:
        from cryptography.hazmat.primitives.ciphers.aead import AESGCM
    except Exception:
        return None, None, None  # encryption not available
    aesgcm = AESGCM(key)
    nonce = os.urandom(12)
    ct = aesgcm.encrypt(nonce, plaintext, aad)
    pt = aesgcm.decrypt(nonce, ct, aad)
    assert pt == plaintext
    return nonce, ct, aad


# ---------- Kyber (PQC) ----------
def kyber_demo(message: bytes, vault: VaultClient):
    # Load a salt from vault (recommended) or generate ephemeral if missing (salt is not secret but should be centrally controlled in prod).
    salt = vault.get_secret("HKDF_SALT") or os.urandom(32)
    context = b"kyber512-handshake"

    # Import Kyber KEM
    try:
        try:
            from pqcrypto.kem.kyber512 import generate_keypair, encapsulate, decapsulate
        except Exception:
            # Some builds name these differently
            from pqcrypto.kem.kyber512 import generate_keypair, encrypt as encapsulate, decrypt as decapsulate
    except Exception as e:
        print("Kyber KEM library not found. Install 'pqcrypto' and re-run.")
        print("Example: pip install pqcrypto")
        sys.exit(1)

    # Server generates keypair
    pk, sk = generate_keypair()  # public key, secret key (bytes)

    # Client encapsulates to server PK (produces ciphertext and a shared secret)
    ct, ss_client = encapsulate(pk)  # ss_client is bytes

    # Server decapsulates to derive the same shared secret
    ss_server = decapsulate(sk, ct)

    if ss_client != ss_server:
        raise RuntimeError("Shared secrets do not match; KEM failed.")

    # Derive a session key with HKDF
    session_key = hkdf(ikm=ss_client, salt=salt, info=context, length=32)

    # Optional encryption demo (if cryptography is installed)
    nonce, ct_gcm, aad = try_encrypt_with_aesgcm(session_key, message)
    print("Kyber key exchange complete.")
    print(f"Derived session key (hex): {session_key.hex()}")

    if nonce is not None:
        print("AES-GCM demonstration:")
        print(f"  Nonce (b64): {base64.b64encode(nonce).decode()}")
        print(f"  Ciphertext (b64): {base64.b64encode(ct_gcm).decode()}")
        print(f"  AAD (utf8): {aad.decode()}")
    else:
        print("AES-GCM encryption not available (optional). Install 'cryptography' for demo.")

    # Return artifacts in case you import this module elsewhere
    return {
        "public_key": pk,
        "ciphertext": ct,
        "session_key": session_key,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--message", default="hello quantum-safe world", help="Plaintext to protect after KEM")
    args = parser.parse_args()

    vault = VaultClient()
    _ = kyber_demo(args.message.encode("utf-8"), vault)


if __name__ == "__main__":
    main()
