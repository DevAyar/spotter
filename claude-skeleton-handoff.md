# claude-skeleton — session handoff

<!-- cruft-check:exempt-historical -->
Current as of **2026-05-20** — **closed loop on the tuner-baseline-fix cycle**. The bug discovered 2026-05-19 (EoG sync attempt) was diagnosed, fixed skeleton-side (Phase 52), and propagated to all three production installs (Phase 53b/c remediation + Phase 54a/b/c re-syncs) in a single continuous arc. All four installs (skeleton dogfood + TV + PB + EoG) now sit at skeleton commit `789d2cd` with populated `raw_template_baselines` (49 entries each). EoG validated the fix end-to-end: 11 LOCALLY_MODIFIED surfaced and preserved byte-identical.

This doc is the chat-session continuity surface. Read top-down at the start of a fresh session to onboard the manager onto current state, locked principles, and the next phase to draft a prompt for. Not a release artefact — lives outside the changelog. (Prior detail: handoff_13_1 for the bug discovery + first sync round; handoff_12 / handoff_10 for the reframe + telemetry arcs.)

## TL;DR

- **CLOSED LOOP on the tuner-baseline-fix cycle.** Bug discovered 2026-05-19 (EoG sync attempt) → diagnosed same session → fixed in **Phase 52** → propagated via **Phase 53b/c** remediation + **Phase 54a/b/c** re-syncs. Bug-discovery → diagnosis → skeleton-side fix → cross-install propagation ran as **one continuous arc**. The structural-immune-system thesis got its first full end-to-end validation: a structural bug surfaced through production miles, got fixed at the source, and the fix reached every install.
- **All four installs now at `789d2cd`** with populated `raw_template_baselines` (49 entries each): skeleton dogfood, TV, PB, EoG.
- **EoG is the proof point.** Phase 54b re-sync surfaced **11 LOCALLY_MODIFIED** — the **3 known regressions** from the 2026-05-19 apply PLUS **8 hidden tuner customizations** the audit's marker-token heuristic couldn't fully detect. All 11 preserved byte-identical via KEEP. The fix doesn't merely stop NEW clobbering; it correctly surfaces the FULL divergence surface that was previously invisible.
- **Substrate validated end-to-end across three production installs with different tuning depths:** PB (clean-fresh, **0** LOCALLY_MODIFIED) / TV (mid-tuned, **8**) / EoG (deeply-tuned, **11**). The depth-of-divergence gradient is exactly what the model predicts.
- **Plan-mode caught a brief-side premise error before shipping.** Phase 52's brief said the bug was install.sh ordering (records the baseline AFTER the tuner). Actual root cause: `update.sh`'s `files` map mutation in the backfill at `update.sh:431-436` (pre-fix) — `install.sh` already records during `cp`, before the tuner, and never invokes it. The immutable-field fix architecture stood **independent** of the diagnostic correction; the design was right even though the brief's diagnosis was wrong. Codified as Finding #7.
- **Phase 52 shipped `7be698e..789d2cd`** (three commits, **no VERSION bump**): install.sh `raw_template_baselines` field, update.sh classification switch + inline `git worktree` migration, docs. CI green on all three OS.
- **Forward roadmap resumes.** The fix-the-bug arc is closed. Top of queue: **Phase 47** (cross-project git memory, needs 5Q scoping — biggest architectural decision), **Phase 48** (token-cost agent, now has live telemetry across all installs), **Phase 49** (`.gitignore` propagation, surfaced repeatedly).

## Where things live

