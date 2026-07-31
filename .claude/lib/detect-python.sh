#!/usr/bin/env bash
# Shared library: the canonical Python interpreter probe (Phase 112).
#
# Single source of truth for interpreter selection across every shipped
# script and lib, on the destructive-patterns-lib precedent. Source this
# file; do NOT execute it.
#
# THE CONTRACT
#   Probes, in order:      python3, then python.
#   Accepts a candidate only if it EXECUTES successfully AND reports
#                          version >= 3.7.
#   Sets DETECTED_PYTHON:  the accepted command name, or the EMPTY STRING
#                          when none qualifies. Never a guess, never a
#                          name that has not been run.
#   Safe to source more than once; safe under `set -u`; writes nothing;
#   prints nothing (callers own their own messaging).
#
# WHY EXECUTION, NOT PRESENCE
#   `command -v python` is satisfied by the Windows Store execution-alias
#   stub, which exits nonzero on every real call — a presence-only probe
#   selects it and the caller then fails somewhere far away, silently
#   no-oping or reporting a WRONG remedy (the Phase 105 audit found a
#   share command advising `update.sh` for what was really a missing
#   interpreter). `python` being Python 2 fails the same way against
#   python3-only syntax. Order matters too: python3 is probed first
#   because on stock macOS and Debian/Ubuntu it is the only real one.
#
# BOOTSTRAP EXCEPTION — KEEP IN SYNC
#   `scripts/install.sh` runs BEFORE this file exists on a target, so it
#   carries an inline copy of this logic on purpose. That is the only
#   sanctioned duplicate. If the probe changes here, change it there too;
#   the inline site carries the matching note pointing back at this file.

# detect_python: populate DETECTED_PYTHON. Returns 0 when an interpreter
# was accepted, 1 when none was — callers decide what that means for them.
detect_python() {
  DETECTED_PYTHON=""
  local _cand
  for _cand in python3 python; do
    if command -v "$_cand" >/dev/null 2>&1 \
       && "$_cand" -c 'import sys; sys.exit(0 if sys.version_info >= (3,7) else 1)' >/dev/null 2>&1; then
      DETECTED_PYTHON="$_cand"
      return 0
    fi
  done
  return 1
}

# python_required_message: the one true sentence for the no-interpreter
# case, so every consumer says the same thing instead of inventing a
# remedy that does not match the actual cause.
python_required_message() {
  printf 'python 3.7+ required but not found on PATH (checked python3, python)'
}

# Populate at source time so callers can simply read DETECTED_PYTHON.
# `|| true` keeps a `set -e` caller alive: not finding an interpreter is
# a condition to report, not an error to abort on.
DETECTED_PYTHON=""
detect_python || true
