#!/usr/bin/env bash
# terraform-plan-scan.sh
# Run tfsec and checkov against a Terraform plan; emit SARIF/JSON for PR annotations.
# - Works locally or in CI
# - Accepts pre-generated plan file or will run `terraform init/plan/show` itself
# - Does not require secrets; exit code non-zero on findings (configurable)

set -Eeuo pipefail
IFS=$'\n\t'

usage() {
  cat <<EOF
Usage: $0 [--dir <terraform_dir>] [--plan <planfile>] [--out-dir <out>] [--fail-on HIGH|MEDIUM|LOW|NONE]
  --dir      Terraform working directory (default: .)
  --plan     Existing binary plan file to use (if omitted, will run plan)
  --out-dir  Output directory for reports (default: ./scan-reports)
  --fail-on  Minimum severity that causes non-zero exit (default: MEDIUM)
EOF
}

DIR="." PLAN="" OUT="./scan-reports" FAIL_ON="MEDIUM"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR="$2"; shift 2;;
    --plan) PLAN="$2"; shift 2;;
    --out-dir) OUT="$2"; shift 2;;
    --fail-on) FAIL_ON="$(tr '[:lower:]' '[:upper:]' <<<"$2")"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

mkdir -p "$OUT"
pushd "$DIR" >/dev/null

# Generate plan (if not supplied)
SHOW_JSON="$OUT/plan.json"
if [[ -z "$PLAN" ]]; then
  echo "[*] Running terraform init/plan/show..."
  terraform init -input=false -no-color >/dev/null
  PLAN="$OUT/tf.plan"
  terraform plan -input=false -out "$PLAN" -no-color
fi
terraform show -json "$PLAN" > "$SHOW_JSON"

# tfsec scan
echo "[*] Running tfsec..."
tfsec --format sarif --out "$OUT/tfsec.sarif" --tfvars-file terraform.tfvars --soft-fail=false || true
tfsec --format json  --out "$OUT/tfsec.json"  --tfvars-file terraform.tfvars --soft-fail=false || true

# checkov scan (on plan file for better accuracy)
echo "[*] Running checkov..."
checkov --framework terraform_plan -f "$SHOW_JSON" -o sarif > "$OUT/checkov.sarif" || true
checkov --framework terraform_plan -f "$SHOW_JSON" -o json  > "$OUT/checkov.json"  || true

popd >/dev/null

# Severity gate (parse both tools' JSON)
echo "[*] Evaluating severity gate ($FAIL_ON)..."
parse_sev() { jq -r '..|.severity? // empty' "$1" 2>/dev/null | tr '[:lower:]' '[:upper:]'; }
rank() { case "$1" in HIGH) echo 3;; MEDIUM) echo 2;; LOW) echo 1;; *) echo 0;; esac; }

threshold="$(rank "$FAIL_ON")"
fail=0
for f in "$OUT"/{tfsec.json,checkov.json}; do
  [[ -f "$f" ]] || continue
  while read -r sev; do
    [[ -z "$sev" ]] && continue
    [[ "$(rank "$sev")" -ge "$threshold" ]] && fail=1
  done < <(parse_sev "$f")
done

echo "[+] Reports saved to $OUT"
[[ $fail -eq 0 ]] || { echo "[!] Severity threshold exceeded"; exit 2; }
