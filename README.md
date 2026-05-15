# claude-skeleton

[![CI](https://github.com/DevAyar/claude-skeleton/actions/workflows/ci.yml/badge.svg)](https://github.com/DevAyar/claude-skeleton/actions/workflows/ci.yml)

> A battle-tested orchestration skeleton for Claude Code projects.

**Status:** v1.1.0 — the capture/reuse loop is live. Five components close autonomy Gap #2 (system-proposes-own-evolution). Used in production on Trainer-View (Flutter + Firebase) and Echoes-Of-Gill (Godot). See [`docs/ROADMAP.md`](docs/ROADMAP.md) for what's next.

## What it is

A standalone meta-system that lets you bootstrap Claude Code orchestration into any project. Install it once into a project, and that project inherits a working setup of agents, skills, scripts, commands, and hooks — already tuned, already documented, already non-destructive.

## The problem it solves

Every serious Claude Code project ends up reinventing the same scaffolding: a managing agent, a routing table, skill conventions, hooks for safety, scripts for mechanical work, docs that don't drift. Doing this from scratch each time is slow and error-prone. Doing it well requires patterns most teams discover only after months of friction.

`claude-skeleton` extracts those patterns into something importable.

## Concept

The project ships two things side-by-side:

- **`.claude/`** — what's used to develop the meta-system itself.
- **`template/`** — the skeleton that gets installed into target projects.

Target projects pull `template/` into their own `.claude/` (and docs, root config) via a non-destructive install: missing files are added, existing files are left alone. Versions are tracked per-project so updates are safe.

Influences: Jake Van Clief's MWP/ICM patterns (canonical sources, one-way dependencies, section-routing, scripts for mechanical work) and field-tested patterns from the Trainer-View project's Phases 1-3.

## Design principles

See [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) for the full design philosophy.

Quick summary:
- Manager + helper architecture (one agent runs the project, helpers handle specialized work).
- Tiered skills: T1 always-on, T2 escalation, T3 on-demand.
- Plugin evaluation discipline — every dependency passes an integration check before adoption.
- Non-destructive install — the target project's existing structure always wins.
- "Not every task is an AI task" — scripts for mechanical work.

## What ships at v1.1.0

- **Orchestration discipline** — directive layer in `template/CLAUDE_MANAGER.md.template` (strategic judgment patterns, dispatch mechanics, plugin marketplace composition, three-commit cadence, recursive ownership L0/L1/L2).
- **Capture/reuse loop (v1.1.0)** — five-component pipeline that turns recurring patterns into reusable artefacts, user-approval-gated at every stage:
  - `session-observer` — emits structured observations from `SESSION_LOG.md` at session end.
  - `workflow-suggester` — drafts capture markdown from observations into `.claude/captures/`.
  - `script-builder` — drafts bash scripts under `.claude/scripts/drafts/` from approved captures.
  - `drift-checker` — surfaces version drift between the installed skeleton and the latest released tag at session start (read-only, no network at session start; `update.sh --check-remote` refreshes the cache).
  - `task-watchdog` — retrospective scan of the prior session's tool-call transcript for long-running bash calls and recurring failures.
- **Baseline tooling** — 14 agents (9 baseline + 5 capture/reuse loop), 6 skills, 4 scripts (`commit.sh`, `deploy.sh`, `drift-check.sh`, `task-watchdog.sh`), 4 slash commands (`/commit`, `/audit`, `/deploy`, `/smoke-test`), 3 hooks (`SessionStart`, `PreCompact`, `SessionEnd`).
- **Install / update infrastructure** — `install.sh` (three modes), `update.sh` (six-way classification using per-file SHA-256 hashes with backfill for legacy markers, plus `--check-remote` for drift-cache refresh), atomic JSON `.skeleton-version` marker.
- **CI** — three-platform matrix (Ubuntu, Windows, macOS) running six install/update scenarios on every push and PR.

For phase-by-phase history see [`docs/CHANGELOG.md`](docs/CHANGELOG.md). For what's coming next — v1.1.x polish, v1.2+ `manager-optimizer`, v2.0 plugin recommendation system — see [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Documentation

- [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) — design principles.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — project layout and install flow.
- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) — install / update, including the per-file-hash mechanism.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — v1.1+ / v1.2+ / v2.0 sequencing.
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) — version history.

## License

MIT — see [LICENSE](LICENSE).
