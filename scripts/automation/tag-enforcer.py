#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
tag-enforcer.py
----------------
Enforce required Azure resource tags (env, owner, data-class) across a subscription or resource group.
- Discovers resources via Azure CLI (stable across providers without API version hassles)
- Reports non-compliant resources
- Optionally auto-remediates (applies default tags) with --remediate
- Supports dry-run and JSON report output

Requirements:
  - Azure CLI logged in with Reader (report) or Contributor (remediate) on target scope
  - Python 3.9+
"""

import argparse, json, os, subprocess, sys
from typing import Dict, List

REQUIRED_DEFAULTS = {
    "env": "prod",
    "owner": "security@company.tld",
    "data-class": "internal"
}

def sh(cmd: List[str]) -> str:
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{r.stderr}")
    return r.stdout

def list_resources(subscription: str, resource_group: str = None) -> List[Dict]:
    cmd = ["az", "resource", "list", "--subscription", subscription, "-o", "json"]
    if resource_group:
        cmd.extend(["-g", resource_group])
    return json.loads(sh(cmd))

def ensure_tags(resource_id: str, tags: Dict[str, str], dry_run: bool):
    if dry_run:
        return
    # Merge tags on the resource; Azure CLI replaces existing tags unless we pass both
    kv = []
    for k, v in tags.items():
        kv.append(f"{k}={v}")
    sh(["az", "resource", "tag", "--ids", resource_id, "--tags", *kv])

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--subscription-id", required=True)
    ap.add_argument("--resource-group")
    ap.add_argument("--required", nargs="+", default=["env","owner","data-class"], help="Required tag keys")
    ap.add_argument("--defaults-json", help="Path to JSON mapping for defaults")
    ap.add_argument("--remediate", action="store_true", help="Apply missing tags with defaults")
    ap.add_argument("--dry-run", action="store_true", help="Show what would change but do not modify")
    ap.add_argument("--out-json", help="Write a JSON compliance report to file")
    args = ap.parse_args()

    defaults = REQUIRED_DEFAULTS.copy()
    if args.defaults_json:
        defaults.update(json.load(open(args.defaults_json)))

    res = list_resources(args.subscription_id, args.resource_group)
    non_compliant = []

    for r in res:
        rid = r.get("id")
        current = r.get("tags") or {}
        missing = [k for k in args.required if k not in current or not str(current.get(k)).strip()]
        if missing:
            proposed = {k: defaults.get(k, f"tbd-{k}") for k in missing}
            non_compliant.append({"id": rid, "missing": missing, "proposed": proposed})
            if args.remediate:
                ensure_tags(rid, {**current, **proposed}, args.dry_run)

    report = {
        "subscription": args.subscription_id,
        "resource_group": args.resource_group,
        "required": args.required,
        "non_compliant_count": len(non_compliant),
        "items": non_compliant
    }

    print(json.dumps(report, indent=2))
    if args.out_json:
        with open(args.out_json, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)
