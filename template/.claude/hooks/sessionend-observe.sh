#!/usr/bin/env bash
# SessionEnd hook for the v1.1+ capture/reuse loop.
#
# Fires at session end. Records the boundary so session-observer
# (dispatched by the manager at next session start) has a clean
# anchor to read against. Also a future entry point for
# task-watchdog (Phase 4) to do recurring-failure observation work
# at session shutdown rather than at next start.
#
# Plugin discipline rule 6: set -uo pipefail minimum. No outbound
# network. No state mutation outside the project directory.

set -uo pipefail

OBS_DIR="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR not set}/.claude/observations"
LOG_FILE="${CLAUDE_PROJECT_DIR}/docs/SESSION_LOG.md"
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

exit 0
