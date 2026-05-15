# Changelog

All notable changes to claude-skeleton are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [Unreleased]

- Default model set to `opusplan` in `template/.claude/settings.json.template` (Opus plan-mode + Sonnet execution). Skeleton's own dogfood `.claude/settings.json` updated to match. Override via `.claude/settings.json` per project.
- Added `session-observer` foundation (v1.1+ capture/reuse loop Phase 1): observation primitive at `template/.claude/agents/05_meta/session-observer.md`, contract schema at `session-observer.schema.md` (8 fields, multi-source-extensible enums for `source` and `pattern_type`), storage surface at `template/.claude/observations/` (one JSON file per `pattern_id`), and SessionEnd hook script at `template/.claude/hooks/sessionend-observe.sh` that records the session boundary. Observation only — no suggesting, drafting, or auto-action; those land in Phase 2 (`workflow-suggester` extension).

## [1.0.0] - 2026-05-14 — Orchestration layer ready for daily use

The first stable cut. Install / update infrastructure shipped, directive layer locked, validated on two real production targets. v1.0 is the orchestration layer ready for daily use across multiple real projects; v1.1+ work (the capture/reuse loop) starts on top of this baseline.

**Strategic layer.** `template/CLAUDE_MANAGER.md.template` is the directive layer the manager reads at session start. Carries the strategic judgment patterns (when to dispatch a helper vs read directly, when to escalate vs propose, when to question framing vs execute), the recursive ownership L0 / L1 / L2 framing (L3 reserved for v1.2+ `manager-optimizer`), the three-commit cadence (work / docs / VERSION+CHANGELOG → push), and the plugin marketplace composition section naming the seven ecosystem sources claude-skeleton composes with. Verbatim design principle: *"Don't be a directory; be a quality filter."*

**Infrastructure.** `scripts/install.sh` (three modes: fresh / merge / replace; atomic JSON marker write; rollback on any error). `scripts/update.sh` (six-way classification using per-file SHA-256 hashes recorded at install time, with one-time backfill for legacy shell-format markers). `template/.claude/scripts/commit.sh` (verbatim five-section commit wrapper) and `template/.claude/scripts/deploy.sh` (uncommitted-changes check, POST-DEPLOY SMOKE TEST banner). GitHub Actions CI on Ubuntu / macOS / Windows runs six install/update scenarios on every push and every PR (`fresh-install`, `fresh-refuse`, `merge-add`, `local-mod-detect`, `local-mod-preserve`, `backfill-migrate`).

**Agents, skills, commands.** Nine baseline agents: `research-helper`, `audit-helper`, `monitoring-helper`, `plan-coordinator`, plus the five 05_meta agents — `project-tuner-helper`, `system-memory-helper`, `agent-slicer`, `workflow-suggester`, `self-audit-helper`, `integration-installer`. Six baseline skills: `schema-verify-before-edit`, `post-edit-test-suggest`, `god-file-grep-first`, `bash-safety` (noise-path excludes, timeout discipline, background-bash wait/kill rules — prevents zombie tasks from unbounded scans hitting `.git`/`.godot`/`node_modules`/build caches), `token-efficiency-monitor`, `plugin-roster-search`. Four slash commands (`/commit`, `/audit`, `/deploy`, `/smoke-test`). Two hooks (`sessionstart-rules.sh`, `precompact-backup.sh`).

**Validation.** Retrofitted onto and stable across two real production targets at different stack profiles: **Trainer-View** (Flutter + Firebase, mobile app shipping features) and **Echoes-Of-Gill** (Godot, game in active development). Two stacks, two team sizes, two update cadences — install/update path survives both.

**Sequencing.** `docs/ROADMAP.md` orders v1.1+ / v1.2+ / v2.0. The v1.1+ centerpiece is the **capture / reuse loop**: `session-observer` notices recurring patterns in actual session work, `workflow-suggester` evolves from suggesting in the abstract to drafting concrete proposed-helper / proposed-script files, `/goals` provides the clarifying-questions layer, `script-builder` formalises approved captures into reusable scripts following the 5-section discipline. Closes the four named autonomy gaps in one named loop.

**Story.** `docs/STORY.md` is the canonical narrative — what claude-skeleton is, why it exists (ADHD-driven design rationale as constraint-forced discipline that turns out to be generally useful for LLM collaboration over weeks), how it works, what's distinctive, and what it isn't. 1839 words, peer-conversational register.

## [0.9.0] - 2026-05-14 — CI: automated three-platform validation

- **`.github/workflows/ci.yml` — three-platform matrix CI.** Runs on every push to `main` and every PR across `ubuntu-latest`, `windows-latest`, and `macos-latest`. `fail-fast: false`, so a single-platform break still surfaces results from the other two. Uses `actions/checkout@v4` and `actions/setup-python@v5` (3.11), then a sequence of named scenario steps from `.github/test-fixtures/scenarios.sh`.
- **`.github/test-fixtures/scenarios.sh` — six scenarios.** Each runs in its own `mktemp -d` target, runs assertions, and trap-cleans:
  - `fresh-install` — clean target → marker is valid JSON with 25 files, all 64-char hex hashes.
  - `fresh-refuse` — populated target → `--mode=fresh` exits non-zero; marker bytes unchanged.
  - `merge-add` — deleted file is re-added by `--mode=merge`; untouched neighbors confirmed by hash.
  - `local-mod-detect` — `update.sh --dry-run` reports `LOCALLY_MODIFIED` for a target file modified after install.
  - `local-mod-preserve` — `update.sh` with `[K]eep` leaves the local file bytes intact.
  - `backfill-migrate` — legacy shell-format marker migrated to JSON after one `update.sh` run.
