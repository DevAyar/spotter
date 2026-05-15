# Hooks

Baseline Claude Code hooks that ship with claude-skeleton. Three events are wired up by default in `settings.json`:

- **SessionStart** → `sessionstart-rules.sh` — does two jobs in one hook: (1) re-injects durable rules from `compactPrompt`, and (2) invokes `.claude/scripts/drift-check.sh` and folds any drift notice into the same `additionalContext` block. Fires on every SessionStart event (no `matcher` restriction). Failure of drift-check (missing/malformed `.skeleton-version`, missing jq) is swallowed — the hook always emits cleanly and never blocks session start.
- **PreCompact** → `precompact-backup.sh` — backs up STATUS.md, SESSION_LOG.md, and CLAUDE.md before auto-compaction.
- **SessionEnd** → `sessionend-observe.sh` — records the session boundary for `session-observer` to scan back from at next session start.

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
- `sessionend-observe.sh` requires nothing beyond standard POSIX tools (uses `mkdir`, `printf`, `date`).
