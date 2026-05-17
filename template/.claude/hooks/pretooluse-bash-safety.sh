#!/usr/bin/env bash
# PreToolUse hook: blocks Bash invocations matching destructive patterns
# before execution. Replaces fragile string-pattern denies in settings.json
# (Phase 11/14 verified those don't reliably fire). Per Anthropic docs:
# "Bash permission patterns that try to constrain command arguments are fragile."
#
# Protocol: reads PreToolUse JSON on stdin (tool_name + tool_input.command);
# emits hookSpecificOutput JSON with permissionDecision = allow | deny.
# Exit 0 in both cases; deny is signaled via JSON, not exit code.
# Fail-closed: jq missing, JSON malformed, or required fields missing -> deny.
#
# Scope: Bash only. tool_name != "Bash" -> allow (no-op for Edit/Write/Read/etc).
#
# Patterns intercepted (10 destructive shapes covered by 6 regexes):
#   rm -rf, git push --force (long+short), git reset --hard origin/,
#   chmod -R 777, and (curl|wget) ... | (bash|sh) pipe-to-shell.
# Pipe-to-shell catches Phase 11's 4 dropped deny rules that were silent
# no-ops because '|' is a subcommand separator in CC's permissions schema.
set -uo pipefail

readonly HOOK_NAME="pretooluse-bash-safety"
readonly DENY_REASON="BLOCKED by ${HOOK_NAME} hook: command matches destructive pattern. If you genuinely need this, run it manually outside Claude Code."

# Destructive-shape patterns live in a shared library so that this hook
# and plugin-quality-check.sh (Phase 24 / heuristic iii) operate against
# the same set — single source of truth. Lib sources DESTRUCTIVE_BASH_PATTERNS.
# Path resolved via CLAUDE_PROJECT_DIR (set by Claude Code harness) for
# CWD-independence; falls back to relative path for manual invocation from
# project root. Phase 30b robustness fix — relative-only path fail-closed
# spuriously when harness CWD drifted from project root.
readonly LIB="${CLAUDE_PROJECT_DIR:-.}/.claude/lib/destructive-bash-patterns.sh"
if [ ! -f "$LIB" ]; then
  # Fail-closed: missing lib means we can't safely vet commands.
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s (destructive-pattern lib missing at %s — fail-closed)"}}\n' \
    "$DENY_REASON" "$LIB"
  exit 0
fi
# shellcheck disable=SC1090,SC1091
source "$LIB"

emit_allow() {
  jq -cn '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow"}}'
  exit 0
}

emit_deny() {
  local reason="$1"
  jq -cn --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}

# jq is required to safely build the response JSON. If missing, hand-build
# a minimal deny payload — the hook fails closed, blocking Bash entirely
# until jq is installed. Surfaces the misconfiguration loudly in the reason.
if ! command -v jq >/dev/null 2>&1; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s (jq missing — fail-closed)"}}\n' \
    "$DENY_REASON"
  exit 0
fi

INPUT=$(cat)
if [ -z "$INPUT" ]; then
  emit_deny "${DENY_REASON} (empty input — fail-closed)"
fi

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || true)
if [ -z "$TOOL_NAME" ]; then
  emit_deny "${DENY_REASON} (unparseable input — fail-closed)"
fi

# Out-of-scope tool — allow. This hook only governs Bash.
if [ "$TOOL_NAME" != "Bash" ]; then
  emit_allow
fi

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
if [ -z "$COMMAND" ]; then
  emit_deny "${DENY_REASON} (Bash invocation with empty command — fail-closed)"
fi

for pattern in "${DESTRUCTIVE_BASH_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    emit_deny "$DENY_REASON"
  fi
done

emit_allow

# Unreachable — emit_* functions exit. Kept for the 5-section discipline.
exit 0
