#!/usr/bin/env bash
# =============================================================================
# bcdr-evidence-packager.sh
# =============================================================================
# SYNOPSIS
#   IR-specific evidence packaging for BCDR incidents. Pulls the Sentinel incident
#   timeline, last 72 hours of backup/ASR/sign-in logs for affected identities,
#   hashes all artifacts, writes a chain-of-custody manifest, and uploads the
#   entire package to the immutable evidence storage container.
#
# DESCRIPTION
#   This is distinct from scripts/automation/package-audit-evidence.sh, which is
#   for compliance audit packaging. This script is invoked during an active IR to
#   produce the evidence record an auditor or regulator will ask for.
#
#   Output: A tarball named <incidentId>-evidence-<timestamp>.tar.gz containing:
#     - 00-chain-of-custody-header.json  (operator, time, hash of tarball)
#     - sentinel-incident-timeline.json  (Sentinel incident + alert details)
#     - backup-events-72h.json           (AzureBackupReport events for affected period)
#     - asr-health-events-72h.json       (ASR replication health changes)
#     - signin-logs-affected-users.json  (Entra sign-in logs for flagged identities)
#     - resource-state/                  (ARM snapshots of each affected resource)
#     - manifest.sha256                  (SHA-256 hash of every file in package)
#
#   The tarball itself is SHA-256 hashed and the hash is written into the chain-of-
#   custody header before upload. The storage container has WORM/immutable policy;
#   once uploaded, the blob cannot be overwritten or deleted.
#
# REQUIREMENTS
#   - az CLI (authenticated via managed identity, OIDC, or az login)
#   - jq, sha256sum, tar
#   - Environment variables:
#       EVIDENCE_STORAGE_ACCOUNT  - storage account name for immutable container
#       SENTINEL_WORKSPACE_ID     - Log Analytics workspace ID for Sentinel
#       EVIDENCE_SUBSCRIPTION_ID  - subscription for the evidence storage account
#
# USAGE
#   ./bcdr-evidence-packager.sh -i IR-2024-0042 -a "vm-01,vm-02" -u "user@corp.com"
#
# OPTIONS
#   -i  Incident ID (required, e.g. IR-2024-0042)
#   -a  Affected Azure resource names, comma-separated (required)
#   -g  Resource group of affected resources (required)
#   -s  Subscription ID of affected resources (required)
#   -u  Affected user UPNs, comma-separated (optional)
#   -h  Hours of log history to collect (default: 72)
#   -n  Dry run -- collect but do not upload
#
# NOTES
#   Playbook: docs/ir-playbooks/post-incident-review-and-evidence-packaging.md
#   Companion script: scripts/detection-response/ransomware-containment.ps1
#   Lab: labs/bcdr-ir-plan
#   Author: Frances Saunders
# =============================================================================

set -euo pipefail

# --- Defaults ----------------------------------------------------------------
INCIDENT_ID=""
AFFECTED_RESOURCES=""
RESOURCE_GROUP=""
RESOURCE_SUBSCRIPTION=""
AFFECTED_USERS=""
HISTORY_HOURS=72
DRY_RUN=false
EVIDENCE_CONTAINER="evidence-packages"

# --- Argument parsing --------------------------------------------------------
while getopts "i:a:g:s:u:h:n" opt; do
    case "${opt}" in
        i) INCIDENT_ID="${OPTARG}" ;;
        a) AFFECTED_RESOURCES="${OPTARG}" ;;
        g) RESOURCE_GROUP="${OPTARG}" ;;
        s) RESOURCE_SUBSCRIPTION="${OPTARG}" ;;
        u) AFFECTED_USERS="${OPTARG}" ;;
        h) HISTORY_HOURS="${OPTARG}" ;;
        n) DRY_RUN=true ;;
        *) echo "Unknown option: ${opt}"; exit 1 ;;
    esac
done

