#!/bin/bash
# =======================================================
# Simulate malicious container workload (cryptojacker)
# =======================================================

RG="rg-cloud-attack-sim"
ACR_NAME="cloudattacklabacr"
CONTAINER_GROUP="malicious-miner"

echo "[*] Building fake cryptominer container..."
cat <<EOF > Dockerfile
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y stress
CMD ["stress", "--cpu", "4"]
EOF

az acr build --registry $ACR_NAME --image miner:latest .

echo "[*] Deploying malicious container instance..."
az container create \
  --resource-group $RG \
  --name $CONTAINER_GROUP \
  --image $ACR_NAME.azurecr.io/miner:latest \
  --cpu 4 --memory 4 \
  --restart-policy Never
