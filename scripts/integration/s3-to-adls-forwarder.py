#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
s3-to-adls-forwarder.py
Cross-cloud log bridge: copy objects from Amazon S3 to Azure Data Lake Storage Gen2 (ADLS).
- Streams objects; supports server-side encryption on S3 (SSE-S3/KMS) transparently
- ADLS upload via azure-storage-blob (hierarchical namespace)
- No plaintext secrets: use standard AWS credentials provider chain + Azure DefaultAzureCredential

Usage:
  python s3-to-adls-forwarder.py --s3-bucket my-logs --s3-prefix incoming/ \
      --adls-account mystorage --adls-container logs --adls-prefix transferred/

Requires:
  pip install boto3 azure-identity azure-storage-blob
"""

import argparse, os, sys, boto3
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--s3-bucket", required=True)
    ap.add_argument("--s3-prefix", default="")
    ap.add_argument("--adls-account", required=True)
    ap.add_argument("--adls-container", required=True)
    ap.add_argument("--adls-prefix", default="")
    ap.add_argument("--max", type=int, default=0, help="Max objects to copy (0 = all)")
    args = ap.parse_args()

    # AWS auth via env/instance profile; Azure via MSI/Workload identity
    s3 = boto3.client("s3")
    cred = DefaultAzureCredential()
    blob_url = f"https://{args.adls_account}.blob.core.windows.net"
    bsc = BlobServiceClient(account_url=blob_url, credential=cred)
    container = bsc.get_container_client(args.adls_container)
    container.create_container(exist_ok=True)

    paginator = s3.get_paginator('list_objects_v2')
    count = 0
    for page in paginator.paginate(Bucket=args.s3_bucket, Prefix=args.s3_prefix):
        for obj in page.get("Contents", []):
            key = obj["Key"]
            # Skip folders
            if key.endswith("/"): continue
            dest_path = os.path.join(args.adls_prefix, key[len(args.s3_prefix):]).lstrip("/")
            blob = container.get_blob_client(dest_path)
            # Stream download from S3 and upload to ADLS
            print(f"Copying s3://{args.s3_bucket}/{key} -> {dest_path}")
            body = s3.get_object(Bucket=args.s3_bucket, Key=key)["Body"]
            blob.upload_blob(body, overwrite=True)
            count += 1
            if args.max and count >= args.max:
                print(f"Limit {args.max} reached"); print({"copied": count}); return

    print({"copied": count})

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print({"error": str(e)}); sys.exit(1)
