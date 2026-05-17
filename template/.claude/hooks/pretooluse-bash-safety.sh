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

# Phase 30c: parser-aware FP exemption for git commit -m message bodies +
# bash heredoc payloads. Destructive-pattern strings inside those exempted
# regions no longer trigger deny. Patterns OUTSIDE exempted regions still
# match (counter-tests verify chained-command, post-heredoc deny preserved).
# Shell-portable: bash regex + sed only — no Python, no extra jq.

# redact_git_commit_messages: replace -m / --message argument bodies with a
# placeholder so destructive-pattern strings in commit messages don't trigger
# deny. Only fires when command begins with `git commit` — chained commands
# after the message ARE preserved (so `git commit -m "rm -rf foo"; rm -rf /`
# still denies on the second cmd). Handles 4 quote/equals forms; the `-mfoo`
# immediate form is intentionally NOT handled (uncommon; safer to under-exempt).
redact_git_commit_messages() {
  local cmd="$1"
  if [[ ! "$cmd" =~ ^[[:space:]]*git[[:space:]]+commit([[:space:]]|$) ]]; then
    printf '%s' "$cmd"
    return
  fi
  printf '%s' "$cmd" | sed -E \
    -e 's/(-m|--message)="[^"]*"/\1="X"/g' \
    -e "s/(-m|--message)='[^']*'/\1='X'/g" \
    -e 's/(-m|--message)[[:space:]]+"[^"]*"/\1 "X"/g' \
    -e "s/(-m|--message)[[:space:]]+'[^']*'/\1 'X'/g"
}

# strip_bash_heredocs: walk command line-by-line; when a heredoc opener
# (<<MARKER, <<-MARKER, <<'MARKER', <<"MARKER") is detected, replace
# subsequent lines with HEREDOC_BODY until matching terminator. Destructive
# patterns OUTSIDE heredoc bodies (before opener, after closer) remain
# intact. Detection regex requires identifier start (letter/underscore)
# — won't accidentally match `<<` in arithmetic / shift contexts.
strip_bash_heredocs() {
  local input="$1"
  local out="" line in_heredoc="" first=1
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$in_heredoc" ]; then
      local trimmed
      trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
      if [ "$trimmed" = "$in_heredoc" ] || [ "$line" = "$in_heredoc" ]; then
        [ $first -eq 0 ] && out+=$'\n'
        out+="$line"
        first=0
        in_heredoc=""
      else
        [ $first -eq 0 ] && out+=$'\n'
        out+="HEREDOC_BODY"
        first=0
      fi
    else
      [ $first -eq 0 ] && out+=$'\n'
      out+="$line"
      first=0
      if [[ "$line" =~ \<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]? ]]; then
        in_heredoc="${BASH_REMATCH[1]}"
      fi
    fi
  done <<< "$input"
  printf '%s' "$out"
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

# Redact exempted content (Phase 30c FP closure):
#   - git commit -m / --message argument bodies
#   - bash heredoc payloads
# Destructive patterns OUTSIDE redacted regions still match.
REDACTED_COMMAND=$(redact_git_commit_messages "$COMMAND")
REDACTED_COMMAND=$(strip_bash_heredocs "$REDACTED_COMMAND")

for pattern in "${DESTRUCTIVE_BASH_PATTERNS[@]}"; do
  if [[ "$REDACTED_COMMAND" =~ $pattern ]]; then
    emit_deny "$DENY_REASON"
  fi
done

emit_allow

# Unreachable — emit_* functions exit. Kept for the 5-section discipline.
exit 0
