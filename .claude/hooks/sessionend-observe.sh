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

# Phase 46b: read CC's SessionEnd JSON payload from stdin once and
# extract session_id + transcript_path. Export as namespaced env vars
# for generate-session-telemetry.sh to consume — bypasses the racy
# mtime heuristic in find_current_jsonl that picks the next session's
# empty JSONL placeholder when CC creates it before this hook returns.
# Vars stay empty if jq missing / payload absent / fields missing —
# lib falls through to existing find_current_jsonl heuristic.
CLAUDE_HOOK_SESSION_ID=""
CLAUDE_HOOK_TRANSCRIPT_PATH=""
INPUT=$(cat)
if [ -n "$INPUT" ] && command -v jq >/dev/null 2>&1; then
  CLAUDE_HOOK_SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || true)
  CLAUDE_HOOK_TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null || true)
fi
export CLAUDE_HOOK_SESSION_ID CLAUDE_HOOK_TRANSCRIPT_PATH

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

# Phase 47c-1: cross-project shared-memory push. Pure git/bash, fail-soft —
# a failed push MUST NOT block session end. No-op unless share mode is enabled.
SHARED_MEMORY_PUSH="${CLAUDE_PROJECT_DIR}/.claude/scripts/shared-memory-push.sh"
if [ -f "$SHARED_MEMORY_PUSH" ]; then
  bash "$SHARED_MEMORY_PUSH" 2>/dev/null || true
fi

exit 0
