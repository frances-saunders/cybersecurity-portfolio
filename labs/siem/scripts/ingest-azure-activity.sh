#!/bin/bash
# -----------------------------------------------------
# Script: ingest-azure-activity.sh
# Purpose: Pull Azure Activity Logs and push into Log Analytics
# -----------------------------------------------------

set -euo pipefail

WORKSPACE_ID="$1"
SHARED_KEY="$2"
LOG_TYPE="AzureActivity"

# Fetch activity logs (last 1 hour)
az monitor activity-log list --max-events 100 \
  --query "[].{time: eventTimestamp, level: level, operation: operationName.value, caller: caller}" \
  -o json > activity.json

# Post logs into Log Analytics workspace
python3 post-to-law.py "$WORKSPACE_ID" "$SHARED_KEY" "$LOG_TYPE" activity.json
