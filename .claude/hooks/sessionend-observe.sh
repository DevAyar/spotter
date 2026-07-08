#!/usr/bin/env bash
# SessionEnd hook for the v1.1+ capture/reuse loop.
#
# Fires at session end. Invokes generate-session-telemetry.sh (Phase 46)
# to write per-event JSONL + per-session markdown rollup +
# token_telemetry observation from the current session's JSONL
# transcript, then the shared-memory push (Phase 47c-1) when share mode
# is enabled. (Until Phase 58 this hook also wrote session-observer's
# trigger marker + SESSION_LOG boundary comments — that producer is
# retired; the writes went with it.)
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
TELEMETRY_LIB="${CLAUDE_PROJECT_DIR}/.claude/lib/generate-session-telemetry.sh"

mkdir -p "$OBS_DIR"

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
