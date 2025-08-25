#!/usr/bin/env bash
# Joins HR context (joiners/leavers/role changes) with UEBA hits for better triage.
# Inputs: hunt_results/summary.json and an HR CSV (user, manager, department, employmentStatus, lastRoleChangeDate)
set -euo pipefail

HR_CSV="${1:-hr_roster.csv}"
HUNT_SUMMARY="hunt_results/summary.json"
OUT="hunt_results/summary_with_hr.json"

if [[ ! -f "$HR_CSV" ]]; then echo "Missing $HR_CSV"; exit 1; fi
if [[ ! -f "$HUNT_SUMMARY" ]]; then echo "Missing $HUNT_SUMMARY"; exit 1; fi

python - "$HR_CSV" "$HUNT_SUMMARY" "$OUT" <<'PY'
import sys, json, csv
hr_file, summary_file, out_file = sys.argv[1:]
with open(summary_file) as f: summary = json.load(f)
hr={}
with open(hr_file, newline='', encoding='utf-8') as f:
    for r in csv.DictReader(f):
        hr[r.get('user','').lower()] = r
for item in summary.get('items', []):
    # naive extract username from filename or keep empty for analyst fill-in
    item['user'] = item.get('user') or ''
    profile = hr.get(item['user'].lower(), {})
    item['hr'] = {k: profile.get(k) for k in ('manager','department','employmentStatus','lastRoleChangeDate')}
with open(out_file,'w',encoding='utf-8') as f: json.dump(summary, f, indent=2)
print(f"Wrote {out_file}")
PY
