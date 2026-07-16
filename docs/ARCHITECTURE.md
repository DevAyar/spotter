# Architecture

The structure of the claude-skeleton project itself, how its pieces fit together, and how it gets installed into target projects.

## The two-`.claude/` distinction

This project has two `.claude/` directories. They serve different purposes and must never be confused.

### `./.claude/` — development working directory

Used by Claude Code sessions working on the meta-system itself. This is what the manager session at the root of `claude-skeleton/` reads when it runs. It contains the agents, skills, scripts, and settings the *meta-system's own development* uses.

Layout:

```
.claude/
├── agents/        # Agents for working on the skeleton itself
├── skills/        # Skills for working on the skeleton itself
├── scripts/       # Scripts for skeleton development
├── commands/      # Slash commands for skeleton development
├── hooks/         # Hooks for skeleton development
└── settings.json  # Settings for the manager session that builds the skeleton
```

### `./template/.claude/` — what gets installed into target projects

The skeleton that ships. When a target project installs claude-skeleton, the contents of `template/.claude/` (after merge logic and per-project customization) become the target's `.claude/`.

Layout mirrors the development directory but with **template** content:

```
template/.claude/
├── agents/                  # Baseline agents target projects inherit
├── skills/                  # Baseline skills target projects inherit
├── scripts/                 # Baseline scripts target projects inherit
├── commands/                # Baseline slash commands target projects inherit
├── hooks/                   # Baseline hooks target projects inherit
└── settings.json.template   # Baseline settings (target-specific values filled at install)
```

**Why two directories?** Because the things that help us *build* the skeleton are not always the same as the things that help target projects *use* it. The meta-system might need a "validate-template" skill that target projects don't need. The skeleton might want a strict `defaultMode: plan`; target projects might want something looser. Keeping these clearly separate prevents leakage.

## Full project layout

```
claude-skeleton/
├── .claude/            # Working dir for developing the skeleton
├── template/           # The shippable skeleton
│   ├── .claude/        # Becomes target project's .claude/
│   ├── docs/           # Doc templates (STATUS, SESSION_LOG, ARCHITECTURE)
│   ├── CLAUDE.md.template
│   ├── CLAUDE_MANAGER.md.template
│   ├── ROUTING.md.template
│   └── .gitignore.template
├── scripts/            # Install / update scripts. Uninstall TBD.
├── docs/               # This project's own documentation
│   ├── PHILOSOPHY.md   # Design principles
│   ├── ARCHITECTURE.md # This file
│   ├── INSTALLATION.md # How to install / update
│   ├── ROADMAP.md      # v1.1+ / v1.2+ / v2.0 sequencing
│   └── CHANGELOG.md    # Version history
├── README.md
├── VERSION             # Single-line semver (canonical version source)
├── LICENSE             # MIT
└── .gitignore
```

## Versioning

Strict semantic versioning. The current version lives in `VERSION` at the project root — one line, no whitespace, no quotes. This is the canonical source.

- **Major** (X.0.0): breaking changes to the template structure or install API. Target projects need explicit migration.
- **Minor** (0.X.0): new helpers, new skills, new optional features. Backward-compatible with existing installs.
- **Patch** (0.0.X): bug fixes, doc improvements, no structural change.

### Per-project install version tracking

When a target project installs claude-skeleton, the installed version is recorded in a marker file at `.claude/.skeleton-version` — JSON, with per-file SHA-256 hashes since 0.8.0 for safe automated updates. On update, `update.sh` reads this marker, compares hashes file-by-file against the current template, and classifies each file (`TEMPLATE_UPDATED` / `LOCALLY_MODIFIED` / `UNCHANGED` / `NEW` / `ORPHAN`) before prompting.

Pre-0.8.0 shell-format markers get migrated automatically on first `update.sh` run via the backfill path — the warning is prominent and `--auto-apply` is forced off so the user can't accidentally bulk-overwrite local modifications during the migration. After backfill, subsequent runs use precise classification.

