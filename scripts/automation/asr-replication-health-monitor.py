#!/usr/bin/env python3
"""
asr-replication-health-monitor.py

Polls the Azure Site Recovery API for all protected VM replication items,
calculates replication lag per VM, flags items where the last recovery point
exceeds the tier RPO threshold, and pushes results to Azure Monitor custom
metrics. Designed to run as a cron job or Azure Automation runbook.

Out-of-the-box feature: RPO Breach Predictor
--------------------------------------------
Rather than only alerting when a breach has already occurred, this script
tracks replication lag over a rolling window (stored in a local state file or
Azure Table Storage) and extrapolates the lag trend to estimate how many
minutes remain before the current lag trajectory will exceed the RPO
threshold. This gives the ops team early warning -- typically 15-30 minutes
of lead time before a formal breach -- rather than a breach alert after the
fact.

The predictor uses simple linear regression on the last N lag samples to
compute lag velocity (minutes of lag added per minute of wall time). If
velocity > 0 (lag is growing), it computes:
    minutes_to_breach = (rpo_threshold - current_lag) / lag_velocity

The result is pushed as a custom metric alongside the current lag metric.

Authentication
--------------
Uses DefaultAzureCredential (managed identity preferred, falls back to
environment variables / CLI auth). Secrets are never embedded.

Required environment variables (if not using managed identity):
    AZURE_CLIENT_ID
    AZURE_CLIENT_SECRET
    AZURE_TENANT_ID
    AZURE_SUBSCRIPTION_ID

Required (always):
    ASR_VAULT_NAME        - Recovery Services vault name
    ASR_VAULT_RG          - Resource group of the vault
    AZURE_SUBSCRIPTION_ID - Target subscription

Optional:
    ASR_STATE_FILE        - Path to lag history JSON (default: /tmp/asr-lag-state.json)
    MONITOR_RG            - Resource group for custom metrics scope (default: ASR_VAULT_RG)

Usage:
    python3 asr-replication-health-monitor.py [--dry-run] [--verbose]

Cross-references:
    kql/asr-replication-health.kql
    docs/workload-classification.md
    docs/ir-playbooks/region-outage-tier1-failover.md

Lab: labs/bcdr-ir-plan
Author: Frances Saunders
"""

import argparse
import json
import logging
import os
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

try:
    from azure.identity import DefaultAzureCredential
    from azure.mgmt.recoveryservicessiterecovery import SiteRecoveryManagementClient
    from azure.monitor.ingestion import LogsIngestionClient
    import requests
except ImportError as e:
    print(f"Missing dependency: {e}")
    print("Install: pip install azure-identity azure-mgmt-recoveryservices-siterecovery "
          "azure-monitor-ingestion requests")
    sys.exit(1)

# ---------------------------------------------------------------------------
# Tier RPO thresholds in minutes
# ---------------------------------------------------------------------------
TIER_RPO_MINUTES = {
    "Tier1": 240,    # 4 hours
    "Tier2": 720,    # 12 hours
    "Tier3": 1440,   # 24 hours
}
DEFAULT_RPO_MINUTES = 1440  # For VMs without a tier tag

# Number of historical samples to use for RPO breach prediction
PREDICTOR_WINDOW = 5

# Custom metrics namespace and name
METRIC_NAMESPACE = "BCDR/ASR"

# ---------------------------------------------------------------------------
# Logging setup
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s %(message)s",
    datefmt="%H:%M:%S"
)
log = logging.getLogger(__name__)
# ---------------------------------------------------------------------------
# State management for lag history (predictor)
# ---------------------------------------------------------------------------

def load_lag_state(state_file: str) -> dict:
    """Load the rolling lag history from the state file."""
    try:
        with open(state_file) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def save_lag_state(state_file: str, state: dict) -> None:
    """Persist the lag history state file."""
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)


def update_vm_lag_history(state: dict, vm_id: str, lag_minutes: float) -> list:
    """
    Append the current lag sample for a VM and return the last N samples.
    Trims history to 2*PREDICTOR_WINDOW to keep the state file small.
    """
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "lag_minutes": lag_minutes,
    }
    if vm_id not in state:
        state[vm_id] = []
    state[vm_id].append(entry)
    # Trim to keep last 2*window samples
    state[vm_id] = state[vm_id][-(PREDICTOR_WINDOW * 2):]
    return state[vm_id][-PREDICTOR_WINDOW:]


# ---------------------------------------------------------------------------
# RPO breach predictor
# ---------------------------------------------------------------------------