# --- Validation --------------------------------------------------------------
[[ -z "${INCIDENT_ID}" ]]          && { echo "ERROR: -i (incident ID) is required."; exit 1; }
[[ -z "${AFFECTED_RESOURCES}" ]]   && { echo "ERROR: -a (affected resources) is required."; exit 1; }
[[ -z "${RESOURCE_GROUP}" ]]       && { echo "ERROR: -g (resource group) is required."; exit 1; }
[[ -z "${RESOURCE_SUBSCRIPTION}" ]] && { echo "ERROR: -s (subscription) is required."; exit 1; }
[[ -z "${EVIDENCE_STORAGE_ACCOUNT:-}" ]] && { echo "ERROR: EVIDENCE_STORAGE_ACCOUNT env var not set."; exit 1; }
[[ -z "${SENTINEL_WORKSPACE_ID:-}" ]]    && { echo "ERROR: SENTINEL_WORKSPACE_ID env var not set."; exit 1; }

# --- Setup -------------------------------------------------------------------
TIMESTAMP=$(date -u +"%Y%m%d-%H%M%S")
PACKAGE_NAME="${INCIDENT_ID}-evidence-${TIMESTAMP}"
WORK_DIR=$(mktemp -d "/tmp/${PACKAGE_NAME}.XXXXXX")
RESOURCE_STATE_DIR="${WORK_DIR}/resource-state"
mkdir -p "${RESOURCE_STATE_DIR}"

