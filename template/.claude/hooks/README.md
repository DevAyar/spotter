# Hooks

Baseline Claude Code hooks that ship with claude-skeleton. Four events are wired by default in `settings.json` — eight registrations across the seven hook scripts here plus one `.claude/scripts/` script wired as a hook:

- **PreCompact** → `precompact-backup.sh` — backs up STATUS.md, SESSION_LOG.md, and CLAUDE.md before auto-compaction.
- **PreToolUse** → `pretooluse-bash-safety.sh` + `pretooluse-powershell-safety.sh` — destructive-pattern gate on Bash / PowerShell tool calls. Fail-closed: a missing pattern lib or unparseable input denies rather than allows.
- **SessionStart** → three registrations:
  - `sessionstart-rules.sh` — four jobs in one hook: (1) re-injects durable rules from `compactPrompt`, (2) invokes `.claude/scripts/drift-check.sh` and folds any drift notice into the same `additionalContext` block, (3) invokes `.claude/scripts/task-watchdog.sh` to emit observations from the prior session's transcript, (4) invokes `.claude/scripts/goals-surface.sh --hook` (Phase 68) for at most one due-scheduled-goals line, 24h cooldown. Failures of the sub-steps are swallowed — the hook always emits cleanly and never blocks session start.
  - `.claude/scripts/plugin-quality-check.sh --hook` — code-quality-auditor's mechanical layer over installed plugin source; 24h cooldown.
  - `sessionstart-cost-summary.sh` — one ambient token-spend line from Phase 46 telemetry against `gate-config.json` thresholds, plus the cooldown-gated Phase 53 optimizer nudge.
- **SessionEnd** → two registrations:
  - `sessionend-observe.sh` — generates Phase 46 session telemetry (via `.claude/lib/generate-session-telemetry.sh`) and runs the shared-memory push when share mode is enabled. (Its session-boundary marker duty retired with `session-observer`, Phase 58.)
  - `sessionend-cost-proposals.sh` — folds staged retier/optimizer draft proposals into their ledgers at the session seam; increments the optimizer session counter.

(The skeleton's own dogfood install wires one additional SessionStart entry, the dogfood-only `cruft-check.sh` — not shipped to targets.)

## What does NOT ship: `PostToolUse` and `SubagentStop`

**Finding (Phase 2 of the parent project):** when the user's `~/.claude/settings.json` declares a hook block (e.g. `PostToolUse`), it **replaces** the project-level block wholesale. The two are not merged — they shadow.

This means a project that registers a `PostToolUse` hook expects it to fire, but if the user has *any* `PostToolUse` configuration at the user level, the project's hook is silently dead. Same for `SubagentStop` and any other event the user configures globally.

We don't ship those hooks because they would fail silently on common dev setups, and silent failure is the worst failure mode.

## Recommended pattern: **wrapper scripts**

If you want post-edit or post-tool behavior, wrap the action itself, not the event. Examples in the baseline:

- `scripts/commit.sh` — every commit goes through this, so post-commit context is reliably visible. No hook needed.
- `scripts/deploy.sh` — every deploy goes through this, so the `POST-DEPLOY SMOKE TEST REQUIRED` banner always fires. No hook needed.

The wrapper is the canonical entry point, so its output always shows. No precedence trap.

## Adding new hooks

Two steps:

1. Drop the script in `.claude/hooks/`. Make it executable (`chmod +x`).
2. Register it in `.claude/settings.json` under the matching event.

If you're adding `PostToolUse` or `SubagentStop`, **re-read the finding above** and consider the wrapper-script pattern first.

## Dependencies

- `sessionstart-rules.sh` requires `jq`. If jq is missing the hook no-ops; the session still starts cleanly.
- `precompact-backup.sh` requires nothing beyond standard POSIX tools.
- `pretooluse-bash-safety.sh` / `pretooluse-powershell-safety.sh` require `jq` and their destructive-pattern libs under `.claude/lib/` — anything missing fails CLOSED (deny), never open.
- `sessionstart-cost-summary.sh` / `sessionend-cost-proposals.sh` require a working `python` or `python3` (execution-validated probe, Phase 63); with neither present they exit 0 silently and the session is unaffected.
- `sessionend-observe.sh` needs standard POSIX tools plus `jq` for CC's stdin payload; its telemetry lib needs a working python (same Phase 63 probe) and fail-softs to a stub rollup otherwise.
