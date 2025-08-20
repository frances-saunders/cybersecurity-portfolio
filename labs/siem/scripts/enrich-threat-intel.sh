#!/bin/bash
# Script: enrich-threat-intel.sh
# Purpose: Enrich Sentinel incidents with TI data for suspicious IOCs

INCIDENT_ID=$1
IOC=$2

echo "Enriching Incident: $INCIDENT_ID for Indicator: $IOC"

# Example: sanitized TI API call
RESPONSE=$(curl -s "https://threat-intel-api/labquery?ioc=$IOC")

echo "Threat Intel Data: $RESPONSE"
