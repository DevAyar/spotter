#!/usr/bin/env bash
# SessionStart hook: re-inject durable rules at session start AND
# surface any signals produced by drift-check.sh / task-watchdog.sh /
# goals-surface.sh.
#
# Seven pieces of work in one hook:
#   1. Read `compactPrompt` from .claude/settings.json (the durable
#      rules block re-injected after auto-compact / on session start).
#   2. Invoke .claude/scripts/drift-check.sh and capture its stdout.
#      Silent when there's no drift; emits a [skeleton-drift] notice
#      block otherwise.
#   3. Invoke .claude/scripts/task-watchdog.sh and capture its stdout.
#      Normally silent (writes observation files for the prior session's
#      long-running calls and recurring failures); stdout is used only
#      for [task-watchdog] warning lines when its internal scan fails.
#   4. Invoke .claude/scripts/goals-surface.sh --hook (Phase 68) and
#      capture its stdout — at most one [goals] line when approved
#      scheduled specs are due, cooldown-gated; silent otherwise.
#   5. First-run welcome (Phase 73): if .claude/.first-run exists
#      (dropped by install.sh, gitignored), emit a one-time orientation
#      block and DELETE the flag — fires exactly once per install
#      lifetime; existing installs never have the flag. The one
#      sanctioned exception to the ambient-line budget.
#   6. Dispatch-class audit cadence (Phase 74): read gate-config's
#      `audits` registry + telemetry/audit-state.json; any enabled
#      audit past its sessions_between_dispatches -> ONE [infrastructure-audit]
#      line, 24h anti-repeat marker. The line surfaces; the manager +
#      human dispatch — nothing auto-runs from here.
#   7. Live status-strip refresh (Phase 97): rewrite
#      .claude/receipts/live.html from on-disk state. File write only,
#      ZERO output, fail-soft — the ambient-line budget is untouched.
#
# All pieces are folded into a single `additionalContext` string
# (blank-line separated). If all are empty, the hook exits 0 with no
# output (no-op). All scripts always exit 0 — their failure NEVER
# blocks session start.
#
# Requires: jq. If jq is not installed, the hook no-ops silently —
# rules won't be re-injected and drift won't be surfaced, but the
# session still starts cleanly. task-watchdog.sh doesn't require jq
# (uses python directly).
set -uo pipefail

# ---- project-root anchor (Phase 116) ----
# Paths below are project-relative and this is invoked by an absolute
# $CLAUDE_PROJECT_DIR path with no cwd set, so without the chdir they
# resolved against the caller's directory. `|| exit 0` because this runs
# on a hook chain that must never block. CLAUDE_MANAGER.md's "Hook path
# resolution discipline" mandates this anchor by name.
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
cd "$ROOT" || exit 0

SETTINGS_FILE=".claude/settings.json"
DRIFT_SCRIPT=".claude/scripts/drift-check.sh"
WATCHDOG_SCRIPT=".claude/scripts/task-watchdog.sh"
GOALS_SCRIPT=".claude/scripts/goals-surface.sh"

if [ ! -f "$SETTINGS_FILE" ]; then
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  # No jq → no clean way to read/write JSON. Skip rather than fail.
  exit 0
fi

PROMPT=$(jq -r '.compactPrompt // empty' "$SETTINGS_FILE" 2>/dev/null || true)

DRIFT_OUTPUT=""
if [ -f "$DRIFT_SCRIPT" ]; then
  # `|| true` so any unexpected drift-check failure (the script itself
  # should always exit 0, but belt-and-braces) never blocks the hook.
  DRIFT_OUTPUT=$(bash "$DRIFT_SCRIPT" 2>/dev/null || true)
fi

WATCHDOG_OUTPUT=""
if [ -f "$WATCHDOG_SCRIPT" ]; then
  WATCHDOG_OUTPUT=$(bash "$WATCHDOG_SCRIPT" 2>/dev/null || true)
fi

GOALS_OUTPUT=""
if [ -f "$GOALS_SCRIPT" ]; then
  GOALS_OUTPUT=$(bash "$GOALS_SCRIPT" --hook 2>/dev/null || true)
fi

