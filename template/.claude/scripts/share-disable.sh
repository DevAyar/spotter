#!/usr/bin/env bash
# share-disable: turn OFF cross-project git memory for THIS install (Phase 47a).
# Flips .claude/share-config.json to enabled=false and stamps disabled_at,
# preserving remote_url + enabled_at as an audit trail. Plain disable leaves
# remote data untouched. With --purge-remote (Phase 47c-2): first delete THIS
# install's own files from the remote (its <producer>/<uuid>/ subtrees +
# installs/<uuid>/), push the deletion, THEN disable — typed-confirmation gated,
# fail-soft (a failed deletion-push leaves the feature enabled for retry).
set -uo pipefail

# ---- constants ----
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
SHARE_CONFIG="$ROOT/.claude/share-config.json"
MARKER="$ROOT/.claude/.skeleton-version"
PY=""
PURGE=0
[ "${1:-}" = "--purge-remote" ] && PURGE=1
TMP_CLONE=""
export GIT_TERMINAL_PROMPT=0

# ---- helpers ----
err() { printf '%s\n' "$*" >&2; }
die() { err "share-disable: error: $*"; exit 1; }

detect_python() {
  if command -v python  >/dev/null 2>&1; then PY="python"
  elif command -v python3 >/dev/null 2>&1; then PY="python3"
  else die "python (3) is required on PATH"; fi
}

# json_field <file> <key> → top-level value on stdout (empty if missing/null).
json_field() {
  "$PY" -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(0)
v = d.get(sys.argv[2])
sys.stdout.write('' if v is None else str(v))
" "$1" "$2"
}

cleanup() { [ -n "$TMP_CLONE" ] && [ -d "$TMP_CLONE" ] && rm -rf "$TMP_CLONE"; }
trap cleanup EXIT INT TERM

# ---- main ----
detect_python

if [ ! -f "$SHARE_CONFIG" ]; then
  printf 'Share mode is not configured for this install — nothing to disable.\n'
  printf 'Use /share-enable <remote-url> to opt in.\n'
  exit 0
fi

PURGED=0
if [ "$PURGE" -eq 1 ]; then
  command -v git >/dev/null 2>&1 || die "git is required for --purge-remote"
  # shellcheck source=../lib/shared-memory-git.sh
  . "$ROOT/.claude/lib/shared-memory-git.sh"   # smg_ensure_clone, smg_push
  UUID="$(json_field "$MARKER" install_uuid)"
  printf '%s' "$UUID" | grep -Eq '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' \
    || die "marker has no well-formed install_uuid — cannot target a purge"
  REMOTE="$(json_field "$SHARE_CONFIG" remote_url)"
  [ -n "$REMOTE" ] || die "no remote_url recorded in share-config.json — nothing to purge"
  # Typed confirmation, EOF-fail-closed (modeled on /share-enable).
  printf "About to permanently remove THIS install's files from %s, then disable.\n" "$REMOTE"
  printf "Other installs' data is untouched. Type 'purge' to confirm: "
  read -r CONFIRM || CONFIRM=""
  CONFIRM="${CONFIRM%$'\r'}"
  [ "$CONFIRM" = "purge" ] || die "cancelled — nothing removed, share mode unchanged"
  TMP_CLONE="$(mktemp -d 2>/dev/null || mktemp -d -t skeleton-purge)"
  smg_ensure_clone "$REMOTE" "$TMP_CLONE" \
    || die "could not clone remote '$REMOTE' — nothing removed, share mode left ENABLED; retry when reachable"
  FOUND=0
  for p in "$TMP_CLONE"/*/"$UUID"; do
    [ -d "$p" ] || continue
    git -C "$TMP_CLONE" rm -r --quiet -- "${p#"$TMP_CLONE"/}" && FOUND=1
  done
  if [ "$FOUND" -eq 1 ]; then
    smg_push "$TMP_CLONE" "purge install $UUID" \
      || die "push of the deletion FAILED — share mode left ENABLED; retry when the remote is reachable"
    printf "Removed this install's files (uuid %s) from the remote.\n" "${UUID:0:8}"
    PURGED=1
  else
    printf 'This install has nothing on the remote — nothing to remove.\n'
  fi
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
if [ "$PURGED" -eq 1 ]; then
  printf "This install's files were removed from the remote (see above).\n"
else
  printf 'Data already on the remote is untouched (use --purge-remote to also remove it).\n'
fi
