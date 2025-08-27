#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
iam-least-privilege-auditor.py
------------------------------
Flags broad Azure RBAC assignments (Owner/Contributor) at subscription scope and suggests tighter scoping.

Approach:
  - Uses Azure CLI to list role assignments (works across tenants/providers)
  - Filters for Owner/Contributor at subscription root (and inherited)
  - Produces a CSV/JSON with suggested action: "Scope to RG or use built-in least-privileged roles"

Requirements:
  Azure CLI, Python 3.9+

Example:
  python iam-least-privilege-auditor.py --subscription-id <SUB> --out-json rbac-findings.json --out-csv rbac-findings.csv
"""

import argparse, csv, json, subprocess, sys
from typing import List, Dict

BROAD_ROLES = {"Owner","Contributor"}

def sh(cmd: List[str]) -> str:
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    return r.stdout

def list_assignments(subscription: str) -> List[Dict]:
    out = sh(["az","role","assignment","list","--subscription",subscription,"--all","--include-inherited","-o","json"])
    return json.loads(out)

def is_subscription_root(scope: str) -> bool:
    return scope.lower().startswith("/subscriptions/") and "/resourcegroups/" not in scope.lower()

def suggestion(role: str) -> str:
    if role == "Owner":
        return "Avoid Owner outside break-glass; prefer scoped Contributor or specific roles at RG/resource."
    if role == "Contributor":
        return "Replace with least-privileged role(s) per workload; scope to RG/resource where possible."
    return "Review"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--subscription-id", required=True)
    ap.add_argument("--out-json", default="rbac-findings.json")
    ap.add_argument("--out-csv", default="rbac-findings.csv")
    args = ap.parse_args()
    try:
        assigns = list_assignments(args.subscription_id)
        findings = []
        for a in assigns:
            role = a.get("roleDefinitionName")
            scope = a.get("scope")
            if role in BROAD_ROLES and is_subscription_root(scope):
                findings.append({
                    "principalName": a.get("principalName"),
                    "principalType": a.get("principalType"),
                    "role": role,
                    "scope": scope,
                    "suggestion": suggestion(role),
                    "id": a.get("id")
                })

        with open(args.out_csv, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["principalName","principalType","role","scope","suggestion","id"])
            w.writeheader(); w.writerows(findings)
        with open(args.out_json, "w", encoding="utf-8") as f:
            json.dump({"subscription": args.subscription_id, "count": len(findings), "items": findings}, f, indent=2)
        print(json.dumps({"count": len(findings), "out_csv": args.out_csv, "out_json": args.out_json}))
    except Exception as e:
        print(json.dumps({"error": str(e)})); sys.exit(1)

if __name__ == "__main__":
    main()
