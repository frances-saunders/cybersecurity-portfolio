#!/usr/bin/env bash
# cis-kernel-params.sh
# Validate critical sysctl params; optionally remediate with --apply.
# Exits non-zero on failure. Backup existing config before changes.

set -Eeuo pipefail
IFS=$'\n\t'

usage(){ cat <<EOF
Usage: $0 [--apply]
Checks:
  net.ipv4.conf.all.rp_filter = 1
  net.ipv4.conf.all.accept_redirects = 0
  net.ipv4.conf.all.accept_source_route = 0
  net.ipv6.conf.all.accept_redirects = 0
EOF
}
APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1

declare -A REQ=(
  [net.ipv4.conf.all.rp_filter]=1
  [net.ipv4.conf.all.accept_redirects]=0
  [net.ipv4.conf.all.accept_source_route]=0
  [net.ipv6.conf.all.accept_redirects]=0
)

fails=0

get_sysctl(){ sysctl -n "$1" 2>/dev/null || echo "NA"; }
set_sysctl(){
  local k="$1" v="$2"
  cp -n /etc/sysctl.conf /etc/sysctl.conf.bak || true
  if grep -q "^$k" /etc/sysctl.conf; then
    sed -i "s|^$k.*|$k = $v|" /etc/sysctl.conf
  else
    echo "$k = $v" >> /etc/sysctl.conf
  fi
  sysctl -w "$k=$v" >/dev/null
}

for key in "${!REQ[@]}"; do
  want="${REQ[$key]}"
  cur="$(get_sysctl "$key")"
  if [[ "$cur" != "$want" ]]; then
    echo "[FAIL] $key : current=$cur expected=$want"
    ((fails++))
    if [[ $APPLY -eq 1 ]]; then
      set_sysctl "$key" "$want"
      echo "  remediated -> $want"
      fails=$((fails-1))
    fi
  else
    echo "[PASS] $key = $want"
  fi
done

echo "Failures: $fails"
exit $fails
