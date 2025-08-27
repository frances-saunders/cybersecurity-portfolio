#!/bin/bash
# Validate AKS clusters against CIS/NIST security benchmarks

CLUSTER_NAME="myakscluster"
RESOURCE_GROUP="rg-secure"

echo "[*] Checking privileged containers..."
kubectl get pods --all-namespaces -o json | jq '.items[] | select(.spec.containers[].securityContext.privileged==true)'
