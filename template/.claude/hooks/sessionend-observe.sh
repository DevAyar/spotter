#!/usr/bin/env bash
# SessionEnd hook for the v1.1+ capture/reuse loop.
#
# Fires at session end. Records the boundary so session-observer
# (dispatched by the manager at next session start) has a clean
# anchor to read against. Also invokes generate-session-telemetry.sh
# (Phase 46) to write per-event JSONL + per-session markdown rollup
# + token_telemetry observation in one shot from the current
# session's JSONL transcript.
#
# Plugin discipline rule 6: set -uo pipefail minimum. No outbound
# network. No state mutation outside the project directory.

set -uo pipefail

OBS_DIR="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}/.claude/observations"
LOG_FILE="${CLAUDE_PROJECT_DIR}/docs/SESSION_LOG.md"
TELEMETRY_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib/generate-session-telemetry.sh"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$OBS_DIR"

# Marker file — session-observer reads its mtime/contents to
# determine the window's end timestamp, then deletes it after the
# observation pass.
printf '%s\n' "$TS" > "$OBS_DIR/.session-ended"

# Append a session-boundary comment to SESSION_LOG.md if it exists
# so session-observer can scan backward from a clean delimiter.
# Silent no-op if the log isn't present (some projects skip it).
if [ -f "$LOG_FILE" ]; then
  printf '\n<!-- session-end: %s -->\n' "$TS" >> "$LOG_FILE"
fi

# Phase 46 telemetry: generate per-event JSONL + per-session markdown
# rollup + token-telemetry observation from the current session's JSONL
# transcript. Lib always exits 0; failures here MUST NOT block the hook.
if [ -x "$TELEMETRY_LIB" ] || [ -f "$TELEMETRY_LIB" ]; then
  bash "$TELEMETRY_LIB" 2>/dev/null || true
fi

exit 0