Without per-file hashes, every update would have to assume the worst (full re-merge with all version migrations). The hash mechanism turns updates into focused, reviewable diffs.

The marker also carries two optional drift-cache fields (`cached_skeleton_head`, `cached_skeleton_head_fetched_at`) populated by `update.sh --check-remote` on explicit user invocation. `drift-checker` (`.claude/agents/05_meta/drift-checker.md` + `.claude/scripts/drift-check.sh`) reads the cache at session start via the SessionStart hook chain and surfaces a version-drift notice when the installed `version` differs from `cached_skeleton_head`. drift-checker is strictly read-only and never touches the network — `--check-remote` is the only path that does, bounded by a 10-second timeout against `git ls-remote --tags`.

## Install flow

Installing claude-skeleton into a target project is a two-stage flow with two distinct agents. The separation matters: file operations are mechanical and safety-critical; project customization is judgment-driven. Mixing them produces an install that's either too cautious or too eager.

### Stage 1 — `scripts/install.sh` + optional `integration-installer` companion

Handles install **mechanics**. Operates under the non-destructive install rule (see `PHILOSOPHY.md`).

`install.sh` (shipped 0.5.0) is the mechanical workhorse — bash script, three modes (fresh / merge / replace), atomic JSON marker write, rollback on any error. Cross-platform via Git Bash on Windows, native bash on Linux / macOS. The `integration-installer` agent (also 0.5.0, lives in `template/.claude/agents/05_meta/`) is the optional judgment companion — it inspects target state, recommends a mode, surfaces edge cases, and produces a structured install plan that `install.sh` then executes. Either can be invoked alone; together they cover both the script-style automated install and the conversational manager-driven install.

Responsibilities:
- File operations (copy, merge, skip) — `install.sh`.
- Mode selection (`--mode=fresh`, `--mode=merge`, `--mode=replace`) — `install.sh` enforces, `integration-installer` recommends.
- Non-destructive overwrite rules: never overwrite an existing file without explicit `--force` confirmation — `install.sh`.
- Version tracking: write the JSON `.skeleton-version` marker with per-file SHA-256 hashes — `install.sh`.
- Rollback on failure: if any step errors, restore the target's `.claude/` to its pre-install state — `install.sh`.

Owns the question: **"How do I put these files into the target safely?"**

Install modes:
- `--mode=fresh` — runs only if the target's `.claude/` is empty. Refuses with a clear error otherwise.
- `--mode=merge` (default) — adds missing files. Leaves existing files alone. Reports what was added and what was skipped.
- `--mode=replace` — requires `--force` and interactive confirmation. The escape hatch for users who explicitly want to overwrite. Defaults to refusing.

### Stage 2 — `project-tuner-helper`

Runs **after** `integration-installer` completes successfully. Inspects the target project and helps customize the freshly-installed baseline.

Responsibilities:
- Inspect the target project: language, stack, frameworks, build tooling, project purpose.
- Recommend which baseline helpers are most relevant given the inspection.
- Suggest project-specific helpers that should exist but don't yet (e.g., a `python-test-runner` skill if the target is a Python project).
- Wait for user approval on the recommendations.
- Generate the approved customizations.

Owns the question: **"What should this project's customizations look like?"**

### End-to-end flow

```
1. User runs install command in target project
2. integration-installer dispatches:
   - Detects target state
   - Selects mode (or honors flag)
   - Performs file ops with safety checks
   - Records version marker
3. Install completes — baseline skeleton is in place
4. project-tuner-helper dispatches:
   - Inspects target project
   - Recommends customizations
5. User approves recommendations
6. project-tuner-helper generates approved customizations
7. Install fully complete
```

