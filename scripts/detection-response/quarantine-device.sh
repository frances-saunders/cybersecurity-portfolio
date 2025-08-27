#!/bin/bash
# Quarantine endpoint using EDR API

DEVICE_ID=$1
API_URL="https://edr.example.com/api/isolate"

curl -X POST $API_URL -H "Authorization: Bearer $EDR_TOKEN" -d "{\"device\": \"$DEVICE_ID\"}"
