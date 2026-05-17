# claude-skeleton — session handoff

<!-- cruft-check:exempt-historical -->
Current as of **2026-05-17** — through **Phase 30c audit closure + Phase 31 codification** (post-v1.1.4 release `2a0caf6` / tag `v1.1.4`).

This doc is the chat-session continuity surface. Read top-down at the start of a fresh session to onboard the manager onto current state, locked principles, and the next phase to draft a prompt for. Not a release artefact — lives outside the changelog.

## TL;DR

- **v1.1.4 shipped 2026-05-17** at `2a0caf6`, tag `v1.1.4`. **Plugin-verification surface open** — `code-quality-auditor` (Phase 24) ships as the first concrete plugin-audit component with three narrow heuristics, composing with `cruft-checker` + `drift-checker` as the **project-level audit triad** firing at SessionStart. Single release-cut commit per Phase 19 / 22 precedent (Phase 25).
<!-- cruft-check:exempt-historical -->
- **v1.1.x polish arc remains closed; v1.1.4 opens new plugin-verification surface.** Five releases in three days: v1.1.0 capture/reuse loop (2026-05-15) → v1.1.1 hook infrastructure correctness (2026-05-16) → v1.1.2 captures-surface enum completion + lesson codification flow (2026-05-16) → v1.1.3 operational-friction relief (2026-05-17) → v1.1.4 plugin-verification surface open (2026-05-17). No v1.1.5 placeholder — left open until real items queue.
- **Phase 24 destructive-pattern shared-lib refactor.** Bash-safety + powershell-safety hooks (Phase 14c / Phase 21) now source pattern arrays from `.claude/lib/destructive-{bash,powershell}-patterns.sh` — **single source of truth** across real-time blocking AND retrospective audit. Adding a new destructive pattern propagates to all enforcement surfaces.
- **First real-world plugin scan: zero findings** against `42crunch-api-security-testing@1.0.1` (the one real installed plugin in `~/.claude/plugins/cache/`). All three heuristics clean. Phase 24's synthetic-plugin verification already proved each heuristic catches its target case; Phase 25's pre-cut sweep was the first real-world pass.
- **GitHub Release** published with the `[1.1.4]` CHANGELOG section as notes: <https://github.com/DevAyar/claude-skeleton/releases/tag/v1.1.4>.
- **Items rolled forward.** `integration-checker` (Layer 1+2) + semantic "fitness vs description" checks (Layer 3) + curated catalog — all fold into v2.0.
- **Audit closure cascade landed (Phase 30 / 30b / 30c).** CC-side audit surfaced 10 findings; 7 mechanical fixes landed in 30b + 30c; 1 emergent hook CWD-independence fix bundled in 30b. Audit-as-skeleton-primitive workflow validated empirically. State-dump §17 bash-safety FP loose-end CLOSED in 30c (parser-aware redaction of `git commit -m` bodies + bash heredoc + PowerShell here-string payloads; counter-tests preserve deny outside exempted regions).
- **Phase 31 codification underway.** Bulk extraction of principles + sprint rules + mission statement into canonical surfaces (ROADMAP § Locked architectural principles now 12 principles; CLAUDE_MANAGER carries empirical-audit + hook-path-discipline + Co-Authored-By-trailer rules; STORY.md has Mission section). Handoff simplified to sprint state + active loose-ends; principles + sprint-rules sections dropped (now in canonical homes — see Where things live below).
<!-- cruft-check:exempt-historical -->
- **v1.2.0 meta-evolution tier** opens next. Nine components, opens with `manager-optimizer` (Level-3 meta-meta). Gated on **v1.1.4 production miles** — plugin-verification surface just opened, audit triad needs operational data. Recommend deferring until v1.1.4 bakes ≥2 weeks on Trainer-View / Echoes-Of-Gill (cadence reset after the v1.1.3 → v1.1.4 ship sequence).
- **v2.0 plugin recommendation** later still — folds `integration-checker` + `code-quality-auditor` Layer 3 semantics + curated catalog. Verbatim principle: *"Don't be a directory; be a quality filter."*
- **CI green** across Ubuntu / macOS / Windows for every commit in the sprint. **Dogfood-mirror invariant** held throughout — every `template/` change byte-identical in skeleton's own `.claude/` except documented intentional drift (defaultMode plan vs default; dogfood-only cruft-check SessionStart hook; `compactPrompt` placeholder vs resolved).

## Where things live

