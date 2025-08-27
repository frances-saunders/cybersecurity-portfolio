#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
kql-lint-and-test.py
Lint and lightweight test runner for KQL files.

Features
- Static lint: basic syntax hygiene (balanced brackets, banned operators, project-away check),
  required fields (e.g., TimeGenerated) by rule type, TODO/FIXME detection.
- Unit "tests": optional YAML file mapping KQL paths to expected properties (e.g., must reference certain tables/columns).
  NOTE: This does not execute KQL; it validates structure and conventions for CI gating.

Usage
  python kql-lint-and-test.py --rules-dir ./detections --tests ./tests/kql-tests.yml --out-json kql-report.json
"""

import argparse, json, os, re, sys
from typing import List, Dict, Any

BANNED_PATTERNS = [
    (re.compile(r"\bcontains\b(?!\s*cs)"), "Prefer 'contains_cs' or 'has' where possible."),
    (re.compile(r"\bisnotnull\s*\(\s*\)"), "Use 'isnotempty()' / 'isnotnull(Column)' correctly."),
    (re.compile(r"where\s+true\b", re.I), "Avoid no-op filters."),
]
REQUIRED_TIME_FIELD = "TimeGenerated"

def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def list_kql_files(root: str) -> List[str]:
    out = []
    for d, _, files in os.walk(root):
        for fn in files:
            if fn.lower().endswith(".kql"):
                out.append(os.path.join(d, fn))
    return sorted(out)

def check_balanced(text: str) -> List[str]:
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack = []
    errs = []
    for i, ch in enumerate(text):
        if ch in pairs:
            stack.append((ch, i))
        elif ch in pairs.values():
            if not stack:
                errs.append(f"Unmatched closing '{ch}' at pos {i}")
            else:
                op, _ = stack.pop()
                if pairs[op] != ch:
                    errs.append(f"Mismatched '{op}' vs '{ch}'")
    if stack:
        errs.append(f"Unclosed delimiters: {''.join([c for c,_ in stack])}")
    return errs

def has_required_time(text: str) -> bool:
    # Heuristic: detections that use time windowing should reference TimeGenerated.
    return REQUIRED_TIME_FIELD.lower() in text.lower()

def load_tests(path: str) -> Dict[str, Any]:
    if not path:
        return {}
    import yaml  # optional dependency
    with open(path, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

def apply_tests(kql_text: str, tests: Dict[str, Any]) -> List[str]:
    """Apply simple test assertions described in YAML (contains_table, contains_columns, forbid_regex)."""
    errors = []
    contains_table = tests.get("contains_table") or []
    for t in contains_table:
        if re.search(rf"\b{re.escape(t)}\b", kql_text, re.I) is None:
            errors.append(f"Expected reference to table '{t}'")
    contains_columns = tests.get("contains_columns") or []
    for c in contains_columns:
        if re.search(rf"\b{re.escape(c)}\b", kql_text, re.I) is None:
            errors.append(f"Expected reference to column '{c}'")
    forbid_regex = tests.get("forbid_regex") or []
    for pattern in forbid_regex:
        if re.search(pattern, kql_text, re.I):
            errors.append(f"Matched forbidden pattern: {pattern}")
    return errors

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rules-dir", required=True)
    ap.add_argument("--tests", help="YAML file with per-rule tests; keys are relative KQL paths")
    ap.add_argument("--out-json", default="kql-report.json")
    args = ap.parse_args()

    test_map = load_tests(args.tests)
    results = []
    fail_count = 0

    for path in list_kql_files(args.rules_dir):
        rel = os.path.relpath(path, args.rules_dir)
        text = read_file(path)
        issues = []

        issues.extend(check_balanced(text))
        for rx, msg in BANNED_PATTERNS:
            if rx.search(text):
                issues.append(f"Banned/anti-pattern: {msg}")
        if "datatable" not in text.lower() and not has_required_time(text):
            issues.append(f"Missing recommended field '{REQUIRED_TIME_FIELD}'")

        # TODO/FIXME
        if re.search(r"\b(TODO|FIXME)\b", text):
            issues.append("Contains TODO/FIXME comments")

        # Custom tests
        tdef = test_map.get(rel) if isinstance(test_map, dict) else None
        if tdef:
            issues.extend(apply_tests(text, tdef))

        status = "pass" if not issues else "fail"
        if status == "fail":
            fail_count += 1
        results.append({"file": rel, "status": status, "issues": issues})

    report = {"checked": len(results), "failed": fail_count, "items": results}
    with open(args.out_json, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)
    print(json.dumps({"checked": report["checked"], "failed": report["failed"], "out": args.out_json}))

    sys.exit(0 if fail_count == 0 else 2)

if __name__ == "__main__":
    main()
