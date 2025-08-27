#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
resource-locks-guard.py
-----------------------
Ensures "CanNotDelete" locks exist on critical resources and emits a drift report.
Critical resources are selected by tag (default: critical=true) or from a file list of resource IDs.

- Read-only by default; use --enforce to create missing locks
- Supports --dry-run for simulated enforcement
- Output JSON suitable for CI dashboards

Requirements:
  - Azure CLI logged in with Reader (report) or Owner/User Access Administrator (to create locks)
"""

import argparse, json, subprocess, sys
from typing import List, Dict

def sh(cmd: List[str]):
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout

def list_critical_resources(subscription: str, tag: str = "critical", value: str = "true", ids_file: str = None) -> List[str]:
    if ids_file:
        return [x.strip() for x in open(ids_file) if x.strip()]
    q = f"[?tags.{tag}=='{value}'].id"
    out = sh(["az","resource","list","--subscription",subscription,"--query",q,"-o","tsv"])
    return [x for x in out.splitlines() if x.strip()]

def has_cannotdelete_lock(resource_id: str) -> bool:
    out = sh(["az","lock","list","--resource","", "--ids", resource_id, "-o","json"])
    for lock in json.loads(out):
        if lock.get("level","").lower() == "cannotdelete":
            return True
    return False

def create_lock(resource_id: str, name: str, dry_run: bool):
    if dry_run:
        return
    sh(["az","lock","create","--name",name,"--lock-type","CanNotDelete","--resource","", "--ids", resource_id])

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--subscription-id", required=True)
    ap.add_argument("--tag", default="critical")
    ap.add_argument("--value", default="true")
    ap.add_argument("--ids-file", help="File with newline-separated resource IDs (overrides tag selection)")
    ap.add_argument("--lock-name", default="protect-cannotdelete")
    ap.add_argument("--enforce", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--out-json")
    args = ap.parse_args()

    items = []
    resources = list_critical_resources(args.subscription_id, args.tag, args.value, args.ids_file)
    missing = 0

    for rid in resources:
        try:
            exists = has_cannotdelete_lock(rid)
        except Exception as e:
            items.append({"id": rid, "error": str(e)})
            continue
        if not exists:
            missing += 1
            if args.enforce:
                try:
                    create_lock(rid, args.lock_name, args.dry_run)
                    status = "created" if not args.dry_run else "would_create"
                except Exception as e:
                    status = f"error:{e}"
            else:
                status = "missing"
        else:
            status = "present"
        items.append({"id": rid, "status": status})

    report = {
        "subscription": args.subscription_id,
        "selector": {"tag": args.tag, "value": args.value, "ids_file": args.ids_file},
        "lock_name": args.lock_name,
        "enforced": args.enforce,
        "dry_run": args.dry_run,
        "checked": len(resources),
        "missing": missing,
        "items": items
    }
    print(json.dumps(report, indent=2))
    if args.out_json:
        with open(args.out_json, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(json.dumps({"error": str(e)})); sys.exit(1)
