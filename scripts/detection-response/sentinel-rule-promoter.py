#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
sentinel-rule-promoter.py
Promotes Microsoft Sentinel Analytics Rules from a "dev" artifacts directory to "prod",
versioning each rule and (optionally) applying via Azure CLI.

Artifacts
- Expects rule JSON files exported from Sentinel (ARM-ish schema or Rule-API schema).
- Increments a "version" property in metadata (adds if missing).
- Writes changelog.json of promoted rules.

Optional apply
- If --apply is set, uses `az` to upsert rules into the target workspace.

Usage
  python sentinel-rule-promoter.py --dev ./rules/dev --prod ./rules/prod --workspace <LAW_NAME> --resource-group <RG> --apply
"""

import argparse, json, os, shutil, subprocess, sys
from datetime import datetime
from typing import Dict

def load_json(p: str) -> Dict:
    return json.load(open(p, "r", encoding="utf-8"))

def dump_json(obj: Dict, p: str):
    with open(p, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2)

def az(*args) -> str:
    r = subprocess.run(["az", *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout

def bump_version(rule: Dict) -> Dict:
    meta = rule.setdefault("metadata", {})
    v = meta.get("version", 0)
    if isinstance(v, str) and v.isdigit():
        v = int(v)
    meta["version"] = int(v) + 1
    meta["lastPromoted"] = datetime.utcnow().isoformat() + "Z"
    return rule

def apply_rule(rule_path: str, ws: str, rg: str):
    # Generic path using ARM template deployment for single resource
    az("monitor", "scheduled-query", "create",
       "--name", os.path.splitext(os.path.basename(rule_path))[0],
       "--resource-group", rg,
       "--workspace-name", ws,
       "--schedule", "PT5M",
       "--condition", "@@PLACEHOLDER@@")  # NOTE: This is a placeholder; in practice use specific params per rule schema.

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dev", required=True)
    ap.add_argument("--prod", required=True)
    ap.add_argument("--workspace")
    ap.add_argument("--resource-group")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--out-changelog", default="changelog.json")
    args = ap.parse_args()

    os.makedirs(args.prod, exist_ok=True)
    changes = []

    for fn in os.listdir(args.dev):
        if not fn.lower().endswith(".json"):
            continue
        src = os.path.join(args.dev, fn)
        dst = os.path.join(args.prod, fn)

        rule = load_json(src)
        rule = bump_version(rule)
        dump_json(rule, dst)

        changes.append({"rule": fn, "prod_path": dst, "version": rule["metadata"]["version"]})

        if args.apply:
            if not (args.workspace and args.resource_group):
                print("ERROR: --apply requires --workspace and --resource-group", file=sys.stderr); sys.exit(2)
            try:
                apply_rule(dst, args.workspace, args.resource_group)
            except Exception as e:
                changes[-1]["apply_error"] = str(e)

    dump_json({"promoted": changes}, args.out_changelog)
    print(json.dumps({"promoted": len(changes), "changelog": args.out_changelog}))
    sys.exit(0)

if __name__ == "__main__":
    main()
