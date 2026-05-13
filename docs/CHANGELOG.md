# Changelog

All notable changes to claude-skeleton are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [0.6.0] - 2026-05-13 — Validation milestone

- **Validation on a real target.** `bash scripts/install.sh --mode=fresh --target <throwaway>` exercised against a fresh non-skeleton project (`C:\Users\darre\Dev\test-skeleton-install\`). Verified: 31 files copy correctly (10 agents, 5 skills, 2 scripts, 4 commands, 3 hook files, 1 settings.json, 3 top-level docs, 3 `docs/` templates); `.skeleton-version` written with all six fields populated; top-level and `docs/*` templates render alongside `.claude/` (first run without `--claude-only`).
- **Fresh-mode refusal verified.** Re-running `--mode=fresh` against the populated target exited 1 with the documented error (`--mode=fresh refused: target .claude/ already has content`) and modified no files.
- **Merge-mode non-destruction verified.** Locally prepended a comment to `.claude/agents/01_research/research-helper.md` and added a fake `.claude/agents/01_research/custom-helper.md`. `--mode=merge` skipped all 31 existing files and copied 0; both local mod and custom file preserved verbatim. `.skeleton-version` updated with new `installed_at` and `mode=merge`.
- **Resolved deferred 4b.6 audit findings.** F10 (shipped `template/PLUGINS.md.template` as the canonical plugin log; tightened `CLAUDE_MANAGER.md.template` to drop the `(or equivalent)` hedge); F11 (rewrote `docs/PHILOSOPHY.md` forward reference to non-existent `integration-checker` skill — clarified `integration-installer` handles install mechanics, not plugin-discipline pre-checks); F13 (created `docs/SESSION_LOG.md` at claude-skeleton root, backfilled Phase 4a-4d history — claude-skeleton now dogfoods its own session-log convention); F14 (replaced stub content in `template/docs/{STATUS,SESSION_LOG,ARCHITECTURE}.md.template` with real baseline structure); F17 (added 4 slash-command routing rows — `/commit`, `/audit`, `/deploy`, `/smoke-test` — to `ROUTING.md.template`); F19 (deploy.sh routing row flags `{{DEPLOY_COMMAND}}` placeholder as a prereq for `project-tuner-helper`).
- **`self-audit-helper` severity rubric tightened.** Replaced the three-word severity definitions in the template helper's contract with explicit HIGH / MEDIUM / LOW rubric with examples, plus an "escalate if unsure" guidance line. Addresses the inconsistent grading observed in the Phase 4c dogfood audit.
- **No install bugs surfaced.** Phase A validation ran end-to-end without modifying `install.sh`; the v0.5.0 script handles fresh, fresh-refusal, and merge-non-destruction correctly against a real target.

## [0.5.0] - 2026-05-13 — Install mechanism

- **`scripts/install.sh`** — curl- or local-installable. Three modes (fresh / merge / replace) with the non-destructive rule enforced. `--claude-only` flag for skeleton-on-skeleton installs. `--dry-run` for safe previews. Auto-detects skeleton checkout by walking up from the script; falls back to cloning the public repo. Auto-detects target via `git rev-parse`. Refuses non-git targets, self-installs (without `--claude-only`), and dirty preflight conditions. Writes `.claude/.skeleton-version` after a successful install. On any error, rolls back every file added by the run.
- **`scripts/update.sh`** — diff-driven update flow. Reads `.skeleton-version`, scans each file under `.claude/` against the current template, presents per-category and per-file decisions. Backs up before overwriting; rollback restores on error. v1 cannot distinguish locally-modified from template-updated without per-file hashes — documented as a limitation.
- **New agent**: `integration-installer` (`template/.claude/agents/05_meta/`) — judgment-driven companion to `install.sh`. Inspects target state, decides mode appropriateness, surfaces edge cases, produces a structured install plan with the exact script invocation. Does not modify files itself. Coordinates with `project-tuner-helper` as the second stage.
- **`.gitattributes`** — forces LF endings for `*.sh` and `*.bash` on all platforms. Bash refuses CRLF shebangs.
- **First dogfood install**: `bash scripts/install.sh --mode=merge --claude-only` against this repo. Populated root `.claude/` with 10 agents, 5 skills, 2 scripts, 4 commands, 3 hook files, and `.skeleton-version`. Existing meta-dev `settings.json` preserved by the non-destructive rule. 23 files match `template/.claude/` byte-for-byte (verified). Clears Finding F16 from the 4b.6 meta-system drift audit.
- **`docs/INSTALLATION.md`** — real content (install / update / uninstall / modes / dry-run / troubleshooting) replacing the Phase 4a stub.
- **Limitation**: subagent registration for custom agents under `.claude/agents/` requires a session restart in Claude Code. Skills register live (verified in-session after the dogfood install).

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
