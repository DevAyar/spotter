#!/usr/bin/env bash
# PreToolUse hook: blocks PowerShell invocations matching destructive patterns
# before execution. Mirrors pretooluse-bash-safety.sh shape with PowerShell-
# specific destructive patterns. PowerShell is a separate tool_name on Windows
# (distinct from Bash); without this hook, PowerShell invocations fall to the
# normal permission flow and prompt the user on every command — the friction
# Phase 21 closes alongside adding PowerShell to settings.json bare allow.
#
# Protocol: reads PreToolUse JSON on stdin (tool_name + tool_input.command);
# emits hookSpecificOutput JSON with permissionDecision = allow | deny.
# Exit 0 in both cases; deny is signaled via JSON, not exit code.
# Fail-closed: jq missing, JSON malformed, or required fields missing -> deny.
#
# Scope: PowerShell only. tool_name != "PowerShell" -> allow (no-op for
# Bash/Edit/Write/Read/etc which have their own hooks or permission paths).
#
# Patterns intercepted (case-insensitive — PowerShell is case-insensitive):
#   Remove-Item -Recurse -Force (and aliases ri/rm/del/erase, short flags -r/-f),
#   Format-Volume, Clear-Disk, Set-ExecutionPolicy Unrestricted/Bypass,
#   iwr|iex (and Invoke-WebRequest|Invoke-Expression) pipe-to-shell,
#   git push --force, git reset --hard origin/.
set -uo pipefail

readonly HOOK_NAME="pretooluse-powershell-safety"
readonly DENY_REASON="BLOCKED by ${HOOK_NAME} hook: command matches destructive pattern. If you genuinely need this, run it manually outside Claude Code."

# Destructive-shape patterns live in a shared library so that this hook
# and plugin-quality-check.sh (Phase 24 / heuristic iii) operate against
# the same set — single source of truth. Lib sources
# DESTRUCTIVE_POWERSHELL_PATTERNS. Patterns are case-insensitive — consumers
# (this hook, plugin-quality-check) enable `shopt -s nocasematch` around the
# match loop.
readonly LIB=".claude/lib/destructive-powershell-patterns.sh"
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
# a minimal deny payload — the hook fails closed, blocking PowerShell entirely
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

# Out-of-scope tool — allow. This hook only governs PowerShell.
if [ "$TOOL_NAME" != "PowerShell" ]; then
  emit_allow
fi

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)
if [ -z "$COMMAND" ]; then
  emit_deny "${DENY_REASON} (PowerShell invocation with empty command — fail-closed)"
fi

# PowerShell language is case-insensitive — enable nocasematch for pattern matching.
shopt -s nocasematch
for pattern in "${DESTRUCTIVE_POWERSHELL_PATTERNS[@]}"; do
  if [[ "$COMMAND" =~ $pattern ]]; then
    shopt -u nocasematch
    emit_deny "$DENY_REASON"
  fi
done
shopt -u nocasematch

emit_allow

# Unreachable — emit_* functions exit. Kept for the 5-section discipline.
exit 0
