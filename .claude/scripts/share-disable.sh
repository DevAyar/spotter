#!/usr/bin/env bash
# share-disable: turn OFF cross-project git memory for THIS install (Phase 47a).
# Flips .claude/share-config.json to enabled=false and stamps disabled_at,
# preserving remote_url + enabled_at as an audit trail. Data already on the
# remote is NOT touched (a --purge-remote flag is deferred to Phase 47c+).
set -uo pipefail

# ---- constants ----
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
SHARE_CONFIG="$ROOT/.claude/share-config.json"
PY=""

# ---- helpers ----
err() { printf '%s\n' "$*" >&2; }
die() { err "share-disable: error: $*"; exit 1; }

detect_python() {
  if command -v python  >/dev/null 2>&1; then PY="python"
  elif command -v python3 >/dev/null 2>&1; then PY="python3"
  else die "python (3) is required on PATH"; fi
}

# ---- main ----
detect_python

if [ ! -f "$SHARE_CONFIG" ]; then
  printf 'Share mode is not configured for this install — nothing to disable.\n'
  printf 'Use /share-enable <remote-url> to opt in.\n'
  exit 0
fi

TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
RESULT="$("$PY" -c "
import json, sys
path, ts = sys.argv[1], sys.argv[2]
with open(path) as f:
    c = json.load(f)
if c.get('enabled') is not True:
    sys.stdout.write('ALREADY_DISABLED')
    sys.exit(0)
c['enabled'] = False
c['disabled_at'] = ts
with open(path, 'w', newline='\n') as f:
    json.dump(c, f, indent=2, sort_keys=True)
    f.write('\n')
sys.stdout.write('DISABLED')
" "$SHARE_CONFIG" "$TS")" || die "failed to update $SHARE_CONFIG"
RESULT="${RESULT%$'\r'}"

if [ "$RESULT" = "ALREADY_DISABLED" ]; then
  printf 'Share mode is already disabled for this install — no change.\n'
  exit 0
fi

printf 'Disabled share mode for this install. No future pushes will occur.\n'
printf 'Data already on the remote is untouched.\n'
printf 'A --purge-remote flag is planned for a future phase (47c+).\n'