- **Portability fix: `sha256sum` vs `shasum -a 256`.** Surfaced by adding macOS to the CI matrix — macOS doesn't ship `sha256sum`. Both `install.sh` and `update.sh` now detect the available command at startup (`detect_sha256`) and route hashing through a shared `$SHA256_CMD`. macOS users can now run the install scripts; previously they would have hit `sha256sum: command not found`.
- **Bug fix in `install.sh`: merge-mode rerun set-e trip.** `write_version_marker` ended with `[ "$marker_existed" = false ] && ADDED_FILES+=("$marker")`. When the marker already existed (re-running `install.sh` in merge mode), the `[` test returned 1, propagated through `&&` to the function's exit code, and tripped `set -e`. The merge install would then roll back the one new file it had just added. Replaced with explicit `if/fi`. Surfaced by the `merge-add` scenario.
- **README CI badge.** Standard GitHub Actions badge directly after the title — current `main` build state is visible at-a-glance for anyone landing on the repo.
- **INSTALLATION.md + ARCHITECTURE.md** got CI sections / rows pointing to the workflow and scenarios fixture.

## [0.8.0] - 2026-05-13 — Per-file hashes enable safe automated updates

- **`.skeleton-version` now stores per-file SHA-256 hashes.** `install.sh` writes a `files` object mapping every installed `.claude/` file's relative path to its content hash at install time. Top-level files (`CLAUDE.md`, etc.) and `--mode=merge` skipped files are not hashed — `update.sh` doesn't touch the former and backfills the latter on first encounter.
- **Schema migration: shell key:value → JSON.** Old markers (versions ≤ 0.7.0) used `version: 0.7.0\nmode: merge\n…` lines; new markers are JSON. Parsing requires `python` (or `python3`) on `PATH`; `jq` is optional / not used. `python` is shipped with most Git Bash for Windows installs.
- **`update.sh` six-way classification.** Each installed file is now bucketed using the recorded / current / template hash triple: `TEMPLATE_UPDATED` (safe to apply), `LOCALLY_MODIFIED` (warn, never auto-update), `UNCHANGED`, `LOCAL_MATCHES_TEMPLATE` (rare), `NEW`, `ORPHAN`. Replaces v1's binary diff that prompted on any difference.
- **`--auto-apply` semantics tightened.** Applies `TEMPLATE_UPDATED` and `NEW` automatically; never `LOCALLY_MODIFIED` or `ORPHAN` — those always require explicit per-file input. Force-disabled during backfill.
- **One-time backfill on pre-0.8.0 markers.** Old shell-format markers trigger a `BACKFILL MODE` warning: prominent banner, forced interactive review, recorded-hash := current-on-disk-hash assumption (can't detect local mods made before migration). Marker is upgraded to JSON after the run.
- **Atomic marker writes.** `install.sh` and `update.sh` both write to `.skeleton-version.tmp.$$` then `mv -f`, preventing partial markers on interrupt.
- **CRLF/LF handling.** Python output is reconfigured to LF on stdout (`sys.stdout.reconfigure(newline="\n")`) and on file open (`open(..., newline="\n")`). Bash side defensively strips CR from dumped marker fields. Discovered during testing — Windows Python 3's text-mode stdout was emitting CRLF, breaking the TSV-to-bash parser.
- **`docs/INSTALLATION.md`** rewritten for update flow: classification table, hash mechanism, backfill notes. v1 limitation section removed.
- **Tests** (against `C:/Users/darre/Dev/test-skeleton-install/`): fresh-install marker validates as JSON with 25 files, all 64-char hex hashes; classification scenarios T2-T5 detect 0 / 1 / 1 / 1 expected counts; T6 backfill prints warning, disables `--auto-apply`, accurately classifies, writes JSON marker. Trainer-View dry-run (existing v0.6.0 marker, untouched) classifies 16 TEMPLATE_UPDATED + 0 LOCALLY_MODIFIED — backfill compatibility confirmed without modifying TV.

## [0.7.0] - 2026-05-13 — Validated on real-world Flutter+Firebase production target

- **Migrated Trainer-View ("Forged In") to claude-skeleton baseline** via `install.sh --mode=merge --claude-only`. 12 new files added (11 baseline + `.skeleton-version`); zero tracked-file modifications to TV's existing 7 agents, 5 skills, 4 hooks, 2 scripts, 13-row ROUTING.md, CLAUDE.md, CLAUDE_MANAGER.md. Non-destructive install validated on real production code. TV's `CLAUDE_MANAGER.md` extended with an "extended frontmatter convention" section (TV-specific `effort` / `memory` / `color` fields acknowledged); `hooks/README.md` extended with an orphan-scripts acknowledgment for TV's two unregistered hooks.
- **`project-tuner-helper` output contract rewritten.** Agent now writes its full report to a file (default `.claude/agent-memory/project-tuner-report-<timestamp>.md`) and returns a brief summary paragraph (path / counts H·M·L / top-3 critical / report-only honor flag). Discovered during TV migration — Agent tool output window truncated a 115k-token inspection between subagent and manager. Returns are now capped at ~300 tokens. Template only; installed copies pick up the fix on next `update.sh` run.
- **`project-tuner-helper` `--report-only` mode formalized.** Adds `PROPOSED:` prefix to every recommendation; disables Edit/Write on project files (still writes the report file itself); self-audits the finalized report and notes any breach in the return paragraph. Documented in agent body and frontmatter description.
- **Subagent registration limitation confirmed (3rd observation).** Phase 3 PolyClaude promotion in Trainer-View, Phase 4c dogfood in this repo, and Phase 4f TV migration all required a Claude Code session restart before newly-installed subagents in numbered folders became dispatchable. Worth documenting as a permanent caveat in `docs/INSTALLATION.md` — deferred to next phase.

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