- **Mission / governance framing** → `docs/STORY.md` § Mission + § Core principles (12 named H3s; matched to ROADMAP CORE 12)
- **Locked architectural principles** → `docs/ROADMAP.md` § Locked architectural principles (core) + § Appendix — operational design principles
- **Strategic judgment patterns + audit cycle + manager directives** → `CLAUDE_MANAGER.md`
- **Baseline semantics under update.sh** (NEW, Phase 52) → `CLAUDE_MANAGER.md` § Baseline semantics under update.sh (H2; byte-identical mirror in `template/CLAUDE_MANAGER.md.template`). Codifies the rule: `LOCALLY_MODIFIED` means a file differs from the template version it was installed from, regardless of who modified it (tuner-helper, user, or both).
- **Marker schema (`raw_template_baselines`)** → `docs/INSTALLATION.md` § Per-file baselines in `.skeleton-version` (Phase 52 updated). Fields: `raw_template_baselines` (immutable, classification source) + deprecated `files` alias (removal queued v1.5+).
- **Update mechanism (FIXED)** → `scripts/update.sh` — classifies against `raw_template_baselines`; inline one-time migration re-hashes the template at the recorded install commit via `git worktree`; safe fallback to current template when the commit can't be located.
- **Install mechanism** → `scripts/install.sh` — records `raw_template_baselines` (during `cp`, before the tuner runs).
- **Per-install constitution doc** → `CLAUDE.md` + `template/CLAUDE.md.template` (Phase 43 reframed; does NOT auto-propagate to installs — Phase 50 will port)
- **CHANGELOG** → `docs/CHANGELOG.md` `[Unreleased]` carries the Phase 52 bullet (no VERSION bump)
- **Core vs integration boundary** → `CLAUDE_MANAGER.md` § Core vs integration boundary
- **Plugin install records** → `docs/PLUGIN-INSTALLS-v1.1.4.md`
- **Observation schema** → `.claude/agents/05_meta/session-observer.schema.md` (Phase 46 `privacy_class` + `target_resource`)
- **Privacy redaction lib** → `.claude/lib/redact-observation.sh`
- **Telemetry generator** → `.claude/lib/generate-session-telemetry.sh`; artifacts under `.claude/telemetry/` (now live across all installs after Phase 54 propagation)
- **SessionEnd hook** → `.claude/hooks/sessionend-observe.sh`
- **CI fixture canonicals** → `.github/test-fixtures/scenarios.sh` (`verify_marker 49`; new scenarios `raw-baseline-install` + `raw-baseline-migrate`, each wired as a `ci.yml` step)
- **Project-tuner-helper** (source of the now-FIXED bug; deliberately untouched by Phase 52 per the fix design) → `.claude/agents/05_meta/project-tuner-helper.md`

## Sprint state — what shipped

### v1.0.0 → v1.1.4 (recap — full per-phase detail in `docs/CHANGELOG.md`)

Orchestration layer (v1.0.0, `5630caa`), capture/reuse loop (v1.1.0), hook infrastructure correctness (v1.1.1), captures-surface enum completion + Model C lesson codification (v1.1.2), operational-friction relief (v1.1.3), plugin-verification surface open (v1.1.4, cut 2026-05-17 at `2a0caf6`).

### Audit-emergent queue (Phases 30 → 34b) + reframe / telemetry arcs (Phases 35 → 46b) — recap

9-phase audit-emergent queue (CC-side audit → mechanical fixes → bulk codification → marker refresh → directive alignment → bundle install → eyes-open claude-mem). Then the reframe arc (Phases 35 → 41, governance reframe), CLAUDE.md reframe + per-component gating + gate-anchored ROADMAP/STORY restructure (Phases 42 → 45), token telemetry foundation + fresh-session stub fix (Phase 46 / 46b). Detail in handoff_10 / handoff_12.

### Phase 46c + first sync round + tuner-baseline bug discovery (recap from handoff_13_1)

Phase 46c shipped (`7be698e`) — CI fixture bump 45→49 + same-commit-fixture-update rule codified in `CLAUDE_MANAGER.md`; first green main since Phase 45. First sync round: TV → `c7865da`, PB → `6011cfe` (both committed-but-unaudited); EoG apply attempted then **REVERTED** to clean `0b2f94c` (its 20-commit backlog + `scripts/update.sh` install preserved). The EoG apply surfaced the **project-tuner-helper baseline-hash bug** (3 confirmed regressions + ~14 suspect files). Full diagnosis in handoff_13_1 § Architectural findings #1.

### NEW SINCE handoff_13_1: closed-loop tuner-baseline fix + propagation — 2026-05-20

#### Phase 52 — Tuner-baseline fix (skeleton-side) — `7be698e..789d2cd` (SHIPPED)

Three commits, no VERSION bump. Switched `update.sh` classification from the mutable `files` map to a new **immutable `raw_template_baselines`** marker field (the template version each file was installed from). A file that differs from that baseline is now `LOCALLY_MODIFIED` — whoever changed it — and is never auto-overwritten, even under `--auto-apply`.