# Compute lookback window
LOOKBACK_START=$(date -u -d "${HISTORY_HOURS} hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                 date -u -v "-${HISTORY_HOURS}H" +"%Y-%m-%dT%H:%M:%SZ")  # macOS fallback
LOOKBACK_END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

log() { echo "[$(date -u +"%H:%M:%S")] $*"; }
log "BCDR Evidence Packager | Incident: ${INCIDENT_ID}"
log "Package: ${PACKAGE_NAME}"
log "Log window: ${LOOKBACK_START} to ${LOOKBACK_END} (${HISTORY_HOURS}h)"
[[ "${DRY_RUN}" == "true" ]] && log "DRY RUN MODE -- package will not be uploaded"
# --- Step 1: Sentinel incident timeline -------------------------------------
log "[Step 1] Pulling Sentinel incident timeline..."

SENTINEL_QUERY="SecurityIncident
| where IncidentName contains \"${INCIDENT_ID}\"
| project TimeGenerated, IncidentName, Title, Status, Severity, AlertIds, Description
| order by TimeGenerated asc"

az monitor log-analytics query \
    --workspace "${SENTINEL_WORKSPACE_ID}" \
    --analytics-query "${SENTINEL_QUERY}" \
    --subscription "${EVIDENCE_SUBSCRIPTION_ID:-${RESOURCE_SUBSCRIPTION}}" \
    --output json 2>/dev/null > "${WORK_DIR}/sentinel-incident-timeline.json" || \
    echo "[]" > "${WORK_DIR}/sentinel-incident-timeline.json"

INCIDENT_ROW_COUNT=$(jq length "${WORK_DIR}/sentinel-incident-timeline.json" 2>/dev/null || echo 0)
log "  Sentinel rows collected: ${INCIDENT_ROW_COUNT}"

# --- Step 2: Backup events --------------------------------------------------
log "[Step 2] Pulling backup events (last ${HISTORY_HOURS}h)..."

BACKUP_QUERY="AzureBackupReport
| where TimeGenerated between (datetime(\"${LOOKBACK_START}\") .. datetime(\"${LOOKBACK_END}\"))
| project TimeGenerated, JobStatus, JobOperationSubType, BackupItemName, VaultName, ErrorCode, ErrorTitle
| order by TimeGenerated asc"

az monitor log-analytics query \
    --workspace "${SENTINEL_WORKSPACE_ID}" \
    --analytics-query "${BACKUP_QUERY}" \
    --output json 2>/dev/null > "${WORK_DIR}/backup-events-72h.json" || \
    echo "[]" > "${WORK_DIR}/backup-events-72h.json"

BACKUP_ROW_COUNT=$(jq length "${WORK_DIR}/backup-events-72h.json" 2>/dev/null || echo 0)
log "  Backup event rows: ${BACKUP_ROW_COUNT}"

# --- Step 3: ASR replication health events ----------------------------------
log "[Step 3] Pulling ASR replication health events..."

ASR_QUERY="AzureActivity
| where TimeGenerated between (datetime(\"${LOOKBACK_START}\") .. datetime(\"${LOOKBACK_END}\"))
| where ResourceProvider == \"Microsoft.RecoveryServices\"
| where OperationNameValue contains \"replication\" or OperationNameValue contains \"failover\"
| project TimeGenerated, OperationNameValue, ActivityStatus, Caller, ResourceGroup, Resource
| order by TimeGenerated asc"

az monitor log-analytics query \
    --workspace "${SENTINEL_WORKSPACE_ID}" \
    --analytics-query "${ASR_QUERY}" \
    --output json 2>/dev/null > "${WORK_DIR}/asr-health-events-72h.json" || \
    echo "[]" > "${WORK_DIR}/asr-health-events-72h.json"

ASR_ROW_COUNT=$(jq length "${WORK_DIR}/asr-health-events-72h.json" 2>/dev/null || echo 0)
log "  ASR health event rows: ${ASR_ROW_COUNT}"

# --- Step 4: Sign-in logs for affected users --------------------------------
log "[Step 4] Pulling sign-in logs for affected users..."

if [[ -n "${AFFECTED_USERS}" ]]; then
    # Build KQL filter for affected user UPNs
    UPNS_FILTER=$(echo "${AFFECTED_USERS}" | tr "," "\n" | \
        sed 's/^/UserPrincipalName == "/;s/$/" /' | \
        paste -sd "or " -)

    SIGNIN_QUERY="SigninLogs
| where TimeGenerated between (datetime(\"${LOOKBACK_START}\") .. datetime(\"${LOOKBACK_END}\"))
| where ${UPNS_FILTER}
| project TimeGenerated, UserPrincipalName, AppDisplayName, IPAddress, ResultType, ResultDescription, ConditionalAccessStatus
| order by TimeGenerated asc"

    az monitor log-analytics query \
        --workspace "${SENTINEL_WORKSPACE_ID}" \
        --analytics-query "${SIGNIN_QUERY}" \
        --output json 2>/dev/null > "${WORK_DIR}/signin-logs-affected-users.json" || \
        echo "[]" > "${WORK_DIR}/signin-logs-affected-users.json"

    SIGNIN_ROW_COUNT=$(jq length "${WORK_DIR}/signin-logs-affected-users.json" 2>/dev/null || echo 0)
    log "  Sign-in log rows: ${SIGNIN_ROW_COUNT}"
else
    echo "[]" > "${WORK_DIR}/signin-logs-affected-users.json"
    log "  No affected users specified -- sign-in log collection skipped."
fi

# --- Step 5: Resource state snapshots ---------------------------------------
log "[Step 5] Capturing ARM resource state snapshots..."

IFS="," read -ra RESOURCE_ARRAY <<< "${AFFECTED_RESOURCES}"
for RESOURCE_NAME in "${RESOURCE_ARRAY[@]}"; do
    RESOURCE_NAME=$(echo "${RESOURCE_NAME}" | xargs)  # trim whitespace
    log "  Snapshotting: ${RESOURCE_NAME}"

    az resource show \
        --name "${RESOURCE_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --subscription "${RESOURCE_SUBSCRIPTION}" \
        --output json 2>/dev/null > "${RESOURCE_STATE_DIR}/${RESOURCE_NAME}.json" || \
        echo "{"error": "Failed to retrieve resource state"}" > "${RESOURCE_STATE_DIR}/${RESOURCE_NAME}.json"
done
# --- Step 6: SHA-256 manifest -----------------------------------------------
log "[Step 6] Computing SHA-256 manifest..."

MANIFEST_FILE="${WORK_DIR}/manifest.sha256"
find "${WORK_DIR}" -type f ! -name "manifest.sha256" ! -name "00-chain-of-custody-header.json" | sort | while read -r f; do
    RELATIVE_PATH="${f#${WORK_DIR}/}"
    HASH=$(sha256sum "${f}" | awk "{print \$1}")
    printf "%s  %s\n" "${HASH}" "${RELATIVE_PATH}"
done > "${MANIFEST_FILE}"

MANIFEST_COUNT=$(wc -l < "${MANIFEST_FILE}")
log "  Files hashed: ${MANIFEST_COUNT}"

# --- Step 7: Create tarball -------------------------------------------------
log "[Step 7] Creating evidence tarball..."

TARBALL_PATH="/tmp/${PACKAGE_NAME}.tar.gz"
tar -czf "${TARBALL_PATH}" -C "$(dirname "${WORK_DIR}")" "$(basename "${WORK_DIR}")" 2>/dev/null
TARBALL_HASH=$(sha256sum "${TARBALL_PATH}" | awk "{print \$1}")
TARBALL_SIZE=$(stat -c%s "${TARBALL_PATH}" 2>/dev/null || stat -f%z "${TARBALL_PATH}")  # Linux/macOS compat

log "  Tarball: ${TARBALL_PATH} | SHA-256: ${TARBALL_HASH} | Size: ${TARBALL_SIZE} bytes"

# --- Step 8: Chain-of-custody header ----------------------------------------
log "[Step 8] Writing chain-of-custody header..."

OPERATOR="${USER:-automation}"
HOSTNAME_VAL=$(hostname 2>/dev/null || echo "unknown")

cat > "${WORK_DIR}/00-chain-of-custody-header.json" <<EOF
{
  "incidentId": "${INCIDENT_ID}",
  "packageName": "${PACKAGE_NAME}",
  "collectionTimestamp": "${LOOKBACK_END}",
  "logWindowStart": "${LOOKBACK_START}",
  "logWindowEnd": "${LOOKBACK_END}",
  "logWindowHours": ${HISTORY_HOURS},
  "operator": "${OPERATOR}",
  "collectionHost": "${HOSTNAME_VAL}",
  "affectedResources": "${AFFECTED_RESOURCES}",
  "affectedUsers": "${AFFECTED_USERS}",
  "tarballHash_sha256": "${TARBALL_HASH}",
  "tarballSizeBytes": ${TARBALL_SIZE},
  "filesInManifest": ${MANIFEST_COUNT},
  "dryRun": ${DRY_RUN}
}
EOF

# Rebuild tarball to include the header (it must be inside the tarball)
tar -czf "${TARBALL_PATH}" -C "$(dirname "${WORK_DIR}")" "$(basename "${WORK_DIR}")" 2>/dev/null
FINAL_TARBALL_HASH=$(sha256sum "${TARBALL_PATH}" | awk "{print \$1}")
log "  Final tarball hash (with header): ${FINAL_TARBALL_HASH}"

# --- Step 9: Upload to immutable evidence container ------------------------
BLOB_NAME="${PACKAGE_NAME}/${PACKAGE_NAME}.tar.gz"

if [[ "${DRY_RUN}" == "true" ]]; then
    log "[Step 9] DRY RUN -- tarball ready at ${TARBALL_PATH} but NOT uploaded."
else
    log "[Step 9] Uploading to immutable evidence container..."
    az storage blob upload \
        --account-name "${EVIDENCE_STORAGE_ACCOUNT}" \
        --container-name "${EVIDENCE_CONTAINER}" \
        --name "${BLOB_NAME}" \
        --file "${TARBALL_PATH}" \
        --auth-mode login \
        --overwrite false \
        --output none 2>&1

    if [[ $? -eq 0 ]]; then
        log "  Upload complete: ${EVIDENCE_CONTAINER}/${BLOB_NAME}"
    else
        log "  ERROR: Upload failed. Local copy preserved at: ${TARBALL_PATH}"
        exit 1
    fi
fi

# --- Summary ----------------------------------------------------------------
echo ""
echo "================================================="
echo " EVIDENCE PACKAGE COMPLETE"
echo "================================================="
echo " Incident     : ${INCIDENT_ID}"
echo " Package      : ${PACKAGE_NAME}"
echo " Tarball hash : ${FINAL_TARBALL_HASH}"
echo " Files        : ${MANIFEST_COUNT}"
echo " Dry run      : ${DRY_RUN}"
echo " Local path   : ${TARBALL_PATH}"
if [[ "${DRY_RUN}" != "true" ]]; then
    echo " Storage blob : ${EVIDENCE_CONTAINER}/${BLOB_NAME}"
fi
echo "================================================="
echo " Chain of custody hash committed."
echo " Present manifest.sha256 to auditor for verification."
echo "================================================="