- **Locked architectural principles** → `docs/ROADMAP.md` § Locked architectural principles
- **Strategic judgment patterns + orchestration rules** → `CLAUDE_MANAGER.md` § Strategic judgment patterns
- **Project mission** → `docs/STORY.md` § Mission
- **Active sprint state** (Phase recaps, what just shipped, what's queued) → this doc § Sprint state — what shipped
- **Active loose ends** (current decisions pending, recurring friction not yet fixed) → this doc § Loose ends / queued items

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

VERSION 1.1.3 → 1.1.4. CHANGELOG promotion with summary "plugin-verification surface open". Pre-cut sweeps: `cruft-check` surfaced 9 heuristic-x findings — README:52 stale v1.1.3 anchor (real fix folded in via marker), 8 handoff findings (transient, deferred to next handoff refresh = Phase 26 below). **Zero heuristic-x findings** elsewhere — Phase 20 scope tuning held cleanly through Phase 24's substantial additions. `plugin-quality-check` against real installed `42crunch-api-security-testing@1.0.1`: **zero findings** — all three heuristics clean on production plugin. **First real-world plugin-audit pass** (Phase 24's synthetic verification already proved each heuristic catches its target). Doc-rot folded in: `.gitignore` extended with `.claude/.last-plugin-quality-check` (matches existing `.last-*` marker family). Annotated tag `v1.1.4` + GitHub Release with `[1.1.4]` CHANGELOG as notes. Handoff refresh deferred to next phase per Phase 23 precedent.

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

**Rolled forward to v1.1.5-or-later or v2.0:**

- `integration-checker` (Layer 1+2 plugin verification) — planned for v2.0.
- Semantic "fitness vs description" checks — Layer 3 originally scoped for `code-quality-auditor`, now deferred to v2.0 alongside `integration-checker`.
- Curated plugin catalog — v2.0 fold.

**No v1.1.5 placeholder yet** — left open until real items queue.

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

**Gating language updated:** v1.2.0 needs **v1.1.4 production miles** before opening (cadence reset after the v1.1.3 → v1.1.4 ship sequence). Without empirical dispatch data from the v1.1.4 baseline (the audit triad now in place), `manager-optimizer` would optimize against vibes — the same trap that pushed it to v1.2+ originally.

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

## Loose ends / queued items

