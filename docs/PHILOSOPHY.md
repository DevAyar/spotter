# Philosophy

The design principles behind Spotter (engine codename `claude-skeleton`). These are the things that make the skeleton coherent rather than a pile of patterns.

## Origins: MWP / ICM

The structural backbone of this project comes from Jake Van Clief's research on Multi-Working-Process (MWP) and In-Context Memory (ICM) patterns ([arXiv:2603.16021](https://arxiv.org/abs/2603.16021)). The four ideas we lean on most:

### Canonical sources

Every fact has exactly one source of truth. If you need to know the current version, you read `VERSION`. If you need to know what's blocked, you read `STATUS.md`. There is no second place where the same fact lives — duplication is how documentation drifts.

Practical implication: when adding a fact to the skeleton, find its canonical home first. If none exists, decide where it should live before writing it down. Never paste the same fact in two files "for convenience."

### One-way dependencies

Files reference other files in a directed acyclic way. `STATUS.md` references `SESSION_LOG.md`; `SESSION_LOG.md` does not reference `STATUS.md`. Cycles in documentation create the same maintenance disasters as cycles in code: a change in one place silently invalidates another, and you only find out when something breaks.

### Section-routing

Work is routed to specialized handlers based on what kind of work it is. A doc-drift audit goes to the `audit-helper` agent; a session retro goes to `monitoring-helper`; mechanical renames go to a script. The routing is explicit (a routing table, not vibes), documented (in `ROUTING.md`), and audited regularly.

### Scripts for mechanical work

When a task has a deterministic transformation — rename across files, regenerate an index, validate a config — write a script. Don't ask an AI to do it. AIs are expensive and non-deterministic. Scripts are cheap and reproducible. The manager dispatches to a script and gets a single clean result back.

## Manager + helper architecture

One agent runs the project. Other agents are helpers it dispatches to.

- **The manager** (defined in `CLAUDE_MANAGER.md` for projects that need one) owns the conversation. It plans, decides scope, dispatches work, integrates results, and reports back. It is the only agent the user talks to.
- **Helpers** are specialists. They do one thing well — code review, security review, doc generation, refactoring, install. They have narrow scopes, focused tools, and shorter context windows. They return results to the manager, not to the user.

The separation matters because context bloat is the single biggest cost in long sessions. Helpers keep the manager's context clean.

## Tier system

Skills and agents are organized into three tiers:

- **T1 — always-on custom.** Things every session in this project needs: routing, status reporting, session logging. Loaded eagerly. Small in number — every T1 is a tax on every session.
- **T2 — escalation.** Things the manager invokes when the work warrants it: code review, security review, deep refactor. Loaded on-demand when a trigger fires.
- **T3 — on-demand.** Niche or experimental capabilities. Loaded only when the user explicitly asks. May or may not be installed in any given project.

The tier boundary is about session cost, not capability. A great skill that runs once a month belongs in T3, not T1.

## Plugin evaluation discipline

Before any third-party plugin, skill, or agent is added to the skeleton, it passes an integration check:

1. Does it have a clear, single responsibility?
2. Does it compose cleanly with the existing manager + helper architecture?
3. Does it follow the canonical-source and one-way-dep rules?
4. What is its tier (T1/T2/T3)?
5. What does it cost — in session tokens, in human attention, in failure modes?

Plugins that fail any of these don't get added. Loose plugin discipline is how Claude Code projects rot — a year of "this looks useful" leaves you with twenty half-integrated skills that conflict.

The pre-add 5-question check is enforced by review; the mechanical slices are automated since v1.1.4 (`plugin-quality-check.sh`) and v1.5 (the discovery checklist) — for the judgment slice, the rules above are the discipline. (The `integration-installer` agent shipped in Phase 4c handles install *mechanics*, not plugin-discipline pre-checks — different concern.)

## Non-destructive install

The install mechanism (Phase 4c) operates under one ironclad rule: **the target project's existing structure always wins.**

If a target project already has `.claude/skills/foo.md`, install does not touch it. If a target project already has its own `CLAUDE.md`, install does not overwrite it. The install adds what's missing and stops.

Three install modes formalize this:

- `--mode=fresh` — only runs if the target's `.claude/` is empty. Refuses with a clear error otherwise.
- `--mode=merge` (default) — adds missing files, leaves existing files alone. Reports what was added and what was skipped.
- `--mode=replace` — explicit `--force` + interactive confirmation required. The escape hatch.

This rule exists because the alternative — silent overwrites — destroys user work. One bad merge can erase weeks of customization. Loud refusal is always preferable to silent destruction.

## "Not every task is an AI task"

The skeleton ships scripts for the things that don't need an AI:

- Renaming a symbol across files → `sed` or a small script.
- Regenerating an index of skills → a script that scans the directory.
- Validating a config file → a JSON schema check.
- Computing a version diff → `git`.

AIs are general-purpose, expensive, and non-deterministic. Scripts are specific, cheap, and reproducible. Whenever the transformation is mechanical, the skeleton prefers the script. This is also how we keep the manager's context clean — the manager dispatches mechanical work to a script and gets a single result back, not a chain of intermediate reasoning.

## What the skeleton is not

A few non-goals, so the scope is clear:

- **Not a generic agent framework.** Claude Code only. The skeleton assumes you're using the official Claude Code CLI and its conventions.
- **Not a replacement for project-specific knowledge.** A target project still needs its own `CLAUDE.md`, its own routing, its own helpers. The skeleton gives you the chassis, not the cargo.
- **Not opinionated about your stack.** The skeleton works with Go, Python, TypeScript, anything. It manages the meta-layer (how Claude Code is organized in your project), not the code itself.

## A note on iteration

This document is a foundation, not a manifesto. The principles above earned their place in Trainer-View's Phases 1-3. New principles may earn their place in later phases. Old principles may turn out to be wrong. The philosophy iterates with the project.

What does not iterate is the *discipline*: every change to the skeleton's philosophy should pass the same scrutiny we ask of every plugin. Why this principle? What does it cost? What does it replace?
