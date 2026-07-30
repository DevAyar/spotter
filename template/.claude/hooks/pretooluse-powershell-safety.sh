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
# Path resolved via CLAUDE_PROJECT_DIR (set by Claude Code harness) for
# CWD-independence; falls back to relative path for manual invocation from
# project root. Phase 30b robustness fix — relative-only path fail-closed
# spuriously when harness CWD drifted from project root.
readonly LIB="${CLAUDE_PROJECT_DIR:-.}/.claude/lib/destructive-powershell-patterns.sh"
readonly BASH_LIB="${CLAUDE_PROJECT_DIR:-.}/.claude/lib/destructive-bash-patterns.sh"

# Phase 106 (P5 — valid JSON always): fixed, path-free constant. See the
# Bash hook for the reasoning — an interpolated Windows path produced
# unparseable JSON, so a fail-closed branch could fail open.
emit_preflight_deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s (%s — fail-closed; see .claude/lib/ and the hook log)"}}\n' \
    "$DENY_REASON" "$1"
  exit 0
}

if [ ! -f "$LIB" ]; then
  # Fail-closed: missing lib means we can't safely vet commands.
  emit_preflight_deny "destructive-pattern lib missing"
fi
# shellcheck disable=SC1090,SC1091
source "$LIB"
# Phase 106 (P3 — fail closed, ASSERTED): present-but-empty lib left the
# array unset and the match loop ran zero times, allowing everything.
if ! declare -p DESTRUCTIVE_POWERSHELL_PATTERNS >/dev/null 2>&1 || [ "${#DESTRUCTIVE_POWERSHELL_PATTERNS[@]}" -eq 0 ]; then
  emit_preflight_deny "destructive-pattern lib present but empty or unreadable"
fi
# Cross-shell (P4): PowerShell can launch bash/sh.
BASH_PATTERNS_OK=0
if [ -f "$BASH_LIB" ]; then
  # shellcheck disable=SC1090,SC1091
  source "$BASH_LIB"
  if declare -p DESTRUCTIVE_BASH_PATTERNS >/dev/null 2>&1 && [ "${#DESTRUCTIVE_BASH_PATTERNS[@]}" -gt 0 ]; then
    BASH_PATTERNS_OK=1
  fi
fi

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
# PowerShell here-string payloads. Destructive-pattern strings inside those
# exempted regions no longer trigger deny. Patterns OUTSIDE exempted regions
# still match (counter-tests verify chained-command, post-here-string deny).
# Shell-portable: bash regex + sed only — no Python, no extra jq.

# redact_git_commit_messages: replace -m / --message argument bodies with a
# placeholder so destructive-pattern strings in commit messages don't trigger
# deny. PowerShell `git commit -m "..."` syntax is identical to bash. Only
# fires when command begins with `git commit` — chained commands after the
# message ARE preserved (so `git commit -m "rm -rf foo"; Remove-Item -Recurse
# -Force C:\` still denies on the second cmd). Handles 4 quote/equals forms.
redact_git_commit_messages() {
  local cmd="$1"
  if [[ ! "$cmd" =~ ^[[:space:]]*git[[:space:]]+commit([[:space:]]|$) ]]; then
    printf '%s' "$cmd"
    return
  fi
  # Phase 106: a message body containing a command substitution is NOT
  # exempt — the shell expands it before git runs.
  if [[ "$cmd" == *'$('* ]] || [[ "$cmd" == *'`'* ]]; then
    printf '%s' "$cmd"
    return
  fi
  printf '%s' "$cmd" | sed -E \
    -e 's/(-m|--message)="[^"]*"/\1="X"/g' \
    -e "s/(-m|--message)='[^']*'/\1='X'/g" \
    -e 's/(-m|--message)[[:space:]]+"[^"]*"/\1 "X"/g' \
    -e "s/(-m|--message)[[:space:]]+'[^']*'/\1 'X'/g"
}