- `e7dcd55` — `install.sh` writes `raw_template_baselines` alongside the (deprecated) `files` map; new CI scenario `raw-baseline-install` + `ci.yml` step.
- `5e2fa6f` — `update.sh` classifies against `raw_template_baselines`; inline one-time migration `git worktree`-pins the recorded install commit and re-hashes the template there (gated so legacy shell markers keep the existing backfill path; never hard-fails); new CI scenario `raw-baseline-migrate` + `ci.yml` step.
- `789d2cd` — docs: new `## Baseline semantics under update.sh` H2 in `CLAUDE_MANAGER.md` + byte-identical template mirror; `docs/INSTALLATION.md` marker-schema update; CHANGELOG `[Unreleased]` bullet.

CI: green on ubuntu / windows / macos. Verified against the live dogfood marker (commit `bba2d8a`): migration recovered 45/49 baselines, 4 safe-fallback, `settings.json` drift correctly `LOCALLY_MODIFIED`, no marker write under `--dry-run`, no stray worktree. **Brief-premise correction:** the bug was update.sh's `files` mutation (backfill), not install.sh ordering — see Finding #7. project-tuner-helper itself untouched.

#### Phase 53b — TV surgical restore — `e647c48` (SHIPPED)

Single commit. Restored **6 files** clobbered by the `c7865da` first-round sync, from pre-sync state `c702b64`: `deploy.sh`, `deploy.md`, `post-edit-test-suggest` (SKILL), `schema-verify-before-edit` (SKILL), `god-file-grep-first` (SKILL), `smoke-test.md`. `commit.sh` / `commit.md` **intentionally skipped** (template versions were the wanted ones). Confirms TV's first-round sync DID carry silent regressions; surgical restore chosen over full revert.

#### Phase 53c — PB hygiene — `35fd693` + `37d5057` + `80ed92a` (SHIPPED)

Three commits. `35fd693` — `.gitignore` (telemetry `events/` + `sessions/` + `.last-plugin-quality-check`). `37d5057` — 31 Godot `.import` files tracked (decision: track). `80ed92a` — SESSION_LOG marker. PB audit found no tuner regressions to restore (it was the fresh-mode install) — only hygiene.

#### Phase 54a — TV re-sync with fixed mechanism — `e647c48..55f3e8a` (SHIPPED)

Two commits on top of the 53b restore. `fb50a09` — marker upgrade + **8 KEEPs**. `55f3e8a` — `.gitignore`. Migration recovered **49 baselines** from `7be698e` (full worktree path). Classification: **8 LOCALLY_MODIFIED** + 0 TEMPLATE_UPDATED / 0 NEW / 0 ORPHAN. The fixed mechanism correctly surfaced TV's tuner customizations; all kept.

#### Phase 54b — EoG re-sync with fixed mechanism — `0b2f94c..880e756` (SHIPPED) — THE PROOF POINT

Two commits on top of the reverted-clean baseline. `bad0d0d` — sync + **11 KEEPs**. `880e756` — `.gitignore`. Migration recovered **24 baselines** from `0beff69` (full worktree path). Classification: **11 LOCALLY_MODIFIED** + 7 TEMPLATE_UPDATED + 7 NEW. The 11 = the **3 known regressions** from the 2026-05-19 apply + **8 hidden tuner customizations** the marker-token heuristic hadn't fully caught. All 11 KEPT byte-identical. End-to-end validation of the fix.

#### Phase 54c — PB re-sync with fixed mechanism — `80ed92a..6550df7` (SHIPPED)

Two commits. `2923e70` — SESSION_LOG housekeeping (per the separate-commit decision). `6550df7` — marker upgrade. Classification: **0/0/0/0** — Phase 52 was docs-only at the `.claude/` scope, and PB had already received the `.claude/` content in the first-round `6011cfe`. Marker now carries `raw_template_baselines`; PB at `789d2cd`.

## Roadmap (condensed; full version in `docs/ROADMAP.md`)

### v1.1.0 → v1.1.4 — ✓ shipped · Audit-emergent queue (30 → 34b) — ✓ COMPLETE · Phases 35 → 46c — ✓ shipped

### Phase 35 evaluation window — REAL SIGNAL NOW ACCRUING

