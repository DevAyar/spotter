# claude-skeleton — session handoff

<!-- cruft-check:exempt-historical -->
Current as of **2026-05-18** — through **Phase 34b** (commit `f72d132`, bundle install arc closed).

This doc is the chat-session continuity surface. Read top-down at the start of a fresh session to onboard the manager onto current state, locked principles, and the next phase to draft a prompt for. Not a release artefact — lives outside the changelog.

## TL;DR

- **Audit-emergent queue COMPLETE** — 9 phases shipped 2026-05-17 → 2026-05-18 (Phase 30 CC-side audit + 30b mechanical fixes + 30c FP exemption + 31 bulk codification + 32a/c/b marker refresh arc + 33 directive layer alignment + 34 bundle install + 34b claude-mem eyes-open). All emerged from chat-strategist + CC-side audit reconciliation; all landed before Phase 35 evaluation window opened.
- **Bundle install of 6 plugins COMPLETE** — 5 trust-tier-clean (`feature-dev`, `code-review`, `commit-commands`, `security-guidance`, `superpowers`) + 1 eyes-open (`claude-mem` v13.2.0 via hybrid marketplace+bootstrap path). All landed in `~/.claude/plugins/cache/`; skeleton-repo footprint = doc artefacts only (`PLUGIN-INSTALLS-v1.1.4.md`, CHANGELOG bullets).
- **Eyes-open install pattern LOCKED** — Phase 34b is canonical first execution; v1.5-tier vetted-with-concerns plugins follow this shape (plan-mode investigation → marketplace-vs-npx determination → pre/post state capture → empirical decision-tree → rollback documentation → concerns disposition by name).
- **Audit-as-skeleton-primitive workflow VALIDATED EMPIRICALLY** — CC-side audit (Phase 30) surfaced 10 findings chat-audit missed; chat-audit surfaced architectural framing CC's line-by-line read didn't; Phase 30b emergent hook-CWD fix dogfood-discovered during testing. The two-tier audit pattern works — codifies as `## Strategic audit cycle` in CLAUDE_MANAGER per Phase 37.
- **Phase 35 evaluation window OPEN** — passive observation ~3 weeks; data accumulates from every CC session; Phase 36 retire/repurpose decisions wait on data. Concurrent strategic work (Phase 37 codification, Phase 36 design draft, Phase 38+ scoping) can ship anytime.
- **v1.1.5 onboarding tier QUEUED** — 5 small phases (README refresh, GETTING-STARTED, PLUGINS-GETTING-STARTED, install.sh post-install message, optional first-run hook). Defers to AFTER pinball + TV/EoG + Phase 35 close per user preference (repo turbulence ≠ external-user-ready yet).
- **Bash CLI form (`claude plugin install ...`) is the canonical plugin install mechanism** — slash commands (`/plugin install`) only work in Claude Code CLI, not Desktop/web (GitHub #42142, #56623). v1.5 design must use bash form to work across environments.
- **Plugin/skeleton scope separation EXPLICIT** — skeleton template = project-scoped (`.claude/`, propagates via install.sh/update.sh from skeleton template); plugins = user-scoped (`~/.claude/plugins/`, doesn't enter any repo). Cloning skeleton repo ≠ getting plugins. "Opt-in everything" is the UX layer.
- **Strategist-chat-layer scope CLARIFIED** — skeleton + bundle-installed plugins (`/feature-dev` for spec elicitation, superpowers for brainstorming, `/code-review` for quality gates, `claude-mem` for cross-session continuity, audit triad for continuous checks) provide strategist-discipline-layer natively for target projects. A separate chat-strategist tab earns its keep ONLY for the meta-system (claude-skeleton itself), because the meta-system edits itself — recursive loop requires external strategic discipline. Pinball + TV + EoG run entirely inside CC; this skeleton chat stays as dedicated strategist for meta-system work.
- **Substrate clean** — CI green throughout (3 OS × every commit); marker refreshed v0.4 → v1.1.4 (45 file hashes); directive layer aligned with shipped reality (no vapor pointers); line-endings policy enforced; bash-safety FP closed (3rd-recurring hit eliminated).

## Where things live

- **Locked architectural principles** → `docs/ROADMAP.md` § Locked architectural principles (now 12 H3 subsections)
- **Strategic judgment patterns + orchestration rules** → `CLAUDE_MANAGER.md` § Strategic judgment patterns
- **Project mission** → `docs/STORY.md` § Mission
- **Core vs integration boundary** → `CLAUDE_MANAGER.md` § Core vs integration boundary (Phase 33)
- **Plugin install records** → `docs/PLUGIN-INSTALLS-v1.1.4.md` (Phase 34 + Phase 34b)
- **Active sprint state** (Phase recaps, what just shipped, what's queued) → this doc § Sprint state — what shipped
- **Active loose ends** → this doc § Loose ends / queued items

This handoff is the chat-session continuity surface — transient sprint state, not durable spec. Durable spec lives in the canonical surfaces above.

## Sprint state — what shipped

### v1.0.0 — 5630caa, 2026-05-14 (recap)

Orchestration layer cut: directive layer (CLAUDE_MANAGER.md.template), 9 baseline agents, 6 skills, install/update infra with per-file SHA-256 hashes, three-platform matrix CI. Validated on Trainer-View (Flutter + Firebase) and Echoes-Of-Gill (Godot). v1.1+ work starts on top of this baseline.

### Phase 1 — `f39b0e3` → `92f0c61` — session-observer foundation

Observation primitive at `template/.claude/agents/05_meta/session-observer.md` + 9-field schema + `template/.claude/observations/` storage + SessionEnd hook script. Multi-source-extensible from day one — `source` and `pattern_type` enums designed for future producers (`task-watchdog`, `cruft-checker`). Observation only — no suggesting, drafting, or auto-action.

### Phase 1b — `5d6ff53` + `b6439be` — dogfood mirror + hooks asymmetry fix

Mirrored session-observer into skeleton's own `.claude/`. Surfaced that the dogfood `settings.json` had no hooks block at all — PreCompact + SessionStart had never been wired in dogfood (template only). Fixed in a follow-up commit. Established the dogfood-mirror invariant as a hard rule for the rest of the sprint.

### Phase 1c — `9711de3` — hooks README doc-rot fix

Updated `template/.claude/hooks/README.md` from listing two wired events (SessionStart, PreCompact) to three (adding SessionEnd from Phase 1). Surgical fix.

### Phase 2 — `3a35ecc` → `400658c` — workflow-suggester rewrite

Wholesale-rewrote v1.0's prose-suggestion `workflow-suggester` into a schema-driven consumer of `.claude/observations/`. Drafts capture markdown files to `.claude/captures/` for human review with an 8-field frontmatter + 4-section body. Idempotent across re-runs (any status counts as "already considered"). Default thresholds: `occurrences >= 3 AND confidence >= medium`. Pure drafting — no downstream artifact building; that's the X-builders.

### Phase 3 — `67491c3` → `d0177dd` — script-builder (first X-builder)

Reads captures filtered to `status: approved AND suggested_artifact_type: script`, drafts bash files under `.claude/scripts/drafts/<source_pattern_id>.sh.draft`. Honors 5-section discipline + path-shape guards + `bash-safety` integration. `.sh.draft` extension makes drafts unexecutable until user promotes. Schema extension to `workflow-suggester.schema.md`: status enum gains `shipped` + optional `shipped_to` field — additive, existing semantics preserved.

### Phase 3c — `1a85d86` — schema body-convention doc-rot fix

Surgical fix to `workflow-suggester.schema.md`'s generic body convention (lines 50-60) to surface the full `draft → approved → shipped` lifecycle. Phase 6 closed two carry-over refs missed here (realistic example body + CLAUDE_MANAGER subsection).

### Pre-Phase-4 — `dcb72bc` — ROADMAP.md restructure

<!-- cruft-check:exempt-historical -->
Strategic chat-side audit between Phase 3 and Phase 4. Captured shifts in canonical sequencing: tight v1.1.0 scope (5 components), v1.1.x polish tier, expanded v1.2.0 (9 components), v2.0 fold, v3.0+ multi-LLM as sibling project, two architectural principles locked (multi-project graduation, two audit surfaces), explicit Cuts section. Doc-only commit, no behaviour change.

### Phase 4 — `ec01c2a` → `c50a8f1` — drift-checker

Read-only version-drift check at session start. Compares installed `version` field in `.skeleton-version` against cached `cached_skeleton_head` (last known remote release). Additive schema extension to the marker (two new fields). New `update.sh --check-remote` flag is the only network path — `git ls-remote --tags`, 10s timeout, picks highest semver tag. SessionStart hook extended to fold `[skeleton-drift]` notice into `additionalContext`. Locked invariants: drift-checker NEVER hits network, NEVER writes marker, NEVER auto-applies.

### Phase 5 — `89d9c31` → `8a8b90e` — task-watchdog + ownership transfer

Retrospective observer of the prior Claude Code session. Reads `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` (second-newest JSONL by mtime — newest is current session), pairs `tool_use`/`tool_result` events, emits two pattern shapes: long-running bash (`pattern_type: other` with notes) and recurring failures (`pattern_type: recurring_failure`). Idempotent via `.last-watchdog-session` marker. Coordinated ownership transfer: session-observer no longer emits `recurring_failure` — task-watchdog is canonical producer of that type. Schema enum unchanged (no new fields, no new values).

### Phase 6 — `d72e092` → `4bff438` — v1.1.0 release cut

Doc-rot sweep first (`d72e092`): two Phase-3c carry-over refs (workflow-suggester schema example body + CLAUDE_MANAGER "When to dispatch workflow-suggester" subsection) updated to surface the full lifecycle including `shipped` + `shipped_to:`. Then release cut (`4bff438`): VERSION 1.0.0 → 1.1.0, CHANGELOG promotion with phase-ordered bullets + summary paragraph, README counts (14 agents / 4 scripts / 3 hooks), ROADMAP v1.1.0 section flipped to all-five-shipped, STORY.md version line. Annotated tag `v1.1.0` + GitHub Release with `[1.1.0]` CHANGELOG as notes.

### Phase 7 — `78160a7` → `fb9fe22` — cruft-checker (v1.1.x first component)

Third observation producer against session-observer's existing 9-field schema (after session-observer and task-watchdog). **Dogfood-only** — lives in skeleton's own `.claude/`, NOT in `template/`, per the locked two-audit-surfaces principle (project-level cruft is v1.2.0's `infrastructure-auditor`). Shipped seven heuristics initially: markdown link to missing file (i); link to missing header (ii); VERSION ↔ CHANGELOG mismatch (iii); README count claims (iv); Phase reference (v); schema field-count claim (vii); tag/VERSION/CHANGELOG at HEAD (ix); cross-doc stale version reference (x). 24h cooldown on hook invocation; manual dispatch ignores. Schema extension to `workflow-suggester`: `suggested_artifact_type` enum gains `doc-fix`. Three-commit cadence — A: mechanism, B: wiring + doc-fix enum + CLAUDE_MANAGER subsection, C: CHANGELOG.

### Phase 8 + 8b — `ec26450` → `6f8865a` — v1.1.x doc-rot sweep

Phase 3c carry-overs and other v1.1.x doc-rot caught by cruft-checker's first runs: workflow-suggester field-count 7→8 ref; cross-doc field-count refs in ROADMAP / handoff; drift-checker illustrative example genericized; bash-safety skill mirrored into dogfood (closed one-skill mirror gap). Backfilled `[Unreleased]` CHANGELOG bullets for Phases 8 + 8b + 11 (`137afeb`).

### Phase 9 — `96c4645` → `5444b27` — dogfood directive layer at skeleton root

Created `CLAUDE.md` + `CLAUDE_MANAGER.md` + `ROUTING.md` at skeleton repo root by resolving from `template/*.template` files (placeholders filled for skeleton-as-project — `{{PROJECT_NAME}}` → `claude-skeleton`, `{{DEPLOY_COMMAND}}` → `N/A — skeleton has no deploy step`, etc.); all other content byte-identical to templates. Trimmed `compactPrompt` in `.claude/settings.json` from 6 rules to 5 (removed strategic content that duplicated `CLAUDE_MANAGER.md`). New `## Dogfood mirror invariants` section in both template and dogfood `CLAUDE_MANAGER` **locked the rule**: template-root `.template` files have byte-identical dogfood mirrors at skeleton repo root, differing only in resolved placeholder values; phase-brief-scoped dogfood-only artefacts (cruft-checker) are explicit exemptions.

### Phase 10 / 10c — `a0046a3` → `9efe98e` — commit-cadence-by-phase-size rubric

Added commit-cadence-by-phase-size rubric to CLAUDE_MANAGER directive layer (small fix / medium phase / large overhaul). Eliminates need for prompt-side COMMITS overrides on small work. Extended cadence rubric: every shipped phase ships a `[Unreleased]` CHANGELOG bullet by default — closes the gap that caused Phase 8 / 8b / 10 / 11 to need backfill commits.

### Phase 11 — `fb5b02f` — permissions allow-list

Added CC permissions allow-list to `settings.json` (6 allow + 10 deny patterns targeting destructive shapes). Eliminates per-tool-use prompts for common operations; preserves prompts on destructive patterns including recursive-force delete, force push, hard reset, `chmod 777`, and 4 pipe-to-shell variants. (Phase 14 later established that 4 of those denies were silent no-ops due to `|` being a subcommand separator in CC's permission schema; replaced with PreToolUse hook.)

### Phase 12 — `864a309` → `c31fc4f` — observation `resolved_at` field

Extended `session-observer.schema.md` with `resolved_at` field (ISO timestamp or null). Producers (session-observer, task-watchdog, cruft-checker) now mark observations resolved when underlying patterns are no longer present. workflow-suggester filters resolved observations from capture generation. Migrated existing observations; closed 5 lingering observations from Phase 8b cruft fixes. Regression-reset semantics: re-emission sets `resolved_at` back to null (re-occurred patterns are unresolved by definition).

### Phase 13 — `4c9dc56` — cruft-check heuristic vii + V_HEADING_RE polish

Heuristic vii now exempts `docs/CHANGELOG.md` (historical entries document field counts as they were at ship time — accurate-at-ship-time, same logic as heuristic x's CHANGELOG exemption). V_HEADING_RE extended to also match Phase-recap heading shapes (`### Phase N — ... vX.Y.Z`), closing the handoff:60 Phase-recap FP and the CHANGELOG:26 historical schema-claim FP. handoff:136 stayed active at this phase — its `### Sprint rules locked in v1.1+` heading isn't a Phase-recap shape; eventually marker-exempted in Phase 20.

### Phase 14 + 14c–14f — `f8aaff6` → `51281e2` — hook infrastructure correctness saga

<!-- cruft-check:exempt-historical -->
The most significant arc of v1.1.1. **Phase 14**: corrected permissions allow/deny syntax against canonical Anthropic docs (Phase 11's `Edit(*)` / `Write(*)` / `Read(*)` used gitignore semantics where `*` is single-directory; bare tool names are the canonical match-all form; Phase 11's 4 pipe-to-shell deny rules were silent no-ops because `|` is a subcommand separator). Final shape: 10 allow + 6 deny patterns. **Phase 14c**: replaced fragile string-pattern denies with PreToolUse hook `pretooluse-bash-safety.sh` per canonical Anthropic docs recommendation ("Bash permission patterns that try to constrain command arguments are fragile"). Hook intercepts Bash invocations BEFORE subcommand splitting; blocks 10 destructive patterns including the 4 pipe-to-shell shapes Phase 11's deny rules couldn't catch. Removed `deny` key entirely from `settings.json`. **Phase 14c-diag → 14d → 14e → 14f**: surfaced that ALL hook entries in `settings.json` had been missing the required `type: "command"` field on the inner hook object since v1.0 — CC's schema validator silently dropped invalid hook entries. Affected: PreCompact backup, SessionStart rules injection, SessionStart cruft-check (Phase 7), SessionEnd session-observer, PreToolUse bash-safety (Phase 14c). All hooks had been silently inert. Phase 14d added `type: command` to every hook entry. Phase 14e caught that `sessionstart-rules.sh` emitted bare `{additionalContext: ...}` instead of the canonical `{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: ...}}` wrapper — CC silently dropped its output. Phase 14f gitignored hook runtime artefacts (`docs/SESSION_LOG.md` appends; `.claude/observations/.session-ended` marker). Discovered when Phase 14c's PreToolUse hook had a visible failure consequence (a destructive curl-pipe-bash should-have-been-blocked test ran); existing hooks failed silently because their absence didn't break anything visible.

### Phase 15 — `b2268b0` — v1.1.1 release cut

VERSION 1.1.0 → 1.1.1. CHANGELOG promotion. ROADMAP v1.1.1 framing. Annotated tag `v1.1.1` + GitHub Release. v1.1.1 makes the skeleton's hook infrastructure actually work for the first time since v1.0 — PreCompact, SessionStart (rules + cruft-check), SessionEnd, and PreToolUse hooks now all fire as designed. Also ships permissions hardening, observation resolution, dogfood directive layer, commit-cadence rubric, and the v1.1.0 polish that prompted the tier.

### Phase 16 — `0987ec0` → `bbb76d0` — cruft-check heuristic viii + infrastructure-fix capture type

Added heuristic viii (hook-entry config-schema validation). Walks every `hooks.<EventName>[*].hooks[*]` entry in `.claude/settings.json` and `template/.claude/settings.json.template`, flags missing `type: "command"` or missing `command` field — the v1.0 → Phase 14c-diag silent-inert failure mode that took five phases (14c → 14d → 14e → 14f) to surface. Paired with new `docs/HOOK_SCHEMA.md` reference doc. New `infrastructure-fix` value added to `workflow-suggester`'s `suggested_artifact_type` enum (config-fix captures, distinct from `doc-fix`'s prose/markdown shape). Closes the v1.1.x hook infrastructure arc retrospectively — failures of this class get caught at the first cruft-check next time, not after operational verification.

### Phase 17 — `c0d1461` — plan-amendment behavior codified

New `### Plan amendment behavior` H3 under `## Strategic judgment patterns` in `CLAUDE_MANAGER.md`. Codifies the rule: apply user-amendment input as a delta by editing the existing plan file in place, do not regenerate the plan from scratch. The failure mode prevented: Claude Code's default tendency to re-plan on any new input, which loses prior plan structure and forces full re-review. Honors the explicit user phrasing "DO NOT re-plan or rewrite — apply the delta and proceed" that emerged as a recurring v1.1.x mitigation (notably during Phases 14f and 16). **Canonical precedent for Model C lesson codification** — lessons codify directly into the directive surface that architecturally fits (here: `CLAUDE_MANAGER.md`), NOT a separate lessons-log doc. Phase 18 then formalised the flow via the `lesson` capture-surface enum value. Phase 9 mirror invariant honored — template + dogfood copies edited in lockstep.

### Phase 18 — `ca2495f` — lessons-log integration (lesson capture-surface enum)

Added `lesson` to `workflow-suggester`'s `suggested_artifact_type` enum — the **lessons-log integration** surface for v1.1.x. Routing extended via the prefix-routing convention: notes starting `"lesson: "` route to `suggested_artifact_type: lesson`; user-authored captures may set the field directly. **No producer heuristics ship** in this phase — autonomous detection of lesson-shaped observations deferred until grounding data exists (same discipline as task-watchdog's deferred resource-anomaly signals). **No X-builder ships** — lessons codify manually via small-fix commit into the directive surface that architecturally fits (`CLAUDE_MANAGER.md`, `docs/ROADMAP.md`, session-handoff doc, etc.) — **Model C codification**, ratifying the precedent Phase 17 set. Capture frontmatter's `shipped_to:` field records the codified location. Completes the captures-surface `suggested_artifact_type` enum expansion for v1.1.x: nine stable values total — `script`, `skill`, `agent`, `command`, `manual_action`, `unclear` baseline plus v1.1.x's `doc-fix`, `infrastructure-fix`, and `lesson`. Model A (captures-as-lessons-library) and Model B (parallel lessons-log doc) explicitly cut in the same phase — see Cuts section.

### Phase 19 — `6faffeb` — v1.1.2 release cut

VERSION 1.1.1 → 1.1.2. CHANGELOG promotion with summary "captures-surface enum completion + hook-schema validation release". Pre-cut sweep surfaced ~55 heuristic-x FPs against legitimate historical `v1.1.0` annotations across agent docs / README / CLAUDE_MANAGER / handoff / ROADMAP — known scope-limitation noise (not actionable; references are correct). Heuristic-x exemption tuning queued under v1.1.3 in ROADMAP. handoff:136 stayed accepted FP at this phase. Annotated tag `v1.1.2` + GitHub Release with `[1.1.2]` CHANGELOG as notes.

### Phase 20 — `3d3deb6` — cruft-checker heuristic-x scope tuning

Extended `EXEMPT_VFILES` and added new `EXEMPT_VDIRS` to cover `.claude/agents/05_meta/` + `template/.claude/agents/05_meta/` (agent and schema docs), `CLAUDE_MANAGER.md`, and `template/.claude/captures/README.md`. Added inline marker convention `<!-- cruft-check:exempt-historical -->` with two placement shapes: same-line (heading / table cell), preceding-line (prose paragraph / multi-sentence bullet). Applied to README / `claude-skeleton-handoff.md` / `docs/ROADMAP.md` stragglers outside V-heading regions. **57 → 0 unresolved heuristic-x FPs.** cruft-checker agent doc updated: heuristic-list count corrected (seven → nine), heuristic 8 / viii moved off the deferred line, new "Inline exemption marker" section documents the convention with usage examples. Dogfood-only — no template mirror, per the locked principle. Single-commit small-fix shape.

### Phase 21 — `d9c09bd` → `a8db385` — bare-tool allows broadening + PowerShell safety parity

Added `PowerShell` to bare `permissions.allow` (covers the Windows tool-ID gap — PowerShell is a separate `tool_name` from Bash; the bare `Bash` allow doesn't cover it). New `pretooluse-powershell-safety.sh` hook (`d9c09bd`) mirrors `pretooluse-bash-safety.sh` shape with PowerShell-specific destructive patterns: `Remove-Item` recursive-force (canonical + aliases ri / rm / del / erase, short flags, either order), `Format-Volume`, `Clear-Disk`, `Set-ExecutionPolicy Unrestricted` / `Bypass`, `iwr|iex` and `Invoke-WebRequest|Invoke-Expression` pipe-to-shell, force-push / hard-reset-to-origin (same syntax in PowerShell as bash). Case-insensitive via `shopt -s nocasematch`. Same locked default-allow design. **Plan-mode empirical audit caught a bad initial diagnosis** — the brief claimed bash-safety returned ask-shape on unmatched non-destructive patterns, but direct hook invocation showed it already returned allow per the Phase 14 locked design. The "tightening" would have been a no-op edit; only the PowerShell gap was real. Settings wiring (`b517e2c`): bare allow + second PreToolUse matcher block. Three-commit cadence (A: hook + template mirror + scenarios bump 40 → 41; B: settings wiring; C: CHANGELOG).

### Phase 22 — `787f4fe` — v1.1.3 release cut

VERSION 1.1.2 → 1.1.3. CHANGELOG promotion with summary "operational-friction relief release". Pre-cut sweep surfaced two findings, both folded into the release-cut commit per the Phase 6 sweep rule: heuristic iv (README hook count `4` → `5`; Phase 21 added a hook file, count not bumped at the time); heuristic v transient (`Phase 20` ref in ROADMAP not yet in CHANGELOG, resolved by adding Phase 20 / Phase 21 tags to the v1.1.3 summary paragraph in the same commit). **Zero unresolved heuristic-x findings** — Phase 20 scope tuning held cleanly across the post-Phase-20 and Phase-21 diffs. Annotated tag `v1.1.3` + GitHub Release with `[1.1.3]` CHANGELOG as notes. Closes the v1.1.x polish arc.

### Phase 24 — `c8272d9` → `43215c3` — code-quality-auditor + destructive-pattern shared-lib refactor

Three-commit cadence. First v1.1.4 component — first plugin-verification surface in the skeleton. **Commit A** (`c8272d9`): new `code-quality-auditor.md` agent + `plugin-quality-check.sh` script (both with byte-identical template mirrors). Three heuristics: (i) manifest-declared component path missing or empty, (ii) hooks.json schema violation (reuses Phase 16 viii validation logic, duplicated in inline Python heredoc with reference comment), (iii) destructive shell patterns against unguarded paths. **Refactor piggyback** extracted destructive-pattern arrays from inline declarations in `pretooluse-bash-safety.sh` (Phase 14c) and `pretooluse-powershell-safety.sh` (Phase 21) into new shared `.claude/lib/destructive-{bash,powershell}-patterns.sh` files. All three consumers (both hooks + plugin-quality-check) now source the libs — **single source of truth**. Hooks fail-closed if lib missing. Refactored hooks regression-tested against Phase 21's inputs (same allow/deny shape). Synthetic-plugin verification: 4 test plugins planted (3 violation cases + 1 clean), each heuristic caught its target case, clean plugin produced zero observations. CI `verify_marker 41 → 45` for 4 new template files. **Commit B** (`e384cff`): pipeline wiring — workflow-suggester routing for `pattern_type: plugin_quality` → `suggested_artifact_type: manual_action` (filename convention deviates to `plugin-quality-<plugin>-<heuristic>.md` for human browsing; idempotency via frontmatter `source_pattern_id`). Schema extensions: `session-observer.schema.md` source enum gains `cruft-checker` (v1.1.x backfill) + `code-quality-auditor`; pattern_type enum gains `plugin_quality`. Settings.json gets a 3rd SessionStart hook entry (dogfood) / 2nd (template). **Commit C** (`43215c3`): doc cleanup — ROADMAP v2.0 section reframed (`integration-checker` "planned for v2.0"); new v1.1.4 open-queue section; pre-commit cruft sweep surfaced 4 findings, all folded in (README counts 14→15 / 4→5; broken-in-template relative link replaced with prose ref; Phase 24 ref added to CHANGELOG for heuristic-v). **Bash-safety commit-message FP hit twice** during synthetic-plugin planting (destructive-pattern strings appearing in heredoc payload + code comment); worked around via Write tool — same FP shape Phase 21 hit. Two empirical data points now.

### Phase 25 — `2a0caf6` — v1.1.4 release cut

VERSION 1.1.3 → 1.1.4. CHANGELOG promotion with summary "plugin-verification surface open". Pre-cut sweeps: `cruft-check` surfaced 9 heuristic-x findings — README:52 stale v1.1.3 anchor (real fix folded in via marker), 8 handoff findings (transient, deferred to next handoff refresh). **Zero heuristic-x findings** elsewhere — Phase 20 scope tuning held cleanly through Phase 24's substantial additions. `plugin-quality-check` against real installed `42crunch-api-security-testing@1.0.1`: **zero findings** — all three heuristics clean on production plugin. **First real-world plugin-audit pass** (Phase 24's synthetic verification already proved each heuristic catches its target). Doc-rot folded in: `.gitignore` extended with `.claude/.last-plugin-quality-check` (matches existing `.last-*` marker family). Annotated tag `v1.1.4` + GitHub Release with `[1.1.4]` CHANGELOG as notes.

### Phase 30 — `748cf5f` — CC-side audit

Read-only artifact at `docs/AUDIT-v1.1.4-cc-side.md` (338 lines, 7 sections). Validated 6 chat-audit predictions; surfaced 10 new findings (1 HIGH, 3 MEDIUM, 6 LOW); disputed chat-audit's retire-candidates (`commit.sh` + `audit-helper` KEEP per non-overlapping scope; `plan-coordinator` NEUTRAL pending feature-dev evaluation). Confirms audit-as-skeleton-primitive workflow validates itself empirically — CC's line-by-line read catches what chat-audit's strategic framing misses; chat-audit catches what CC's narrow focus doesn't.

### Phase 30b — `c2739a5` + `f61f11b` + `0806357` — Audit-finding mechanical fixes

Three-commit cadence covering 7 audit findings (H1-H7). Schema carve-out for deterministic producers (`occurrences ≥ 1` allowed for cruft-checker + code-quality-auditor); cruft-check.sh header heuristic count + confidence-tier comment; `timeout` portability fallback in `update.sh` + env-overridable `SKELETON_REPO_URL`; 11 new destructive patterns in libs (rsync/dd/mkfs/truncate/find-root/shred|srm shapes + Stop/Restart-Computer/Set-Acl/Compress-Archive/wmic shapes); 4 new CI scenarios (check-remote-cached, hook-fail-closed, cruft-check-fixture, replace-with-yes-piped). **Emergent fix:** PreToolUse hooks now resolve LIB via `${CLAUDE_PROJECT_DIR:-.}` instead of relative path — discovered when `cd /tmp` during testing exposed fail-closed-on-CWD-drift lockup. Codified as architectural rule in CLAUDE_MANAGER (Phase 31).

### Phase 30c — `bcabac0` + `4d77913` — bash-safety + powershell-safety FP exemption

Parser-aware redaction of `git commit -m` message bodies + heredoc/here-string payloads in both PreToolUse hooks. Closes 3rd-recurring FP (Phase 21 + 24 + 30b empirical hits). Counter-tests (semicolon-chained, AND-chained, bare-pattern, post-heredoc) verify destructive patterns OUTSIDE exempted shapes still deny. Shell-portable parser — bash regex + sed only; no Python/jq in redaction logic.

### Phase 31 — `89b7208` + `0bb9504` + `f849fdb` — Bulk codification

Three-commit cadence. Extracted 5 "Other principles" + 1 sprint rule (Compose-with-available-surfaces) into `docs/ROADMAP.md` § Locked architectural principles (now 12 H3 subsections). Codified 2 sprint rules (empirical-audit before trusting diagnoses, Co-Authored-By trailer) + hook-path-resolution discipline (Phase 30b emergent) as CLAUDE_MANAGER strategic-judgment H3s. Added Mission section to `docs/STORY.md`. Production-miles precision reframe in ROADMAP v1.2.0 gating. Simplified handoff doc (322→244 lines, 24% reduction). Back-mirrored template→dogfood for `self-audit-helper.md` (73→92 lines) + `project-tuner-helper.md` (124→188 lines).

### Phase 32a — `a0194cc` — Marker refresh dry-run inventory

Read-only artifact at `docs/AUDIT-v1.1.4-marker-refresh-dryrun.md`. Captured `update.sh --dry-run` output against v0.4 fossil marker. 4 TEMPLATE_UPDATED entries (3 line-ending FP + 1 locked settings.json drift). 8 empirical learnings about update.sh behavior. **Mental-model drift caught:** `--claude-only` flag is install.sh-only; `update.sh` by-design scopes to `.claude/`.

### Phase 32c — `bba2d8a` — Line-ending normalization

Tightened `.gitattributes` with `* text=auto eol=lf` policy rule. Stripped CRLF from 3 worktree files (`audit-helper.md`, `monitoring-helper.md`, `session-observer.md`). Closed 3 of 4 Phase 32a TEMPLATE_UPDATED entries (line-ending FP). Fix was policy-level — index already held LF; only worktree had CRLF due to `core.autocrlf=true`.

### Phase 32b — `9a50ea2` — Marker refresh apply

Ran `update.sh` interactively with `[S]kip all` defaults. Refreshed `.claude/.skeleton-version` from v0.4 fossil (6-line shell-export) → v1.1.4 schema (JSON, 58 lines, 45-entry files object). Empirical learning: `update.sh classify()` silent-backfills `hash_recorded` for ALL template-walked files including skipped — marker captures "current baseline" not "template baseline." Settings.json recorded at dogfood-resolved bytes (intentional drift preserved). Marker arc closed (32a → 32c → 32b).

### Phase 33 — `1a2dee4` + `baf21a7` + `f874fa9` — Directive layer alignment

Three-commit cadence. Removed `/goals` TEMPLATE STUB (vapor pointer; `/spec` build decision reversed per audit reconciliation). Reframed `integration-checker` H3 from TEMPLATE STUB to "STATUS: DEFERRED to v2.0." Added new `### When to dispatch code-quality-auditor` H3 (6 dispatch H3s total). Added new `## Core vs integration boundary` H2 (12 durable core primitives + 4-item integration layer + 3 boundary discipline rules). Dropped `.skeleton-version dogfood lag` loose-end from handoff (closed post-32b). Both CLAUDE_MANAGER mirrors byte-identical modulo placeholder drift.

### Phase 34 — `07d9b26` — Bundle install (5 of 6 plugins)

First non-skeleton-meta phase in audit-emergent queue. Mid-execution mechanism switch: `/plugin` slash commands unavailable in Claude Code Desktop (GitHub #42142, #56623); switched to `claude plugin install` bash CLI form. CC drove install autonomously via Bash tool (no user-pause needed; original plan's slash-command pause was obsolete with correct tool). Installed `feature-dev` + `code-review` + `commit-commands` + `security-guidance` + `superpowers`. Trust-tier-2 vetting via WebFetch surfaced claude-mem concerns; deferred to Phase 34b for eyes-open install. `plugin-quality-check` zero findings on all 5; no `installed_plugins.json` vs `enabledPlugins` gap (GitHub #20661 didn't reproduce). New: `docs/PLUGIN-INSTALLS-v1.1.4.md` (394-line install record).

### Phase 34b — `f72d132` — claude-mem eyes-open install (Phase 34 deferral closure)

Hybrid install path: marketplace install (`claude plugin marketplace add thedotmack/claude-mem` + `claude plugin install claude-mem@thedotmack`) landed plugin cleanly + `npx claude-mem install` bootstrap completed runtime state. Empirical disposition of 4 original concerns: (1) Bun upgraded in-place 1.3.9 → 1.3.14, uv freshly installed at `~/.local/bin/uv.exe`, NO shell rc edits (none exist on Windows Git Bash); (2) daemon autostart skipped in non-TTY environment (user opt-in via `npx claude-mem start`); (3) network egress code paths exist but not activated; (4) marketplace path empirically clean (issue #1170 closed). Disk-full incident during npm install captured as real-world lesson (plugins with native deps need 2-3GB headroom). Eyes-open install pattern established as canonical for v1.5-tier vetted-with-concerns plugins.

## Roadmap (condensed; full version in `docs/ROADMAP.md`)

### v1.1.0 — ✓ all 5 components shipped

Capture/reuse loop in production. Pipeline running daily on dogfood + real production targets (Trainer-View, Echoes-Of-Gill).

### v1.1.x — ✓ polish arc closed (cut at v1.1.3 on 2026-05-17)

Four releases in three days closed the polish arc cleanly:

- **v1.1.1** (Phase 15) — hook infrastructure correctness (PreCompact + SessionStart + SessionEnd + PreToolUse now actually fire); permissions hardening; observation resolution mechanism; dogfood directive layer; commit-cadence-by-phase-size rubric.
- **v1.1.2** (Phase 19) — captures-surface `suggested_artifact_type` enum completion (`doc-fix` + `infrastructure-fix` + `lesson` joined `script` / `skill` / `agent` / `command` / `manual_action` / `unclear`); cruft-checker heuristic viii (hook-entry config-schema validation); plan-amendment behavior codified.
- **v1.1.3** (Phase 22) — operational-friction relief: heuristic-x scope tuning (Phase 20, 57 → 0 FPs); PowerShell bare allow + safety hook parity (Phase 21).

**Shipped components in v1.1.x:** cruft-checker (Phase 7, third observation producer, dogfood-only).

### v1.1.4 — ✓ shipped (cut on 2026-05-17)

Plugin-verification surface open. One concrete component, one piggyback refactor:

- **`code-quality-auditor`** (Phase 24) — first plugin-verification surface. Reads installed plugin source for three narrow heuristics — manifest honesty (i + ii) + security hygiene (iii — destructive shell patterns against unguarded paths). Composes with `cruft-checker` + `drift-checker` as the **project-level audit triad** firing at SessionStart. Ships in `template/`. Routes via `workflow-suggester` as `suggested_artifact_type: manual_action`. Semantic Layer 3 "fitness vs description" deferred to v2.0.
- **Destructive-pattern shared lib extraction** (Phase 24 piggyback) — moved patterns from inline declarations in Phase 14c / Phase 21 hooks into `.claude/lib/destructive-{bash,powershell}-patterns.sh`. All consumers source the libs. Single source of truth across real-time blocking and retrospective audit.

**Rolled forward to v2.0:** `integration-checker` (Layer 1+2 plugin verification); semantic "fitness vs description" checks (Layer 3); curated plugin catalog.

### Audit-emergent queue — ✓ COMPLETE (Phase 30 → 34b, 2026-05-17 → 2026-05-18)

9 phases shipped over 2 days, all post-v1.1.4 release cut. CC-side audit (Phase 30) opened the queue; mechanical fixes (30b/c) closed line-by-line findings; bulk codification (31) moved principles to canonical homes; marker refresh arc (32a/c/b) brought dogfood marker from v0.4 fossil to v1.1.4 current; directive layer alignment (33) removed vapor pointers; bundle install (34) put 5 trust-tier-clean plugins into operation; eyes-open install (34b) closed the claude-mem deferral via hybrid marketplace+bootstrap path. No new VERSION cut — all changes additive on v1.1.4 substrate. Phase 35 evaluation window opens next.

### v1.1.5 — Onboarding tier (NEW, queued for post-Phase-35-close)

5 small phases adding the user-experience layer the skeleton has lacked while being a single-user project:

- **v1.1.5-A:** README.md onboarding refresh (landing page, decision framework, install command, "what you get")
- **v1.1.5-B:** `docs/GETTING-STARTED.md` (first-15-minutes walkthrough after install)
- **v1.1.5-C:** `docs/PLUGINS-GETTING-STARTED.md` (plugin install onboarding, explicit "you don't have to install any of these" framing)
- **v1.1.5-D:** install.sh post-install message ("✓ Installed. See GETTING-STARTED.md for next steps")
- **v1.1.5-E (optional):** First-run SessionStart welcome hook (one-time, self-disabling)

Strategic significance: closes the "skeleton built for an audience of one" gap. "Opt-in everything" UX principle locked: cloning ≠ installing; installing skeleton ≠ installing plugins; installing recommended plugins ≠ activating optional features. Each layer is a deliberate user choice. Sequencing: AFTER pinball + TV/EoG + Phase 35 close — repo turbulence during testing ≠ external-user-ready state.

### v1.2.0 — meta-evolution tier

Nine components turning v1.1.0 primitives into a self-tuning surface:

- `manager-optimizer` (L3 meta-meta) — watches manager dispatch patterns, suggests CLAUDE_MANAGER refinements.
- `artifact-fit-analyzer` — detects redundancy / inefficiency / missing combinations across the project's artefacts.
- `/goals` expanded — research → targeted clarify → spec pipeline. X-builders consume spec docs natively.
- Loop pruning (via manager-optimizer) — retires unused captures + dispatched-zero scripts.
- `meta-session-observer` + `template-promoter` — multi-project graduation mechanism.
- `token-efficiency-monitor` (upgraded) — proactive flag before dispatch (closes Gap #4).
- `infrastructure-auditor` (project-level, in template/) — scheduled audit coordinator dispatching cruft / drift / artifact-fit checkers.
- `roadmap-auditor` (skeleton-level, dogfood only) — drift between roadmap and codebase.
- Scheduled-goals support in `/goals` — `schedule` field, session-start surfacing of due items.

**Gating language updated:** v1.2.0 needs **v1.1.x production miles** before opening, where production miles BEGIN when `update.sh` runs against TV/EoG post-Phase-35. Without empirical dispatch data from live targets, `manager-optimizer` would optimize against vibes.

### v1.5 — ecosystem integration tier (gated on Phase 35 evaluation + v1.1.5 onboarding ship)

Phase 38+ surface: `recommendation.schema` (project-scoped plugin recommendation manifest), `code-quality-auditor` candidate mode (extends Phase 24 component to evaluate recommended plugins pre-install), `plugin-discovery-agent`, `plugin-context-matcher`, SessionStart hook + cooldown for plugin-aware suggestions, first-install integration with installer flow, composition-rule docs. Bash CLI form (`claude plugin install ...`) is canonical install mechanism per the Phase 34 finding — works across Claude Code Desktop / web / CLI.

### v2.0 — plugin recommendation surface

Folds `integration-checker` + `code-quality-auditor` Layer 3 semantics + curated catalog. The standalone-phase framing is gone. *"Don't be a directory; be a quality filter."* (verbatim).

### v3.0+ — multi-LLM orchestration as sibling project

Re-targeting the skeleton for Claude + DeepSeek + others would change the project's centre of gravity. Stays Claude-Code-only through v2.0. If pursued: sibling project (e.g. `claude-skeleton-bridge`), not a feature graft.

## Cuts (rationale locked, do not relitigate)

- **`skill-builder` and `agent-builder` cut from v1.1+ X-builder sequence.** Markdown writing is cheap — no automation gain. The recommendation/analysis function for "should this be a skill, agent, script, or command?" moves to `artifact-fit-analyzer` (v1.2.0). `script-builder` stays because bash has structural discipline (strict-mode, path-shape guards, `bash-safety`) markdown doesn't.
- **Gap #1 (auto-dispatch by intent) deferred to v1.2+.** Closing it without empirical dispatch data would mean optimizing against vibes — the same trap that pushed `manager-optimizer` itself to v1.2+. Manual dispatch via `CLAUDE_MANAGER.md.template` patterns continues to work; gap is a known seam, not a blocker.
- **Plugin recommendation as a standalone v2.0 phase cut.** Folded into `integration-checker` + `code-quality-auditor`. A catalog without quality verification is a directory (which the verbatim principle rules out); quality verification without a catalog is just `integration-checker`. The two only justify a v2.0 phase together.
<!-- cruft-check:exempt-historical -->
- **Lessons-log as separate parallel doc (Model B) cut in v1.1.2.** A `docs/LESSONS.md`-style dedicated reference doc with its own schema and its own lifecycle. Cut at Phase 18 in favor of Model C (codify directly into the directive surface that architecturally fits — `CLAUDE_MANAGER.md` / `docs/ROADMAP.md` / handoff). Rationale: duplicates content with the directive layer; readers consult two docs for one rule; drift between LESSONS.md and the directive layer becomes a real maintenance cost. Model C is the single-source-of-truth move.
<!-- cruft-check:exempt-historical -->
- **Captures-as-lessons-library (Model A) cut in v1.1.2.** A persistent library of captures under `.claude/captures/` that includes lessons as a queryable reference category. Cut at Phase 18. Rationale: captures are draft-then-ship work-items with `draft → approved → shipped` (or `rejected`) lifecycle, not durable reference. A library accumulates stale captures and re-purposes the captures surface in a way that conflicts with X-builder consumption. Lessons codify into the directive layer (Model C); captures stay as ephemeral work-tracking.
- **User-pause-on-plugin-install assumption cut.** Phase 34 originally planned a user-pause for slash-command execution. Bash CLI form (`claude plugin install ...`) is invokable via Bash tool → CC drives end-to-end. Original assumption was an artifact of the wrong tool, not an inherent property of plugin install. Lesson: when CC plans a user-pause, interrogate whether it's necessary or just an assumed tool limitation.
- **claude-mem indefinite deferral cut.** Phase 34's HALT-ON-CONCERN initial disposition was "skip claude-mem; defer indefinitely." User feedback flipped to eyes-open install via dedicated Phase 34b. The deferral wasn't actually indefinite; it was waiting for a properly-scoped phase. Pattern lesson: HALT-ON-CONCERN means "pause for informed consent," not "permanent refusal."

## Architectural findings from this sprint

Strategic-level findings that aren't already locked as principles but inform future design.

- **Audit-as-skeleton-primitive workflow VALIDATED EMPIRICALLY.** Two-tier audit (strategist + CC, or chat + line-by-line) catches more than either alone. Composition + disagreement + reconciliation produces stronger findings than single-source review. Phase 37 will codify into CLAUDE_MANAGER as `## Strategic audit cycle` section.
- **Bash CLI form is canonical for plugin installs.** v1.5 ecosystem-integration tier's discovery → recommendation → install pipeline MUST use bash form (`claude plugin install ...`), not slash commands, to work across Claude Code Desktop / web / CLI. Input for Phase 38+ design.
- **Plugin/skeleton scope separation.** Skeleton template = project-scoped (`.claude/`, propagates via install.sh/update.sh); plugins = user-scoped (`~/.claude/plugins/`, doesn't enter any repo). v1.5-A `recommendation.schema.md` design must respect this: recommendations live in project repo (travel with the project); installs are user-scoped (don't force on collaborators).
- **"Opt-in everything" UX principle.** Cloning the repo doesn't install the skeleton. Installing the skeleton doesn't install plugins. Installing recommended plugins doesn't enable optional features. Each layer is a deliberate user choice — the user-experience-side expression of approval-gated autonomy. v1.1.5 onboarding tier operationalizes this principle.
- **Hook path resolution discipline LOCKED** (Phase 30b emergent, Phase 31 codified). Hooks resolve paths via `${CLAUDE_PROJECT_DIR:-.}`, not relative paths. Applies to all future hooks; existing hooks audit-checked during future maintenance.
- **Eyes-open install pattern LOCKED** (Phase 34b canonical execution). For vetted-with-concerns plugins: plan-mode investigation → marketplace-vs-npx determination → pre/post state capture → empirical decision-tree → rollback documentation → concerns disposition by name. Each concern from vetting addressed empirically post-install.
- **Strategist-chat-layer scope LOCKED: meta-system only, not target projects.** The skeleton was built so target projects DON'T need a separate strategic-chat-layer hovering above CC. v1.1.4's plugin bundle (feature-dev + code-review + commit-commands + security-guidance + superpowers + claude-mem) operationalizes this — `/feature-dev` elicits specs with in-depth questioning, superpowers' brainstorming surfaces strategic tradeoffs, `/code-review` provides 4-agent quality gates pre-commit, claude-mem persists cross-session context, the skeleton's audit triad runs continuously underneath. **The recursion test:** a separate strategist-chat tab earns its keep IFF the work being done can edit the discipline itself. claude-skeleton edits itself (meta-meta-system); pinball doesn't (just a game). **How it applies:** future-you defaulting to "create a chat for every project" is a code smell — interrogate whether the project actually edits the system providing its discipline. If yes → strategist-chat layer needed. If no → CC + skeleton + plugins is sufficient. Pinball + TV + EoG + any future target projects run inside CC; this skeleton chat stays as the dedicated strategist layer because the skeleton edits itself.

## Loose ends / queued items

- **Node.js 20 deprecation in CI** — GitHub Actions deprecation timeline cites June 2026 for full removal. CI uses `actions/checkout@v4` + `actions/setup-python@v5` which still rely on Node 20 internals. Watch for action version bumps before then; the matrix may need a refresh.
- **`uninstall.sh` deferred.** No production demand yet — both current targets (Trainer-View, Echoes-Of-Gill) have stable installs. Will ship when there's real signal (e.g. a user trying to roll back the skeleton). Locked invariants when it lands: read `.skeleton-version`'s `files` map, prompt before deleting any locally-modified file (same `LOCALLY_MODIFIED` discipline `update.sh` uses).
- **`defaultMode` mismatch.** Template ships `"defaultMode": "default"` in `settings.json.template`; skeleton's dogfood `.claude/settings.json` uses `"defaultMode": "plan"`. Intentional — dogfood-as-meta-system needs plan-mode discipline; target projects don't necessarily. Don't conflate.
<!-- cruft-check:exempt-historical -->
- **task-watchdog deferred signals.** Three signals out of v1.1.0 scope, ordered by gating: (1) **no-progress** — same tool call returning identical output ≥N times consecutively; needs real-time hook surface CC doesn't expose. (2) **approval-waiting** — tool prompt sitting unanswered for >N minutes; same hook-surface gap. (3) **resource anomalies** — token / memory / CPU spikes; bundles with v1.2.0 `token-efficiency-monitor` proactive upgrade (same Gap #4 investigation into Claude Code's token-data exposure to agents).
- **PreCompact + SessionEnd verification opportunistic.** Both hooks exist (PreCompact backup, SessionEnd session-observer) and emit valid schema-conformant output. Their real-time firing is observed only opportunistically — we know they emit correctly because the SessionStart cruft-check pattern was the same shape and was verified after Phase 14d's `type: command` wiring fix. Deferred unless / until a session inspection turns up a misfire.
<!-- cruft-check:exempt-historical -->
- **Unresolved Bash-growth mystery in `settings.local.json`.** Pre-Phase-21, 12 `Bash(...)` entries had accumulated in the local file via "Always allow" clicks despite the bash-safety hook returning `permissionDecision: allow` on those same commands. Most likely cause: pre-Phase-14d historical residue when hooks were silently inert; CC's "Always allow" doesn't auto-prune entries that are now redundant. Phase 21 verified the hook DOES emit allow correctly post-Phase-14d. No code change earned. Diagnose only if growth resumes post-v1.1.4 (no new Bash entries observed during Phase 22 / 24 / 25 sessions).
- **Windows Git Bash /tmp path gotcha** — synthetic-test only, not a runtime issue. Phase 24 hit this during plugin-quality-check synthetic verification: `/tmp/tmp.XXXX` (Git Bash POSIX path) confuses Windows Python's `os.path.normpath` — slashes get converted to backslashes and the path resolves wrong. **Production path** `~/.claude/plugins/cache/` resolves correctly via `os.path.expanduser` to `C:\Users\<user>\.claude\plugins\cache\` (Windows-native absolute). For synthetic tests on Windows, use `$env:TEMP\<dir>` or `C:\tmp\<dir>` rather than Git Bash's `/tmp`.
- **Phase 35 watch items (claude-mem-specific):** `PostToolUse(*)` + `PreToolUse(Read)` + `UserPromptSubmit` + `Stop` hook chain noise; MCP server (`mcp-search`) reliability + context cost; daemon stability if user opts in via `npx claude-mem start`; 4-way `make-plan` command overlap (claude-mem vs skeleton vs feature-dev); 3-way `smart-explore` command overlap; context-injection token cost from superpowers SessionStart hook; `PreToolUse(Read)` hot-path latency on every file Read.
- **Disk-space pre-check for plugin installs.** Phase 34b hit disk-full during npm install. Plugins with substantial native dependencies (tree-sitter family, sqlite, etc.) need 2-3GB headroom. v1.5-A `recommendation.schema` design should include `estimated_install_footprint_gb` field; v1.1.5-C plugins-getting-started doc should warn about this. No skeleton-side mitigation possible.
- **`cached_skeleton_head` population deferred indefinitely on dogfood.** Phase 32b left this null. Structurally meaningless on dogfood (dogfood IS upstream — asking "is dogfood ahead of dogfood?" returns "always equal by definition"). Will populate naturally on TV/EoG via `--check-remote` when those updates run.
- **commit-commands vs commit.sh dispatch overlap (Phase 36 retire-candidate).** Phase 34 surfaced this. Phase 35 evaluation needs side-by-side observation to inform Phase 36 decision. CC-audit Section 5 Dispute 2 disputed retirement (commit.sh has verbatim-contract value); empirical Phase 35 data may confirm or refute.
- **Phase 35 watch item — empirical validation of strategist-chat-layer scope.** If pinball / TV / EoG sessions reveal a recurring need for chat-side strategic discipline that the skeleton + plugins can't provide natively, that's a v1.5+ finding: the skeleton's strategist-role provisioning needs more work. Document the gap if it surfaces (specific scenarios where CC + plugins didn't provide enough strategic pushback, where you reached for a separate chat instinctively, etc.). Negative result (no gap surfaces; CC + plugins is sufficient) confirms the skeleton's core value proposition.

## What's next

**Phase 35 evaluation window NOW OPEN** (passive observation, ~3 weeks; data accumulates from every CC session).

### Suggested sequencing during Phase 35

| Window | Action | Why |
|---|---|---|
| Days 1-3 after Phase 35a | Restart CC; baseline observation of 6 plugins (especially claude-mem hooks firing on first activated session); use dogfood normally | claude-mem hooks load at session start — must restart for activation. Baseline data captured before propagating to other projects. |
| Days 3-7 | Pinball install + first major prompt | Fresh project; tests v1.1.4 substrate on new-project context; lower stakes than TV/EoG; pinball is primary creative focus. |
| Days 7-14 | TV update via `bash <skeleton>/scripts/update.sh` against Trainer-View | Higher stakes (deployed at trainer-view.web.app); inherits all v1.1.x improvements; production miles BEGIN here per locked production-miles framing. |
| Days 14-21 | EoG update via same mechanism | Staggered from TV; if TV update surfaces `update.sh` issues, address before EoG. |
| Day 21+ | Phase 35 closes; Phase 36 (retire/repurpose decisions) opens with empirical data | Decision-execution phase. |

**Note on chat structure during Phase 35:** Pinball, TV, and EoG run entirely inside CC. No separate Claude chat tabs needed for them — the skeleton's directive layer + bundle-installed plugins provide the strategist discipline natively (`/feature-dev` for spec elicitation, superpowers brainstorming for in-depth questioning, `/code-review` for quality gates, claude-mem for cross-session continuity, audit triad for continuous checks). This skeleton chat stays as the dedicated strategist layer ONLY because the skeleton edits itself (meta-meta-system recursion); target projects don't have that recursion problem.

### Concurrent strategic work (chat-side, anytime during Phase 35)

- **Phase 37 codification** — audit-as-skeleton-primitive workflow into CLAUDE_MANAGER `## Strategic audit cycle` section + queue `strategic-audit-coordinator` for v1.2.0+. Doc-shuffle; can ship in a single afternoon.
- **Phase 36 design draft** — composition rules framework, written before Phase 36 execution.
- **Phase 38+ design scoping** — v1.5 component plans (`recommendation.schema`, `code-quality-auditor` candidate mode, `plugin-discovery-agent`, `plugin-context-matcher`, etc.).

### Post-Phase-35 sequence

1. **Phase 36** — retire/repurpose decisions (`plan-coordinator` only; `commit.sh` + `audit-helper` KEEP per CC-audit Section 5 dispute, ratified).
2. **v1.1.5 onboarding tier** — 5 small phases A-E. Closes the "single-user project" gap. Sequenced AFTER pinball + TV/EoG so external visibility lands on stable substrate, not turbulence.
3. **Phase 37 codification** — audit-as-primitive workflow into CLAUDE_MANAGER (if not already shipped concurrently during Phase 35).
4. **Phase 38+ v1.5 ecosystem-integration tier** — `recommendation.schema`, `code-quality-auditor` candidate mode, `plugin-discovery-agent`, `plugin-context-matcher`, SessionStart hook + cooldown, first-install integration, composition-rule docs.
5. **Phase 45** — v1.5.0 release cut.
6. **Phase 46+** — v1.2.0 design opens (gated on v1.1.x production miles ≥ 2 weeks on TV/EoG, which begins post-update during Phase 35).
