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
)
