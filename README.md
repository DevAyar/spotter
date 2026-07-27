# Spotter

[![CI](https://github.com/DevAyar/spotter/actions/workflows/ci.yml/badge.svg)](https://github.com/DevAyar/spotter/actions/workflows/ci.yml)

Spotter is a governance layer for Claude Code. Install it into a repo and it
watches for scope drift and doc rot while you work, then files what it finds
as drafts you review. Nothing changes your project until you say yes. If you
searched for Claude Code governance, AI coding guardrails, or a way to keep
scope drift from quietly eating a six-month project, this is that. It assumes
you already know Claude Code's agents, hooks, skills, and plugins, and it
composes with that ecosystem instead of replacing it.

Each install runs its own copy and tunes it to its own project. The template
in this repo (engine codename `claude-skeleton`) is the seed, not the product.

## What it does

- Reads the previous session's transcript at session start and files anything
  that kept failing or ran far too long
  ([task-watchdog.sh](template/.claude/scripts/task-watchdog.sh)).
- Turns recurring patterns into one-page captures. You approve, reject, or
  ignore by editing a single frontmatter field
  ([captures/README.md](template/.claude/captures/README.md)).
- Prints what the last sitting actually cost, at session start, with
  thresholds compared against the sitting figure rather than a scary
  multi-day cumulative
  ([sessionstart-cost-summary.sh](template/.claude/hooks/sessionstart-cost-summary.sh)).
- Vets Claude Code plugins before you install them. Discovery inventories the
  marketplaces into a manifest with evidence, and the matcher only marks an
  entry recommended or not_recommended when it can prove the reason. A
  rejection without a provable reason fails the schema
  ([plugin-discovery.sh](template/.claude/scripts/plugin-discovery.sh),
  [plugin-context-matcher.sh](template/.claude/scripts/plugin-context-matcher.sh),
  [recommendation.schema.md](template/.claude/recommendations/recommendation.schema.md)).
  Installing stays yours, through `/plugin`, by hand.
- Audits itself at session start on a 24h cooldown: doc rot, version drift,
  installed-plugin sanity
  ([plugin-quality-check.sh](template/.claude/scripts/plugin-quality-check.sh),
  [drift-check.sh](template/.claude/scripts/drift-check.sh)).

Everything runs from SessionStart and SessionEnd hooks. No cron, no daemons,
nothing fires mid-task.

## The system keeps receipts

Design habits the codebase holds itself to. All of them are checkable in the
record, which is the point.

- It watches itself. A per-project optimizer reads the install's own
  telemetry, observations, and git history, then drafts changes to its own
  directive files. Drafts only. Nothing it writes ever applies itself
  ([manager-optimizer.md](template/.claude/agents/05_meta/manager-optimizer.md)).
- Claims carry evidence. Audit findings cite file and line on both sides, and
  plugin verdicts quote the files they judged. The project's own dollar costs
  stay in [docs/CHANGELOG.md](docs/CHANGELOG.md), receipts included.
- Every change waits for approval. Captures, specs, optimizer proposals, and
  plugin verdicts all move through the same draft lifecycle, and the gate is
  the same gate everywhere.
- It has retired its own parts. When an audit showed one component duplicating
  another's scope, the scope was consolidated and the record kept (commit
  96c454e). When a real mistake slipped through, the fix landed as a durable
  session rule through the same capture loop that handles everything else
  (commit 1571cbb).

## Install

Fresh project: `bash <spotter-checkout>/scripts/install.sh` from the target
repo. Updating later: `bash <spotter-checkout>/scripts/update.sh`, which
classifies every file and never overwrites your local changes without a
per-file prompt.

First 15 minutes: [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md).
Mechanics: [docs/INSTALLATION.md](docs/INSTALLATION.md).

## What it is not

- A productivity plugin. The job is keeping a project coherent over months.
  Speed shows up as a side effect of fewer messes.
- Autonomous. Reading, planning, and drafting are free. Changes wait for you.
- Multi-LLM. Claude Code only, on purpose.
- A plugin directory. It vets what it pulls in and tells you why, both ways.

## License

BUSL-1.1. Free for individuals and personal use. Company, team, or commercial
use needs a license; see [LICENSE](LICENSE) and [COMMERCIAL.md](COMMERCIAL.md).
Converts to MIT in 2030.

## Read more

- [docs/ROADMAP.md](docs/ROADMAP.md) for where it's going, readiness-gated.
- [docs/STORY.md](docs/STORY.md) for why it's shaped this way.
- [docs/CHANGELOG.md](docs/CHANGELOG.md) for what's landed.
- [CLAUDE_MANAGER.md](CLAUDE_MANAGER.md) for the directive surface installed
  projects inherit.
