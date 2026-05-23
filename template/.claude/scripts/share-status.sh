#!/usr/bin/env bash
# share-status: report cross-project git memory state for THIS install (Phase 47a).
# Reads .claude/share-config.json (opt-in state) and .claude/.skeleton-version
# (install identity). Read-only — changes nothing.
set -uo pipefail

# ---- constants ----
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
SHARE_CONFIG="$ROOT/.claude/share-config.json"
MARKER="$ROOT/.claude/.skeleton-version"
LAST_PUSH="$ROOT/.claude/.last-shared-push"
PY=""

# ---- helpers ----
err() { printf '%s\n' "$*" >&2; }
die() { err "share-status: error: $*"; exit 1; }

detect_python() {
  if command -v python  >/dev/null 2>&1; then PY="python"
  elif command -v python3 >/dev/null 2>&1; then PY="python3"
  else die "python (3) is required on PATH"; fi
}

# ---- main ----
detect_python

if [ ! -f "$SHARE_CONFIG" ]; then
  printf 'Share mode: not configured. Use /share-enable <remote-url> to opt in.\n'
  exit 0
fi

"$PY" -c "
import json, sys
sys.stdout.reconfigure(newline='\n')
cfg_path, marker_path, last_push_path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(cfg_path) as f:
    c = json.load(f)
uuid = label = ''
try:
    with open(marker_path) as f:
        m = json.load(f)
    uuid = m.get('install_uuid') or ''
    label = m.get('install_label') or ''
except Exception:
    pass
enabled = c.get('enabled') is True
print('Share mode: ' + ('ENABLED' if enabled else 'disabled'))
print('  Remote URL:    ' + str(c.get('remote_url') or '(none)'))
print('  Enabled at:    ' + str(c.get('enabled_at') or '(unknown)'))
if not enabled:
    print('  Disabled at:   ' + str(c.get('disabled_at') or '(unknown)'))
print('  Install UUID:  ' + (uuid or '(missing)'))
print('  Install label: ' + (label or '(missing)'))
if enabled:
    try:
        with open(last_push_path) as f:
            lp = json.load(f)
        print('  Last push:     ' + str(lp.get('last_push_at') or '(never)'))
        fp = lp.get('files_pushed')
        print('  Files pushed:  ' + (str(fp) if fp is not None else '(unknown)'))
    except Exception:
        print('  Last push:     (never)')
        print('  Files pushed:  0')
" "$SHARE_CONFIG" "$MARKER" "$LAST_PUSH"
