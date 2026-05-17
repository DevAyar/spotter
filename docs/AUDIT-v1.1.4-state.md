# Skeleton state at v1.1.4 — audit input

Generated for the post-v1.1.4 audit. Snapshot at commit `62f17f7be429dd8c34ddee44aafefc100a62592e` (HEAD on `main` after the pre-pinball queue commit). Not a release artifact — exists to drive the chat-side audit and may be deleted after the audit lands.

Factual inventory only. No recommendations, no editorializing. Each section follows the spec shape exactly.

---

## Section 1: Directive layer

### `CLAUDE.md` (dogfood, repo root)

- **Path:** `CLAUDE.md`
- **Line count:** 34
- **H2 sections:** `## Communication style` / `## Code style` / `## Design system rules` / `## Manager + helper architecture` / `## Where things live`
- **Notable subsections:** none (file is flat — all sections H2)
- **Drift vs template:** dogfood is the resolved form. Placeholders filled per project-tuner-helper outputs: `{{PROJECT_NAME}}` → `claude-skeleton`; `{{PROJECT_TAGLINE}}` → "Orchestration layer on the Claude Code ecosystem."; `{{WHO_YOU_ARE_WORKING_WITH}}` → "Project owner + peers — digestible, not portfolio/mass-market…"; `{{COMMUNICATION_STYLE}}` → ADHD-scaffolding prose; `{{CODE_STYLE}}` → bash 5-section discipline; `{{DESIGN_SYSTEM_RULES}}` → "N/A — skeleton has no rendered UI." Template `<!-- Remove this section… -->` comment is dropped in dogfood.

### `CLAUDE.md.template` (template, ships to target projects)

- **Path:** `template/CLAUDE.md.template`
- **Line count:** 35
- **H2 sections:** identical set as dogfood mirror
- **Notable subsections:** none
- **Drift vs dogfood:** carries 6 `{{PLACEHOLDER}}` tokens; carries the `<!-- Remove this section at install time… -->` comment in Design system rules. `project-tuner-helper` is the resolution mechanism.

### `CLAUDE_MANAGER.md` (dogfood, repo root)

- **Path:** `CLAUDE_MANAGER.md`
- **Line count:** 281
- **H2 sections:** `## What this manager is` / `## Manager pattern` / `## Strategic judgment patterns` / `## Section-routing — the core read discipline` / `## Dispatch mechanics` / `## Helper roster` / `## Tier system` / `## Three-commit cadence` / `## Plugin marketplace composition` / `## Plugin discipline` / `## Template-content vs template-stubs map` / `## Dogfood mirror invariants`
- **Notable subsections (Strategic judgment patterns):** `### Recursive ownership — L0 / L1 / L2 (L3 reserved)` (H3 under "What this manager is"); `### Dispatch a helper vs read files directly` / `### Escalate to the user vs propose autonomously` / `### Question the user's framing vs execute the request` / `### Plan amendment behavior` / `### Invoke /goals vs ship direct` (TEMPLATE STUB) / `### Apply integration-checker before any plugin install` (TEMPLATE STUB) / `### Apply bash-safety to any recursive scan or project-wide file op` / `### Model selection` / `### When to consult observations` / `### When to dispatch workflow-suggester` / `### When to dispatch script-builder` / `### When to dispatch drift-checker` / `### When to dispatch task-watchdog` / `### When to dispatch cruft-checker`
- **Notable subsections (Plugin marketplace composition):** `### Composition, not competition` / `### Ecosystem we draw from` / `### How a plugin gets installed` / `### Design principle` ("Don't be a directory; be a quality filter.")
- **Notable subsections (Three-commit cadence):** `### Commit cadence by phase size` (small-fix / medium / large rubric)
- **Drift vs template:** dogfood is the resolved form. `{{PROJECT_NAME}}` → `claude-skeleton` in title (line 1). All other prose is byte-identical to template.

### `CLAUDE_MANAGER.md.template` (template)

- **Path:** `template/CLAUDE_MANAGER.md.template`
- **Line count:** 282
- **H2 sections:** identical set as dogfood mirror
- **Notable subsections:** identical to dogfood mirror (same H3s, same TEMPLATE STUB markers)
- **Drift vs dogfood:** 1-line diff in title placeholder `# Manager session — {{PROJECT_NAME}}`. All H2/H3 structure byte-identical.

### `ROUTING.md` (dogfood, repo root)

- **Path:** `ROUTING.md`
- **Line count:** 36
- **H2 sections:** `## Baseline routes`
- **Notable subsections:** none — single table with 24 routes (mix of agents, scripts, skills, hooks, slash commands)
- **Drift vs template:** dogfood resolves `{{DEPLOY_COMMAND}}` placeholder to "N/A — skeleton has no deploy step; published as git tags + GitHub Release" (in `deploy.sh` route row + `/deploy` slash command row).

### `ROUTING.md.template` (template)

- **Path:** `template/ROUTING.md.template`
- **Line count:** 37
- **H2 sections:** `## Baseline routes`
- **Drift vs dogfood:** 1-line difference for title placeholder + the `{{DEPLOY_COMMAND}}` placeholder appearing in two rows (deploy.sh + /deploy).

### Documented drift summary

Drift between template and dogfood mirrors is documented in CLAUDE_MANAGER.md § Dogfood mirror invariants (lines 277-281):

> Skeleton repo root acts as the skeleton's own first installed project. Template-root files have byte-identical dogfood mirrors at skeleton repo root, differing ONLY in resolved placeholder values… Dogfood-only artifacts explicitly scoped to dogfood per their phase brief (e.g. `cruft-checker`, which audits the skeleton's own roadmap) are EXEMPT from template parity.

Locked drift categories:
1. **`{{PROJECT_NAME}}`** filled in dogfood, placeholder in template.
2. **`{{DEPLOY_COMMAND}}`** filled in dogfood ROUTING.md row + deploy.sh script; placeholder in template ROUTING + script.
3. **`{{COMPACT_PROMPT}}`** filled in dogfood settings.json; placeholder in template.
4. **`defaultMode`** = `plan` in dogfood; `default` in template.
5. **cruft-checker dogfood-only** — agent + script + SessionStart hook entry present in dogfood, absent in template.
6. **`self-audit-helper`** — dogfood 73 lines, template 92 lines (template has extended Severity rubric with HIGH/MEDIUM/LOW + examples). See Section 16.
7. **`project-tuner-helper`** — dogfood 124 lines, template 188 lines (template has additional "Output contract" + "`--report-only` mode" subsections from Phase 4f). See Section 16.

---

## Section 2: Agents

15 agents ship in `template/.claude/agents/` (the baseline that target projects install). Dogfood `.claude/agents/` carries the same 15 + 1 dogfood-only agent (`cruft-checker`) = 16 total. Three `.schema.md` files (not agents themselves) live alongside in `05_meta/`: covered in Section 8.

Mirror status: byte-identical except for `self-audit-helper` and `project-tuner-helper` (see Section 16) and the dogfood-only `cruft-checker`.

### `research-helper`

- **File path:** `.claude/agents/01_research/research-helper.md` (42 lines) + `template/.claude/agents/01_research/research-helper.md` (byte-identical)
- **Tier:** `01_research` / L1
- **Purpose:** Generic documentation and reference lookup. Local-first, web-second; routes around god-files; returns pointer + brief summary.
- **Inputs read:** Glob/Grep results from project tree; WebSearch + WebFetch on miss.
- **Outputs:** structured report — Answer / Source / Confidence / Caveats. No file writes.
- **Triggers:** manual dispatch only.
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read, WebSearch, WebFetch. **Model:** sonnet.
- **Dependencies:** none.

### `audit-helper`

- **File path:** `.claude/agents/02_audit/audit-helper.md` (43 lines) + template mirror
- **Tier:** `02_audit` / L1
- **Purpose:** Drift detection between project state and project records (docs vs code reality).
- **Inputs read:** doc files (STATUS.md, CHANGELOG, README, ROUTING.md); Glob/Grep against current tree.
- **Outputs:** drift report — Claim / Reality / Severity / Suggested fix per finding.
- **Triggers:** manual dispatch; routed by `/audit` slash command.
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read. **Model:** sonnet.
- **Dependencies:** none.

### `monitoring-helper`

- **File path:** `.claude/agents/03_monitoring/monitoring-helper.md` (42 lines) + template mirror
- **Tier:** `03_monitoring` / L1
- **Purpose:** Session retro and grading against rubric.
- **Inputs read:** forward-chronological tail of `docs/SESSION_LOG.md` (via `wc -l` + offset-anchored Read).
- **Outputs:** graded table per session + Patterns section if repeats + single Recommended next step.
- **Triggers:** manual dispatch.
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read, Bash. **Model:** sonnet.
- **Dependencies:** none.

### `plan-coordinator`

- **File path:** `.claude/agents/04_planning/plan-coordinator.md` (44 lines) + template mirror
- **Tier:** `04_planning` / L1
- **Purpose:** Plan-mode dispatcher for multi-file cross-cutting changes (Explore / Plan / Review / Final-plan workflow).
- **Inputs read:** files in scope via Glob/Grep/Read; section-routes god-files.
- **Outputs:** plan with Context / Approach / Critical files / Verification / Non-goals sections.
- **Triggers:** manual dispatch.
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read. **Model:** opus.
- **Dependencies:** none.

### `agent-slicer`

