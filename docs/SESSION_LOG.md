# Session log — claude-skeleton

Per-session record for the claude-skeleton project itself. Reverse-chronological — newest at top.

We dogfood the convention shipped in `template/docs/SESSION_LOG.md.template`: one H2 per session, brief summary, "Changed" and "Next" footer lines, optional subheaders for in-session audits/reviews/decisions.

## 2026-05-13 — Phase 4f: validated migration on Trainer-View + tuner output-contract fix

First real-world migration: `Trainer-View` (Flutter+Firebase production app, "Forged In") adopted claude-skeleton v0.6.0 via `install.sh --mode=merge --claude-only`. Non-destructive install confirmed against a complex pre-existing `.claude/` (7 agents, 5 skills, 4 hooks, 2 scripts, 13-row ROUTING.md, hand-tuned CLAUDE.md/CLAUDE_MANAGER.md).

**Install result (TV side):**

- 12 new files added (11 baseline + `.skeleton-version`): plan-coordinator, 6 meta-agents, plugin-roster-search, token-efficiency-monitor, `/audit` command, `hooks/README.md`.
- 14 files skipped (TV's preserved): all 01-03 agents, all customized skills/scripts/hooks/commands by name clash, `settings.json`, `CLAUDE.md`, etc.
- Zero tracked-file modifications to TV's existing customizations (verified via `git diff` against `pre-claude-skeleton-migration` backup branch).
- Numbered folders coexist: `04_planning + 04_strategy`, `05_meta + 05_integration`. Discovery is glob-based, not numeric — functionally fine, visually a little awkward.
- 2 tuner recommendations applied in TV (extended frontmatter convention in `CLAUDE_MANAGER.md`; orphan-scripts acknowledgment in `hooks/README.md`).

**Bug found and fixed: Agent tool output truncation.** `project-tuner-helper` dispatched in `--report-only` mode produced ~115k tokens of inspection upstream (65 tool uses, ~6 min). Downstream, only the trailing conclusion reached the manager — the Agent tool's output window truncated the per-item Q1–Q5 rationale in transit. Real bug; would affect every non-trivial project install.

Fixed in commits `69fe782` (output contract rewrite — agent writes full report to a file path, returns brief summary paragraph) and `07ea8f5` (follow-up: signpost two-mode behavior in `## What it generates`). New contract: default report path `.claude/agent-memory/project-tuner-report-<timestamp>.md`; return payload has 4 bullets capped at ~300 tokens. `--report-only` mode formalized — `PROPOSED:` prefix on every recommendation, no Edit/Write on project files (still writes the report file itself).

**Subagent registration limitation — 3rd confirmation.** Newly-installed subagents in numbered folders require a session restart to register for dispatch. Pattern observed in Phase 3 (PolyClaude promotion in TV), Phase 4c (dogfood install in this repo), now Phase 4f (TV migration). Worth documenting as a permanent caveat in `docs/INSTALLATION.md` — deferred to next phase.

**Tuner quality grade: B+.** Two HIGH-value items applied. Conservative-correct skips on placeholders (TV's CLAUDE.md is hand-written, no placeholders to fill) and new-helper proposals (rejected duplicates of existing handlers). Truncation prevented full audit of Q1–Q5 detail — grade would have been higher absent the bug, which is fixed for next time.

**Notable:** zero tracked-file modifications in TV proves non-destructive merge install works on real production code. The 14-file skip list matched the pre-install audit predictions exactly.

**Changed:**
- `template/.claude/agents/05_meta/project-tuner-helper.md` — output contract rewrite + `--report-only` mode formalized (commits `69fe782` + `07ea8f5`).
- `docs/SESSION_LOG.md` (this entry).
- `docs/CHANGELOG.md` — `[0.7.0]` entry.
- `VERSION` — `0.6.0` → `0.7.0`.

**Next:** Phase 4g (TBD) — likely the INSTALLATION.md subagent-restart caveat write-up + a second target migration (Echoes-Of-Gill or Fitness-Website).

## 2026-05-13 — Phase 4d/4e: validation on real targets + deferred 4b.6 findings

Validated the install mechanism against a non-skeleton target for the first time and resolved the medium-severity audit findings deferred from Phase 4b.6.

**Validation (against `C:\Users\darre\Dev\test-skeleton-install\`, a throwaway):**

- **Deliverable 1 — `--mode=fresh` install: PASS.** 31 files copied (10 agents, 5 skills, 2 scripts, 4 commands, 3 hook files, 1 settings.json, 3 top-level docs, 3 docs/* templates). `.claude/.skeleton-version` written with all six fields populated correctly (version=0.5.0, commit=8e54083, mode=fresh, claude_only=false). Top-level `CLAUDE.md` / `CLAUDE_MANAGER.md` / `ROUTING.md` and `docs/STATUS.md` / `docs/SESSION_LOG.md` / `docs/ARCHITECTURE.md` all rendered from their `.template` sources. Exit 0.
- **Deliverable 2 — fresh-mode refusal: PASS.** Re-running `--mode=fresh` exited 1 with `error: --mode=fresh refused: target .claude/ already has content (e.g. .../.skeleton-version). Use --mode=merge.` No files modified.
- **Deliverable 3 — merge-mode non-destruction: PASS.** Locally modified `.claude/agents/01_research/research-helper.md` (prepended `<!-- LOCAL CUSTOMIZATION -->` comment) and added a fake `.claude/agents/01_research/custom-helper.md`. Re-ran `--mode=merge`: 0 copied, 31 skipped. Local customization preserved verbatim; custom helper untouched. `.skeleton-version` updated with new `installed_at` timestamp and `mode=merge`.

**Deferred 4b.6 audit findings — resolved:**

- **F11** — `docs/PHILOSOPHY.md` forward reference to nonexistent `integration-checker` skill rewritten. The reference dated from before Phase 4c; what shipped is `integration-installer` (an agent, different concern). New wording acknowledges plugin-discipline is currently rule-only, with the future skill as aspiration.
- **F10** — Shipped `template/PLUGINS.md.template` as the canonical plugin log. Tightened `template/CLAUDE_MANAGER.md.template` line 51 to drop the "or equivalent" hedge now that the template exists.
- **F13** — Created this file (`docs/SESSION_LOG.md`). claude-skeleton now dogfoods its own session-log convention.
- **F14** — Replaced stub content in `template/docs/{STATUS,SESSION_LOG,ARCHITECTURE}.md.template` with real baseline structure (sections + placeholder bullets + "how to keep this current" notes). Stubs no longer ship as TODO comments.
- **F17** — Added 4 slash-command routing rows to `template/ROUTING.md.template` (`/commit`, `/audit`, `/deploy`, `/smoke-test`) so the table covers every surface a target project sees.
- **F19** — Updated the `deploy.sh` routing row to flag `{{DEPLOY_COMMAND}}` as a prereq filled by `project-tuner-helper`.

**Changed:**
- `docs/PHILOSOPHY.md` — F11
- `docs/SESSION_LOG.md` (new) — F13
- `template/PLUGINS.md.template` (new) — F10
- `template/CLAUDE_MANAGER.md.template` — F10
- `template/ROUTING.md.template` — F17, F19
- `template/docs/{STATUS,SESSION_LOG,ARCHITECTURE}.md.template` — F14

**Next:**
- Commit C: tighten `self-audit-helper` severity rubric.
- Commit D: bump VERSION to 0.6.0, CHANGELOG entry, push origin/main.

## 2026-05-13 — Phase 4c: install mechanism + first dogfood

Built and shipped `scripts/install.sh` (three modes: fresh / merge / replace; `--claude-only`, `--dry-run`, `--force`; auto-detects skeleton checkout, falls back to clone; rollback on error) and `scripts/update.sh`. Added the `integration-installer` agent as the judgment-side companion. First dogfood install (`--mode=merge --claude-only`) populated root `.claude/` with the full baseline; subagent registration survived a session restart, verified by dispatching `self-audit-helper` and `system-memory-helper` as registered subagents at low token cost (8.7k and 9.3k respectively).

**Changed:** `scripts/install.sh`, `scripts/update.sh`, `template/.claude/agents/05_meta/integration-installer.md`, `.gitattributes`, `docs/INSTALLATION.md`, root `.claude/` (populated by the dogfood).
**Next:** Validate against a non-skeleton target (Phase 4d/4e — see entry above).

### Audit — 4b.6 meta-system drift — 2026-05-13

20 findings. HIGH-severity items fixed before 4c landed (see commit `d3c4f1a`). Medium-severity items F10, F11, F13, F14, F17, F19 deferred into Phase 4d; cleared in entry above.

## 2026-05-13 — Phase 4b: baseline content + meta-management

Built the baseline shipped content under `template/.claude/`:
- Four core helpers (research, audit, monitoring, plan-coordinator).
- Four meta helpers (system-memory, agent-slicer, workflow-suggester, self-audit) — Phase 4b.5 expansion.
- Five skills (schema-verify, post-edit-test, god-file-grep, token-efficiency-monitor, plugin-roster-search).
- Two scripts (commit.sh, deploy.sh) with 5-section verbatim output and uncommitted-changes guards.
- Four slash commands (`/commit`, `/audit`, `/deploy`, `/smoke-test`).
- Two hooks (sessionstart-rules, precompact-backup).
- `project-tuner-helper` (Phase 4b.6) — the customization side of the install flow.

**Changed:** `template/.claude/**` (all baseline content), `template/{CLAUDE,CLAUDE_MANAGER,ROUTING}.md.template`, `template/.claude/settings.json.template`.
**Next:** Phase 4c install mechanism + `integration-installer`.

## 2026-05-13 — Phase 4a: foundation

Project initialized. Directory structure (`.claude/`, `template/`, `scripts/`, `docs/`) established. Initial docs scaffolded (README, PHILOSOPHY, ARCHITECTURE, INSTALLATION stub, CHANGELOG). MIT LICENSE, `.gitignore`, `VERSION` (0.1.0) in place. `.claude/settings.json` configured with plan-mode default. Two-agent install flow (integration-installer + project-tuner-helper) documented in ARCHITECTURE.md — no implementation yet.

**Changed:** initial repo layout.
**Next:** Phase 4b — populate `template/.claude/` with baseline content.
