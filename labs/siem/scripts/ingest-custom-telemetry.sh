#!/bin/bash
# -----------------------------------------------------
# Script: ingest-custom-telemetry.sh
# Purpose: Demonstrates ingestion of IoT telemetry into SIEM
# -----------------------------------------------------

set -euo pipefail

WORKSPACE_ID="$1"
SHARED_KEY="$2"
LOG_TYPE="IoTTelemetry"

# Sample telemetry payload
cat <<EOF > telemetry.json
[
  { "deviceId": "iot-001", "rpm": 7200, "temp": 85.3, "status": "OK" },
  { "deviceId": "iot-002", "rpm": 6800, "temp": 95.1, "status": "Warning" }
]
EOF

# Forward to Log Analytics
python3 post-to-law.py "$WORKSPACE_ID" "$SHARED_KEY" "$LOG_TYPE" telemetry.json
