#!/usr/bin/env bash
# SessionStart hook: re-inject durable rules at session start AND
# surface any signals produced by drift-check.sh / task-watchdog.sh /
# goals-surface.sh.
#
# Four pieces of work in one hook:
#   1. Read `compactPrompt` from .claude/settings.json (the durable
#      rules block re-injected after auto-compact / on session start).
#   2. Invoke .claude/scripts/drift-check.sh and capture its stdout.
#      Silent when there's no drift; emits a [skeleton-drift] notice
#      block otherwise.
#   3. Invoke .claude/scripts/task-watchdog.sh and capture its stdout.
#      Normally silent (writes observation files for the prior session's
#      long-running calls and recurring failures); stdout is used only
#      for [task-watchdog] warning lines when its internal scan fails.
#   4. Invoke .claude/scripts/goals-surface.sh --hook (Phase 68) and
#      capture its stdout — at most one [goals] line when approved
#      scheduled specs are due, cooldown-gated; silent otherwise.
#
# All pieces are folded into a single `additionalContext` string
# (blank-line separated). If all are empty, the hook exits 0 with no
# output (no-op). All scripts always exit 0 — their failure NEVER
# blocks session start.
#
# Requires: jq. If jq is not installed, the hook no-ops silently —
# rules won't be re-injected and drift won't be surfaced, but the
# session still starts cleanly. task-watchdog.sh doesn't require jq
# (uses python directly).
set -uo pipefail

SETTINGS_FILE=".claude/settings.json"
DRIFT_SCRIPT=".claude/scripts/drift-check.sh"
WATCHDOG_SCRIPT=".claude/scripts/task-watchdog.sh"
GOALS_SCRIPT=".claude/scripts/goals-surface.sh"

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

WATCHDOG_OUTPUT=""
if [ -f "$WATCHDOG_SCRIPT" ]; then
  WATCHDOG_OUTPUT=$(bash "$WATCHDOG_SCRIPT" 2>/dev/null || true)
fi

GOALS_OUTPUT=""
if [ -f "$GOALS_SCRIPT" ]; then
  GOALS_OUTPUT=$(bash "$GOALS_SCRIPT" --hook 2>/dev/null || true)
fi

if [ -z "$PROMPT" ] && [ -z "$DRIFT_OUTPUT" ] && [ -z "$WATCHDOG_OUTPUT" ] && [ -z "$GOALS_OUTPUT" ]; then
  exit 0
fi

# Combine in fixed order: rules → drift → watchdog → goals. Blank-line
# separators only between non-empty pieces.
COMBINED="$PROMPT"
append_block() {
  local block="$1"
  [ -z "$block" ] && return
  if [ -n "$COMBINED" ]; then
    COMBINED="$COMBINED"$'\n\n'"$block"
  else
    COMBINED="$block"
  fi
}
append_block "$DRIFT_OUTPUT"
append_block "$WATCHDOG_OUTPUT"
append_block "$GOALS_OUTPUT"

# Emit hook JSON. The canonical SessionStart schema wraps additionalContext
# inside hookSpecificOutput — Claude Code silently drops a bare top-level
# additionalContext field, so the wrapper is load-bearing.
jq -n --arg p "$COMBINED" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $p}}'
