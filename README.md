# claude-skeleton

> A battle-tested orchestration skeleton for Claude Code projects.

**Status: pre-alpha, in active development.** This README is a draft and will be updated once the project is installable.

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

## Status

- **Phase 4a:** project foundation. Directory layout, initial docs, version 0.1.0. ✓
- **Phase 4b:** populated `template/.claude/` with baseline agents, skills, scripts, commands, hooks. Reached 0.2.0. ✓
- **Phase 4b.5:** added `project-tuner-helper` — the customization side of the install flow. Reached 0.3.0. ✓
- **Phase 4b.6:** added the meta-management layer (`05_meta/` tier) — agents and skills that watch, modify, and audit the system itself. Reached 0.4.0. ✓
- **Phase 4c (next):** install / update mechanism (`scripts/install.sh`) + `integration-installer`.
- **Phase 4d-e:** validation, test projects.
- **Phase 5+:** iteration on real-world use.

Current version: **0.4.0**. The skeleton's content is functional; the install mechanics are what remain before target projects can pull it in.

## Documentation

- [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) — design principles.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — project layout and install flow.
- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) — install/update (stub).
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) — version history.

## License

MIT — see [LICENSE](LICENSE).

---

*Draft README. Update once the install mechanism lands.*
