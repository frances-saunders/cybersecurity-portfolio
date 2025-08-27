#!/usr/bin/env bash
# triage-collector-linux.sh
# Linux live response triage. No memory dump. Redacts common PII in text outputs.
# Produces a tar.gz with SHA256 manifest.

set -Eeuo pipefail
IFS=$'\n\t'

OUTDIR="${1:-./triage}"
TS="$(date +%Y%m%d%H%M%S)"
ROOT="$OUTDIR/linux-$TS"
mkdir -p "$ROOT"

save() { local f="$1"; shift; "$@" > "$ROOT/$f" 2>&1 || true; }

echo "[*] System info..."
save uname.txt uname -a
save os-release.txt cat /etc/os-release
save lsb-release.txt lsb_release -a

echo "[*] Processes & services..."
save ps-aux.txt ps auxww
save systemd-units.txt systemctl list-units --type=service --state=running
save crontab.txt crontab -l || true
save cron-system.txt cat /etc/crontab || true

echo "[*] Network..."
save ip-a.txt ip a
save route.txt ip route
save ss-anp.txt ss -anp
save lsof-nP.txt lsof -nP || true

echo "[*] Persistence & users..."
save sudoers.txt cat /etc/sudoers
save passwd.txt cat /etc/passwd
save shadow-perms.txt ls -l /etc/shadow
save authorized_keys.txt grep -R --line-number .ssh/authorized_keys $HOME /root 2>/dev/null || true

# Redact PII patterns in text outputs
echo "[*] Redacting common PII..."
for f in $(find "$ROOT" -type f -name "*.txt"); do
  sed -E -i \
    -e 's/[0-9]{3}-[0-9]{2}-[0-9]{4}/[REDACTED-SSN]/g' \
    -e 's/([Pp]assword\s*[:=]\s*)\S+/\1[REDACTED]/g' \
    -e 's/([Aa][Pp][Ii][_ -]?[Kk]ey\s*[:=]\s*)\S+/\1[REDACTED]/g' \
    "$f"
done

# Hash manifest
echo "[*] Hashing..."
MAN="$ROOT/manifest.json"
python3 - "$ROOT" "$MAN" <<'PY'
import sys, os, hashlib, json
root, man = sys.argv[1], sys.argv[2]
items = []
for d,_,files in os.walk(root):
  for fn in files:
    p = os.path.join(d,fn)
    h=hashlib.sha256()
    with open(p,'rb') as f:
      for chunk in iter(lambda:f.read(65536),b''): h.update(chunk)
    items.append({"path": os.path.relpath(p, root), "sha256": h.hexdigest()})
with open(man,'w') as f: json.dump(items,f,indent=2)
PY

TAR="$OUTDIR/triage-$TS.tar.gz"
tar -czf "$TAR" -C "$OUTDIR" "linux-$TS"
echo "[+] Wrote $TAR"
