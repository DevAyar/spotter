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
#
# MATCHING CONTRACT (Phase 106; command word added Phase 108). Consumers
# apply this set TWICE: once to the raw command and once to a CANONICAL
# form. A match in EITHER form denies.
#
# The canonical form normalizes BOTH halves of an invocation:
#   FLAGS (Phase 106) — clusters split (-fr -> -f -r), long flags
#     expanded (--recursive -> -r, --force -> -f), backslash escapes
#     removed (\rm -> rm), delimiters spaced out (;rm -> ; rm).
#   COMMAND WORD (Phase 108) — a path token whose FINAL segment is a
#     destructive executable reduces to that segment (POSIX and Windows
#     separators, optional .exe); pass-through wrapper words (env,
#     command, exec, nohup, time, xargs, sudo, doas) are dropped so the
#     next word becomes the command word, repeatedly, so stacked
#     wrappers reduce; quoted command words are unquoted. Tokens
#     containing '=' are never reduced — an earlier draft erased a
#     device path in an of=... operand that way.
#
# OUT OF SCOPE, named rather than implied — this contract exists because
# Phase 106's did not say what it did not cover:
#   - aliases and shell functions defined elsewhere (the hook sees a
#     name, never a definition);
#   - arbitrary interpreters reading a program from stdin;
#   - obfuscated forms that assemble a command word at runtime through
#     variable expansion or string concatenation.
# These are boundaries of a shape heuristic, not oversights. The
# PreToolUse hooks are a floor, not a sandbox. That is why
# patterns below can assume one-flag-per-token shapes without dropping the
# literal spellings — the literals stay so retrospective consumers
# (plugin-quality-check.sh heuristic iii, which greps raw file text) keep
# matching exactly what they matched before. Canonicalization only ever
# ADDS coverage; it never replaces a rule.

readonly -a DESTRUCTIVE_BASH_PATTERNS=(
  '(^|[[:space:]])rm[[:space:]]+-rf([[:space:]]|$)'
  # Phase 106: canonical-form rm — any flag order, any spelling, once the
  # canonicalizer has split clusters and expanded long forms. Both orders.
  '(^|[[:space:]])rm([[:space:]]+-[A-Za-z])*[[:space:]]+-[rR]([[:space:]]+-[A-Za-z])*[[:space:]]+-f([[:space:]]|$)'
  '(^|[[:space:]])rm([[:space:]]+-[A-Za-z])*[[:space:]]+-f([[:space:]]+-[A-Za-z])*[[:space:]]+-[rR]([[:space:]]|$)'
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
  # Phase 106 coverage gaps (Phase 105 audit, Wave B SHOULD-FIX set):
  # pipe-to-shell with an intermediate word (| sudo bash, | env sh), and
  # eval of a fetch — the two commonest real cradle shapes.
  '(curl|wget)[[:space:]][^|]*\|[[:space:]]*([a-z][a-z0-9_-]*[[:space:]]+)*(bash|sh|zsh)([[:space:]]|$)'
  '(^|[[:space:]])eval[[:space:]]+.*(curl|wget)[[:space:]]'
  # NVMe and any digit-bearing device node — the pre-106 rules were
  # hardcoded to legacy /dev/sd[a-z] naming.
  '(^|[[:space:]])dd[[:space:]]+.*of=/dev/(nvme|sd|hd|vd|mmcblk|xvd)[a-z0-9]*'
  '(^|[[:space:]])mkfs(\.[a-z0-9]+)?[[:space:]]+.*/dev/[a-z]+[a-z0-9]*'
)
