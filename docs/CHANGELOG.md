# Changelog

All notable changes to claude-skeleton are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [0.4.0] - 2026-05-13 — Meta-management layer

- **Four new agents** (`template/.claude/agents/05_meta/`):
  - `system-memory-helper` — system inventory (agents / skills / scripts / commands / hooks / plugins).
  - `agent-slicer` — surgical edits to existing agent files with frontmatter validation.
  - `workflow-suggester` — pattern detection over `SESSION_LOG.md`; pure suggestion.
  - `self-audit-helper` — meta-system drift detection (orphans, dead refs, doc drift, missing routes).
- **Two new skills** (`template/.claude/skills/`):
  - `token-efficiency-monitor` — observational alert when a subtask's cost exceeds 1.5× its expected envelope.
  - `plugin-roster-search` — lightweight capability → handler lookup across `.claude/` and active plugin directories.
- **Routing**: six new rows in `ROUTING.md.template`, grouped by purpose (inventory & search, modification, audit, observation).
- **Architectural milestone**: the meta-system now has recursive ownership — the skeleton can watch, modify, and audit itself. Each agent and skill is context-aware: it walks whatever `.claude/` is active where it runs. Works inside `claude-skeleton` (managing the meta-system's development) and inside any target project after install.

## [0.3.0] - 2026-05-13 — project-tuner-helper

- **New agent**: `project-tuner-helper` (`template/.claude/agents/05_meta/`). Inspects the target project after baseline installation, recommends placeholder fills, helper tightening, and project-specific helpers, awaits user approval, and generates only what was approved. Language-agnostic (Python, JS/TS, Go, Rust, Flutter, Godot, Bash).
- **Routing**: new row in `ROUTING.md.template` mapping "set up new project / install skeleton / tune skeleton to this project" to `project-tuner-helper`.
- **Install flow status**: customization side of the two-agent install flow is now functional. Mechanics side (`integration-installer`) lands in Phase 4c.

## [0.2.0] - 2026-05-13 — Baseline template content

- **Baseline agents** (`template/.claude/agents/`): `research-helper`, `audit-helper`, `monitoring-helper`, `plan-coordinator`. Minimal frontmatter; section-routing documented as a behavioral instruction in each agent body.
- **Baseline skills** (`template/.claude/skills/`): `schema-verify-before-edit`, `post-edit-test-suggest`, `god-file-grep-first`. Each ships with a baseline watched-list and an extension marker for `project-tuner-helper`.
- **Baseline scripts** (`template/.claude/scripts/`): `commit.sh` (5-section verbatim output, path-shape guard) and `deploy.sh` (uncommitted-changes check, `{{DEPLOY_COMMAND}}` placeholder, POST-DEPLOY SMOKE TEST REQUIRED banner).
- **Baseline slash commands** (`template/.claude/commands/`): `/commit`, `/audit`, `/smoke-test` (routing marker — real impl in `browser-tester` plugin), `/deploy`.
- **Baseline hooks** (`template/.claude/hooks/`): `sessionstart-rules.sh` (re-injects `compactPrompt` after compaction) and `precompact-backup.sh` (backs up STATUS / SESSION_LOG / CLAUDE.md). README documents why `PostToolUse` and `SubagentStop` are not shipped (user-level settings shadow project-level blocks).
- **Templated config files**: `CLAUDE.md.template`, `CLAUDE_MANAGER.md.template`, `ROUTING.md.template`, `.claude/settings.json.template` — all with `{{PLACEHOLDER}}` syntax for `project-tuner-helper` to fill at install time.
- **Deferred to 4b.5**: `project-tuner-helper` agent. Designed and built fresh on top of the now-stable baseline.

## [0.1.0] - 2026-05-13 — Pre-alpha foundation

- Project initialized.
- Directory structure established (`.claude/`, `template/`, `scripts/`, `docs/`).
- Initial docs scaffolded (`README`, `PHILOSOPHY`, `ARCHITECTURE`, `INSTALLATION` stub, `CHANGELOG`).
- MIT `LICENSE`, `.gitignore`, `VERSION` (`0.1.0`) in place.
- `.claude/settings.json` configured with plan-mode default and durable rules in `compactPrompt`.
- Two-agent install flow documented in `ARCHITECTURE.md` (`integration-installer` for mechanics, `project-tuner-helper` for customization). No implementation yet.
- No features yet — Phase 4a is foundation only. Features land in subsequent phases:
  - **4b**: populate `template/.claude/` with baseline agents/skills/hooks; build `project-tuner-helper`.
  - **4c**: install/update mechanism + `integration-installer`.
  - **4d-e**: validation, test projects.
