# claude-skeleton

Orchestration layer on the Claude Code ecosystem.

You are working with Project owner + peers — digestible, not portfolio/mass-market. Drop marketing register. Useful first, philosophy second.

## Communication style

Plain English with translation. Push back when wrong, don't sycophant. Prose default; bullets earn their place. ADHD scaffolding: short feedback loops, approval gates.

Defaults: plain English, jargon-with-translation, what-to-do-next first. Skip preambles and trailing summaries — the diff and the commit message are the record.

## Code style

Bash 5-section discipline (shebang+strict-mode / constants / helpers / main / cleanup), strict mode (`set -uo pipefail` minimum, `set -e` when halting on first error), path-shape guards before mutation, `bash-safety` skill integration for any recursive scan. Markdown-first for docs.

## Design system rules

<!-- Remove this section at install time if the project has no design system or UI concerns. project-tuner-helper handles the removal. -->

N/A — skeleton has no rendered UI.

## Manager + helper architecture

`CLAUDE_MANAGER.md` is the directive layer — read it for the helper roster, the dispatch rules and strategic judgment patterns (when to dispatch a helper vs read directly, when to escalate vs propose, when to question framing vs execute), the recursive ownership **L0 / L1 / L2** framing, the three-commit cadence, and the **plugin marketplace composition** (how this project draws from the broader Claude Code ecosystem). `ROUTING.md` is the task → handler table.

## Where things live

- `.claude/agents/` — subagents (helpers), organized by purpose (`01_research`, `02_audit`, `03_monitoring`, `04_planning`, `05_meta`).
- `.claude/skills/` — behavioral skills (rules the manager honors without a hook).
- `.claude/scripts/` — mechanical wrappers (`commit.sh`, `deploy.sh`, ...).
- `.claude/commands/` — slash commands.
- `.claude/hooks/` — Claude Code hooks (SessionStart, PreCompact).
- `docs/` — project records (STATUS.md, SESSION_LOG.md, ARCHITECTURE.md, ...).
