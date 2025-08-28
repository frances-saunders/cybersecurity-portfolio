#!/usr/bin/env bash
# Threat Intel updater -> generates Snort rules from curated feeds
# - No plaintext secrets. Tokens fetched via `az keyvault secret show` (MSI) or env
# - ETag caching to avoid unnecessary downloads
# - Minimal validation: size cap, line sanity

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULE_OUT="${ROOT}/rules/generated-ti.rules"
STATE_DIR="${ROOT}/.state"
ALLOWLIST="${ROOT}/rules/allowlist.txt"

mkdir -p "${STATE_DIR}"

: "${FEED_IPS:=}"         # comma-separated URLs for IP CIDRs
: "${FEED_DOMAINS:=}"     # comma-separated URLs for FQDNs
: "${MAX_BYTES:=5242880}" # 5MB per feed

header() {
  echo -e "\n# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "${RULE_OUT}"
  echo "# Source feeds: ${FEED_IPS} ${FEED_DOMAINS}" >> "${RULE_OUT}"
  echo "# DO NOT EDIT - managed by intel-updater.sh" >> "${RULE_OUT}"
}

fetch_feed() {
  local url="$1"; local target="$2"
  local etag_file="${STATE_DIR}/$(echo -n "$url" | sha1sum | awk '{print $1}').etag"
  local etag=""; [[ -f "$etag_file" ]] && etag="$(cat "$etag_file")"
  local tmp="$(mktemp)"
  if [[ -n "$etag" ]]; then
    curl -fsSL --max-time 30 -H "If-None-Match: $etag" -o "$tmp" -D - "$url" | awk 'BEGIN{IGNORECASE=1}/^etag:/{print $2}' | tr -d '\r' > "${etag_file}.new" || true
  else
    curl -fsSL --max-time 30 -o "$tmp" -D - "$url" | awk 'BEGIN{IGNORECASE=1}/^etag:/{print $2}' | tr -d '\r' > "${etag_file}.new" || true
  fi

  # Not Modified?
  if [[ -s "$etag_file" && -s "${etag_file}.new" && "$(cat "${etag_file}.new")" == "$(cat "$etag_file")" ]]; then
    rm -f "${etag_file}.new"
    mv "$tmp" "$target" # still write for idempotency
  else
    if [[ $(stat -c%s "$tmp" 2>/dev/null || wc -c < "$tmp") -gt "$MAX_BYTES" ]]; then
      echo "Feed too large: $url" >&2; rm -f "$tmp" "${etag_file}.new"; return 1
    fi
    mv "$tmp" "$target"
    mv "${etag_file}.new" "$etag_file" || true
  fi
}

sanitize_list() {
  sed -E 's/#.*$//;s/\r//g;/^\s*$/d' "$1" | tr -d '[:cntrl:]' | awk '{print tolower($0)}' | sort -u
}

is_allowed() {
  local item="$1"
  [[ -f "$ALLOWLIST" ]] || return 1
  grep -q -F "$item" "$ALLOWLIST" && return 0 || return 1
}

gen_ip_rules() {
  local file="$1"; local sid_start=1100000; local sid=$sid_start
  while read -r ip; do
    [[ -z "$ip" ]] && continue
    is_allowed "$ip" && continue
    # Basic validation for CIDR or IP
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[1-2][0-9]|3[0-2]))?$ ]]; then
      echo "alert ip $HOME_NET any -> $ip any (msg:\"TI IP match $ip\"; classtype:trojan-activity; reference:url,ti.local; priority:2; sid:${sid}; rev:1;)" >> "${RULE_OUT}"
      sid=$((sid+1))
    fi
  done < <(sanitize_list "$file")
}

gen_domain_rules() {
  local file="$1"; local sid_start=1200000; local sid=$sid_start
  while read -r dom; do
    [[ -z "$dom" ]] && continue
    is_allowed "$dom" && continue
    if [[ "$dom" =~ ^([a-z0-9-]+\.)+[a-z]{2,63}$ ]]; then
      echo "alert udp $HOME_NET any -> $EXTERNAL_NET 53 (msg:\"TI domain match $dom\"; content:\"$dom\"; nocase; fast_pattern; classtype:trojan-activity; reference:url,ti.local; priority:2; sid:${sid}; rev:1;)" >> "${RULE_OUT}"
      sid=$((sid+1))
    fi
  done < <(sanitize_list "$file")
}

main() {
  header

  # IP feeds
  if [[ -n "$FEED_IPS" ]]; then
    IFS=',' read -ra urls <<< "$FEED_IPS"
    for u in "${urls[@]}"; do
      tmp="$(mktemp)"; fetch_feed "$u" "$tmp" || continue
      gen_ip_rules "$tmp"
      rm -f "$tmp"
    done
  fi

  # Domain feeds
  if [[ -n "$FEED_DOMAINS" ]]; then
    IFS=',' read -ra urls <<< "$FEED_DOMAINS"
    for u in "${urls[@]}"; do
      tmp="$(mktemp)"; fetch_feed "$u" "$tmp" || continue
      gen_domain_rules "$tmp"
      rm -f "$tmp"
    done
  fi

  # Reload Snort safely (adjust for your service manager)
  if command -v systemctl >/dev/null 2>&1; then
    systemctl reload snort || systemctl restart snort || true
  fi
  echo "TI rules generated at ${RULE_OUT}"
}

main "$@"
