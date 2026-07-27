# Spotter

[![CI](https://github.com/DevAyar/spotter/actions/workflows/ci.yml/badge.svg)](https://github.com/DevAyar/spotter/actions/workflows/ci.yml)

Spotter is per-project governance for Claude Code. It watches a project for
scope drift, scope decay, and doc rot, and turns what it observes into fixes
that wait at approval gates — nothing lands without your yes; a structural
immune system, if you want the one-line framing. Each install runs its own
copy and tunes it to its own project; the shared template here (engine
codename: `claude-skeleton`) is the seed, not the product. It assumes you
already know Claude Code — agents, hooks, skills, slash commands — and
composes with that ecosystem instead of replacing it.

## What it actually does

The loop, in the order it runs on a real project over months:

- **Observation producers watch the work.** A watchdog reads the prior
  session's transcript at session start and files what recurred — repeated
  failures, long-running calls ([`task-watchdog.sh`](template/.claude/scripts/task-watchdog.sh));
  a plugin auditor checks installed plugin source on a 24h cooldown; session-end
  telemetry records what each session actually consumed.
- **Observations become reviewable captures.** `workflow-suggester` drafts a
  one-page capture per recurring pattern; you approve, reject, or ignore by
  editing one frontmatter field ([`captures/README.md`](template/.claude/captures/README.md)).
- **Approved captures become artifacts.** This isn't aspirational — the loop
  has run end-to-end: one shipped capture consolidated duplicated audit scope,
  another landed a durable session rule that has already caught real mistakes.
- **The cost line tells the truth.** Session start prints what the last
  *sitting* cost — not the multi-day lineage cumulative — with the lineage as
  context, and thresholds compare against the sitting figure
  ([`sessionstart-cost-summary.sh`](template/.claude/hooks/sessionstart-cost-summary.sh)).
- **A per-project optimizer watches the manager itself.** It reads the
  project's own telemetry, observations, and git history and drafts refinements
  to the directive surfaces — drafts only; nothing it writes ever applies
  itself ([`manager-optimizer`](template/.claude/agents/05_meta/manager-optimizer.md)).
- **Goals become specs before they become work.** `/goals` runs repo-grounded
  research, asks at most one batched round of clarifying questions, and writes
  a spec you approve before anything builds — with an optional schedule that
  surfaces approved specs at session start when due
  ([`goals.md`](template/.claude/commands/goals.md)).

Everything above ships in the template and runs from SessionStart/SessionEnd
hooks on cooldowns — no cron, no background billing, nothing mid-flow.

## Install

Fresh project: `bash <skeleton-checkout>/scripts/install.sh` from the target
repo. Existing install: `bash <skeleton-checkout>/scripts/update.sh` — it
classifies every file (unchanged / template-updated / locally-modified / new /
orphan) and never overwrites your local modifications without a per-file
prompt. `install.sh` refuses to re-run on an installed target, so the two
paths can't be confused. First 15 minutes after install:
[`docs/GETTING-STARTED.md`](docs/GETTING-STARTED.md). Mechanics:
[`docs/INSTALLATION.md`](docs/INSTALLATION.md).

## What it is not

- **Not a productivity plugin.** Discipline is the point; speed is what you
  get back from not cleaning up messes later.
- **Not autonomous.** Thinking is free (read, plan, observe, draft); anything
  that changes the project waits for your approval. That line is load-bearing
  everywhere in the system.
- **Not multi-LLM.** Claude Code only, by design.
- **Not a plugin directory.** It composes with the ecosystem and vets what it
  pulls in — a quality filter, not a catalog.

## Where it is now

- **Version:** v1.1.5, with the running record in
  [docs/CHANGELOG.md](docs/CHANGELOG.md) `[Unreleased]` (this bullet
  deliberately names no commit, so it can't rot).
- **In production:** Trainer-View (Flutter + Firebase), Echoes-Of-Gill
  (Godot), plus the skeleton's own dogfood install.
- **Tier status:** the v1.1.4 substrate and the v1.2.0 per-project components
  (optimizer, artifact-fit analysis, /goals pipeline) are live; the onboarding
  tier is in progress.

## Read more

- [`docs/ROADMAP.md`](docs/ROADMAP.md) — where it's going, readiness-gated.
- [`docs/STORY.md`](docs/STORY.md) — why it's shaped this way.
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) — what's landed.
- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) — install + update mechanics.
- [`CLAUDE_MANAGER.md`](CLAUDE_MANAGER.md) — the directive surface installed
  projects inherit.

## License

BUSL-1.1 — free for individuals, commercial use licensed; see [LICENSE](LICENSE) + [COMMERCIAL.md](COMMERCIAL.md).

---

*Written for peers and informed devs familiar with Claude Code's plugin
marketplace, agents, hooks, and slash commands. Not a portfolio piece — useful
first, philosophy second.*
