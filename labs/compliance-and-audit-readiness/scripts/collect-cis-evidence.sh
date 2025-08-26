#!/usr/bin/env bash
# Collects CIS-aligned Azure Policy evidence using Azure CLI.
# - Prefers Managed Identity if available; otherwise uses 'az login --use-device-code'.
# - No secrets are stored; outputs are local files only.

set -euo pipefail

SUBSCRIPTION_ID="${1:-}"
ASSIGNMENT_FILTER="${2:-CIS}"
DAYS="${3:-30}"

if [[ -z "$SUBSCRIPTION_ID" ]]; then
  echo "Usage: $0 <subscriptionId> [assignmentFilter=CIS] [days=30]"
  exit 1
fi

# Try Managed Identity first
if ! az account show >/dev/null 2>&1; then
  if az login --identity >/dev/null 2>&1; then
    echo "Authenticated with Managed Identity."
  else
    echo "Managed Identity not available. Using device login."
    az login --use-device-code >/dev/null
  fi
fi

az account set --subscription "$SUBSCRIPTION_ID"

BASE_DIR="$(pwd)/evidence/cis"
mkdir -p "$BASE_DIR"

# Pull assignments that appear to be CIS-related
ASSIGNMENTS_JSON="$BASE_DIR/assignments.json"
az policy assignment list --query "[?contains(tolower(displayName),'${ASSIGNMENT_FILTER,,}') || contains(tolower(name),'${ASSIGNMENT_FILTER,,}')]" > "$ASSIGNMENTS_JSON"

FROM="$(date -u -d "-${DAYS} days" +"%Y-%m-%dT%H:%M:%SZ")"
TO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

SUMMARY_CSV="$BASE_DIR/summary.csv"
NONCOMPLIANT_CSV="$BASE_DIR/noncompliant.csv"
echo "AssignmentName,Scope,Compliant,NonCompliant,CompliancePct,WindowDays" > "$SUMMARY_CSV"
echo "Timestamp,PolicyDefinitionName,PolicyDefinitionAction,ResourceId,PolicyAssignmentName,ComplianceState" > "$NONCOMPLIANT_CSV"

ASSIGNMENT_IDS=$(jq -r '.[].id' "$ASSIGNMENTS_JSON")
for AID in $ASSIGNMENT_IDS; do
  ANAME=$(jq -r ".[] | select(.id==\"$AID\") | .displayName" "$ASSIGNMENTS_JSON")
  SCOPE=$(jq -r ".[] | select(.id==\"$AID\") | .scope" "$ASSIGNMENTS_JSON")

  # Use policy insights query
  STATES=$(az policy state list --query-start-time "$FROM" --query-end-time "$TO" --filter "PolicyAssignmentId eq '$AID'" --top 5000)
  C=$(echo "$STATES" | jq '[ .[] | select(.complianceState=="Compliant") ] | length')
  N=$(echo "$STATES" | jq '[ .[] | select(.complianceState=="NonCompliant") ] | length')
  TOTAL=$((C+N))
  if [[ "$TOTAL" -gt 0 ]]; then
    PCT=$(awk "BEGIN {printf \"%.1f\", (100.0 * $C / $TOTAL)}")
  else
    PCT="0.0"
  fi
  echo "\"$ANAME\",\"$SCOPE\",$C,$N,$PCT,$DAYS" >> "$SUMMARY_CSV"

  echo "$STATES" | jq -r '.[] | select(.complianceState=="NonCompliant") | [.timestamp, .policyDefinitionName, .policyDefinitionAction, .resourceId, .policyAssignmentName, .complianceState] | @csv' >> "$NONCOMPLIANT_CSV"
done

# Update manifest
cat > "$(pwd)/evidence/manifest.json" <<EOF
{
  "collectedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "framework": "CIS",
  "subscription": "$SUBSCRIPTION_ID",
  "windowDays": $DAYS,
  "files": [
    "$(realpath "$ASSIGNMENTS_JSON")",
    "$(realpath "$SUMMARY_CSV")",
    "$(realpath "$NONCOMPLIANT_CSV")"
  ]
}
EOF

echo "CIS evidence collection complete."
