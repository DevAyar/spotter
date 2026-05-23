#!/usr/bin/env bash
# shared-memory-push: Phase 47c-1 SessionEnd orchestrator + /share-push backend.
# If share mode is enabled, ensure .claude/shared-memory/ is a working clone of
# the remote, pull --rebase, run the 47b producer, and push any new events.
# Fail-soft throughout — a failed push MUST NEVER block or delay session end; the
# next SessionEnd retries and catches up (incremental via the last-push marker).
# Pure git/bash, no model invocation.
#
# Usage:
#   shared-memory-push.sh            SessionEnd path — silent (stderr logs only).
#   shared-memory-push.sh --manual   /share-push — emits user-facing status.
#
# No-op (exit 0, no clone) when share-config.json is absent or enabled != true.

set -uo pipefail

# ---- constants ----
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
# shellcheck source=../lib/shared-memory-lib.sh
. "$SCRIPT_DIR/../lib/shared-memory-lib.sh"   # SM_ROOT, SM_TREE, SM_SHARE_CONFIG, SM_PY, sm_*
# shellcheck source=../lib/shared-memory-git.sh
. "$SCRIPT_DIR/../lib/shared-memory-git.sh"   # smg_ensure_clone, smg_pull_rebase, smg_push
PRODUCE="$SCRIPT_DIR/shared-memory-produce.sh"
LAST_PUSH="$SM_ROOT/.claude/.last-shared-push"
NOTICE="[shared-memory-push]"
MANUAL=0
[ "${1:-}" = "--manual" ] && MANUAL=1

# ---- helpers ----
log() { printf '%s %s\n' "$NOTICE" "$*" >&2; }
say() { [ "$MANUAL" -eq 1 ] && printf '%s\n' "$*"; return 0; }

# remote_url: print the configured remote when share is enabled; non-zero else.
remote_url() {
  [ -n "$SM_PY" ] || return 1
  "$SM_PY" - "$SM_SHARE_CONFIG" <<'PY'
import json, sys
try:
    c = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(1)
if c.get("enabled") is not True:
    sys.exit(1)
sys.stdout.write(c.get("remote_url") or "")
PY
}

# record_last_push: write the last-push marker (timestamp + tracked file count)
# and echo the count. Called only after a confirmed successful push.
record_last_push() {
  local count
  count="$(git -C "$SM_TREE" ls-files 2>/dev/null | wc -l | tr -d ' ')"
  "$SM_PY" - "$LAST_PUSH" "$(sm_now_iso)" "${count:-0}" <<'PY'
import json, sys
with open(sys.argv[1], "w", newline="\n") as f:
    json.dump({"last_push_at": sys.argv[2], "files_pushed": int(sys.argv[3])},
              f, indent=2, sort_keys=True)
    f.write("\n")
PY
  printf '%s' "${count:-0}"
}

# ---- main ----
main() {
  if ! sm_share_enabled; then
    say "Share mode is not enabled — nothing to push. Use /share-enable to opt in."
    return 0
  fi
  sm_have_python || { say "python not available — cannot push."; return 0; }
  command -v git >/dev/null 2>&1 || { say "git not available — cannot push."; return 0; }
  local url
  url="$(remote_url)" || { say "Share mode enabled but no remote_url — nothing to push."; return 0; }
  [ -n "$url" ] || { say "Share mode enabled but no remote_url — nothing to push."; return 0; }

  if ! smg_ensure_clone "$url" "$SM_TREE"; then
    log "clone unavailable — skipping this session"
    say "Remote unavailable ($url) — nothing pushed; will retry."
    return 0
  fi
  # Safety net: never run git ops if the clone is absent — they would fall
  # through to the parent repo. ensure_clone returning 0 should guarantee a .git.
  if [ ! -d "$SM_TREE/.git" ]; then
    log "shared-memory is not a working clone — aborting (no push)"
    say "Could not establish the shared-memory clone — nothing pushed."
    return 0
  fi
  smg_pull_rebase "$SM_TREE" || true
  bash "$PRODUCE" >/dev/null 2>&1 || true   # 47b producer writes into the clone

  # On-change gate: push only when a NON-version event changed. version.json is
  # current-state — the 47b producer rewrites it with a fresh event_timestamp on
  # every run — so version-only churn is not a real change. Discard that churn so
  # the working tree stays clean for the next pull --rebase.
  local changed
  changed="$(git -C "$SM_TREE" status --porcelain 2>/dev/null | grep -v '^.. version/' || true)"
  if [ -z "$changed" ]; then
    git -C "$SM_TREE" checkout -- . 2>/dev/null || true
    say "Nothing to push — shared memory unchanged since last push."
    return 0
  fi
  if smg_push "$SM_TREE" "shared-memory sync $(sm_now_iso)"; then
    local n; n="$(record_last_push)"
    say "Pushed: shared memory synced to $url ($n file(s) tracked)."
  else
    log "push failed (fail-soft) — next SessionEnd retries"
    say "Push failed (remote unreachable?) — will retry next session."
  fi
  return 0
}

main "$@"

# ---- cleanup ----
exit 0   # fail-soft: never propagate failure to the SessionEnd hook
