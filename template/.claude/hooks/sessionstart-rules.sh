#!/usr/bin/env bash
# SessionStart hook: re-inject durable rules at session start AND surface
# any version-drift notice produced by drift-check.sh.
#
# Two pieces of work in one hook:
#   1. Read `compactPrompt` from .claude/settings.json (the durable rules
#      block re-injected after auto-compact / on session start).
#   2. Invoke .claude/scripts/drift-check.sh and capture its stdout. The
#      script is silent when there's no drift; emits a [skeleton-drift]
#      notice block otherwise. drift-check.sh always exits 0 — its
#      failure NEVER blocks session start.
#
# Both pieces are folded into a single `additionalContext` string. If
# both are empty, the hook exits 0 with no output (no-op).
#
# Requires: jq. If jq is not installed, the hook no-ops silently — rules
# won't be re-injected and drift won't be surfaced, but the session
# still starts cleanly.
set -uo pipefail

SETTINGS_FILE=".claude/settings.json"
DRIFT_SCRIPT=".claude/scripts/drift-check.sh"

if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  # No jq → no clean way to read/write JSON. Skip rather than fail.
  exit 0
fi

PROMPT=$(jq -r '.compactPrompt // empty' "$SETTINGS_FILE")

DRIFT_OUTPUT=""
if [ -f "$DRIFT_SCRIPT" ]; then
  # `|| true` so any unexpected drift-check failure (the script itself
  # should always exit 0, but belt-and-braces) never blocks the hook.
  DRIFT_OUTPUT=$(bash "$DRIFT_SCRIPT" 2>/dev/null || true)
fi

if [ -z "$PROMPT" ] && [ -z "$DRIFT_OUTPUT" ]; then
  exit 0
fi

# Combine: rules block first, then drift notice (if any). Blank-line
# separator only when both are present.
COMBINED="$PROMPT"
if [ -n "$DRIFT_OUTPUT" ]; then
  if [ -n "$COMBINED" ]; then
    COMBINED="$COMBINED"$'\n\n'"$DRIFT_OUTPUT"
  else
    COMBINED="$DRIFT_OUTPUT"
  fi
fi

# Emit hook JSON. additionalContext is a Claude Code SessionStart field that
# gets injected into the conversation.
jq -n --arg p "$COMBINED" '{additionalContext: $p}'
