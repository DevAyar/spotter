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
├── scripts/            # Install / update / uninstall scripts (Phase 4c)
├── docs/               # This project's own documentation
│   ├── PHILOSOPHY.md   # Design principles
│   ├── ARCHITECTURE.md # This file
│   ├── INSTALLATION.md # How to install (Phase 4c)
│   └── CHANGELOG.md    # Version history
├── README.md
├── VERSION             # Single-line semver (0.1.0)
├── LICENSE             # MIT
└── .gitignore
```

## Versioning

Strict semantic versioning. The current version lives in `VERSION` at the project root — one line, no whitespace, no quotes. This is the canonical source.

- **Major** (X.0.0): breaking changes to the template structure or install API. Target projects need explicit migration.
- **Minor** (0.X.0): new helpers, new skills, new optional features. Backward-compatible with existing installs.
- **Patch** (0.0.X): bug fixes, doc improvements, no structural change.

### Per-project install version tracking

When a target project installs claude-skeleton, the installed version is recorded in a marker file inside the target's `.claude/` (proposed path: `.claude/.skeleton-version`). On update, the install script reads this marker, compares it to the current `VERSION`, and runs only the migrations that apply.

Without this marker, every update would have to assume the worst (full re-merge with all version migrations). The marker turns updates into focused diffs.

## Install flow

Installing claude-skeleton into a target project is a two-stage flow with two distinct agents. The separation matters: file operations are mechanical and safety-critical; project customization is judgment-driven. Mixing them produces an install that's either too cautious or too eager.

### Stage 1 — `integration-installer` (Phase 4c)

Handles install **mechanics**. Operates under the non-destructive install rule (see `PHILOSOPHY.md`).

Responsibilities:
- File operations (copy, merge, skip).
- Merge-mode detection: choose between `--mode=fresh`, `--mode=merge`, `--mode=replace`.
- Non-destructive overwrite rules: never overwrite an existing file in the target without explicit `--force` confirmation.
- Version tracking: write `.skeleton-version` marker, log install metadata.
- Rollback on failure: if any step errors, restore the target's `.claude/` to its pre-install state.

Owns the question: **"How do I put these files into the target safely?"**

Install modes:
- `--mode=fresh` — runs only if the target's `.claude/` is empty. Refuses with a clear error otherwise.
- `--mode=merge` (default) — adds missing files. Leaves existing files alone. Reports what was added and what was skipped.
- `--mode=replace` — requires `--force` and interactive confirmation. The escape hatch for users who explicitly want to overwrite. Defaults to refusing.

### Stage 2 — `project-tuner-helper` (Phase 4b)

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

## Where things live

A quick map of which file owns which kind of decision:

| Concern | File / Directory | Notes |
|---|---|---|
| Current version | `VERSION` | Canonical source. |
| Design principles | `docs/PHILOSOPHY.md` | The "why" of the skeleton. |
| Project layout | `docs/ARCHITECTURE.md` | This file. |
| Install / update / uninstall instructions | `docs/INSTALLATION.md` | Filled in Phase 4c. |
| Version history | `docs/CHANGELOG.md` | Keep-a-Changelog format. |
| Template content (shipping) | `template/` | Everything under here is shippable artifact. |
| Skeleton's own dev tools | `.claude/` | Not shipped to target projects. |
| Install / update scripts | `scripts/` | Phase 4c. |

## Deferred (Phase 4b+)

- Concrete template content in `template/.claude/{agents,skills,scripts,commands,hooks}/` (Phase 4b).
- `project-tuner-helper` agent implementation (Phase 4b).
- `integration-installer` agent + `scripts/install.sh`, `scripts/update.sh`, `scripts/uninstall.sh` (Phase 4c).
- Test projects under `test-projects/` for validation (Phase 4d-e).
- `INSTALLATION.md` content (Phase 4c).
