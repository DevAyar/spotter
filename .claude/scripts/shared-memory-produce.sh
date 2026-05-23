#!/usr/bin/env bash
# shared-memory-produce: Phase 47b producer orchestrator. Walks the four
# source-artifact classes (captures / observations / telemetry / version),
# redacts each, wraps it in the uniform envelope, and writes events into the
# LOCAL shared-memory tree (.claude/shared-memory/). No git, no push — that
# is Phase 47c. No-op unless share mode is enabled. Idempotent: re-runs add
# no duplicate events (append-only producers skip existing keys; version is
# overwritten current-state).

set -uo pipefail

# ---- constants ----
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
# shellcheck source=../lib/shared-memory-lib.sh
. "$SCRIPT_DIR/../lib/shared-memory-lib.sh"
REDACT_OBS="$SCRIPT_DIR/../lib/redact-observation.sh"
REDACT_CAP="$SCRIPT_DIR/../lib/redact-capture.sh"
CAPTURES_DIR="$SM_ROOT/.claude/captures"
OBS_DIR="$SM_ROOT/.claude/observations"

# ---- helpers ----
# walk_captures: terminal-state captures → captures/<uuid>/<date>/<stem>.json
# (the filename stem is the source_pattern_id / capture_id, the idem key).
walk_captures() {
  local f key env date
  date="$(sm_today_utc)"
  [ -d "$CAPTURES_DIR" ] || return 0
  for f in "$CAPTURES_DIR"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "README.md" ] && continue
    key="$(basename "$f" .md)"
    if env="$(bash "$REDACT_CAP" "$f" 2>/dev/null)"; then
      printf '%s\n' "$env" | sm_write_event captures "$key" "$date"
    fi
  done
}

# walk_observations: every non-telemetry observation through the existing
# redact-observation.sh gate → observations/<uuid>/<date>/<pattern_id>.json.
# local-only is refused (exit 2) and skipped; safe-to-share passes through;
# share-with-redaction is field-stripped.
walk_observations() {
  local f red env date pid first_seen pt
  date="$(sm_today_utc)"
  [ -d "$OBS_DIR" ] || return 0
  for f in "$OBS_DIR"/*.json; do
    [ -e "$f" ] || continue
    pt="$(sm_json_field "$f" pattern_type)"
    [ "$pt" = "token_telemetry" ] && continue
    if red="$(bash "$REDACT_OBS" "$f" 2>/dev/null)"; then
      pid="$(sm_json_field "$f" pattern_id)"
      [ -n "$pid" ] || continue
      first_seen="$(sm_json_field "$f" first_seen)"
      env="$(printf '%s' "$red" | sm_build_envelope observations "$first_seen")" || continue
      printf '%s\n' "$env" | sm_write_event observations "$pid" "$date"
    fi
  done
}

# walk_telemetry: the token_telemetry observation only (safe-to-share, so the
# gate passes it through) → telemetry/<uuid>/<date>/<session_id>.json. Raw
# telemetry/events/*.jsonl + sessions/*.md stay local (gitignored), never here.
walk_telemetry() {
  local f red env date sid first_seen
  date="$(sm_today_utc)"
  [ -d "$OBS_DIR" ] || return 0
  for f in "$OBS_DIR"/*.json; do
    [ -e "$f" ] || continue
    [ "$(sm_json_field "$f" pattern_type)" = "token_telemetry" ] || continue
    if red="$(bash "$REDACT_OBS" "$f" 2>/dev/null)"; then
      sid="$(sm_json_field "$f" target_resource)"
      sid="${sid#session:}"
      [ -n "$sid" ] || sid="$(basename "$f" .json)"
      first_seen="$(sm_json_field "$f" first_seen)"
      env="$(printf '%s' "$red" | sm_build_envelope telemetry "$first_seen")" || continue
      printf '%s\n' "$env" | sm_write_event telemetry "$sid" "$date"
    fi
  done
}

# walk_version: current marker state → version/<uuid>/version.json. Overwritten
# (current-state, NOT append-only) so it always reflects the install's now.
walk_version() {
  local payload env
  [ -f "$SM_MARKER" ] || return 0
  payload="$("$SM_PY" - "$SM_MARKER" <<'PY'
import json, sys
sys.stdout.reconfigure(newline="\n")
m = json.load(open(sys.argv[1], encoding="utf-8"))
out = {k: m.get(k) for k in ("version", "commit", "install_uuid", "install_label", "install_created")}
json.dump(out, sys.stdout)
PY
)" || return 0
  env="$(printf '%s' "$payload" | sm_build_envelope version "")" || return 0
  printf '%s\n' "$env" | sm_write_event version version "-"
}

# ---- main ----
main() {
  sm_share_enabled || return 0      # disabled / unconfigured → no tree, no events
  sm_have_python   || return 0
  walk_captures
  walk_observations
  walk_telemetry
  walk_version
}

main "$@"
rc=$?

# ---- cleanup ----
exit "$rc"
