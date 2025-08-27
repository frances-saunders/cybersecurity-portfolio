-- linux-baseline-osquery.sql
-- Osquery queries aligned with common CIS Linux benchmarks for fleet visibility.
-- Use with a scheduler (e.g., osqueryd) and pack configuration. Each SELECT is safe read-only.

-- 1) Kernel and OS metadata
SELECT name AS kernel, version, path FROM kernel_info;
SELECT * FROM os_version;

-- 2) Logged-in users (interactive)
SELECT user, tty, host, time FROM logged_in WHERE type = 'user';

-- 3) World-writable directories without sticky bit (should be remediated)
SELECT path, mode FROM file
WHERE type='directory' AND (mode & 0002) != 0 AND (mode & 01000) = 0;

-- 4) Listening network ports (unexpected daemons)
SELECT pid, name, protocol, local_address, local_port, path
FROM listening_ports LEFT JOIN processes USING (pid);

-- 5) Password policy (min length / max days) via shadow & login.defs parse
SELECT * FROM users WHERE username NOT IN ('root') AND (shell LIKE '%/nologin' OR shell LIKE '%/false') IS NOT 1;
SELECT key, value FROM magic WHERE path='/etc/login.defs' AND key IN ('PASS_MAX_DAYS','PASS_MIN_DAYS','PASS_MIN_LEN');

-- 6) SUID/SGID binaries (audit unusual)
SELECT path, uid, gid, mode FROM suid_bin;

-- 7) Loaded kernel modules (denylist unexpected)
SELECT name, version, size, used_by FROM kernel_modules;

-- 8) File integrity baseline (optional; if hash_paths configured)
SELECT path, sha256 FROM hash WHERE path LIKE '/bin/%' OR path LIKE '/sbin/%';

-- 9) SSH daemon configuration checks
SELECT key, value FROM ssh_configs WHERE path='/etc/ssh/sshd_config' AND key IN ('PermitRootLogin','PasswordAuthentication','Protocol');

-- 10) Crontab & systemd timers (persistence)
SELECT * FROM crontab;
SELECT * FROM systemd_units WHERE sub_state='running' AND unit LIKE '%.timer';

-- 11) Mounted filesystems with noexec/nodev/nosuid flags
SELECT device, path, type, options FROM mounts WHERE path NOT LIKE '/proc%';

-- 12) Sysctl network hardening (rp_filter, redirects, source route)
SELECT * FROM sysctl WHERE key IN (
  'net.ipv4.conf.all.rp_filter',
  'net.ipv4.conf.all.accept_redirects',
  'net.ipv4.conf.all.accept_source_route',
  'net.ipv6.conf.all.accept_redirects'
);

-- 13) Suspicious new setuid files in last 24h (requires file_events)
-- SELECT path, action, atime, mtime FROM file_events WHERE target_path LIKE '%.(sh|bin|py)' AND (mode & 04000)!=0 AND time > (strftime('%s','now')-86400);

-- NOTE: For scheduled use, convert this .sql into a pack JSON mapping with intervals and constraints.
