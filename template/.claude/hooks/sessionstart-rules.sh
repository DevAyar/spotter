#!/usr/bin/env bash
# SessionStart hook: re-inject durable rules at session start.
# Reads `compactPrompt` from .claude/settings.json and emits it as
# additionalContext in the hook output JSON.
#
# Requires: jq. If jq is not installed, the hook no-ops silently — rules just
# won't be re-injected. The session still starts cleanly.
set -uo pipefail

SETTINGS_FILE=".claude/settings.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  # No jq → no clean way to read/write JSON. Skip rather than fail.
  exit 0
fi

PROMPT=$(jq -r '.compactPrompt // empty' "$SETTINGS_FILE")

if [ -z "$PROMPT" ]; then
  exit 0
fi

# Emit hook JSON. additionalContext is a Claude Code SessionStart field that
# gets injected into the conversation.
jq -n --arg p "$PROMPT" '{additionalContext: $p}'