# First-run welcome (Phase 73): consume the flag FIRST (deletion is the
# fire-once absolute), then emit. Flag absent -> zero output, zero cost.
WELCOME_OUTPUT=""
FIRST_RUN_FLAG=".claude/.first-run"
if [ -f "$FIRST_RUN_FLAG" ]; then
  rm -f "$FIRST_RUN_FLAG" 2>/dev/null || true
  WELCOME_OUTPUT="[claude-skeleton] First session in this project — welcome.
The skeleton added agents, skills, scripts, commands, and hooks under .claude/ —
all of it observes and drafts; nothing changes your project without your approval.
A quiet first session is correct: the system speaks when it has observed something.
First move worth trying:  /goals <a real small goal> - or ask for the plugin manifest (plugin-discovery drafts, you review, /plugin installs by hand)
The 15-minute tour: docs/GETTING-STARTED.md in the skeleton checkout
(https://github.com/DevAyar/spotter/blob/main/docs/GETTING-STARTED.md)"
fi

# Dispatch-class audit cadence (Phase 74). Inline bash+jq — this hook
# already requires jq. Sessions-only cadence (locked principle); the 24h
# marker is anti-repeat noise-gating, not the cadence.
AUDIT_OUTPUT=""
AUDIT_MARKER=".claude/.last-audit-nudge"
AUDIT_STATE=".claude/telemetry/audit-state.json"
GATE_CONF=".claude/gate-config.json"
if [ -f "$GATE_CONF" ] && [ -f "$AUDIT_STATE" ]; then
  audit_cooldown_ok=true
  if [ -f "$AUDIT_MARKER" ]; then
    last=$(cat "$AUDIT_MARKER" 2>/dev/null || echo 0)
    case "$last" in ''|*[!0-9]*) last=0 ;; esac
    now=$(date +%s)
    [ $((now - last)) -lt 86400 ] && audit_cooldown_ok=false
  fi
  if [ "$audit_cooldown_ok" = true ]; then
    DUE=$(jq -r --slurpfile st "$AUDIT_STATE" '
      [ (.audits // {}) | to_entries[]
        | select(.value.enabled == true)
        | . as $a
        | ($st[0][$a.key].sessions_since_dispatch // 0) as $n
        | select(($a.value.sessions_between_dispatches // 999999) <= $n)
        | "\($a.key) (last dispatched \($n) sessions ago)"
      ] | join(", ")
    ' "$GATE_CONF" 2>/dev/null || true)
    if [ -n "$DUE" ]; then
      AUDIT_OUTPUT="[infrastructure-audit] due: $DUE — the manager dispatches on your go"
      date +%s > "$AUDIT_MARKER" 2>/dev/null || true
    fi
  fi
fi

# Phase 97: refresh the live status strip (file write only, ZERO output,
# fail-soft - the ambient-line budget is untouched). One of the strip's
# two writers; the other is the ship-time render.
RECEIPT_RENDER=".claude/scripts/receipt-render.sh"
if [ -f "$RECEIPT_RENDER" ]; then
  bash "$RECEIPT_RENDER" --live >/dev/null 2>&1 || true
fi

if [ -z "$PROMPT" ] && [ -z "$DRIFT_OUTPUT" ] && [ -z "$WATCHDOG_OUTPUT" ] && [ -z "$GOALS_OUTPUT" ] && [ -z "$WELCOME_OUTPUT" ] && [ -z "$AUDIT_OUTPUT" ]; then
  exit 0
fi

# Combine in fixed order: welcome → rules → drift → watchdog → goals.
# Blank-line separators only between non-empty pieces.
COMBINED=""
append_block() {
  local block="$1"
  [ -z "$block" ] && return
  if [ -n "$COMBINED" ]; then
    COMBINED="$COMBINED"$'\n\n'"$block"
  else
    COMBINED="$block"
  fi
}
append_block "$WELCOME_OUTPUT"
append_block "$PROMPT"
append_block "$DRIFT_OUTPUT"
append_block "$WATCHDOG_OUTPUT"
append_block "$GOALS_OUTPUT"
append_block "$AUDIT_OUTPUT"

# Emit hook JSON. The canonical SessionStart schema wraps additionalContext
# inside hookSpecificOutput — Claude Code silently drops a bare top-level
# additionalContext field, so the wrapper is load-bearing.
jq -n --arg p "$COMBINED" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $p}}'