Either stage can be invoked independently:
- `integration-installer` alone for a CI-style automated install (no interactive tuning).
- `project-tuner-helper` alone for re-tuning an existing install (e.g., after the target's stack changes).

## Helper roster overview

`template/.claude/agents/` ships organized by numbered tier folders, each holding helpers of a related role. The current skeleton-baseline roster (17 agents; counts re-derived mechanically at edit time per `CLAUDE_MANAGER.md` § Roster and doc surfaces update in the same phase):

| Tier | Folder | Helpers | Role |
|---|---|---|---|
| 1 | `01_research/` | `research-helper` | Docs / library / API lookup. |
| 2 | `02_audit/` | `audit-helper` | Drift detection between docs and reality. |
| 3 | `03_monitoring/` | `monitoring-helper` | Session retro and grading. |
| 4 | `04_planning/` | `plan-coordinator` | Multi-file cross-cutting change planning. |
| 5 | `05_meta/` | `project-tuner-helper`, `system-memory-helper`, `agent-slicer`, `workflow-suggester`, `self-audit-helper`, `integration-installer`, `drift-checker`, `task-watchdog`, `script-builder`, `code-quality-auditor`, `token-cost-monitor`, `manager-optimizer`, `artifact-fit-analyzer`, `plugin-discovery-agent` | Meta-management — customizes, inspects, modifies, audits, installs, observes, and optimizes. |

`template/.claude/skills/` ships six baseline skills: `schema-verify-before-edit`, `post-edit-test-suggest`, `god-file-grep-first`, and `bash-safety` (behavioral conventions for the manager), plus `token-efficiency-monitor` and `plugin-roster-search` (meta-management observers).

The `05_meta/` tier is what makes the skeleton self-managing: `project-tuner-helper` customizes a fresh install, `self-audit-helper` watches the meta-system for drift, `agent-slicer` modifies agents safely, `system-memory-helper` answers "what's installed," `workflow-suggester` proposes captures for recurring patterns, and `integration-installer` is the judgment companion to `scripts/install.sh`. The v1.1.x–v1.2.0 additions extend the same self-management loop: `drift-checker` and `task-watchdog` observe (version drift, prior-session patterns), `script-builder` builds from approved captures, `code-quality-auditor` vets plugin source, `token-cost-monitor` watches spend, `manager-optimizer` watches the manager itself, `artifact-fit-analyzer` audits the artifact set for overlap and gaps, and `plugin-discovery-agent` inventories the plugin ecosystem into the draft recommendation manifest. Each is context-aware — it inspects whatever `.claude/` is active where it runs, so it works inside `claude-skeleton` itself and inside any target project after install.

## Where things live

A quick map of which file owns which kind of decision:

| Concern | File / Directory | Notes |
|---|---|---|
| Current version | `VERSION` | Canonical source. |
| Design principles | `docs/PHILOSOPHY.md` | The "why" of the skeleton. |
| Project layout | `docs/ARCHITECTURE.md` | This file. |
| Install / update instructions | `docs/INSTALLATION.md` | Real content as of Phase 4g (includes the per-file-hash mechanism). |
| Forward-looking sequencing | `docs/ROADMAP.md` | v1.1+ / v1.2+ / v2.0. Living. |
| Version history | `docs/CHANGELOG.md` | Keep-a-Changelog format. |
| Template content (shipping) | `template/` | Everything under here is shippable artifact. |
| Skeleton's own dev tools | `.claude/` | Not shipped to target projects. |
| Install / update scripts | `scripts/` | `install.sh` + `update.sh`. |
| Continuous integration | `.github/workflows/ci.yml` + `.github/test-fixtures/scenarios.sh` | Cross-platform smoke tests for the install/update path (Ubuntu, Windows, macOS). |

## Deferred

- `scripts/uninstall.sh` — explicit removal flow. v1.0 documentation lists the manual `rm -rf` recipe.
- A first-party `test-projects/` directory under the repo for in-tree end-to-end validation. CI runs install/update scenarios in throwaway `mktemp -d` targets ([`.github/test-fixtures/scenarios.sh`](../.github/test-fixtures/scenarios.sh)) and that has been sufficient through 0.9.0.

For forward-looking work — v1.1+ capture / reuse loop, v1.2+ `manager-optimizer`, v2.0 plugin recommendation system — see [`docs/ROADMAP.md`](ROADMAP.md).