- **Node.js 20 deprecation in CI** — GitHub Actions deprecation timeline cites June 2026 for full removal. CI uses `actions/checkout@v4` + `actions/setup-python@v5` which still rely on Node 20 internals. Watch for action version bumps before then; the matrix may need a refresh.
- **`uninstall.sh` deferred.** No production demand yet — both current targets (Trainer-View, Echoes-Of-Gill) have stable installs. Will ship when there's real signal (e.g. a user trying to roll back the skeleton). Locked invariants when it lands: read `.skeleton-version`'s `files` map, prompt before deleting any locally-modified file (same `LOCALLY_MODIFIED` discipline `update.sh` uses).
- **`defaultMode` mismatch.** Template ships `"defaultMode": "default"` in `settings.json.template`; skeleton's dogfood `.claude/settings.json` uses `"defaultMode": "plan"`. Intentional — dogfood-as-meta-system needs plan-mode discipline; target projects don't necessarily. Don't conflate.
- **Existing installs ready for `update.sh` to v1.1.4.** Trainer-View and Echoes-Of-Gill are still on v1.0 baseline. v1.1.4 is the natural moment to run `bash <skeleton>/scripts/update.sh` against their `.claude/`. Six-way classification handles the delta: new template agents (session-observer, drift-checker, task-watchdog, code-quality-auditor), new template scripts (`drift-check.sh`, `task-watchdog.sh`, `plugin-quality-check.sh`), new template lib (`destructive-{bash,powershell}-patterns.sh`), 5 hook files including the new PowerShell safety hook from Phase 21, schema docs, the `resolved_at` observation-schema extension, the captures surface (workflow-suggester rewrite + script-builder X-builder), the captures-surface enum expansion (`doc-fix` / `infrastructure-fix` / `lesson`), and the SessionStart hook chain now firing the plugin-quality-check entry. Update is non-destructive; local modifications stay.
<!-- cruft-check:exempt-historical -->
- **task-watchdog deferred signals.** Three signals out of v1.1.0 scope, ordered by gating: (1) **no-progress** — same tool call returning identical output ≥N times consecutively; needs real-time hook surface CC doesn't expose. (2) **approval-waiting** — tool prompt sitting unanswered for >N minutes; same hook-surface gap. (3) **resource anomalies** — token / memory / CPU spikes; bundles with v1.2.0 `token-efficiency-monitor` proactive upgrade (same Gap #4 investigation into Claude Code's token-data exposure to agents).
<!-- cruft-check:exempt-historical -->
- **handoff:136 disposition.** The `v0.9.0` historical anchor (in the prose "the v1.0 cut shipped a stale README ('v0.9.0') that survived nine months") was an indefinite-accepted heuristic-x FP through v1.1.2. Phase 20 marker-exempted it via `<!-- cruft-check:exempt-historical -->`. Preserved as a historical anchor — the v1.0 stale-README incident motivates the "sweep at release cuts" sprint rule; deleting the reference would lose the rule's rationale.
- **PreCompact + SessionEnd verification opportunistic.** Both hooks exist (PreCompact backup, SessionEnd session-observer) and emit valid schema-conformant output. Their real-time firing is observed only opportunistically — we know they emit correctly because the SessionStart cruft-check pattern was the same shape and was verified after Phase 14d's `type: command` wiring fix. Deferred unless / until a session inspection turns up a misfire.
- **`.skeleton-version` dogfood lag.** Skeleton repo doesn't carry its own `.skeleton-version` marker. The marker exists for target-project installs to track which skeleton commit they came from. Dogfood lag is intentional — skeleton edits its own `.claude/` directly without going through `install.sh` — so no marker is meaningful for skeleton-as-project. Don't add one; don't treat the absence as drift.
<!-- cruft-check:exempt-historical -->
- **Unresolved Bash-growth mystery in `settings.local.json`.** Pre-Phase-21, 12 `Bash(...)` entries had accumulated in the local file via "Always allow" clicks despite the bash-safety hook returning `permissionDecision: allow` on those same commands. Most likely cause: pre-Phase-14d historical residue when hooks were silently inert; CC's "Always allow" doesn't auto-prune entries that are now redundant. Phase 21 verified the hook DOES emit allow correctly post-Phase-14d. No code change earned. Diagnose only if growth resumes post-v1.1.4 (no new Bash entries observed during Phase 22 / 24 / 25 sessions).
- **Windows Git Bash /tmp path gotcha** — synthetic-test only, not a runtime issue. Phase 24 hit this during plugin-quality-check synthetic verification: `/tmp/tmp.XXXX` (Git Bash POSIX path) confuses Windows Python's `os.path.normpath` — slashes get converted to backslashes and the path resolves wrong (e.g. `/tmp/...` becomes `\tmp\...` which Windows Python treats as a relative path that doesn't exist). **Production path** `~/.claude/plugins/cache/` resolves correctly via `os.path.expanduser` to `C:\Users\<user>\.claude\plugins\cache\` (Windows-native absolute). For synthetic tests on Windows, use `$env:TEMP\<dir>` or `C:\tmp\<dir>` rather than Git Bash's `/tmp`. Worth flagging here so future synthetic-test work doesn't waste an hour rediscovering this.

## What's next

Post-Phase-31 codification cascade landing now. v1.1.4 released; audit closure (Phase 30 / 30b / 30c) and codification (Phase 31) shipped post-cut. v1.1.5 has no major feature items queued. Two strategic directions remain open:

<!-- cruft-check:exempt-historical -->
**Defer v1.2.0 design open until v1.1.4 bakes.** v1.2.0 meta-evolution tier opens with `manager-optimizer` (Level-3 meta-meta — watches HOW the manager decides). Gated on production miles per ROADMAP § v1.2.0 Gating. v1.1.4 just shipped; the audit triad (cruft-checker + drift-checker + code-quality-auditor) hasn't accumulated any operational data yet. Recommend waiting **≥2 weeks of active use on Trainer-View / Echoes-Of-Gill** before opening v1.2.0 design. Without real dispatch data — *including data on which audit-triad findings are real vs noise* — `manager-optimizer` would optimize against vibes. Passive option — no work; just wait for the baseline to mature.

**Phase 32+ pre-pinball queue.** Marker refresh (Phase 32 — `update.sh` against self), directive-layer alignment (Phase 33 — remove `/goals` TEMPLATE STUB, reframe `integration-checker` as DEFERRED, add `code-quality-auditor` dispatch H3), bundle install of 6 ecosystem plugins (Phase 34), evaluation window (Phase 35), composition rules + retire/repurpose decisions (Phase 36+), v1.5 ecosystem integration tier (Phases 38-45). Pre-pinball queue captured in `docs/ROADMAP.md` § v1.1.5+.

**Standard three-commit cadence throughout v1.1+** — brief → plan → A (mechanism) → B (integration + dogfood mirror) → C (CHANGELOG bullet) → push. Small-fix phases collapse to single commits per the Phase 10 rubric. Pre-cut cruft + plugin-quality sweeps mandatory at release cuts (Phase 6 / 19 / 22 / 25 precedent). Empirical audit before trusting brief diagnoses (Phase 21 precedent, now codified in `CLAUDE_MANAGER.md`).
