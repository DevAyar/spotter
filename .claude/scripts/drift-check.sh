#!/usr/bin/env bash
# drift-check: read-only version-drift check.
# Compares .claude/.skeleton-version's `version` field against the
# cached `cached_skeleton_head` (last known remote release). Emits a
# notice on stdout if they differ; silent if matching. Always exits 0
# so the SessionStart hook chain never blocks. Invoked by
# sessionstart-rules.sh; also manually dispatchable by drift-checker.
# NEVER fetches the network, NEVER writes the marker. Cache refresh
# is `bash scripts/update.sh --check-remote`.

set -uo pipefail

# ---- constants ----
MARKER_PATH=".claude/.skeleton-version"
NOTICE_PREFIX="[skeleton-drift]"

# ---- project-root anchor (Phase 116) ----
# Paths below are project-relative and this is invoked by an absolute
# $CLAUDE_PROJECT_DIR path with no cwd set, so without the chdir they
# resolved against the caller's directory. `|| exit 0` because this runs
# on a hook chain that must never block. CLAUDE_MANAGER.md's "Hook path
# resolution discipline" mandates this anchor by name.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 0

# ---- helpers ----
emit() { printf '%s\n' "$*"; }

# read_field <jq-expression> — null/missing handled by `// empty`
read_field() {
  jq -r "$1 // empty" "$MARKER_PATH" 2>/dev/null
}

days_since() {
  local ts="$1"
  if [ -z "$ts" ]; then printf 'unknown'; return; fi
  local epoch_then epoch_now
  epoch_then=$(date -u -d "$ts" +%s 2>/dev/null) \
    || epoch_then=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$ts" +%s 2>/dev/null) \
    || { printf 'unknown'; return; }
  epoch_now=$(date -u +%s)
  printf '%d' $(( (epoch_now - epoch_then) / 86400 ))
}

# ---- main ----
if [ ! -f "$MARKER_PATH" ]; then
  emit "$NOTICE_PREFIX no .skeleton-version — install may need rerun"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  # No jq → no clean way to read JSON. Silent no-op (same fallback
  # pattern as sessionstart-rules.sh).
  exit 0
fi

# Smoke-test the JSON. If parse fails, degrade gracefully.
if ! jq -e . "$MARKER_PATH" >/dev/null 2>&1; then
  emit "$NOTICE_PREFIX marker unreadable — session continues, drift unknown"
  exit 0
fi

VERSION=$(read_field '.version')
CACHED=$(read_field '.cached_skeleton_head')
FETCHED_AT=$(read_field '.cached_skeleton_head_fetched_at')

if [ -z "$CACHED" ]; then
  emit "$NOTICE_PREFIX cache empty (no last-known remote version)."
  emit "  installed: ${VERSION:-unknown}"
  emit "  refresh:   bash scripts/update.sh --check-remote"
  exit 0
fi

if [ "$VERSION" = "$CACHED" ]; then
  exit 0
fi

DAYS=$(days_since "$FETCHED_AT")
emit "$NOTICE_PREFIX update available."
emit "  installed: ${VERSION:-unknown}"
emit "  available: $CACHED   (cache: ${DAYS} day(s) old)"
emit "  run:       bash scripts/update.sh"
exit 0
