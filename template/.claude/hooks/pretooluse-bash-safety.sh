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
readonly PS_LIB="${CLAUDE_PROJECT_DIR:-.}/.claude/lib/destructive-powershell-patterns.sh"

# Phase 106 (P5 — valid JSON always): the pre-flight deny payloads are
# emitted before jq is known to exist, so they are FIXED, path-free
# constants. Interpolating $LIB produced unparseable JSON on Windows
# paths (backslashes are invalid JSON escapes), which meant the deny
# could be dropped entirely — a fail-closed branch that failed open.
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
# Phase 106 (P3 — fail closed, ASSERTED): a present-but-empty or truncated
# lib left the array unset, and "${ARR[@]}" on an unset array expands to
# nothing even under set -u, so the match loop ran zero times and EVERY
# command was allowed. Verify the array is declared AND non-empty.
if ! declare -p DESTRUCTIVE_BASH_PATTERNS >/dev/null 2>&1 || [ "${#DESTRUCTIVE_BASH_PATTERNS[@]}" -eq 0 ]; then
  emit_preflight_deny "destructive-pattern lib present but empty or unreadable"
fi
# Cross-shell (P4): a Bash invocation can launch PowerShell, so the
# PowerShell set is loaded too and applied when the command does that.
PS_PATTERNS_OK=0
if [ -f "$PS_LIB" ]; then
  # shellcheck disable=SC1090,SC1091
  source "$PS_LIB"
  if declare -p DESTRUCTIVE_POWERSHELL_PATTERNS >/dev/null 2>&1 && [ "${#DESTRUCTIVE_POWERSHELL_PATTERNS[@]}" -gt 0 ]; then
    PS_PATTERNS_OK=1
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
  # Phase 106: a message body containing a command substitution is NOT
  # exempt — the shell expands $(...) / `...` before git ever sees it, so
  # `git commit -m "$(rm -rf /tmp/x)"` really does run the inner command.
  # Ambiguity resolves toward scanning (P2).
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
      # Phase 106 (P2 — when unsure, DO NOT blank). An opener counts only
      # when we are confident: the marker must END the line (the real
      # `cat > f <<EOF` shape), the line must carry no `#` before the
      # `<<` (a comment mentioning <<EOF is not an opener), and `<<<`
      # here-strings are excluded. Anything else is scanned, not skipped:
      # over-scanning risks a false positive, under-scanning permits the
      # operation. Pre-106 this blanked every following line on ANY
      # `<<IDENT` sighting, so a comment could hide `rm -rf /`.
      if [[ ! "$line" =~ \<\<\< ]] \
         && [[ "$line" =~ ^([^#]*)\<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]?[[:space:]]*$ ]]; then
        in_heredoc="${BASH_REMATCH[2]}"
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

# Phase 106 (P1 — canonicalize, don't enumerate). Normalize the command
# so single-character spelling variants collapse onto one shape:
#   \rm -> rm            (backslash escapes dropped)
#   ;rm / &&rm / (rm     (delimiters spaced out, so commands are anchored)
#   --recursive -> -r    (long flags expanded)
#   -fr -> -f -r         (single-dash clusters split, repeatedly)
# The canonical form is scanned IN ADDITION to the raw command, never
# instead of it: canonicalization is text rewriting on untrusted input,
# and every rewrite is a chance to erase something that mattered, so the
# raw pass stays as the floor. A match in either form denies.
canonicalize_bash() {
  local c="$1"
  # Phase 108 — COMMAND-WORD canonicalization. This runs FIRST, before
  # the Phase 106 escape-stripping: that step removes backslashes before
  # letters (to reduce an escaped command word), which would destroy a
  # Windows path separator before it could be recognised as one.
  # Phase 106 normalized flags but never the command word, so a
  # directory-prefixed invocation reached allow — found live by
  # Trainer-View's 106 propagation leg (c465884). Rewrite: any token
  # whose FINAL path segment is the real executable reduces to that
  # segment (POSIX and Windows separators, optional .exe suffix). This
  # also subsumes the escaped-command-word case.
  # Looped: sed's /g resumes AFTER a match, and the trailing space is part
  # of the match, so two adjacent path tokens cannot both reduce in one
  # pass. Three passes cover realistic command lines (the same repeat trick
  # the flag splitter below uses).
  # Reduce ONLY tokens whose final segment is an executable the pattern set
  # actually cares about. An earlier draft reduced every path-shaped token
  # and thereby erased an argument the rules match on (a device path in an
  # of=... operand) — the exact "canonicalization can erase what mattered"
  # risk the 106 contract names. Tokens containing '=' are never touched.
  local EXE='(rm|dd|mkfs[.a-z0-9]*|shred|srm|chmod|rsync|truncate|find|git|curl|wget|sh|bash|zsh|powershell|pwsh|cmd)'
  local p
  for p in 1 2 3; do
    c=$(printf '%s' "$c" | sed -E \
          -e "s@(^| )[^ =]*[/\\\\]${EXE}(\.exe)?( |\$)@\1\2\4@g" \
          -e "s@(^| )${EXE}\.exe( |\$)@\1\2\3@g")
  done
  c=$(printf '%s' "$c" | sed -E \
        -e 's/\\([A-Za-z])/\1/g' \
        -e 's/([;()&|{}<>])/ \1 /g' \
        -e 's/"/ " /g' \
        -e "s/'/ ' /g" \
        -e 's/--recursive/-r/g; s/--force/-f/g; s/--dir/-d/g')
  # Phase 108: quotes are spaced out above so an adjacent command word gets
  # anchored, then DROPPED here so a quoted command word is not severed
  # from its own flags in the canonical view. Whitespace collapses at the
  # end of the function.
  c=$(printf '%s' "$c" | sed -E -e 's/"//g' -e "s/'//g")
  # Second path-reduction pass: a QUOTED absolute path only becomes a
  # reducible token once the quotes are gone. The first pass still has to
  # run before the escape-strip above (which would eat a Windows
  # separator), so the reduction runs on both sides of that step.
  for p in 1 2 3; do
    c=$(printf '%s' "$c" | sed -E \
          -e "s@(^| )[^ =]*[/\\\\]${EXE}(\.exe)?( |\$)@\1\2\4@g" \
          -e "s@(^| )${EXE}\.exe( |\$)@\1\2\3@g")
  done
  # Wrapper words that pass a command through to the shell are dropped so
  # the next word becomes the command word; repeated so stacked wrappers
  # reduce. Quoted command words fall out of the quote-spacing above.
  local i
  for i in 1 2 3 4; do
    c=$(printf '%s' "$c" | sed -E \
          -e 's/(^| )(env|command|exec|nohup|time|xargs|sudo|doas)( +-[A-Za-z0-9]+)*( +[A-Za-z_][A-Za-z0-9_]*=[^ ]*)*( +)/\1/g')
  done
  for i in 1 2 3 4; do
    c=$(printf '%s' "$c" | sed -E 's/(^| )-([A-Za-z])([A-Za-z]+)/\1-\2 -\3/g')
  done
  printf '%s' "$c" | tr -s '[:space:]' ' '
}
CANONICAL_COMMAND=$(canonicalize_bash "$REDACTED_COMMAND")

for pattern in "${DESTRUCTIVE_BASH_PATTERNS[@]}"; do
  if [[ "$REDACTED_COMMAND" =~ $pattern ]] || [[ "$CANONICAL_COMMAND" =~ $pattern ]]; then
    emit_deny "$DENY_REASON"
  fi
done

# Cross-shell (P4): this Bash command launches PowerShell, so its payload
# is PowerShell — apply that pattern set too. Pre-106 each hook was blind
# to the other's shell, so `powershell.exe -c "Remove-Item -Recurse
# -Force C:\Windows"` walked straight through the Bash gate.
if [ "$PS_PATTERNS_OK" -eq 1 ] && [[ "$REDACTED_COMMAND" =~ (^|[[:space:]/\\])(powershell(\.exe)?|pwsh(\.exe)?)([[:space:]]|$) ]]; then
  PS_VIEW=$(printf '%s' "$REDACTED_COMMAND" | tr '[:upper:]' '[:lower:]' \
    | sed -E -e 's/"/ " /g' \
             -e "s/'/ ' /g" \
             -e 's/([;()&|{}])/ \1 /g' \
             -e 's/(^|[[:space:]])-r(e(c(u(r(s(e)?)?)?)?)?)?([[:space:]]|$)/\1-recurse\8/g' \
             -e 's/(^|[[:space:]])-f(o(r(c(e)?)?)?)?([[:space:]]|$)/\1-force\6/g')
  shopt -s nocasematch
  for pattern in "${DESTRUCTIVE_POWERSHELL_PATTERNS[@]}"; do
    if [[ "$REDACTED_COMMAND" =~ $pattern ]] || [[ "$PS_VIEW" =~ $pattern ]]; then
      shopt -u nocasematch
      emit_deny "$DENY_REASON"
    fi
  done
  shopt -u nocasematch
fi

emit_allow

# Unreachable — emit_* functions exit. Kept for the 5-section discipline.
exit 0
