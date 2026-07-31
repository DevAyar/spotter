#!/usr/bin/env bash
# Shared library: destructive PowerShell command patterns.
#
# Single source of truth for the destructive-pattern regex set applied by
# both pretooluse-powershell-safety.sh (PreToolUse hook — real-time
# blocking) and plugin-quality-check.sh heuristic iii (audits installed
# plugin scripts retrospectively). Lock the patterns; consumers source.
#
# Source this file to populate DESTRUCTIVE_POWERSHELL_PATTERNS as a bash
# array. DO NOT execute directly — this is a library, not an entry point.
# Patterns are case-insensitive — consumers enable `shopt -s nocasematch`
# around the match loop.
#
# Adding patterns: append to the array. Patterns must use POSIX ERE
# (extended regex) shape. Anchor with (^|[[:space:]]) ... ([[:space:]]|$)
# for portability — POSIX ERE doesn't standardize \b across implementations.

# MATCHING CONTRACT (Phase 106; command word added Phase 108). Consumers
# apply this set TWICE: once to the raw command and once to a CANONICAL
# form. A match in EITHER form denies.
#
# The canonical form normalizes BOTH halves of an invocation:
#   PARAMETERS (Phase 106) — lowercased, and unambiguous parameter
#     prefixes expanded to full names (-rec -> -recurse, -for ->
#     -force). PowerShell accepts any unambiguous prefix, so
#     literal-spelling matching was bypassable by construction.
#   COMMAND WORD (Phase 108) — module- and snapin-qualified cmdlet names
#     reduce to the bare cmdlet (a qualifier, a backslash, then the
#     verb-noun); a path-form executable reduces to its final segment;
#     quoted and ampersand-invoked command words are unquoted.
#
# OUT OF SCOPE, named rather than implied:
#   - aliases and functions defined elsewhere in the session;
#   - arbitrary interpreters reading a program from stdin;
#   - obfuscated forms that assemble a command word at runtime through
#     variable expansion or string concatenation.
# These are boundaries of a shape heuristic, not oversights. The
# PreToolUse hooks are a floor, not a sandbox. Literal spellings stay in the set so retrospective
# consumers grepping raw file text keep matching what they matched before.

readonly -a DESTRUCTIVE_POWERSHELL_PATTERNS=(
  '(^|[[:space:]])(remove-item|ri|rm|del|erase)([[:space:]]).*(-r(ecurse)?)([[:space:]]|:).*(-f(orce)?)([[:space:]]|$)'
  '(^|[[:space:]])(remove-item|ri|rm|del|erase)([[:space:]]).*(-f(orce)?)([[:space:]]|:).*(-r(ecurse)?)([[:space:]]|$)'
  '(^|[[:space:]])(format-volume|clear-disk)([[:space:]]|$)'
  'set-executionpolicy[[:space:]]+(unrestricted|bypass)'
  '(invoke-webrequest|iwr|curl|wget)[[:space:]]+[^|]*\|[[:space:]]*(invoke-expression|iex)([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]]+--force([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]]+-f([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin/'
  # Phase 30b additions (audit H6 — pattern-completeness gaps surfaced by CC-side audit):
  '(^|[[:space:]])stop-computer[[:space:]]+.*-force'
  '(^|[[:space:]])restart-computer[[:space:]]+.*-force'
  '(^|[[:space:]])set-acl[[:space:]]+.*(c:\\windows|c:\\program)'
  '(^|[[:space:]])compress-archive[[:space:]]+.*-force.*-destinationpath[[:space:]]+.*(c:\\users|c:\\)'
  '(^|[[:space:]])wmic[[:space:]]+(diskdrive|os|process)[[:space:]]+.*(delete|format|terminate)'
  # Phase 106 coverage gaps (Phase 105 audit, Wave B): the delete routes
  # that bypass the cmdlet entirely, and the cradle/overwrite shapes the
  # literal iwr|iex rule missed.
  '\[system\.io\.(directory|file)\]::delete'
  '(^|[[:space:]])cmd([[:space:]]+/[a-z])*[[:space:]]+.*(^|[[:space:]])(rd|rmdir)[[:space:]]+.*/s'
  '(new-object[[:space:]]+([a-z.]*\.)?webclient)'
  '(^|[[:space:]])(set-content|out-file|add-content)[[:space:]]+.*(c:\\windows|system32|drivers\\etc)'
  '(^|[[:space:]])(remove-item|ri|del|erase)[[:space:]]+.*(\$env:|[a-z]:\\)(windows|program files|users)'
)