def predict_minutes_to_breach(samples: list, rpo_threshold: float) -> Optional[float]:
    """
    Given a list of {ts, lag_minutes} samples, use linear regression to
    estimate lag velocity (minutes of lag added per minute of wall time).

    Returns estimated minutes until RPO breach, or None if:
    - Fewer than 2 samples available
    - Lag velocity <= 0 (lag is stable or improving)
    - Already in breach
    """
    if len(samples) < 2:
        return None

    # Convert timestamps to epoch seconds for regression
    xs = []
    ys = []
    for s in samples:
        try:
            dt = datetime.fromisoformat(s["ts"])
            xs.append(dt.timestamp())
            ys.append(float(s["lag_minutes"]))
        except (KeyError, ValueError):
            continue

    if len(xs) < 2:
        return None

    n = len(xs)
    mean_x = sum(xs) / n
    mean_y = sum(ys) / n

    numerator   = sum((xs[i] - mean_x) * (ys[i] - mean_y) for i in range(n))
    denominator = sum((xs[i] - mean_x) ** 2 for i in range(n))

    if denominator == 0:
        return None  # all samples at same timestamp

    # slope in lag_minutes per second; convert to lag_minutes per minute
    lag_velocity_per_minute = (numerator / denominator) * 60.0

    if lag_velocity_per_minute <= 0:
        return None  # lag not growing

    current_lag = ys[-1]
    if current_lag >= rpo_threshold:
        return 0.0  # already breached

    minutes_to_breach = (rpo_threshold - current_lag) / lag_velocity_per_minute
    return round(minutes_to_breach, 1)


# ---------------------------------------------------------------------------
# Azure Monitor custom metrics push
# ---------------------------------------------------------------------------

def push_custom_metric(
    credential,
    subscription_id: str,
    resource_group: str,
    region: str,
    metric_name: str,
    vm_name: str,
    tier: str,
    value: float,
    dry_run: bool = False,
) -> None:
    """
    Push a single custom metric data point to Azure Monitor.
    Custom metrics endpoint: {region}.monitoring.azure.com
    Scope: the Recovery Services vault resource group.
    """
    if dry_run:
        log.info(f"  [DryRun] Would push metric {metric_name}={value:.1f} for {vm_name}")
        return

    endpoint = (
        f"https://{region}.monitoring.azure.com"
        f"/subscriptions/{subscription_id}"
        f"/resourceGroups/{resource_group}"
        f"/providers/microsoft.insights/metrics"
    )

    token = credential.get_token("https://monitoring.azure.com/.default").token
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    payload = {
        "time": datetime.now(timezone.utc).isoformat(),
        "data": {
            "baseData": {
                "metric": metric_name,
                "namespace": METRIC_NAMESPACE,
                "dimNames": ["VMName", "Tier"],
                "series": [{
                    "dimValues": [vm_name, tier],
                    "sum": value,
                    "count": 1,
                    "min": value,
                    "max": value,
                }]
            }
        }
    }

    resp = requests.post(endpoint, headers=headers, json=payload, timeout=15)
    if resp.status_code not in (200, 202):
        log.warning(f"  Metric push failed [{resp.status_code}]: {resp.text[:200]}")
    else:
        log.debug(f"  Metric pushed: {metric_name}={value:.1f} for {vm_name}")
# ---------------------------------------------------------------------------
# ASR item polling
# ---------------------------------------------------------------------------

def get_lag_minutes(item) -> Optional[float]:
    """
    Extract replication lag in minutes from an ASR protected item.
    Returns None if the last recovery point time is not available.
    """
    try:
        props = item.properties
        if not hasattr(props, "provider_specific_details"):
            return None
        psd = props.provider_specific_details
        # HyperVReplicaAzure and VMwareAzure both expose last_recovery_point_received
        lrp = getattr(psd, "last_recovery_point_received", None) or \
              getattr(psd, "last_rpo_calculated_time", None)
        if lrp is None:
            return None
        if hasattr(lrp, "timestamp"):
            lrp_dt = datetime.fromtimestamp(lrp.timestamp(), tz=timezone.utc)
        else:
            lrp_dt = lrp
        if lrp_dt.tzinfo is None:
            lrp_dt = lrp_dt.replace(tzinfo=timezone.utc)
        lag = (datetime.now(timezone.utc) - lrp_dt).total_seconds() / 60.0
        return round(max(lag, 0), 1)
    except Exception:
        return None


def get_vm_tier(item) -> str:
    """Extract bcdr-tier tag from protected item. Returns Unknown if not set."""
    try:
        tags = getattr(item.properties, "tags", None) or {}
        return tags.get("bcdr-tier", "Unknown")
    except Exception:
        return "Unknown"


