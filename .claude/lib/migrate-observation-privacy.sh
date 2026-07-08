#!/usr/bin/env bash
# migrate-observation-privacy: idempotent backfill of the v1.1.5
# privacy_class field on observation files. For each .json under
# .claude/observations/ that lacks privacy_class, sets it to
# "local-only" (conservative default). Files already carrying the
# field are skipped — re-runs produce zero new diffs.
#
# Required by Phase 46 schema bump: all observations must carry
# privacy_class so redact-observation.sh can enforce cross-install
# policy. Producers (task-watchdog, cruft-checker,
# code-quality-auditor) emit the field directly on new observations;
# this script handles the migration of pre-v1.1.5 files.
#
# Read-only on files already migrated. Atomic rewrite (tmp + mv) on
# files that need the field added. No network. No writes outside
# .claude/observations/. Always exits 0 so it can be chained.

set -uo pipefail

# ---- constants ----
OBS_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/observations"
DEFAULT_CLASS="local-only"
NOTICE_PREFIX="[migrate-observation-privacy]"

# ---- helpers ----
need_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf '%s jq not found on PATH — skipping migration\n' "$NOTICE_PREFIX" >&2
    exit 0
  }
}

has_privacy_class() {
  jq -e 'has("privacy_class")' "$1" >/dev/null 2>&1
}

migrate_one() {
  local obs="$1"
  local tmp="${obs}.tmp.$$"
  # -a forces ASCII escapes (matches Python producers' json.dump default
  # ensure_ascii=True). tr -d '\r' strips Windows CRLFs (jq honors the
  # MSYS text-mode \n→\r\n translation by default on Git Bash).
  if ! jq -aS --indent 2 ". + {privacy_class: \"$DEFAULT_CLASS\"}" "$obs" 2>/dev/null \
        | tr -d '\r' > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  # Empty output = jq error masked by pipe. Guard against truncation.
  if [ ! -s "$tmp" ]; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$obs"
}

# ---- main ----
need_jq

if [ ! -d "$OBS_DIR" ]; then
  exit 0
fi

migrated=0
skipped=0
failed=0

shopt -s nullglob
for obs in "$OBS_DIR"/*.json; do
  if has_privacy_class "$obs"; then
    skipped=$((skipped + 1))
    continue
  fi
  if migrate_one "$obs"; then
    migrated=$((migrated + 1))
  else
    failed=$((failed + 1))
  fi
done
shopt -u nullglob

# ---- cleanup ----
printf '%s migrated=%d skipped=%d failed=%d\n' \
  "$NOTICE_PREFIX" "$migrated" "$skipped" "$failed"

exit 0
