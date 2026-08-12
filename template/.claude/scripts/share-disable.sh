#!/usr/bin/env bash
# share-disable: turn OFF cross-project git memory for THIS install (Phase 47a).
# Flips .claude/share-config.json to enabled=false and stamps disabled_at,
# preserving remote_url + enabled_at as an audit trail. Plain disable leaves
# remote data untouched. With --purge-remote (Phase 47c-2): delete THIS
# install's own files from the remote (its <producer>/<uuid>/ subtrees +
# installs/<uuid>/) and push the deletion — typed-confirmation gated.
# ORDER (Phase 122): confirm, then DISABLE, then purge. The two writes are
# individually atomic but the pair used to tear — with the purge first, an
# interrupt between them left the remote purged and share still enabled, so
# the next SessionEnd re-pushed exactly what was purged. Disable is the
# cheap, locally reversible half; the purge is a deletion on a shared
# remote. Committing the cheap half first means every interrupt point leaves
# share OFF and nothing re-shares. A failed purge therefore leaves the
# feature DISABLED with the purge outstanding and independently retryable —
# deliberately different from the pre-122 whole-operation retry.
set -uo pipefail

# ---- constants ----
ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
# shellcheck source=../lib/detect-python.sh
. "$ROOT/.claude/lib/detect-python.sh"
SHARE_CONFIG="$ROOT/.claude/share-config.json"
MARKER="$ROOT/.claude/.skeleton-version"
PY=""
PURGE=0
[ "${1:-}" = "--purge-remote" ] && PURGE=1
TMP_CLONE=""
DISABLE_RESULT=""   # set by disable_share(); pre-set so `set -u` cannot bite
export GIT_TERMINAL_PROMPT=0

# ---- helpers ----
err() { printf '%s\n' "$*" >&2; }
die() { err "share-disable: error: $*"; exit 1; }

detect_python() {
  # Phase 112: selection comes from the canonical probe (sourced above);
  # this wrapper keeps THIS script's failure semantics — die with a true
  # message. The audit's complaint was misdiagnosis, so the message names
  # the real cause rather than a remedy that does not match it.
  PY="$DETECTED_PYTHON"
  [ -n "$PY" ] || die "$(python_required_message)"
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

# disable_share -> prints DISABLED or ALREADY_DISABLED; dies on write failure.
# Phase 122: factored out of main so the ordering can put it BEFORE the purge.
# The write itself is unchanged -- same fields, same JSON shape -- only when
# it runs moved.
disable_share() {
  local ts result
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  result="$("$PY" -c "
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
" "$SHARE_CONFIG" "$ts")" || die "failed to update $SHARE_CONFIG"
  printf '%s' "${result%$'\r'}"
}

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
  # Read from stdin (keyboard, or the slash command's piped answer) or the
  # controlling terminal /dev/tty when stdin is redirected/disconnected — same
  # rationale as /share-enable.
  if [ -t 0 ] || [ -p /dev/stdin ]; then
    read -r CONFIRM || CONFIRM=""
  elif { exec 3</dev/tty; } 2>/dev/null; then
    read -r CONFIRM <&3 || CONFIRM=""
    exec 3<&-
  else
    read -r CONFIRM || CONFIRM=""
  fi
  CONFIRM="${CONFIRM%$'\r'}"
  [ "$CONFIRM" = "purge" ] || die "cancelled — nothing removed, share mode unchanged"

  # ---- Phase 122: DISABLE COMMITS FIRST, then purge. ----
  # These two writes are individually atomic but the PAIR used to tear: with
  # the purge first, an interrupt between them left the remote purged and
  # this config still enabled=true, so the next SessionEnd re-produced from
  # untouched LOCAL sources and re-pushed exactly what the user typed 'purge'
  # to delete. The halves are not equally reversible -- disabling is cheap
  # and locally undoable (/share-enable again), purging is a deletion on a
  # shared remote -- so the commit order is cheap-and-safe first, irreversible
  # second. Every interrupt point then leaves share off (sm_share_enabled
  # gates the push at shared-memory-push.sh:80), nothing re-shares, and the
  # only outstanding work is a purge that can simply be re-run.
  DISABLE_RESULT="$(disable_share)"

  TMP_CLONE="$(mktemp -d 2>/dev/null || mktemp -d -t skeleton-purge)"
  smg_ensure_clone "$REMOTE" "$TMP_CLONE" \
    || die "share mode is now DISABLED (nothing will be pushed), but the remote '$REMOTE' could not be reached — nothing was removed from it. Re-run /share-disable --purge-remote when it is reachable."
  FOUND=0
  for p in "$TMP_CLONE"/*/"$UUID"; do
    [ -d "$p" ] || continue
    git -C "$TMP_CLONE" rm -r --quiet -- "${p#"$TMP_CLONE"/}" && FOUND=1
  done
  if [ "$FOUND" -eq 1 ]; then
    smg_push "$TMP_CLONE" "purge install $UUID" \
      || die "share mode is now DISABLED (nothing will be pushed), but the push of the deletion FAILED — this install's files are still on the remote. Re-run /share-disable --purge-remote when it is reachable."
    printf "Removed this install's files (uuid %s) from the remote.\n" "${UUID:0:8}"
    PURGED=1
  else
    printf 'This install has nothing on the remote — nothing to remove.\n'
  fi
fi

# In the purge path the disable already ran (above, deliberately first). In
# the plain path it runs here, exactly as it always did.
if [ "$PURGE" -eq 0 ]; then
  DISABLE_RESULT="$(disable_share)"
fi

# Phase 122: the report is driven by WHAT HAPPENED, not by an early exit.
# Previously an ALREADY_DISABLED result printed "no change" and returned
# before saying anything about the purge -- harmless when the purge ran
# second and rarely, but the reorder makes the resume path (share already
# off, purge still outstanding) the normal way to finish an interrupted
# run, and that path must report the purge it just completed.
if [ "$DISABLE_RESULT" = "DISABLED" ]; then
  printf 'Disabled share mode for this install. No future pushes will occur.\n'
else
  printf 'Share mode was already disabled for this install.\n'
fi

if [ "$PURGED" -eq 1 ]; then
  printf "This install's files were removed from the remote (see above).\n"
elif [ "$PURGE" -eq 0 ]; then
  printf 'Data already on the remote is untouched (use --purge-remote to also remove it).\n'
fi