Three production installs (PB / TV / EoG) are now synced to skeleton HEAD through the **fixed** update mechanism. Unlike the 2026-05-19 first-round syncs (which may have carried silent regressions, now remediated), these re-syncs are clean, audited, and divergence-correct — so they **count as real Phase 35 signal accrual** (replaces handoff_13_1's "today's syncs do NOT count" caveat). The window has already validated its purpose: the multi-project production-miles design surfaced the tuner-baseline bug, and the same design validated the fix.

### Phases 52 + 53b/c + 54a/b/c — ✓ ALL SHIPPED

The tuner-baseline-fix cycle, end to end. See § Sprint state.

### Next-priority queue (forward roadmap resumes)

- **Phase 47 — Cross-project git memory (wild-idea-1).** Pre-build 5Q scoping pending in chat. Biggest architectural decision queued; could collapse v3+ cross-install graduation into v1.5 territory.
- **Phase 48 — Token-cost agent.** Manager-peer-sophistication agent (CORE 11). Now has **real telemetry data across all installs** to design against (Phase 46 telemetry live everywhere after Phase 54 propagation).
- **Phase 49 — `.gitignore` propagation in update.sh.** Surfaced repeatedly across TV/PB/EoG; ready for scoping. Likely bundles the SessionEnd-hook / SESSION_LOG-marker fix (see Loose ends).
- **Phase 50 — CLAUDE.md / CLAUDE_MANAGER.md universal-shape port** to TV/EoG/PB. Manual diff-and-port pass (per-project governance owns the constitution, so update.sh won't carry it).
- **Phase 51 — TV observation diagnostic.** TV has zero observation `.json` files; blocks v1.2.0 per-project mechanism design for TV specifically.

### v1.1.5 — Onboarding tier (OPEN)

5 phases A-E. Now unblocked — onboarding docs can safely reference the **fixed** update flow.

### v1.2.0 — Meta-evolution tier (per-component gating per Phase 44)

Per-project components open as soon as ANY ONE project produces sufficient empirical signal — and the Phase 54 re-syncs are the first real accrual. Pure-design components (`/goals` expanded mechanism, scheduled-goals schedule field) open NOW.

### v1.5 / v2.0 / v3.0+ — same as handoff_12/13_1

v1.5 ecosystem integration (gated on v1.1.5 ship), v2.0 plugin recommendation surface, v3.0+ ecosystem maturity. Cross-install graduation machinery may move to v1.5 if wild-idea-1 (Phase 47) ships earlier.

## Wild ideas backlog

Carry-over from handoff_13_1, unchanged:

1. **Cross-project memory via git, no infrastructure.** RANKED #1.
2. **Discipline-as-code.** RANKED #3.
3. **Inverted gate / `/flow` mode.** RANKED #5.
4. **The "ant farm" — synthetic dogfood projects.** RANKED #2.
5. **`/debate` command.** RANKED #4. v2.0 placement.
6. **Handoff/discovery chatbot surface.** Hosted "Ask &lt;ProjectName&gt;" — different category from discipline mechanisms; belongs as candidate companion project (like the multi-LLM bridge), not skeleton-core. The underlying need ("knowing what plugins/scripts/agents I have installed") is NOT actually a chatbot — it's `/inventory` (manifest-based v1, already in the v1.5 backlog). Chatbot UI was over-engineered delivery surface. **RANKED LOW.**

**User idea #7 — `.gitignore` propagation in update.sh** — CODIFIED as Phase 49 candidate.

## Cuts (rationale locked, do not relitigate)

Carry-overs from handoff_12 / handoff_13_1 — all still valid. **No new cuts this session.**

## Architectural findings from this sprint

### #1 (RESOLVED) — The project-tuner-helper baseline-hash bug

`project-tuner-helper` customizes template files at install time; those edits were baked into the install-time baseline hashes `update.sh` recorded, so tuner customizations looked UNMODIFIED to the modification check and `[A]pply all` silently overwrote them with generic template versions. Discovered 2026-05-19 (EoG apply: 3 confirmed regressions + ~14 suspect).

**RESOLVED in Phase 52** (`7be698e..789d2cd`) via the immutable `raw_template_baselines` field (classification compares current file → the template version it was installed from). **Propagated** to all installs: TV (Phase 53b restore + Phase 54a re-sync, `55f3e8a`), PB (Phase 53c hygiene + Phase 54c re-sync, `6550df7`), EoG (Phase 54b re-sync, `880e756`). EoG's 11 LOCALLY_MODIFIED — 3 known + 8 previously-hidden — preserved byte-identical, validating the fix end-to-end. Note the actual root cause was `update.sh`'s `files` mutation in the backfill, not install.sh ordering (see Finding #7).

### #2 (OPEN — Phase 49) — `.gitignore` propagation gap in update.sh

When the skeleton adds a template directory that should be gitignored (e.g. `telemetry/events/`, `telemetry/sessions/`), the project pulling the update gets the dir but not the ignore rule. Mitigated **ad hoc** this cycle — each Phase 53c/54a/54b/54c re-sync committed a per-project `.gitignore` — but the systematic fix in `update.sh` remains **Phase 49**. Design directions: (a) `update.sh` detects new template dirs that look ignorable and proposes additions, or (b) ship `.gitignore-fragment` files per template directory.

### #3 (OPEN — Phase 51) — Empty-observations signal on TV

TV's `.claude/observations/` has zero `.json` files despite being a Phase 35 production-miles project. If TV isn't accumulating observations, it isn't feeding the data layer v1.2.0 `manager-optimizer` design depends on. **Phase 51** diagnostic before any v1.2.0 per-project component depending on observation density gets designed.

### #4 (OPEN — Phase 50) — CLAUDE.md / CLAUDE_MANAGER.md don't auto-propagate

Per-project governance: each install owns its constitution after install, and update.sh respects this. Consequence: Phase 41/43 universal-shape improvements (and the new Phase 52 `## Baseline semantics` H2) don't reach TV/EoG/PB without an explicit manual port. **Phase 50** candidate. Pattern lock: any future skeleton-level reframe of `CLAUDE.md` / `CLAUDE_MANAGER.md` needs a paired "port to installed projects" phase queued as follow-up.

### #5 (carry-over, codified) — Handoff entries can go stale vs git ground truth

EoG's "pending tune commit awaiting user review" was actually already committed, just unpushed. Discipline lesson (memory edit #10): any CC prompt acting on handoff assertions about project state must ground-truth via `git log --oneline -N && git status` FIRST. Still load-bearing.

### #6 (carry-over, now validated cleanly) — Time-since-install correlates with sync friction

PB (most-recent fresh install) → 0 LOCALLY_MODIFIED; TV (older) → 8; EoG (longest-running, deepest-tuned) → 11. With the tuner-baseline bug now FIXED, this gradient is **legible and accurate** (handoff_13_1 caveated that LOCALLY_MODIFIED counts under-reported real divergence; post-fix they don't). Reinforces "skeleton ships a seed, projects diverge naturally" — and the divergence is now correctly surfaced and preserved.

### #7 (NEW) — Plan-mode as brief-error insurance

Phase 52's brief had an inaccurate premise: it claimed `install.sh` recorded the baseline AFTER the tuner. Actual: `install.sh` records during `cp`, before the tuner, and never invokes it — the real bug was `update.sh`'s `files` map mutation in the backfill at `update.sh:431-436` (pre-fix). CC's plan-mode pass surfaced the discrepancy **before** commits shipped; the immutable-field fix architecture stood independent of the diagnostic correction (the design was right even though the diagnosis was wrong). **Discipline lesson:** plan-mode is not just scope verification — it's **brief-premise verification**. Codify going forward: the pre-build 5Q scoping rule enforces upfront definition, but plan-mode is the safety net when a brief's *diagnosis itself* is wrong, not just its scope.

## Loose ends / queued items

**Closed since handoff_13_1:**
- ✓ **Phase 52** tuner-baseline fix — SHIPPED (`7be698e..789d2cd`).
- ✓ **TV first-round sync uncertainty** (`c7865da`) — audited; 6 files surgically restored (Phase 53b `e647c48`); re-synced clean (Phase 54a `55f3e8a`).
- ✓ **PB first-round sync uncertainty** (`6011cfe`) — audited (no regressions); hygiene + re-sync (Phase 53c / 54c `6550df7`).
- ✓ **EoG re-sync** — done (Phase 54b `880e756`), 11 KEEPs preserved.
- ✓ **Godot `.import` tracking decision (PB)** — resolved: tracked (`37d5057`). EoG handled in its re-sync.

**NEW from this session — queued:**
- **Residual `M docs/SESSION_LOG.md` on TV** — hook-appended session-end marker left the tree dirty post-push; queue for the next session-log commit.
- **7 EoG infra files now live** (telemetry hooks + scripts + agent-doc additions from the re-sync) — the first SessionEnd run is worth a glance for unexpected errors, but nothing requires action.
- **SessionEnd hook routinely appends to `docs/SESSION_LOG.md`**, making "clean tree post-push" verifications structurally awkward across multiple phases — needs a small fix (gitignore the marker OR make the hook idempotent against clean trees). Queue as a **Phase 49 follow-up** or its own small phase.

**Carry-overs still queued (from handoff_12/13_1):**
- **`defaultMode` template question.** Template ships `default`; dogfood uses `plan`. The bug-driven urgency is gone (Phase 52 + EoG re-sync correctly KEPT `plan`), but the design question stands: should the template ship `plan` as default given how broadly users want plan-mode protection? Revisit, not urgent.
- **claude-mem summarization empirical verification** — first fresh-session test in a future chat.
- **Node.js 20 deprecation in CI** — `actions/checkout@v4` + `actions/setup-python@v5` (June 2026 watch); trivial bump whenever CI is next touched.
- **`uninstall.sh` deferred** — no production demand.
- **task-watchdog deferred signals** — bundle with the token-cost agent (Phase 48).
- **PreCompact + SessionEnd verification opportunistic.**
- **Bash-growth mystery in `settings.local.json`** — diagnose only if growth resumes.
- **Windows Git Bash /tmp path gotcha** — synthetic-test only.
- **Phase 35 watch items (claude-mem-specific).**
- **Disk-space pre-check for plugin installs.**
- **`cached_skeleton_head` population deferred indefinitely on dogfood** (structurally meaningless — dogfood IS upstream).
- **commit-commands vs commit.sh dispatch overlap** — Phase 36 evaluation candidate.
- **Bash-safety FP scoping** — recurring FP across Phase 21 + 24; needs a proper 5Q scoping pass.
- **EoG stale branches cleanup** (`pre-skeleton-migration-20260513` + `worktree-agent-…`) — trivial.
- **CLAUDE.md L5 + L25 tone pass** — bundle with the Phase 50 port pass if appropriate.
- **README minimal-alignment edit** — small coherence move pre-v1.1.5-A.
- **Update cadence visibility** — skeleton could surface "N commits behind" as a session-start observation via the drift-checker producer. Phase 52 made this adjacent: install.sh now records the install commit + raw template hashes per file, so recording/comparing skeleton HEAD per project is a short hop. v1.5 candidate.

## What's next

**The fix-the-bug arc is closed.** All four installs are at `789d2cd` with correct baselines; the forward roadmap resumes. Top-priority order:

1. **Phase 47 — Cross-project git memory (wild-idea-1).** Needs the pre-build 5Q scoping pass; biggest architectural decision queued. Could pull v3+ cross-install graduation forward into v1.5.
2. **Phase 48 — Token-cost agent.** Has real telemetry data to design against now that Phase 46 telemetry is live across all installs (post-Phase-54 propagation).
3. **Phase 49 — `.gitignore` propagation in update.sh.** Surfaced repeatedly across TV/PB/EoG; ready for scoping. Likely bundles the SessionEnd-hook / SESSION_LOG-marker fix.
4. **Phase 50 — CLAUDE.md / CLAUDE_MANAGER.md universal-shape port** to TV/EoG/PB. Manual diff-and-port pass (one prompt per project, or one with three sections).
5. **Phase 51 — TV observation diagnostic.** TV has zero observation `.json` files; blocks v1.2.0 per-project mechanism design for TV specifically.
6. **v1.1.5 onboarding tier** — 5 phases A-E; now safe to reference the fixed update flow.
7. **v1.2.0 design work** — per-project gate triggers as signal accrues from the Phase 54 re-syncs.

### Pure design work available now

Same list as handoff_12/13_1. With the tuner-baseline arc closed, Phase 47's 5Q scoping is the natural new top-priority pure-design item.

### Note on chat structure

Strategist chat stays as the dedicated strategist layer; Pinball, TV, EoG run entirely inside CC. The multi-tab parallel-sync pattern (strategist chat + parallel CC tabs) proved out across the discovery → fix → propagation arc — it's a validated operational mode.

### Day-end disposition

The single most consequential cycle of the project so far ran to completion: a structural bug that would have silently eroded every install's customizations was discovered through production miles, diagnosed (with a plan-mode catch of the brief's own misdiagnosis), fixed at the source, and propagated to all three production installs — each one's divergence now correctly surfaced and preserved. The skeleton did exactly what it's for. Clean stopping point; the next session opens on Phase 47 scoping with full supporting context.
