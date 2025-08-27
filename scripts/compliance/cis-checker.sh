#!/usr/bin/env bash
# cis-checker.sh
# Minimal Linux CIS checks (extendable). Non-zero on failure.

set -Eeuo pipefail
fails=0
check(){ local name="$1"; shift; echo -n "[*] $name ... "; if eval "$@"; then echo OK; else echo FAIL; fails=$((fails+1)); fi; }

# Password policy (example)
check "PASS_MAX_DAYS <= 365" "awk '\$1==\"PASS_MAX_DAYS\"{exit !(\$2<=365)}' /etc/login.defs"

# Root PATH sanity (no . in PATH)
check "Root PATH sanitized" "sudo -n -u root env | grep -E '^PATH=' | grep -vq ':\.:|^\.:'"

# World-writable files without sticky bit
check "World-writable w/o sticky" "! find / -xdev -type d -perm -0002 ! -perm -1000 2>/dev/null | grep -q ."

echo "Failures: $fails"
exit $fails