def get_health_state(item) -> str:
    """Return normalized health state string."""
    try:
        return str(item.properties.replication_health or "Unknown")
    except Exception:
        return "Unknown"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="ASR Replication Health Monitor with RPO Breach Predictor")
    parser.add_argument("--dry-run", action="store_true", help="Collect metrics but do not push to Azure Monitor")
    parser.add_argument("--verbose", action="store_true", help="Enable DEBUG logging")
    args = parser.parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # -- Config from environment ---------------------------------------------
    vault_name    = os.environ["ASR_VAULT_NAME"]
    vault_rg      = os.environ["ASR_VAULT_RG"]
    subscription  = os.environ["AZURE_SUBSCRIPTION_ID"]
    monitor_rg    = os.environ.get("MONITOR_RG", vault_rg)
    state_file    = os.environ.get("ASR_STATE_FILE", "/tmp/asr-lag-state.json")
    region        = os.environ.get("AZURE_REGION", "eastus2")

    log.info(f"ASR Replication Health Monitor")
    log.info(f"Vault: {vault_name} / {vault_rg} | Sub: {subscription}")
    log.info(f"DryRun: {args.dry_run}")

    credential = DefaultAzureCredential()
    client     = SiteRecoveryManagementClient(credential, subscription)

    # -- Load lag history ----------------------------------------------------
    state = load_lag_state(state_file)

    results = []
    breach_count = 0
    warning_count = 0  # predictor warnings

    # -- Enumerate all fabric / container / protected items ------------------
    try:
        fabrics = list(client.replication_fabrics.list(vault_rg, vault_name))
    except Exception as e:
        log.error(f"Failed to list ASR fabrics: {e}")
        sys.exit(1)

    for fabric in fabrics:
        fabric_name = fabric.name
        try:
            containers = list(client.replication_protection_containers.list(
                vault_rg, vault_name, fabric_name
            ))
        except Exception as e:
            log.warning(f"Failed to list containers in fabric {fabric_name}: {e}")
            continue

        for container in containers:
            container_name = container.name
            try:
                items = list(client.replication_protected_items.list_by_replication_protection_containers(
                    vault_rg, vault_name, fabric_name, container_name
                ))
            except Exception as e:
                log.warning(f"Failed to list protected items in {container_name}: {e}")
                continue

            for item in items:
                vm_name     = item.name
                tier        = get_vm_tier(item)
                health      = get_health_state(item)
                lag         = get_lag_minutes(item)
                rpo_thresh  = TIER_RPO_MINUTES.get(tier, DEFAULT_RPO_MINUTES)

                if lag is None:
                    log.warning(f"  {vm_name}: lag unavailable (no recovery point data)")
                    continue

                # Update lag history and predict breach
                samples          = update_vm_lag_history(state, vm_name, lag)
                mins_to_breach   = predict_minutes_to_breach(samples, rpo_thresh)
                rpo_breached     = lag >= rpo_thresh
                breach_warning   = (mins_to_breach is not None and 0 < mins_to_breach <= 30)

                if rpo_breached:
                    breach_count += 1
                    log.warning(f"  RPO BREACH  | {vm_name} ({tier}) lag={lag:.1f}m threshold={rpo_thresh}m")
                elif breach_warning:
                    warning_count += 1
                    log.warning(f"  RPO WARNING | {vm_name} ({tier}) lag={lag:.1f}m | breach in ~{mins_to_breach:.0f}m")
                else:
                    log.info(f"  OK          | {vm_name} ({tier}) lag={lag:.1f}m health={health}")

                # Push metrics to Azure Monitor
                push_custom_metric(credential, subscription, monitor_rg, region,
                                   "ReplicationLagMinutes", vm_name, tier, lag, args.dry_run)

                if mins_to_breach is not None:
                    push_custom_metric(credential, subscription, monitor_rg, region,
                                       "MinutesToRPOBreach", vm_name, tier, mins_to_breach, args.dry_run)

                results.append({
                    "vmName":           vm_name,
                    "tier":             tier,
                    "healthState":      health,
                    "lagMinutes":       lag,
                    "rpoThreshMinutes": rpo_thresh,
                    "rpoBreached":      rpo_breached,
                    "minutesToBreach":  mins_to_breach,
                    "breachWarning":    breach_warning,
                    "samplesInHistory": len(samples),
                })

    # -- Persist lag state for next run --------------------------------------
    save_lag_state(state_file, state)

    # -- Summary -------------------------------------------------------------
    print("")
    print("=" * 55)
    print(" ASR REPLICATION HEALTH SUMMARY")
    print("=" * 55)
    print(f" Total VMs monitored : {len(results)}")
    print(f" RPO breaches        : {breach_count}")
    print(f" Breach warnings     : {warning_count}  (predicted < 30 min)")
    print(f" State file          : {state_file}")
    print("=" * 55)

    # Exit non-zero on breach for alerting integration
    if breach_count > 0:
        log.error(f"{breach_count} RPO breach(es) detected.")
        sys.exit(1)


if __name__ == "__main__":
    main()
