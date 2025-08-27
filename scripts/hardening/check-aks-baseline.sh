#!/usr/bin/env bash
# check-aks-baseline.sh
# Lightweight checks for AKS cluster hardening aligned to CIS/NIST controls.
# Requires: kubectl, jq, and access to the cluster context.

set -Eeuo pipefail
IFS=$'\n\t'

echo "== AKS Baseline Checks =="

fail=0
check() { local name="$1"; local cmd="$2"; echo -n "[*] $name ... "; if eval "$cmd"; then echo "OK"; else echo "FAIL"; fail=$((fail+1)); fi; }

# 1. Privileged containers denied
check "Privileged containers" \
  '! kubectl get pods --all-namespaces -o json | jq -e ".items[] |
     any(.spec.containers[]?; .securityContext.privileged==true)" >/dev/null'

# 2. Host namespaces restricted
check "Host namespaces restricted" \
  '! kubectl get pods --all-namespaces -o json | jq -e ".items[] |
     any(.spec; .hostNetwork==true or .hostPID==true or .hostIPC==true)" >/dev/null'

# 3. NetworkPolicy present in namespaces (deny-by-default preferred)
check "NetworkPolicies present" \
  'np_total=$(kubectl get networkpolicy -A --no-headers 2>/dev/null | wc -l); test $np_total -gt 0'

# 4. Approved image registries enforced (simple heuristic)
APPROVED="${APPROVED_REGISTRIES:-acr.azurecr.io|mcr.microsoft.com}"
check "Images from approved registries ($APPROVED)" \
  "! kubectl get pods -A -o json | jq -r '.items[].spec.containers[].image' |
     grep -Ev '($APPROVED)' | grep -q ."

# 5. Pod Security Standards labels (baseline/restricted) on namespaces
check "PSS labels on namespaces" \
  '! kubectl get ns -o json | jq -e ".items[] |
     select(.metadata.labels.\"pod-security.kubernetes.io/enforce\"==null)" >/dev/null'

echo "== Summary: $((fail==0?0:fail)) failing checks =="
exit $fail