# strip_ps_herestrings: walk command line-by-line; when a PowerShell
# here-string opener (`@"` or `@'` at end of line, after some text) is
# detected, replace subsequent lines with HERESTRING_BODY until the matching
# closer (`"@` or `'@` at start of line, possibly with trailing text).
# Destructive patterns OUTSIDE here-string bodies remain intact.
strip_ps_herestrings() {
  local input="$1"
  local out="" line in_hs="" first=1
  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$in_hs" ]; then
      local trimmed
      trimmed=$(printf '%s' "$line" | sed 's/^[[:space:]]*//')
      if [ "$in_hs" = "double" ] && [[ "$trimmed" =~ ^\"@ ]]; then
        [ $first -eq 0 ] && out+=$'\n'
        out+="$line"; first=0; in_hs=""
      elif [ "$in_hs" = "single" ] && [[ "$trimmed" =~ ^\'@ ]]; then
        [ $first -eq 0 ] && out+=$'\n'
        out+="$line"; first=0; in_hs=""
      else
        [ $first -eq 0 ] && out+=$'\n'
        out+="HERESTRING_BODY"; first=0
      fi
    else
      [ $first -eq 0 ] && out+=$'\n'
      out+="$line"; first=0
      # Phase 106 (P2 — when unsure, DO NOT blank). A here-string opener
      # counts only when the line looks like a real assignment opener
      # (`$x = @"`), not merely any line that happens to END in @" — which
      # pre-106 meant `Write-Host "mail a@"` blanked every following line
      # and hid the destructive command underneath it.
      if [[ "$line" =~ (^|[[:space:]])\$?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*@\"[[:space:]]*$ ]]; then
        in_hs="double"
      elif [[ "$line" =~ (^|[[:space:]])\$?[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*@\'[[:space:]]*$ ]]; then
        in_hs="single"
      fi
    fi
  done <<< "$input"
  printf '%s' "$out"
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

# Redact exempted content (Phase 30c FP closure):
#   - git commit -m / --message argument bodies
#   - PowerShell here-string payloads (@"..."@ and @'...'@)
# Destructive patterns OUTSIDE redacted regions still match.
REDACTED_COMMAND=$(redact_git_commit_messages "$COMMAND")
REDACTED_COMMAND=$(strip_ps_herestrings "$REDACTED_COMMAND")

# Phase 106 (P1 — canonicalize, don't enumerate). PowerShell accepts ANY
# unambiguous parameter prefix, so `-rec -for` runs exactly as `-Recurse
# -Force` while literal-spelling matching sailed past it. The canonical
# view lowercases (PowerShell is case-insensitive) and expands every
# prefix of -recurse / -force to the full name; delimiters are spaced out
# so commands stay anchored. Scanned IN ADDITION to the raw command.
canonicalize_ps() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E \
    -e 's/([;()&|{}])/ \1 /g' \
    -e 's/"/ " /g' \
    -e "s/'/ ' /g" \
    -e 's/(^|[[:space:]])-r(e(c(u(r(s(e)?)?)?)?)?)?([[:space:]]|$)/\1-recurse\8/g' \
    -e 's/(^|[[:space:]])-f(o(r(c(e)?)?)?)?([[:space:]]|$)/\1-force\6/g' \
    | tr -s '[:space:]' ' '
}
CANONICAL_COMMAND=$(canonicalize_ps "$REDACTED_COMMAND")

# PowerShell language is case-insensitive — enable nocasematch for pattern matching.
shopt -s nocasematch
for pattern in "${DESTRUCTIVE_POWERSHELL_PATTERNS[@]}"; do
  if [[ "$REDACTED_COMMAND" =~ $pattern ]] || [[ "$CANONICAL_COMMAND" =~ $pattern ]]; then
    shopt -u nocasematch
    emit_deny "$DENY_REASON"
  fi
done
shopt -u nocasematch

# Cross-shell (P4): this PowerShell command launches bash/sh, so its
# payload is a shell command — apply the Bash pattern set too.
if [ "$BASH_PATTERNS_OK" -eq 1 ] && [[ "$REDACTED_COMMAND" =~ (^|[[:space:]/\\])(bash|sh|zsh)(\.exe)?[[:space:]] ]]; then
  BASH_VIEW=$(printf '%s' "$REDACTED_COMMAND" | sed -E \
        -e 's/\\([A-Za-z])/\1/g' \
        -e 's/([;()&|{}<>])/ \1 /g' \
        -e 's/"/ " /g' \
        -e "s/'/ ' /g" \
        -e 's/--recursive/-r/g; s/--force/-f/g')
  for _i in 1 2 3 4; do
    BASH_VIEW=$(printf '%s' "$BASH_VIEW" | sed -E 's/(^| )-([A-Za-z])([A-Za-z]+)/\1-\2 -\3/g')
  done
  BASH_VIEW=$(printf '%s' "$BASH_VIEW" | tr -s '[:space:]' ' ')
  for pattern in "${DESTRUCTIVE_BASH_PATTERNS[@]}"; do
    if [[ "$REDACTED_COMMAND" =~ $pattern ]] || [[ "$BASH_VIEW" =~ $pattern ]]; then
      emit_deny "$DENY_REASON"
    fi
  done
fi

emit_allow

# Unreachable — emit_* functions exit. Kept for the 5-section discipline.
exit 0
