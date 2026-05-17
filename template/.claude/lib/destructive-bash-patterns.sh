#!/usr/bin/env bash
# Shared library: destructive Bash command patterns.
#
# Single source of truth for the destructive-pattern regex set applied by
# both pretooluse-bash-safety.sh (PreToolUse hook — real-time blocking)
# and plugin-quality-check.sh heuristic iii (audits installed plugin
# scripts retrospectively). Lock the patterns; consumers source them.
#
# Source this file to populate DESTRUCTIVE_BASH_PATTERNS as a bash array.
# DO NOT execute directly — this is a library, not an entry point.
#
# Adding patterns: append to the array. Patterns must use POSIX ERE
# (extended regex) shape. Anchor with (^|[[:space:]]) ... ([[:space:]]|$)
# for portability — POSIX ERE doesn't standardize \b across implementations.

readonly -a DESTRUCTIVE_BASH_PATTERNS=(
  '(^|[[:space:]])rm[[:space:]]+-rf([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]]+--force([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+push[[:space:]]+-f([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin/'
  '(^|[[:space:]])chmod[[:space:]]+-R[[:space:]]+777([[:space:]]|$)'
  '(curl|wget)[[:space:]]+[^|]*\|[[:space:]]*(bash|sh)([[:space:]]|$)'
  # Phase 30b additions (audit H6 — pattern-completeness gaps surfaced by CC-side audit):
  '(^|[[:space:]])rsync[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*--delete[[:space:]]+/'
  '(^|[[:space:]])dd[[:space:]]+.*of=/dev/sd[a-z]+'
  '(^|[[:space:]])mkfs\.[a-z]+[[:space:]]+/dev/[a-z]+'
  '(^|[[:space:]])truncate[[:space:]]+-s[[:space:]]+0[[:space:]]+/etc/'
  '(^|[[:space:]])find[[:space:]]+/[[:space:]]+.*-delete'
  '(^|[[:space:]])(shred|srm)[[:space:]]+/'
)