- **File path:** `.claude/agents/05_meta/agent-slicer.md` (77 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Surgical edits to existing agent files; frontmatter-validates before and after.
- **Inputs read:** target agent file + sibling agents in same folder for convention.
- **Outputs:** Edit diff + frontmatter validation result + body-contradiction flag if any.
- **Triggers:** manual dispatch (one agent per dispatch).
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read, Edit. **Model:** sonnet.
- **Dependencies:** agent frontmatter schema (name / description / tools / model — only these four fields permitted).

### `integration-installer`

- **File path:** `.claude/agents/05_meta/integration-installer.md` (115 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Companion to `scripts/install.sh` — judgment-driven install planning (target-state detection, mode choice, conflict-resolution, rollback triggers).
- **Inputs read:** target `.claude/` state; `.claude/.skeleton-version` if present; git status; project type hints (package.json / pyproject.toml / etc.); skeleton source (template/.claude/, VERSION).
- **Outputs:** structured install plan + exact `install.sh` invocation. Does NOT modify files.
- **Triggers:** manual dispatch on user "install claude-skeleton here" or troubleshooting.
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read, Write, Bash. **Model:** opus.
- **Dependencies:** `scripts/install.sh`, `project-tuner-helper` (sequential — installer plans, install.sh executes, tuner customizes).

### `project-tuner-helper` (template-only elaboration)

- **File path:** `.claude/agents/05_meta/project-tuner-helper.md` (124 lines) + `template/.claude/agents/05_meta/project-tuner-helper.md` (188 lines)
- **Tier:** `05_meta` / L2
- **Purpose:** Post-install / re-tuning agent. Inspects target project, recommends customizations to fill 9 placeholders, awaits user approval, generates only what was approved. Language-agnostic.
- **Inputs read:** 6 inspection passes — Language detection (extensions + lockfiles) / Framework detection (deps) / Test runner (config files) / Deploy/build (Makefile, package.json scripts, etc.) / Existing config (current .claude/) / Project type heuristic (UI-bearing vs not).
- **Outputs:** structured report grouped by destination file; placeholder fills + baseline helper tightening + project-specific helpers (T2) + structural edits. Template-only addition: report file written to caller-specified path or `.claude/agent-memory/project-tuner-report-<UTC-timestamp>.md`. Return payload is short paragraph with report path + counts by confidence + top-3 critical findings.
- **Triggers:** after `integration-installer` completes; manual re-tune.
- **Status:** shipped v1.0 baseline; template extended in Phase 4f with `--report-only` mode + Output contract subsection (file-based report to avoid Agent-tool output-window truncation on large projects).
- **Tools:** Glob, Grep, Read, Edit, Write, Bash. **Model:** opus.
- **Dependencies:** `integration-installer` precedes it; nine placeholders defined: `PROJECT_NAME`, `PROJECT_TAGLINE`, `WHO_YOU_ARE_WORKING_WITH`, `COMMUNICATION_STYLE`, `CODE_STYLE`, `DESIGN_SYSTEM_RULES`, `TEST_COMMAND`, `DEPLOY_COMMAND`, `COMPACT_PROMPT`.

### `system-memory-helper`

- **File path:** `.claude/agents/05_meta/system-memory-helper.md` (73 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** System inventory agent. Lists / searches installed agents, skills, scripts, commands, hooks, plugins.
- **Inputs read:** `.claude/agents/**`, `skills/**`, `scripts/**`, `commands/**`, `hooks/**`; plugin directories declared in settings.json.
- **Outputs:** structured listing grouped by type, one-line description per entry pulled from frontmatter or top heading.
- **Triggers:** manual dispatch ("what do I have available?" / "where is X?").
- **Status:** shipped v1.0 baseline.
- **Tools:** Glob, Grep, Read, Bash. **Model:** sonnet.
- **Dependencies:** none.

### `self-audit-helper` (template-only elaboration)

- **File path:** `.claude/agents/05_meta/self-audit-helper.md` (73 lines) + `template/.claude/agents/05_meta/self-audit-helper.md` (92 lines)
- **Tier:** `05_meta` / L2
- **Purpose:** Audits the meta-system itself — orphans, dead references, doc drift, missing routes.
- **Inputs read:** all of `.claude/`; ROUTING.md; CLAUDE_MANAGER.md; settings.json; STATUS.md + ARCHITECTURE.md if they reference helpers.
- **Outputs:** drift report grouped by category — Orphans / Dead references / Doc drift / Missing routes. Each finding: Type / Location / Severity / Suggested fix.
- **Triggers:** manual dispatch (pre-release / post-refactor / monthly).
- **Status:** shipped v1.0 baseline; template version has extended Severity rubric (HIGH/MEDIUM/LOW with examples — "escalate if unsure"); dogfood version has short rubric. See Section 16.
- **Tools:** Glob, Grep, Read, Bash. **Model:** sonnet.
- **Dependencies:** none.

### `workflow-suggester`

- **File path:** `.claude/agents/05_meta/workflow-suggester.md` (85 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Reads observations + drafts capture markdown files for human review. Pure drafting — does not build artifacts, modify observations, or auto-approve.
- **Inputs read:** `.claude/observations/*.json` (input); `.claude/captures/*.md` (for idempotency — greps for `^source_pattern_id:` to skip already-captured).
- **Outputs:** one `.claude/captures/<source_pattern_id>.md` per warranted observation, conforming to `workflow-suggester.schema.md`. Default thresholds: `resolved_at == null AND occurrences >= 3 AND confidence >= med`. Special filename: `code-quality-auditor` `plugin_quality` observations land at `plugin-quality-<plugin-name>-<heuristic-id>.md` (deviation from default).
- **Triggers:** manual dispatch (weekly retrospective rhythm; observation count >5-10 unreviewed).
- **Status:** shipped v1.1+ Phase 2.
- **Tools:** Read, Grep, Glob, Write. **Model:** (not specified — inherits settings.json default).
- **Dependencies:** consumes `session-observer.schema.md`; emits `workflow-suggester.schema.md`. Routing rules: `viii: ` prefix → `infrastructure-fix`; `lesson: ` prefix → `lesson`; cruft-checker default → `doc-fix`; code-quality-auditor `plugin_quality` → `manual_action`.

### `script-builder`

- **File path:** `.claude/agents/05_meta/script-builder.md` (107 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** First X-builder. Reads approved-script captures and drafts bash scripts under `.claude/scripts/drafts/<source_pattern_id>.sh.draft` following the 5-section discipline.
- **Inputs read:** `.claude/captures/*.md` filtered to `status: approved AND suggested_artifact_type: script`; `.claude/scripts/drafts/*.sh.draft` for idempotency.
- **Outputs:** one `.sh.draft` file per warranted capture per `script-builder.schema.md` (5-section discipline + path-shape guards + bash-safety conventions).
- **Triggers:** manual dispatch after user approves captures.
- **Status:** shipped v1.1+ Phase 3.
- **Tools:** Read, Grep, Glob, Write. **Model:** (not specified).
- **Dependencies:** consumes `workflow-suggester.schema.md`; emits `script-builder.schema.md`. No auto-promotion (user `mv`s and `chmod +x`s).

### `session-observer`

- **File path:** `.claude/agents/05_meta/session-observer.md` (62 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Observation primitive. Detects repeated patterns in session work and writes observation files.
- **Inputs read:** `docs/SESSION_LOG.md` recent tail (backward from `<!-- session-end: -->` marker or last N sessions); `.claude/observations/.session-ended` marker mtime; `git log --since=...`; existing `.claude/observations/` files for re-observation.
- **Outputs:** JSON files at `.claude/observations/<pattern_id>.json` per `session-observer.schema.md`. Pattern types: `repeated_command`, `repeated_edit`, `error_resolution`, `recurring_failure` (NOT emitted — task-watchdog is canonical producer), `other`.
- **Triggers:** session start if `.session-ended` marker exists; manual dispatch; before planning multi-step work.
- **Status:** shipped v1.1+ Phase 1.
- **Tools:** Read, Grep, Glob, Write. **Model:** (not specified).
- **Dependencies:** emits `session-observer.schema.md`. Consumed by `workflow-suggester`.

### `task-watchdog`

- **File path:** `.claude/agents/05_meta/task-watchdog.md` (72 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Retrospective observer of prior Claude Code session's tool calls — long-running bash (>5min) + recurring failures (same signature ≥3 times in-session). **Canonical producer** of `recurring_failure` observations.
- **Inputs read:** `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` (second-newest by mtime — assumes newest = current session); reads `tool_use` + `tool_result` blocks with `isSidechain: false`; idempotency marker at `.claude/observations/.last-watchdog-session`.
- **Outputs:** observation JSON files per `session-observer.schema.md`. Two pattern shapes — long-running bash (`pattern_type: other`, notes `"long-running bash call (>{N}m)"`); recurring failure (`pattern_type: recurring_failure`, signature = normalized first-line of `tool_result.content` or `toolUseResult.stderr`).
- **Triggers:** SessionStart hook chain (after `drift-check.sh`); manual dispatch.
- **Status:** shipped v1.1+ Phase 5.
- **Tools:** Read, Bash, Write. **Model:** (not specified).
- **Dependencies:** emits against `session-observer.schema.md`. Mechanism: `.claude/scripts/task-watchdog.sh` (374 lines).

### `drift-checker`

- **File path:** `.claude/agents/05_meta/drift-checker.md` (77 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Reads `.claude/.skeleton-version`, compares installed `version` against cached `cached_skeleton_head`, surfaces structured drift notice if different. Read-only — no marker writes, no network.
- **Inputs read:** `.claude/.skeleton-version` fields `version`, `cached_skeleton_head`, `cached_skeleton_head_fetched_at`. NOTHING else.
- **Outputs:** single text block on stdout prefixed `[skeleton-drift]`. Four cases: marker missing / marker malformed / cache empty / version mismatch. Silent on match.
- **Triggers:** SessionStart hook chain (first invocation after `sessionstart-rules.sh`); manual dispatch.
- **Status:** shipped v1.1+ Phase 4.
- **Tools:** Read, Bash. **Model:** (not specified).
- **Dependencies:** mechanism is `.claude/scripts/drift-check.sh` (74 lines). Cache refresh path is `bash scripts/update.sh --check-remote` (separate, network-touching, user-invoked).

### `cruft-checker` (DOGFOOD-ONLY)

- **File path:** `.claude/agents/05_meta/cruft-checker.md` (128 lines) — NO template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** Dogfood-only retrospective auditor of skeleton's own docs/refs. 9 cruft classes — broken links / missing anchors / VERSION↔CHANGELOG mismatches / stale README counts / non-existent phase refs / stale schema-field claims / hook-entry config-schema violations / tag↔VERSION↔CHANGELOG at HEAD / cross-doc stale version refs.
- **Inputs read:** all `.md` files outside `.claude/observations/` and `.git/`; VERSION; docs/CHANGELOG.md; README.md; template/.claude/** for actual counts; `template/.claude/agents/05_meta/*.schema.md` for field counts; git refs.
- **Outputs:** observation files per `session-observer.schema.md` — `source: cruft-checker`, `pattern_type: other`, notes carry heuristic prefix (e.g. `"i: link-missing-file → docs/INSTALLATION.md:42: target docs/MISSING.md"`). Full resolve pass after detection.
- **Triggers:** SessionStart hook chain (third entry in dogfood `.claude/settings.json` — `bash .claude/scripts/cruft-check.sh --hook` with 24h cooldown via `.claude/.last-cruft-check`); manual dispatch.
- **Status:** shipped v1.1+ Phase 6.
- **Tools:** Read, Bash, Glob, Grep, Write. **Model:** (not specified).
- **Dependencies:** mechanism is `.claude/scripts/cruft-check.sh` (631 lines). Locked dogfood-only per "two distinct audit surfaces" principle (ROADMAP) — project-level cruft handled by v1.2.0's `infrastructure-auditor`.

### `code-quality-auditor`

- **File path:** `.claude/agents/05_meta/code-quality-auditor.md` (112 lines) + template mirror
- **Tier:** `05_meta` / L2
- **Purpose:** First plugin-verification surface. Reads installed plugin source under `~/.claude/plugins/cache/` and emits observations for 3 heuristics: (i) manifest path missing/empty / (ii) hooks/ present but hooks.json malformed/schema-violating / (iii) destructive shell patterns against unguarded paths. Composes with cruft-checker + drift-checker as **project-level audit triad**.
- **Inputs read:** `~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`; `<plugin>/.claude-plugin/plugin.json`; `<plugin>/commands/`, `agents/`, `skills/`, `hooks/`, `scripts/`; `<plugin>/hooks/hooks.json` if present.
- **Outputs:** observation files per `session-observer.schema.md` — `source: code-quality-auditor`, `pattern_type: plugin_quality`, notes carry heuristic prefix (i/ii/iii). Capture filename convention: `plugin-quality-<plugin>-<heuristic>.md`.
- **Triggers:** SessionStart hook chain (`bash .claude/scripts/plugin-quality-check.sh --hook` with 24h cooldown via `.claude/.last-plugin-quality-check`); manual dispatch; `--plugin-dir` flag for synthetic testing.
- **Status:** shipped v1.1.4 Phase 24. SHIPS IN TEMPLATE (unlike cruft-checker).
- **Tools:** Read, Bash, Glob, Grep, Write. **Model:** (not specified).
- **Dependencies:** mechanism is `.claude/scripts/plugin-quality-check.sh` (429 lines). Sources `.claude/lib/destructive-bash-patterns.sh` + `.claude/lib/destructive-powershell-patterns.sh`. Reuses hook-schema validation from `cruft-check.sh` heuristic viii (`docs/HOOK_SCHEMA.md` is canonical reference).

---

## Section 3: Skills

6 skills ship, byte-identical mirror across `template/.claude/skills/` and `.claude/skills/`. All are behavioral (no enforcement hooks). All inherit project-tuner-helper extension points.

### `bash-safety`

- **File path:** `.claude/skills/bash-safety/SKILL.md` (94 lines) + template mirror
- **Purpose:** Before running recursive scans or backgrounded bash, apply noise-path excludes, timeout, maxdepth, wait/kill discipline.
- **Mirror status:** both — byte-identical.
- **Consumed by:** the manager (per CLAUDE_MANAGER `### Apply bash-safety to any recursive scan` H3); cited by `script-builder.schema.md` line 120-130 ("bash-safety integration" section — generated scripts MUST follow). Also routed in `ROUTING.md` (recursive scan / project-wide file count row).

### `god-file-grep-first`

- **File path:** `.claude/skills/god-file-grep-first/SKILL.md` (45 lines) + template mirror
- **Purpose:** Before Reading a file >1000 lines, Grep for exact target first, Read narrowly with offset/limit.
- **Mirror status:** both — byte-identical.
- **Consumed by:** the manager (per CLAUDE_MANAGER § Section-routing — refs the 1000-line threshold as always-on rule); routed in ROUTING.md.

### `plugin-roster-search`

- **File path:** `.claude/skills/plugin-roster-search/SKILL.md` (49 lines) + template mirror
- **Purpose:** Grep across agent/skill/command descriptions for capability lookup. Returns top 3 candidates ranked by description fit.
- **Mirror status:** both — byte-identical.
- **Consumed by:** the manager when ROUTING.md has no matching row; routed in ROUTING.md.

### `post-edit-test-suggest`

- **File path:** `.claude/skills/post-edit-test-suggest/SKILL.md` (41 lines) + template mirror
- **Purpose:** After Edit/Write on a watched source path, surface the test command as next step (no PostToolUse hook used — behavioral, more robust than mechanical).
- **Mirror status:** both — byte-identical.
- **Consumed by:** the manager; routed in ROUTING.md (edit-on-source-file row). Uses `{{TEST_COMMAND}}` placeholder (filled by project-tuner-helper).

### `schema-verify-before-edit`

- **File path:** `.claude/skills/schema-verify-before-edit/SKILL.md` (37 lines) + template mirror
- **Purpose:** Before editing structured config (`.claude/settings.json`, `package.json`, `tsconfig.json`, `.github/workflows/*.yml`), read file shape + schema first.
- **Mirror status:** both — byte-identical.
- **Consumed by:** the manager (cited in CLAUDE_MANAGER § Dispatch mechanics rule 7); routed in ROUTING.md.

### `token-efficiency-monitor`

- **File path:** `.claude/skills/token-efficiency-monitor/SKILL.md` (57 lines) + template mirror
- **Purpose:** After dispatched subtask completes, if token cost exceeds 1.5× expected envelope, surface one-line observation with likely-cause hypothesis. Observational, not enforcing.
- **Mirror status:** both — byte-identical.
- **Consumed by:** the manager after every dispatched subtask; routed in ROUTING.md.

---

## Section 4: Scripts

Repo root `scripts/` has 2 install/update scripts. Template `.claude/scripts/` has 5 scripts. Dogfood `.claude/scripts/` has the same 5 + `cruft-check.sh` (dogfood-only). Plus a `drafts/` subdirectory in both `.claude/scripts/` with a README + .gitkeep (for `script-builder` output staging).

### `scripts/install.sh` (repo-root)

- **File path:** `scripts/install.sh` (465 lines)
- **Purpose:** Non-destructive installer for claude-skeleton into a target project. Three modes (fresh / merge / replace). Writes per-file SHA-256 hashes to `.claude/.skeleton-version`.
- **Invoked by:** manual user invocation (`bash scripts/install.sh ...`) or curl-pipe; `integration-installer` plans the invocation; CI tests it via `.github/test-fixtures/scenarios.sh`.
- **Inputs / outputs:** reads template/, target tree; writes target's `.claude/` + `.skeleton-version`. Flags: `--mode={fresh,merge,replace}`, `--source`, `--target`, `--claude-only`, `--dry-run`, `--force`. Top-level files (CLAUDE.md, README, etc.) never overwritten regardless of mode.
- **Lib dependencies:** none (self-contained).
- **Mirror status:** N/A — repo-root infrastructure, not installed.

### `scripts/update.sh` (repo-root)

- **File path:** `scripts/update.sh` (857 lines)
- **Purpose:** Non-destructive updater using per-file SHA-256 hashes for six-way classification of installed files vs current template. Also handles drift-cache refresh.
- **Invoked by:** manual user invocation; CI tests via `.github/test-fixtures/scenarios.sh` (backfill-migrate, local-mod-detect, local-mod-preserve scenarios).
- **Inputs / outputs:** reads `.claude/.skeleton-version` + current `.claude/` + template; writes updates per user approval; writes marker updates. Flags: `--auto-apply`, `--dry-run`, `--check-remote`. Six-way classification: UNCHANGED / TEMPLATE_UPDATED / LOCALLY_MODIFIED / NEW / ORPHAN / LOCAL_MATCHES_TEMPLATE. `--auto-apply` accepts TEMPLATE_UPDATED + NEW only; never LOCALLY_MODIFIED or ORPHAN. `--check-remote` runs `git ls-remote --tags` (10s timeout) and writes `cached_skeleton_head` + `cached_skeleton_head_fetched_at`; no diff/classification in that mode.
- **Lib dependencies:** none (self-contained). Uses bash 3.2-compatible map emulation for macOS compatibility.
- **Mirror status:** N/A — repo-root infrastructure.

### `commit.sh`

- **File path:** `template/.claude/scripts/commit.sh` (57 lines) + dogfood mirror byte-identical
- **Purpose:** Mechanical commit wrapper. Emits 5 verbatim sections to stdout (PRE-COMMIT STATUS / STAGE COMMAND / COMMIT STDOUT / POST-COMMIT STATUS / NEW COMMIT HASH).
- **Invoked by:** `/commit` slash command (→ template/.claude/commands/commit.md); manual; ROUTING.md "Commit the staged changes" row.
- **Inputs / outputs:** stdin: nothing; arg $1: commit message (path-shape guard rejects path-shaped or code-extension-ending inputs); stdout: 5-section report.
- **Lib dependencies:** none.
- **Mirror status:** both — byte-identical.

### `deploy.sh`

- **File path:** `template/.claude/scripts/deploy.sh` (51 lines) + dogfood mirror
- **Purpose:** Deploy wrapper. Path-shape guard + uncommitted-changes check + POST-DEPLOY SMOKE TEST REQUIRED banner on success.
- **Invoked by:** `/deploy` slash command; manual.
- **Inputs / outputs:** args: deploy flags; uses `{{DEPLOY_COMMAND}}` placeholder. In dogfood, this is `N/A — skeleton has no deploy step; published as git tags + GitHub Release` (script is effectively unusable in dogfood since the placeholder isn't a runnable command — intentional, skeleton has no app to deploy).
- **Lib dependencies:** none.
- **Mirror status:** both — byte-identical structurally; differs only via `{{DEPLOY_COMMAND}}` placeholder resolution.

### `drift-check.sh`

- **File path:** `template/.claude/scripts/drift-check.sh` (74 lines) + dogfood mirror byte-identical
- **Purpose:** Read-only version-drift check. Compares marker's `version` against `cached_skeleton_head`. Always exits 0.
- **Invoked by:** SessionStart hook chain (`sessionstart-rules.sh` shells it); `drift-checker` agent shells the same script.
- **Inputs / outputs:** reads `.claude/.skeleton-version`; stdout: `[skeleton-drift]`-prefixed notice or silent.
- **Lib dependencies:** none. Requires `jq` (silent no-op if missing).
- **Mirror status:** both — byte-identical.

### `task-watchdog.sh`

- **File path:** `template/.claude/scripts/task-watchdog.sh` (374 lines) + dogfood mirror byte-identical
- **Purpose:** Retrospective scan of prior session's JSONL transcript. Two pattern detectors (long-running bash >5min; recurring failure ≥3 times). 5-section bash wrapper around inline Python helper.
- **Invoked by:** SessionStart hook chain (after `drift-check.sh`); `task-watchdog` agent shells it.
- **Inputs / outputs:** reads `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` (second-newest by mtime); writes observation files + `.last-watchdog-session` marker. Constants: `DURATION_THRESHOLD_MS=300000`, `FAILURE_OCCURRENCE_THRESHOLD=3`, `EVIDENCE_CAP=20`. `CLAUDE_PROJECTS_DIR_OVERRIDE` env var for test fixtures.
- **Lib dependencies:** none.
- **Mirror status:** both — byte-identical.

### `plugin-quality-check.sh`

- **File path:** `template/.claude/scripts/plugin-quality-check.sh` (429 lines) + dogfood mirror byte-identical
- **Purpose:** Plugin-verification scan over `~/.claude/plugins/cache/`. 5-section bash wrapper around inline Python helper implementing 3 heuristics. 24h cooldown via `.claude/.last-plugin-quality-check`.
- **Invoked by:** SessionStart hook chain (`--hook` mode); `code-quality-auditor` agent shells it.
- **Inputs / outputs:** reads plugin source under `$DEFAULT_PLUGIN_DIR = $HOME/.claude/plugins/cache`; writes observation files + cooldown marker. Flags: `--hook` (enables cooldown), `--plugin-dir <path>` (override default — synthetic testing).
- **Lib dependencies:** `.claude/lib/destructive-bash-patterns.sh` + `.claude/lib/destructive-powershell-patterns.sh` (source for heuristic iii pattern matching). Reuses `docs/HOOK_SCHEMA.md` validation logic for heuristic ii.
- **Mirror status:** both — byte-identical. SHIPS IN TEMPLATE (target projects also install plugins).

### `cruft-check.sh` (DOGFOOD-ONLY)

- **File path:** `.claude/scripts/cruft-check.sh` (631 lines) — NO template mirror
- **Purpose:** Skeleton-doc cruft scanner. 5-section bash wrapper around inline Python helper implementing 9 heuristics (i, ii, iii, iv, v, vii, viii, ix, x — vi deferred). 24h cooldown via `.claude/.last-cruft-check`.
- **Invoked by:** dogfood SessionStart hook chain (`--hook` mode); `cruft-checker` agent.
- **Inputs / outputs:** reads `.md` files repo-wide (with EXEMPT_VFILES + EXEMPT_VDIRS + EXEMPT_VREGION_FILES exclusions for heuristic x); writes observation files + cooldown marker. Flags: `--hook` (enables cooldown).
- **Lib dependencies:** none directly. Uses `docs/HOOK_SCHEMA.md` for heuristic viii validation (inline Python).
- **Mirror status:** DOGFOOD ONLY. Locked per "two distinct audit surfaces" principle.

---

## Section 5: Commands

4 slash commands, all mirrored byte-identical between `.claude/commands/` and `template/.claude/commands/`.

### `/commit`

- **File path:** `.claude/commands/commit.md` (11 lines) + template mirror
- **Purpose:** Run mechanical commit wrapper. Emits five-section verbatim report.
- **Mirror status:** both — byte-identical.
- **Current state:** baseline. Wraps `bash .claude/scripts/commit.sh "$ARGUMENTS"`. `allowed-tools: Bash(.claude/scripts/commit.sh:*)`. Argument-hint: `"<commit message>"`.

### `/audit`

- **File path:** `.claude/commands/audit.md` (14 lines) + template mirror
- **Purpose:** Dispatch `audit-helper` with `<doc>:<section>` scope arg. Appends `### Audit — <scope> — <date>` to `docs/SESSION_LOG.md`.
- **Mirror status:** both — byte-identical.
- **Current state:** baseline. Argument-hint: `"<doc>:<section>"`. Surfaces findings verbatim; does not auto-fix.

### `/deploy`

- **File path:** `.claude/commands/deploy.md` (15 lines) + template mirror
- **Purpose:** Run `bash .claude/scripts/deploy.sh $ARGUMENTS`. Surfaces POST-DEPLOY SMOKE TEST REQUIRED banner verbatim on success.
- **Mirror status:** both — byte-identical.
- **Current state:** baseline. `allowed-tools: Bash(.claude/scripts/deploy.sh:*)`. Recommends `/smoke-test` after success.

### `/smoke-test`

- **File path:** `.claude/commands/smoke-test.md` (13 lines) + template mirror
- **Purpose:** Routing marker only — real implementation lives in `browser-tester` plugin (Tier 3, opt-in).
- **Mirror status:** both — byte-identical.
- **Current state:** baseline placeholder. Falls back to manual instructions if `browser-tester` not installed.

---

## Section 6: Hooks

5 hook scripts in `.claude/hooks/` and `template/.claude/hooks/` (mirrored byte-identical) + `README.md` per side. Hook registrations live in `settings.json` / `settings.json.template` (see Section 10).

### Hook scripts

All hook scripts: `set -uo pipefail` minimum, exit 0 on every path (never block).

- **`sessionstart-rules.sh`** (76 lines, both mirrors byte-identical) — re-injects durable rules from `compactPrompt`, invokes `drift-check.sh`, invokes `task-watchdog.sh`. Folds all 3 outputs into single `additionalContext` via `hookSpecificOutput` wrapper. Requires `jq` (silent no-op if missing).
- **`precompact-backup.sh`** (33 lines) — copies `docs/STATUS.md`, `docs/SESSION_LOG.md`, `CLAUDE.md` to `.claude/agent-memory/precompact-backups/<filename>.<UTC-timestamp>`. agent-memory/ is gitignored. No deps beyond POSIX.
- **`sessionend-observe.sh`** (33 lines) — writes timestamp to `.claude/observations/.session-ended` marker + appends `<!-- session-end: TIMESTAMP -->` to `docs/SESSION_LOG.md`. Anchor for session-observer's next scan window.
- **`pretooluse-bash-safety.sh`** (86 lines) — reads stdin PreToolUse JSON, blocks Bash commands matching destructive patterns via `.claude/lib/destructive-bash-patterns.sh`. Emits `permissionDecision: allow|deny` JSON. Fail-closed if lib missing, jq missing, JSON malformed.
- **`pretooluse-powershell-safety.sh`** (96 lines) — mirror of bash-safety but for PowerShell. Uses `.claude/lib/destructive-powershell-patterns.sh`. Case-insensitive matching via `shopt -s nocasematch`. Phase 21 addition.

### Hook entries in `settings.json` (dogfood)

| Event | Matcher | Script | `type: command`? | Mirror status | Purpose |
|---|---|---|---|---|---|
| PreCompact | `auto` | `bash $CLAUDE_PROJECT_DIR/.claude/hooks/precompact-backup.sh` | ✓ | Both | Back up critical docs before auto-compact. |
| PreToolUse | `Bash` | `bash $CLAUDE_PROJECT_DIR/.claude/hooks/pretooluse-bash-safety.sh` | ✓ | Both | Block destructive Bash commands. |
| PreToolUse | `PowerShell` | `bash $CLAUDE_PROJECT_DIR/.claude/hooks/pretooluse-powershell-safety.sh` | ✓ | Both | Block destructive PowerShell commands. |
| SessionStart | (none) | `bash $CLAUDE_PROJECT_DIR/.claude/hooks/sessionstart-rules.sh` | ✓ | Both | Re-inject durable rules; surface drift; surface watchdog signals. |
| SessionStart | (none) | `bash $CLAUDE_PROJECT_DIR/.claude/scripts/cruft-check.sh --hook` | ✓ | **DOGFOOD ONLY** | Run cruft-checker with 24h cooldown. |
| SessionStart | (none) | `bash $CLAUDE_PROJECT_DIR/.claude/scripts/plugin-quality-check.sh --hook` | ✓ | Both | Run plugin-quality-check with 24h cooldown. |
| SessionEnd | (none) | `bash $CLAUDE_PROJECT_DIR/.claude/hooks/sessionend-observe.sh` | ✓ | Both | Record session boundary for session-observer. |

### Hook entries in `settings.json.template` (template)

Identical to dogfood EXCEPT the dogfood-only cruft-check.sh SessionStart entry is absent. Template has 2 SessionStart entries (sessionstart-rules + plugin-quality-check); dogfood has 3.

All entries carry `type: "command"` — heuristic viii compliance verified Phase 16. Hook entries documented per `docs/HOOK_SCHEMA.md` (canonical source: <https://docs.claude.com/en/docs/claude-code/hooks>).

`docs/HOOK_SCHEMA.md` is the local reference. It validates `type: "command"` + non-empty `command` field — what cruft-check.sh heuristic viii AND plugin-quality-check.sh heuristic ii enforce.

### Hooks README

`.claude/hooks/README.md` + `template/.claude/hooks/README.md` (byte-identical, 39 lines): explains why PostToolUse / SubagentStop are NOT shipped (user-level settings.json `hooks` blocks shadow project-level — silent failure mode); recommends wrapper-script pattern (commit.sh, deploy.sh) instead.

---

## Section 7: Lib files

2 lib files, mirrored byte-identical between `.claude/lib/` and `template/.claude/lib/`. Single source of truth for destructive-pattern arrays (Phase 24 refactor extracted from inline declarations in hook scripts).

### `destructive-bash-patterns.sh`

- **File path:** `.claude/lib/destructive-bash-patterns.sh` (23 lines) + template mirror byte-identical
- **Purpose:** Sources the `DESTRUCTIVE_BASH_PATTERNS` bash array — 6 POSIX ERE regex patterns covering 10 destructive shapes.
- **Patterns:** rm -rf / git push --force (long+short) / git reset --hard origin/ / chmod -R 777 / (curl|wget) ... | (bash|sh) pipe-to-shell.
- **Consumers:**
  - `template/.claude/hooks/pretooluse-bash-safety.sh` (real-time blocking).
  - `.claude/hooks/pretooluse-bash-safety.sh` (real-time blocking, dogfood mirror).
  - `template/.claude/scripts/plugin-quality-check.sh` heuristic iii (retrospective audit).
  - `.claude/scripts/plugin-quality-check.sh` heuristic iii (retrospective audit, dogfood mirror).
- **Mirror status:** both — byte-identical.

### `destructive-powershell-patterns.sh`

- **File path:** `.claude/lib/destructive-powershell-patterns.sh` (27 lines) + template mirror byte-identical
- **Purpose:** Sources the `DESTRUCTIVE_POWERSHELL_PATTERNS` bash array — 8 POSIX ERE patterns, case-insensitive (consumers enable `shopt -s nocasematch`).
- **Patterns:** Remove-Item -Recurse -Force (aliases ri/rm/del/erase, short flags -r/-f either order) / Format-Volume / Clear-Disk / Set-ExecutionPolicy Unrestricted|Bypass / (Invoke-WebRequest|iwr|curl|wget) ... | (Invoke-Expression|iex) / git push --force / git reset --hard origin/.
- **Consumers:** same shape as bash variant — both `pretooluse-powershell-safety.sh` hooks + both `plugin-quality-check.sh` heuristic iii.
- **Mirror status:** both — byte-identical.

---

## Section 8: Schemas

3 schema docs in `template/.claude/agents/05_meta/` (and dogfood mirrors — byte-identical). Schemas live as `*.schema.md` files alongside their owning agent.

### `session-observer.schema.md`

- **File path:** `.claude/agents/05_meta/session-observer.schema.md` (120 lines) + template mirror byte-identical
- **Field count and field names (9 required + 1 conditional):**
  - `pattern_id` (string, 64-char lowercase hex) — required
  - `source` (string enum, extensible) — required
  - `pattern_type` (string enum, extensible) — required
  - `occurrences` (integer ≥ 2) — required
  - `first_seen` (ISO-8601 UTC string) — required
  - `last_seen` (ISO-8601 UTC string) — required
  - `resolved_at` (ISO-8601 UTC string OR null) — required (Phase 12 extension)
  - `evidence` (array of event objects with `timestamp` / `kind` / `summary` / `tool_name?` / `args_redacted?`) — required, capped at 20 entries
  - `confidence` (string enum: `low` | `med` | `high`) — required
  - `notes` (string ≤ 120 chars) — conditional (required when `pattern_type == "other"`)
- **Field constraints:**
  - `source` enum: `session-observer`, `task-watchdog`, `manual`, `other`, `cruft-checker`, `code-quality-auditor`.
  - `pattern_type` enum: `repeated_command`, `repeated_edit`, `error_resolution`, `recurring_failure`, `other`, `plugin_quality`.
  - `pattern_id` = SHA-256 of `pattern_type + normalized_signature`.
- **Producers (4):** `session-observer`, `task-watchdog`, `cruft-checker`, `code-quality-auditor`.
- **Consumers (1+ planned):** `workflow-suggester` (v1.1+). Planned: v2.0 plugin-recommendation system, v1.2+ `manager-optimizer`.

### `workflow-suggester.schema.md`

- **File path:** `.claude/agents/05_meta/workflow-suggester.schema.md` (148 lines) + template mirror byte-identical
- **Field count and field names (7 required + 1 optional = 8 total in YAML frontmatter; body has 4 prose sections):**
  - `capture_id` (string, 64-char lowercase hex; default `capture_id == source_pattern_id`) — required
  - `source_pattern_id` (string, 64-char lowercase hex) — required
  - `source_pattern_type` (string enum, copied from observation) — required
  - `status` (string enum: `draft` | `approved` | `shipped` | `rejected`) — required
  - `confidence` (string enum: `low` | `med` | `high`) — required
  - `suggested_artifact_type` (string enum, extensible) — required
  - `created_at` (ISO-8601 UTC string) — required
  - `shipped_to` (project-relative path string) — optional (set by user after promote when `status: shipped`)
- **Field constraints:**
  - `suggested_artifact_type` enum (9 values): `script`, `skill`, `agent`, `command`, `manual_action`, `unclear`, `doc-fix`, `infrastructure-fix`, `lesson`.
  - Body 4 sections (prose, not frontmatter): `# Capture: <slug>` / `## Pattern` / `## Evidence` / `## Suggested response` / `## Approving / rejecting`.
- **Producers (1):** `workflow-suggester`.
- **Consumers:** `script-builder` (v1.1+ Phase 3, filters to `status: approved AND suggested_artifact_type: script`). Future X-builders (`skill-builder`, `agent-builder`, `command-builder`) are cut per ROADMAP § Cuts. `doc-fix` / `infrastructure-fix` / `lesson` resolved manually (no X-builder).

### `script-builder.schema.md`

- **File path:** `.claude/agents/05_meta/script-builder.schema.md` (213 lines) + template mirror byte-identical
- **Field count and field names:** N/A — this schema documents a **5-section bash discipline**, not a frontmatter schema. Each generated draft script under `.claude/scripts/drafts/<source_pattern_id>.sh.draft` has 5 sections in order: (1) Shebang + strict mode, (2) Constants / config, (3) Helpers, (4) Main logic, (5) Cleanup / error handling / exit.
- **Constraints:**
  - `set -uo pipefail` floor (non-negotiable per plugin discipline rule 6).
  - `set -e` when halting on first error.
  - `trap '...' ERR` when mutating state.
  - Path-shape guards on inputs (CLAUDE_PROJECT_DIR validation; first-arg shape rejection; prereq-file existence; prereq-dir existence; command -v for non-POSIX binaries).
  - bash-safety conventions for any recursive scan (noise-path excludes, timeout, -maxdepth, no naked `&`).
  - Draft-header comment block linking back to source capture + promote instructions.
  - Length target: 30–80 lines per draft.
  - Filename: `<source_pattern_id>.sh.draft` (the `.sh.draft` suffix is intentional — can't be accidentally executed).
- **Producers (1):** `script-builder`.
- **Consumers:** user reviews + manually promotes (rename + chmod +x + flip capture status to shipped). No automatic downstream consumer.

---

## Section 9: Captures + observations infrastructure

### Storage paths

- **`.claude/captures/`** (dogfood) — directory present, contains only `.gitkeep` + `README.md` (3391 bytes). **Zero actual capture files committed.**
- **`.claude/observations/`** (dogfood) — directory present, contains `.gitkeep` + `.session-ended` (21 bytes — currently exists, written by SessionEnd hook 2026-05-17T14:02 per filesystem mtime) + `README.md` (2421 bytes) + **~90 runtime `.json` observation files (gitignored per `.gitignore`).** These accumulate from session-observer / task-watchdog / cruft-checker / code-quality-auditor over dogfood usage; not part of the repo's tracked tree.
- **`template/.claude/captures/`** — directory present, contains only `.gitkeep` + `README.md` (3391 bytes — byte-identical to dogfood mirror).
- **`template/.claude/observations/`** — directory present, contains only `.gitkeep` + `README.md` (2421 bytes — byte-identical to dogfood mirror).
- **`.claude/scripts/drafts/`** (dogfood) + **`template/.claude/scripts/drafts/`** — both contain only `.gitkeep` + `README.md`. Zero actual `.sh.draft` files committed.

### Lifecycle states

**Capture lifecycle** (workflow-suggester.schema.md § Status semantics):
- `draft` — workflow-suggester sets on creation. X-builders skip.
- `approved` — user manually edits. X-builders pick up.
- `shipped` — user manually edits after promote. X-builders skip. Accompanied by `shipped_to:` field with promoted-artifact path.
- `rejected` — user manually edits. Do-not-re-suggest marker. File persists indefinitely.

All four statuses count as "already considered" for workflow-suggester idempotency. To re-open a rejected pattern: delete the file, re-dispatch.

**Observation lifecycle** (`resolved_at` semantics per session-observer.schema.md):
- Set by producer, NOT user.
- `null` on every new emission and re-emission (regression-reset).
- Timestamp written by producer's resolve pass when its scan no longer detects the pattern.
- Resolution-pass behavior is producer-specific:
  - `cruft-checker` → **full resolve pass** (scope covers entire skeleton on every scan; absence is meaningful).
  - `task-watchdog` → **session-bounded** (each scan covers one prior session; absence not meaningful; older observations stay `null` indefinitely — intentional).
  - `session-observer` → **scoped resolve pass** (within current scan window).
  - `code-quality-auditor` → **full resolve pass** (every scan covers every installed plugin).

Resolved observations stay on disk (audit trail). Consumers filter by `resolved_at != null` → skip when drafting captures. v2.0 `manager-optimizer` is eventual pruning surface.

### Filename conventions

- Observation: `<pattern_id>.json` where `pattern_id = SHA-256(pattern_type + normalized_signature)`.
- Capture (default): `<source_pattern_id>.md` (matches observation pattern_id — direct idempotency).
- Capture (v1.1.4 deviation for code-quality-auditor `plugin_quality`): `plugin-quality-<plugin-name>-<heuristic-id>.md` for at-a-glance browsing. Idempotency still preserved via frontmatter `source_pattern_id` field, not filename.
- Draft script: `<source_pattern_id>.sh.draft` — the `.sh.draft` suffix prevents accidental execution.
- Promoted script: `<descriptive-name>.sh` chosen by user (kebab-case lowercase).

### Idempotency mechanisms

- **workflow-suggester:** greps all `.md` files in `.claude/captures/` for `^source_pattern_id:` frontmatter; skips observations whose pattern_id appears in any capture (any status).
- **script-builder:** checks for existing `.claude/scripts/drafts/<source_pattern_id>.sh.draft` filename; skips if present.
- **session-observer:** re-observation of same pattern_id → bumps `occurrences`, appends to evidence (capped at 20), updates `last_seen`. Pattern_id is stable across re-observations.
- **task-watchdog:** marker file `.claude/observations/.last-watchdog-session` holds last-processed JSONL `sessionId`. Same sessionId → exit silent.
- **cruft-checker:** 24h cooldown marker `.claude/.last-cruft-check` (epoch seconds) — only enforced when `--hook` flag passed.
- **code-quality-auditor:** 24h cooldown marker `.claude/.last-plugin-quality-check` (epoch seconds) — only enforced when `--hook` flag passed.

---

## Section 10: Settings + permissions

### `.claude/settings.json` (dogfood, 89 lines)

- **`model`:** `opusplan`
- **`permissions.defaultMode`:** `plan`
- **`permissions.allow` (11 entries):** `Bash`, `PowerShell`, `Edit`, `Write`, `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `NotebookEdit`, `Agent`.
- **`compactPrompt`:** resolved string (the durable rules block: "TWO .claude/ dirs exist…" + Template files use .template suffix + Non-destructive install + Plan before structural changes + Verify file existence). Currently mirrors `CLAUDE.md` `## Where things live` discipline.
- **`hooks`** (cross-reference Section 6 — 7 entries total: 1 PreCompact + 2 PreToolUse + 3 SessionStart + 1 SessionEnd).
- **Documented intentional drift vs template:** `defaultMode: plan` (template has `default`); `compactPrompt` resolved (template has `{{COMPACT_PROMPT}}` placeholder); 3rd SessionStart entry runs `bash .claude/scripts/cruft-check.sh --hook` (template has only 2 SessionStart entries — cruft-check is dogfood-only).

### `template/.claude/settings.json.template` (template, 81 lines)

- **`model`:** `opusplan`
- **`permissions.defaultMode`:** `default`
- **`permissions.allow` (11 entries):** identical set to dogfood.
- **`compactPrompt`:** `{{COMPACT_PROMPT}}` placeholder. project-tuner-helper fills at install.
- **`hooks`** (cross-reference Section 6 — 6 entries: 1 PreCompact + 2 PreToolUse + 2 SessionStart + 1 SessionEnd).
- **Documented intentional drift vs dogfood:** see above (same 3 categories from dogfood's perspective).

### Permission allow patterns

Both files allow the same 11 bare-tool identifiers (no command-pattern grants like `Bash(git status:*)` — that's a deliberate choice; bare allows are simpler and rely on PreToolUse safety hooks for destructive-pattern blocking).

The `settings.local.json` file (user-level, gitignored) accumulates "Always allow" Bash command-pattern grants per session. See handoff loose-ends "Unresolved Bash-growth mystery in `settings.local.json`" for the v1.1.4 inventory of 12 grants from pre-Phase-14d residue.

---

## Section 11: Install / update infrastructure

### `scripts/install.sh` modes + flags

- **Modes (`--mode=`):**
  - `fresh` — refuses unless target `.claude/` is empty (only `.gitkeep` allowed). Then copies everything.
  - `merge` (default) — copies only missing files. Skips silently when target has the file.
  - `replace` — overwrites existing files. Requires `--force` AND interactive `YES` confirmation.
- **Flags:** `--source` (skeleton checkout path, auto-detected from script location by default), `--target` (target project path), `--claude-only` (skip top-level files like CLAUDE.md), `--dry-run`, `--force` (required for `replace`), `--help`.
- **Top-level safety:** files outside `.claude/` (CLAUDE.md, README, .gitignore, etc.) are NEVER overwritten by install.sh regardless of mode. Re-running install never clobbers project-level docs.

### `scripts/update.sh` classification logic (six-way)

| Class | Meaning | Default action |
|---|---|---|
| `UNCHANGED` | Recorded hash == current == template | Skip silently |
| `TEMPLATE_UPDATED` | You haven't touched it; template moved on | `[A]pply all / [R]eview / [S]kip all` |
| `LOCALLY_MODIFIED` | You've changed it since install | Per-file prompt, default `[K]eep`. NEVER auto-updated. |
| `NEW` | Template has it; you don't | `Copy all? [Y/n]` |
| `ORPHAN` | You have it (in marker); template no longer ships it | `Delete? [y/N]`. NEVER auto-deleted. |
| `LOCAL_MATCHES_TEMPLATE` | Recorded hash differs from current+template (which match) — local edit then accidentally re-matched template | Reconcile silently |

`--auto-apply` accepts `TEMPLATE_UPDATED` + `NEW` only. Top-level files are not updated by update.sh — re-run install.sh manually.

### `scripts/update.sh` flags

- `--source <path>` — local skeleton checkout (auto-clones from `SKELETON_REPO_URL` if absent).
- `--target <path>` — target project root.
- `--auto-apply` — auto-accept TEMPLATE_UPDATED + NEW.
- `--dry-run` — classify but don't write.
- `--check-remote` — runs `git ls-remote --tags` (10s timeout) and writes `cached_skeleton_head` + `cached_skeleton_head_fetched_at` to marker. No diff/classification in this mode.
- `--help`.

### `.skeleton-version` marker fields + schema

JSON marker at `.claude/.skeleton-version`. Per `docs/INSTALLATION.md` § "Per-file hashes" + § "Drift cache":

- `version` (semver string, e.g. `"1.1.4"`) — installed skeleton version.
- `commit` (git SHA at install time) — skeleton checkout commit.
- `installed_at` (ISO-8601 UTC) — when install.sh wrote the marker.
- `mode` (`fresh` | `merge` | `replace`) — install.sh mode used.
- `claude_only` (bool) — whether `--claude-only` was passed.
- `source` (path string) — resolved skeleton source path.
- `updated_at` (ISO-8601 UTC, optional) — when update.sh last touched the marker.
- `cached_skeleton_head` (semver string | null) — last known remote release. Populated only by `update.sh --check-remote`. `null` on fresh installs.
- `cached_skeleton_head_fetched_at` (ISO-8601 UTC | null) — when cache was last refreshed.
- `files` (object: `<relpath>` → `<sha256>`) — per-file install-time hashes. The map keys are paths relative to `.claude/`; values are 64-char lowercase hex SHA-256 of the file at install time.

Pre-0.8.0 marker format (shell-export style) backfills to JSON on first update.sh run with a prominent warning. <!-- cruft-check:exempt-historical -->

### Hash-generation script invocations

`install.sh` detects SHA-256 command at startup — `sha256sum` (Linux/Git Bash) or `shasum -a 256` (macOS). Hashes every `.claude/` file it writes and records `<relpath><TAB><sha256>` entries in `INSTALLED_HASHES` array, then serializes to the `files` object via Python (`python` or `python3` on PATH).

`update.sh` uses three hashes per file — recorded-at-install (from marker `files`), current-on-disk (recompute), current-in-template (recompute) — to classify into the six categories above. macOS bash 3.2 compatibility via `MARKER_HASH_ENTRIES` parallel-arrays map emulation (no `declare -A`).

### Documented edge cases

Per `docs/INSTALLATION.md` § FAQ + `claude-skeleton-handoff.md` loose-ends:

- `LOCALLY_MODIFIED` never auto-updated — explicit input always required.
- `ORPHAN` never auto-deleted — explicit input always required.
- `NEW_IN_TEMPLATE` covered by `NEW` classification.
- Top-level files never updated by `update.sh` — separate manual re-install path.
- `uninstall.sh` not yet shipped — deferred per handoff loose-end (no production demand from TV / EoG).
- Backfill mode for pre-0.8.0 markers — `BACKFILL_MODE=true` on shell-format detect, emits prominent warning. <!-- cruft-check:exempt-historical -->

---

## Section 12: CI

### Workflow files in `.github/workflows/`

- **`ci.yml`** (65 lines) — single workflow file.

### Platforms × scenarios matrix

- **Platforms:** `ubuntu-latest`, `windows-latest`, `macos-latest` (3 OS, `fail-fast: false`).
- **Scenarios** (6, run on each OS):
  1. `fresh-install`
  2. `fresh-refuse`
  3. `merge-add`
  4. `local-mod-detect`
  5. `local-mod-preserve`
  6. `backfill-migrate`
- **Total matrix:** 3 OS × 6 scenarios = 18 scenario runs per CI invocation.

Plus two help-only smoke steps per OS: `bash scripts/install.sh --help >/dev/null` and `bash scripts/update.sh --help >/dev/null`.

Setup steps (per OS): `actions/checkout@v4`, `actions/setup-python@v5` (Python 3.11), environment show (`uname -a`, `python --version`, sha256sum/shasum presence check, bash version).

### What each scenario verifies

Scenarios are implemented in `.github/test-fixtures/scenarios.sh` (single file). Per scenario name:

- `fresh-install` — `install.sh --mode=fresh` succeeds against empty target; verifies file count matches expected baseline (most recent CHANGELOG entry references `verify_marker 45` — adjusted at each phase).
- `fresh-refuse` — `install.sh --mode=fresh` refuses against non-empty target.
- `merge-add` — `install.sh --mode=merge` (default) adds missing files without touching present ones.
- `local-mod-detect` — `update.sh` correctly classifies a locally-edited file as `LOCALLY_MODIFIED`.
- `local-mod-preserve` — `update.sh` does NOT auto-update `LOCALLY_MODIFIED` files even with `--auto-apply`.
- `backfill-migrate` — `update.sh` correctly backfills a pre-0.8.0 shell-format marker to JSON, with warning. <!-- cruft-check:exempt-historical -->

`scenarios.sh` is the contract; CI calls it with the scenario name as `$1`.

---

## Section 13: Docs

### `docs/` (8 files)

- **`docs/PHILOSOPHY.md`** (97 lines) — Design principles: MWP/ICM origins (canonical sources, one-way dependencies, section-routing, scripts for mechanical work); manager + helper architecture; tier system. Audience: anyone evaluating the design before adopting. Last meaningful update: pre-v1.1.0 (foundational doc). <!-- cruft-check:exempt-historical -->
- **`docs/ARCHITECTURE.md`** (183 lines) — Project layout, two-`.claude/` distinction, install flow. Audience: developers working on the skeleton. Last meaningful update: tracks Phase 4-era setup; minor refreshes at Phase 4d / 4f for placeholder list + tuner flow.
- **`docs/INSTALLATION.md`** (280 lines) — Install / update / uninstall how-to + per-file-hash mechanism + `--check-remote` drift cache. Audience: skeleton users (target-project owners). Last meaningful update: tracked with each install/update mechanism change; backfill section added at 0.8.0; drift cache section added at v1.1+ Phase 4. EXEMPT_VFILES per cruft-check.sh (historical version refs throughout). <!-- cruft-check:exempt-historical -->
- **`docs/HOOK_SCHEMA.md`** (50 lines) — Reference doc summarizing the Claude Code hook schema that cruft-check.sh heuristic viii + plugin-quality-check.sh heuristic ii validate. Canonical source link to <https://docs.claude.com/en/docs/claude-code/hooks>. Audience: anyone adding a new hook. Created Phase 16 (cruft-checker heuristic viii rollout).
- **`docs/STORY.md`** (79 lines) — Narrative doc — what the skeleton is, why it exists (ADHD + LLM-collaboration generalisation), how it works (four layers), how to use it, where it's heading. Audience: peer-level discoverers. EXEMPT_VFILES per cruft-check.sh (legitimate historical version refs).
- **`docs/SESSION_LOG.md`** (116 lines) — Per-session entry log. Forward-chronological. Most recent boundary: `<!-- session-end: 2026-05-17T18:02:38Z -->`. Audience: monitoring-helper and human retro. Most recent meaningful entry: `## 2026-05-13 — Phase 4a: foundation` (per session-start hook display); ~16 session-end boundary markers follow. EXEMPT_VFILES per cruft-check.sh.
- **`docs/ROADMAP.md`** (330 lines) — Canonical durable spec for v1.1+ / v1.2.0 / v2.0 sequencing + Locked architectural principles (6 H3s, post the principles-extraction commit). H2 sections: `## v1.0 — shipped` / `## v1.1+ — the capture / reuse loop` / `## v1.1.5+ pre-pinball queue` (the pre-pinball queue commit addition) / `## v1.2.0 — meta-evolution release` / `## Locked architectural principles` / `## v2.0 — plugin ecosystem layer` / `## v3.0+ / future-future` / `## Cuts — rationale for what's not in the queue` / `## Dependency graph (updated)` / `## Closing — scope discipline`. EXEMPT_VREGION_FILES per cruft-check.sh (V-headings auto-exempt their region).
- **`docs/CHANGELOG.md`** (187 lines after the pre-pinball queue commit) — Version history, Keep a Changelog format. EXEMPT_VFILES per cruft-check.sh. Current top entries: `## [Unreleased]` (2 doc-shuffle bullets from the principles-extraction commit + the pre-pinball queue commit); `## [1.1.4] - 2026-05-17 — Plugin-verification surface open`.

### Repo-root docs (5 files)

- **`README.md`** (69 lines) — User-facing intro. Status line: "v1.1.4 — plugin-verification surface open" (cruft-check exempt-historical marker). Status section / What it is / Problem / Concept / Design principles / What ships at v1.1.4 / Documentation index / License. Last meaningful update: v1.1.4 release cut (Phase 25 swept agent count 14→15 + script count 4→5; Phase 24 README:52 stale-v1.1.3 fix). <!-- cruft-check:exempt-historical -->
- **`ROUTING.md`** (36 lines) — see Section 1 (directive layer). Routing table only; no other sections.
- **`CLAUDE.md`** (34 lines) — see Section 1 (directive layer).
- **`CLAUDE_MANAGER.md`** (281 lines) — see Section 1 (directive layer). EXEMPT_VFILES per cruft-check.sh (intentional v1.1.x scope annotations on producer/consumer descriptions).
- **`claude-skeleton-handoff.md`** (322 lines) — Sprint-state / chat-onboarding snapshot. H2 sections: TL;DR / Architecture state / Sprint progress / Recently shipped / Cuts / Locked architectural principles (6 + "Other principles" + "Sprint rules locked in v1.1+") / Loose ends / queued items / What's next. EXEMPT_VREGION_FILES per cruft-check.sh. Last meaningful update: the v1.1.4 handoff refresh commit (commit 625c83e — "refresh through v1.1.4 — add Phase 24/25 + single-source-of-truth principle").

### Cross-references

- `README.md` links → `docs/PHILOSOPHY.md`, `docs/ARCHITECTURE.md`, `docs/INSTALLATION.md`, `docs/ROADMAP.md`, `docs/CHANGELOG.md`.
- `CLAUDE.md` references `CLAUDE_MANAGER.md` + `ROUTING.md`.
- `CLAUDE_MANAGER.md` references `.claude/skills/bash-safety/SKILL.md`, `.claude/agents/05_meta/session-observer.schema.md`, `docs/ROADMAP.md`, multiple .schema.md files via §-anchor.
- `docs/ROADMAP.md` references `CLAUDE_MANAGER.md.template` (plugin marketplace composition section).
- `docs/HOOK_SCHEMA.md` referenced by `cruft-check.sh` heuristic viii + `plugin-quality-check.sh` heuristic ii + `code-quality-auditor.md`.
- `claude-skeleton-handoff.md` references `docs/ROADMAP.md` § Locked architectural principles (the principles-extraction commit cross-doc move).
- Schema docs (`*.schema.md`) referenced by their owning agent + by consumers (workflow-suggester.md → session-observer.schema.md, script-builder.md → script-builder.schema.md, etc.).

Template-only docs (not installed elsewhere): `template/PLUGINS.md.template`, `template/docs/STATUS.md.template`, `template/docs/SESSION_LOG.md.template`, `template/docs/ARCHITECTURE.md.template`, `template/.gitignore.template`.

---

## Section 14: Plugin verification surface (v1.1.4)

### `code-quality-auditor.md` agent location + heuristics

- **Agent path:** `.claude/agents/05_meta/code-quality-auditor.md` (112 lines) + `template/.claude/agents/05_meta/code-quality-auditor.md` (byte-identical mirror).
- **Heuristics (3 in v1.1.4 scope):**
  - **(i) Manifest path missing or empty** — `plugin.json`'s `components` block declares a path (e.g. `commands/`, `hooks/`) but the directory doesn't exist OR contains no files matching the expected extension (`.md` for commands/agents/skills, `hooks.json` for hooks). Confidence: `high`.
  - **(ii) Hooks present but `hooks.json` malformed** — when plugin contains `hooks/` directory, validate `hooks.json` against canonical Anthropic hook schema (`type: "command"` + non-empty `command` field per `docs/HOOK_SCHEMA.md`). Catches missing fields, parse errors, empty `hooks` blocks. Reuses validation logic from `cruft-check.sh` heuristic viii. Confidence: `high`.
  - **(iii) Destructive shell pattern against unguarded path** — walks plugin's `.sh` / `.ps1` / `.bash` scripts. Applies destructive-pattern regex sets from `.claude/lib/destructive-{bash,powershell}-patterns.sh` (shared with PreToolUse hooks — single source of truth). Emits when destructive pattern targets unguarded path (`/`, `~`, `~/`, `$HOME`) rather than project-scoped variable or relative path. Confidence: `med` (regex match has modest FP risk).

Semantic checks (fitness vs description, license compliance, network-call detection, suspicious dependency graph) are **deferred to v2.0** per ROADMAP — they fold into plugin-recommendation discipline alongside `integration-checker` (planned Layer 1+2).

### `plugin-quality-check.sh` location + plugin path resolution

- **Script path:** `.claude/scripts/plugin-quality-check.sh` (429 lines) + `template/.claude/scripts/plugin-quality-check.sh` (byte-identical mirror). 5-section bash wrapper around inline Python helper.
- **Plugin path resolution:**
  - Default: `$DEFAULT_PLUGIN_DIR = $HOME/.claude/plugins/cache`
  - Override: `--plugin-dir <path>` flag (for synthetic testing).
  - Walks `<plugin_dir>/<marketplace>/<plugin>/<version>/` tree, processing each plugin in turn.
  - Per-plugin reads: `<plugin>/.claude-plugin/plugin.json` (required manifest); declared component directories (`commands/`, `agents/`, `skills/`, `hooks/`, `scripts/`); `<plugin>/hooks/hooks.json` when present.
- **Missing plugin cache:** the common case (no plugins installed). Agent emits zero observations and exits clean.

### Synthetic-plugin verification approach (Phase 24)

Per CHANGELOG entry for v1.1.4 and handoff loose-end "Windows Git Bash /tmp path gotcha": Phase 24 verified each of the 3 heuristics catches its target case by creating synthetic plugin fixtures (a plugin with missing component path; a plugin with malformed hooks.json; a plugin with destructive shell patterns against unguarded paths). Used `--plugin-dir` to point the script at the synthetic fixture.

Known gotcha (Windows-only, synthetic-test): Git Bash POSIX path `/tmp/tmp.XXXX` confuses Windows Python's `os.path.normpath` (slashes get converted, path resolves wrong). Production path `~/.claude/plugins/cache/` works via `os.path.expanduser`. For synthetic tests on Windows, use `$env:TEMP\<dir>` or `C:\tmp\<dir>`.

### Real-world plugin scan results (Phase 25)

Per the v1.1.4 release commit (2a0caf6) message:

- 1 real installed plugin: `42crunch-api-security-testing@1.0.1`.
- All 3 heuristics: **clean** (0 findings).
- Phase 24's synthetic-plugin verification already proved each heuristic catches its target case; Phase 25 was the first real-world pass.

---

## Section 15: Locked principles inventory

Cross-reference of "locked" principle content across the three load-bearing surfaces.

### `docs/ROADMAP.md` § Locked architectural principles (6 H3s — post the principles-extraction commit)

1. **Multi-project graduation** — pattern graduates from one project's `.claude/` to `template/` when crossing 4-part threshold (≥66% of installs, min 3 projects, ≥4 weeks stable, zero negative observations). v1.2+ mechanism via `meta-session-observer` + `template-promoter`.
2. **Two distinct audit surfaces** — project-level (`infrastructure-auditor` in `template/`) vs skeleton-level (`roadmap-auditor` in dogfood only). Both via `/goals` expanded `schedule` field.
3. **Captures-surface enum stability** (added the principles-extraction commit from handoff) — `suggested_artifact_type` enum has 9 stable values: 6 baseline + 3 v1.1.x additions (`doc-fix`, `infrastructure-fix`, `lesson`). Prefix-routing convention for new values. Defer producer + X-builder until grounding data exists.
4. **Model C lesson codification** (added the principles-extraction commit) — lessons codify directly into directive surface (CLAUDE_MANAGER.md, docs/ROADMAP.md, claude-skeleton-handoff.md). NOT a separate lessons-log doc. Model A (captures-as-library) and Model B (parallel LESSONS.md) explicitly considered and cut.
5. **Billing-pool design constraint for v1.2.0** (added the principles-extraction commit) — scheduled mechanisms in v1.2.0 must fire via **SessionStart hooks**, NOT cron + `claude -p`. Why: Anthropic subscription billing splits subscription-pool from API-pool quota on 2026-06-15.
6. **Single source of truth for safety patterns** (added the principles-extraction commit) — destructive-pattern arrays live in `.claude/lib/destructive-{bash,powershell}-patterns.sh`, sourced by real-time blocking hooks AND retrospective audit (heuristic iii). Hook-schema validation is currently duplicated between cruft-check.sh viii + plugin-quality-check.sh ii — acceptable because canonical reference is small + stable.

### `claude-skeleton-handoff.md` § Locked architectural principles (6 + auxiliary)

Same 6 principles as ROADMAP (in same order, mostly verbatim — handoff is the original; ROADMAP was the the principles-extraction commit extraction). Plus:

- **Other principles (in custom-instructions, not re-derived here)** — 5 listed:
  - Ever-evolving being, not a fixed install.
  - Approval-gated autonomy — thinking is autonomous, action is approved.
  - Define-everything-upfront — brief specs lock interpretations before code.
  - Narrow-scope-by-design — each phase locks scope at brief time.
  - Composition, not competition — composes with `/plugin` marketplace + 7 community libraries.
- **Sprint rules locked in v1.1+** — 7 rules with **Why:** / **How to apply:** structure:
  1. Sweep known doc-rot at release cuts; don't defer to cruft-checker.
  2. Don't ship retrospective signals that need a Claude Code surface that doesn't exist yet.
  3. Empirical audit before trusting diagnosis.
  4. Prefix-routing mechanism for new enum values.
  5. Pre-existing drift gets fixed during related edits.
  6. Release-cut sweep findings get dispositioned, not just fixed.
  7. Co-Authored-By trailer convention (`Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`).

### `CLAUDE_MANAGER.md` (& `.template`)

No section labeled "Locked architectural principles" — but several sections carry locked-rule semantics:

- **`## Strategic judgment patterns`** with 11 H3 rules (Dispatch helper vs read; Escalate vs propose; Question framing vs execute; Plan amendment behavior; Invoke /goals vs ship direct; Apply integration-checker; Apply bash-safety; Model selection; When to consult observations; When to dispatch [each of 5 capture/reuse loop agents]).
- **`## Plugin marketplace composition`** with locked design principle "Don't be a directory; be a quality filter." (verbatim quote).
- **`## Plugin discipline`** with 8 numbered rules (no silent hook installs; no outbound network at hook time; local modifications recorded; no secrets; conflicts fail closed; plugin shell scripts run under set -uo pipefail minimum; promotion is manual; drift reviewed on demand).
- **`## Dogfood mirror invariants`** — locked mirror parity rule (template-root files have byte-identical dogfood mirrors except resolved placeholders; dogfood-only artifacts are exempt per phase brief).
- **`## Three-commit cadence`** with locked A/B/C rhythm + small-fix/medium/large-overhaul rubric.

### Drift between handoff and ROADMAP versions

- **Verbatim alignment:** 6 principles in ROADMAP are content-identical to handoff (the principles-extraction commit's "preserve verbatim" rule was honored modulo opener-drop + `(see Cuts)` drop in Model C).
- **Coverage drift:** handoff has 11 additional locked items not in ROADMAP (5 "Other principles" + 7 "Sprint rules"). These are intentionally NOT extracted to ROADMAP per the principles-extraction commit scope — sprint rules and Phase-N references are operational/sprint-state, not architectural-spec material. Audit-priority question: should any of the 7 sprint rules graduate to ROADMAP, or to CLAUDE_MANAGER?
- **Auxiliary "Other principles" content** likely already covered by CLAUDE_MANAGER strategic judgment + tier-system + dogfood-mirror sections — possible doc-rot to flag.

### Principles in handoff/CLAUDE_MANAGER that arguably should be in ROADMAP

Per the principles-extraction commit scope, NOT extracted (decisions deferred):
- The 7 sprint rules (handoff). Some are operational mechanics ("Co-Authored-By trailer convention") that arguably belong in CLAUDE_MANAGER, not ROADMAP. Audit task: triage which of the 7 are architectural-spec material.
- Plugin discipline rules 1-8 (CLAUDE_MANAGER) — currently lives in directive layer; arguably architectural per "Composition, not competition" framing.
- Dogfood mirror invariant (CLAUDE_MANAGER) — operational rule with architectural implications.

---

## Section 16: Intentional drift inventory

Documented template-vs-dogfood divergences. The first three are LOCKED INTENTIONAL DRIFT per directive layer; the last three may be UNINTENTIONAL DRIFT worth audit attention.

### LOCKED INTENTIONAL (per CLAUDE_MANAGER.md § Dogfood mirror invariants)

1. **`compactPrompt` placeholder vs resolved**
   - Template: `"compactPrompt": "{{COMPACT_PROMPT}}"` in `settings.json.template`.
   - Dogfood: resolved string with the durable-rules block.
   - Mechanism: `project-tuner-helper` fills at install.

2. **`defaultMode` plan vs default**
   - Template: `"defaultMode": "default"` in `settings.json.template`.
   - Dogfood: `"defaultMode": "plan"` in `.claude/settings.json`.
   - Documented in handoff loose-ends: "Intentional — dogfood-as-meta-system needs plan-mode discipline; target projects don't necessarily."

3. **Dogfood-only artifacts**
   - `cruft-checker` agent: `.claude/agents/05_meta/cruft-checker.md` (128 lines) — NO template mirror.
   - `cruft-check.sh` script: `.claude/scripts/cruft-check.sh` (631 lines) — NO template mirror.
   - SessionStart hook entry running `cruft-check.sh --hook`: present in `.claude/settings.json` (line 62-67); absent in `settings.json.template`.
   - Locked per ROADMAP § Two distinct audit surfaces (skeleton-level audit ≠ project-level audit).
   - Repo-root CLAUDE.md / CLAUDE_MANAGER.md / ROUTING.md: dogfood-resolved forms of the `.template` counterparts. Locked drift = placeholder resolution only.

4. **Placeholder resolution drift**
   - `{{PROJECT_NAME}}` → `claude-skeleton` (CLAUDE.md, CLAUDE_MANAGER.md, ROUTING.md titles).
   - `{{PROJECT_TAGLINE}}` → "Orchestration layer on the Claude Code ecosystem." (CLAUDE.md).
   - `{{WHO_YOU_ARE_WORKING_WITH}}` → "Project owner + peers…" (CLAUDE.md).
   - `{{COMMUNICATION_STYLE}}` → ADHD-scaffolding prose (CLAUDE.md).
   - `{{CODE_STYLE}}` → bash 5-section discipline (CLAUDE.md).
   - `{{DESIGN_SYSTEM_RULES}}` → "N/A — skeleton has no rendered UI." (CLAUDE.md) + the `<!-- Remove this section… -->` comment dropped in dogfood.
   - `{{DEPLOY_COMMAND}}` → "N/A — skeleton has no deploy step…" (ROUTING.md two rows; also referenced literally in deploy.sh as `{{DEPLOY_COMMAND}}` in both dogfood + template — the dogfood deploy.sh script body still carries the literal placeholder token, intentionally non-runnable).

### POSSIBLY UNINTENTIONAL — surfaced during audit-input gen

5. **`self-audit-helper.md` template > dogfood (line count drift)**
   - `.claude/agents/05_meta/self-audit-helper.md` — 73 lines.
   - `template/.claude/agents/05_meta/self-audit-helper.md` — 92 lines.
   - Template version has extended Severity rubric: explicit HIGH / MEDIUM / LOW classification with example findings per level + "escalate if unsure" rule. Dogfood version has only one-line `high / medium / low` listing.
   - Possibly intentional (template improvement that wasn't back-mirrored) OR mirror gap.
   - Audit-priority: confirm direction (should dogfood be updated to match template? should template revert?).

6. **`project-tuner-helper.md` template > dogfood (line count drift)**
   - `.claude/agents/05_meta/project-tuner-helper.md` — 124 lines.
   - `template/.claude/agents/05_meta/project-tuner-helper.md` — 188 lines.
   - Template version has additional sections: `## Output contract` (file-based report, return-payload contract, ~300-token return cap) + `## --report-only mode` (no Edit/Write on project files, `PROPOSED:` prefix, self-audit before return).
   - Per the template agent's frontmatter description, these additions came from Phase 4f's Trainer-View migration (reports for complex pre-existing `.claude/` exceeding 100k tokens, only tail reaching the dispatcher).
   - Possibly intentional Phase 4f update to template that wasn't back-mirrored to dogfood. Possibly intentional dogfood-as-simpler-case asymmetry. Audit-priority: confirm direction.

7. **SessionStart hook entry count**
   - Dogfood `.claude/settings.json` has 3 SessionStart entries: sessionstart-rules.sh, cruft-check.sh --hook, plugin-quality-check.sh --hook.
   - Template `settings.json.template` has 2 SessionStart entries: sessionstart-rules.sh, plugin-quality-check.sh --hook.
   - Drift count = 1 (the cruft-check.sh dogfood-only entry).
   - Locked intentional per dogfood-only cruft-checker scoping.

### Documented per handoff loose-ends (informational drift)

- **`settings.local.json` Bash growth (pre-Phase-14d residue)** — 12 grants accumulated despite bash-safety returning allow. Pre-Phase-14d historical residue; CC's "Always allow" doesn't auto-prune.
- **`.skeleton-version` dogfood lag** — skeleton repo doesn't carry its own marker. Intentional (skeleton edits its own `.claude/` directly without `install.sh`).
- **bash-safety commit-message FP recurring** — Phase 21 + 24 (2 empirical data points). Hook catches destructive patterns inside `git commit -m "..."` message bodies AND heredoc payloads. Workaround: rewording / using Write tool. Low-priority maintenance.
- **Windows Git Bash `/tmp` path gotcha** — synthetic-test only, not runtime.

---

## Section 17: Outstanding items

See `claude-skeleton-handoff.md` § "Loose ends / queued items" for the canonical inventory. Items live there to avoid duplication. Categories present (counts per the v1.1.4 handoff refresh, the v1.1.4 handoff refresh commit commit 625c83e):

- Node.js 20 deprecation in CI (June 2026 watch).
- `uninstall.sh` deferred (no production demand).
- `defaultMode` mismatch (intentional, documented).
- Existing installs ready for `update.sh` to v1.1.4 (TV / EoG on v1.0 baseline; pre-pinball deferral logged in the pre-pinball queue commit ROADMAP).
- `task-watchdog` deferred signals (3 — no-progress, approval-waiting, resource anomalies).
- `handoff:136` disposition (Phase 20 marker exemption for v0.9.0 historical anchor). <!-- cruft-check:exempt-historical -->
- PreCompact + SessionEnd verification opportunistic.
- `.skeleton-version` dogfood lag.
- bash-safety commit-message FP exemption (Option 2 in handoff "What's next").
- Unresolved Bash-growth mystery in `settings.local.json`.
- Windows Git Bash /tmp path gotcha (synthetic-test only).

the pre-pinball queue commit ROADMAP `## v1.1.5+ pre-pinball queue` is the queue of buildable work + audit-gated backlog for the v1.1.4 → pinball window. Reference there for in-flight strategic items (claude-mem install, /goal-vs-/goals naming collision, /superpowers compose-vs-compete question, first-install plugin-suggestion flow, multi-session-cumulative friction detection).

---

[End of artifact]
