# claude-skeleton — session handoff

Current as of **2026-05-15** — through **v1.1.0 release** (commit `4bff438`, tag `v1.1.0`).

This doc is the chat-session continuity surface. Read top-down at the start of a fresh session to onboard the manager onto current state, locked principles, and the next phase to draft a prompt for. Not a release artefact — lives outside the changelog.

## TL;DR

- **v1.1.0 shipped 2026-05-15.** The capture/reuse loop is in production: five components — `session-observer`, `workflow-suggester`, `script-builder`, `drift-checker`, `task-watchdog` — closing autonomy **Gap #2** (system-proposes-own-evolution). Pipeline: observations → captures → drafts → promoted artefacts, with user-approval gates at every stage.
- **GitHub Release** published with the `[1.1.0]` CHANGELOG section as notes: <https://github.com/DevAyar/claude-skeleton/releases/tag/v1.1.0>.
- **v1.1.x polish is next.** cruft-checker opens the tier (third observation producer; pattern well-established after task-watchdog). Then code-quality-auditor, then lessons-log integration. Standard three-commit cadence.
- **v1.2.0 meta-evolution tier** follows v1.1.x. Nine components, opens with `manager-optimizer` (Level-3 meta-meta). Empirical reason for the gate: v1.1.0 needs production miles before the manager-optimizer has real dispatch data to optimize against.
- **v2.0 plugin recommendation** later still — folds `integration-checker` + `code-quality-auditor` + curated catalog. Verbatim principle: *"Don't be a directory; be a quality filter."*
- **CI green** across Ubuntu / macOS / Windows for every commit in this sprint. **Dogfood-mirror invariant** held throughout — every `template/` change byte-identical in skeleton's own `.claude/`.

## Sprint state — what shipped

### v1.0.0 — 5630caa, 2026-05-14 (recap)

Orchestration layer cut: directive layer (CLAUDE_MANAGER.md.template), 9 baseline agents, 6 skills, install/update infra with per-file SHA-256 hashes, three-platform matrix CI. Validated on Trainer-View (Flutter + Firebase) and Echoes-Of-Gill (Godot). v1.1+ work starts on top of this baseline.

### Phase 1 — `f39b0e3` → `92f0c61` — session-observer foundation

Observation primitive at `template/.claude/agents/05_meta/session-observer.md` + 8-field schema + `template/.claude/observations/` storage + SessionEnd hook script. Multi-source-extensible from day one — `source` and `pattern_type` enums designed for future producers (`task-watchdog`, `cruft-checker`). Observation only — no suggesting, drafting, or auto-action.

### Phase 1b — `5d6ff53` + `b6439be` — dogfood mirror + hooks asymmetry fix

Mirrored session-observer into skeleton's own `.claude/`. Surfaced that the dogfood `settings.json` had no hooks block at all — PreCompact + SessionStart had never been wired in dogfood (template only). Fixed in a follow-up commit. Established the dogfood-mirror invariant as a hard rule for the rest of the sprint.

### Phase 1c — `9711de3` — hooks README doc-rot fix

Updated `template/.claude/hooks/README.md` from listing two wired events (SessionStart, PreCompact) to three (adding SessionEnd from Phase 1). Surgical fix.

### Phase 2 — `3a35ecc` → `400658c` — workflow-suggester rewrite

Wholesale-rewrote v1.0's prose-suggestion `workflow-suggester` into a schema-driven consumer of `.claude/observations/`. Drafts capture markdown files to `.claude/captures/` for human review with a 7-field frontmatter + 4-section body. Idempotent across re-runs (any status counts as "already considered"). Default thresholds: `occurrences >= 3 AND confidence >= medium`. Pure drafting — no downstream artifact building; that's the X-builders.

### Phase 3 — `67491c3` → `d0177dd` — script-builder (first X-builder)

Reads captures filtered to `status: approved AND suggested_artifact_type: script`, drafts bash files under `.claude/scripts/drafts/<source_pattern_id>.sh.draft`. Honors 5-section discipline + path-shape guards + `bash-safety` integration. `.sh.draft` extension makes drafts unexecutable until user promotes. Schema extension to `workflow-suggester.schema.md`: status enum gains `shipped` + optional `shipped_to` field — additive, existing semantics preserved.

### Phase 3c — `1a85d86` — schema body-convention doc-rot fix

Surgical fix to `workflow-suggester.schema.md`'s generic body convention (lines 50-60) to surface the full `draft → approved → shipped` lifecycle. Phase 6 closed two carry-over refs missed here (realistic example body + CLAUDE_MANAGER subsection).

### Pre-Phase-4 — `dcb72bc` — ROADMAP.md restructure

Strategic chat-side audit between Phase 3 and Phase 4. Captured shifts in canonical sequencing: tight v1.1.0 scope (5 components), v1.1.x polish tier, expanded v1.2.0 (9 components), v2.0 fold, v3.0+ multi-LLM as sibling project, two architectural principles locked (multi-project graduation, two audit surfaces), explicit Cuts section. Doc-only commit, no behaviour change.

### Phase 4 — `ec01c2a` → `c50a8f1` — drift-checker

Read-only version-drift check at session start. Compares installed `version` field in `.skeleton-version` against cached `cached_skeleton_head` (last known remote release). Additive schema extension to the marker (two new fields). New `update.sh --check-remote` flag is the only network path — `git ls-remote --tags`, 10s timeout, picks highest semver tag. SessionStart hook extended to fold `[skeleton-drift]` notice into `additionalContext`. Locked invariants: drift-checker NEVER hits network, NEVER writes marker, NEVER auto-applies.

### Phase 5 — `89d9c31` → `8a8b90e` — task-watchdog + ownership transfer

Retrospective observer of the prior Claude Code session. Reads `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl` (second-newest JSONL by mtime — newest is current session), pairs `tool_use`/`tool_result` events, emits two pattern shapes: long-running bash (`pattern_type: other` with notes) and recurring failures (`pattern_type: recurring_failure`). Idempotent via `.last-watchdog-session` marker. Coordinated ownership transfer: session-observer no longer emits `recurring_failure` — task-watchdog is canonical producer of that type. Schema enum unchanged (no new fields, no new values).

### Phase 6 — `d72e092` → `4bff438` — v1.1.0 release cut

Doc-rot sweep first (`d72e092`): two Phase-3c carry-over refs (workflow-suggester schema example body + CLAUDE_MANAGER "When to dispatch workflow-suggester" subsection) updated to surface the full lifecycle including `shipped` + `shipped_to:`. Then release cut (`4bff438`): VERSION 1.0.0 → 1.1.0, CHANGELOG promotion with phase-ordered bullets + summary paragraph, README counts (14 agents / 4 scripts / 3 hooks), ROADMAP v1.1.0 section flipped to all-five-shipped, STORY.md version line. Annotated tag `v1.1.0` + GitHub Release with `[1.1.0]` CHANGELOG as notes.

## Roadmap (condensed; full version in `docs/ROADMAP.md`)

### v1.1.0 — ✓ all 5 components shipped

Capture/reuse loop in production. Pipeline running daily on dogfood + real production targets.

### v1.1.x — polish before v1.2.0

- **cruft-checker** — third observation producer. Surfaces dangling refs, doc-rot, stale CHANGELOG entries, deprecated patterns. Feeds `workflow-suggester` like any other source. Natural opener for v1.1.x — pattern well-established after task-watchdog.
- **code-quality-auditor** — Layer 3 of plugin verification. Reads actual source code; evaluates fitness vs description. Folds into `integration-checker` for v2.0.
- **Lessons-log integration as `suggested_artifact_type: lesson`** — no separate skill; collapses into existing captures surface.

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

### v2.0 — plugin recommendation surface

Folds `integration-checker` + `code-quality-auditor` + curated catalog. The standalone-phase framing is gone. *"Don't be a directory; be a quality filter."* (verbatim).

### v3.0+ — multi-LLM orchestration as sibling project

Re-targeting the skeleton for Claude + DeepSeek + others would change the project's centre of gravity. Stays Claude-Code-only through v2.0. If pursued: sibling project (e.g. `claude-skeleton-bridge`), not a feature graft.

## Cuts (rationale locked, do not relitigate)

- **`skill-builder` and `agent-builder` cut from v1.1+ X-builder sequence.** Markdown writing is cheap — no automation gain. The recommendation/analysis function for "should this be a skill, agent, script, or command?" moves to `artifact-fit-analyzer` (v1.2.0). `script-builder` stays because bash has structural discipline (strict-mode, path-shape guards, `bash-safety`) markdown doesn't.
- **Gap #1 (auto-dispatch by intent) deferred to v1.2+.** Closing it without empirical dispatch data would mean optimizing against vibes — the same trap that pushed `manager-optimizer` itself to v1.2+. Manual dispatch via `CLAUDE_MANAGER.md.template` patterns continues to work; gap is a known seam, not a blocker.
- **Plugin recommendation as a standalone v2.0 phase cut.** Folded into `integration-checker` + `code-quality-auditor`. A catalog without quality verification is a directory (which the verbatim principle rules out); quality verification without a catalog is just `integration-checker`. The two only justify a v2.0 phase together.

## Locked architectural principles

### Multi-project graduation threshold

A pattern graduates from one project's `.claude/` into `template/` (i.e. ships to every install) when it crosses a hard four-part threshold:

- **≥66% of installed projects** show the same pattern (broad adoption, not narrow taste).
- **Minimum 3 projects** in the sample (one or two installs is anecdote).
- **≥4 weeks stable** — no edits or reverts in any contributing project during the window.
- **Zero negative observations** in the same window — no project has flagged the pattern as broken, noisy, or contraindicated.

v1.2+ mechanism: `meta-session-observer` watches cross-install signal → `workflow-suggester` drafts a graduation capture (`suggested_artifact_type: graduation`) → user approves → `template-promoter` moves the artefact, updates `install.sh` manifests, regenerates baseline hashes, updates CI scenarios. Threshold + mechanism together prevent the skeleton from inheriting any one project's idiosyncrasies.

### Two distinct audit surfaces

The skeleton runs audits at two scopes; mixing them muddies discipline.

- **Project-level (`infrastructure-auditor` in `template/`).** Audits a single project's `.claude/`. Installed everywhere. Dispatches `cruft-checker` + `drift-checker` + `artifact-fit-analyzer`. Findings local to the project.
- **Skeleton-level (`roadmap-auditor` in dogfood only).** Audits the skeleton's own roadmap, schemas, cross-phase contracts. Lives ONLY in dogfood `.claude/`, never `template/`. Findings are about the skeleton itself — drift between roadmap claims and codebase reality.

Shared mechanics (cruft detection, doc-rot catches), different scope. Both scheduled via `/goals` expanded `schedule` field.

### Other principles (in custom-instructions, not re-derived here)

- **Ever-evolving being, not a fixed install** — the skeleton ships a baseline; `project-tuner-helper` shapes it per-project; `workflow-suggester` keeps catching new patterns.
- **Approval-gated autonomy** — thinking is autonomous, action is approved.
- **Define-everything-upfront** — brief specs lock interpretations before code; plan-mode is the canonical place to surface them.
- **Narrow-scope-by-design** — each phase locks scope at brief time; "out of scope" sections in plans are load-bearing.
- **Composition, not competition** — claude-skeleton composes with the `/plugin` marketplace and seven named community libraries; doesn't replace them.

### Sprint rules locked in v1.1+

Two rules surfaced during the sprint that should persist across sessions:

- **Sweep known doc-rot at release cuts; don't defer to cruft-checker.** Release cuts must ship the truth. Shipping known-stale docs with a release tag is exactly the rot pattern the skeleton is built to prevent. **Why:** the v1.0 cut shipped a stale README ("v0.9.0") that survived nine months until Phase 6 caught it — that's the failure mode. **How to apply:** at release-cut phases, fold any flagged doc-rot fixes into Commit A so the tagged commit captures the corrected state. Surgical fixes only; don't expand into a broader audit (that's `cruft-checker`'s job). Phase 6 set the precedent.
- **Don't ship retrospective signals that need a Claude Code surface that doesn't exist yet.** **Why:** Phase 5's task-watchdog originally had 5 candidate signals; two of them (no-progress, approval-waiting) needed real-time hook surfaces CC doesn't expose, and a third (resource anomalies) needed token-data exposure that's not in any current hook. Shipping those as conditional deliverables would have pushed scoping decisions into the CC tab. **How to apply:** when a brief proposes a signal whose detection requires unavailable instrumentation, defer it to the version where the relevant investigation lands (typically v1.2.0 for token data, future for real-time hooks) and explicitly note the deferral in the brief's locked decisions. Phase 5 set the precedent for task-watchdog's 2-signal scope.

## Loose ends / queued items

- **Node.js 20 deprecation in CI** — GitHub Actions deprecation timeline cites June 2026 for full removal. CI uses `actions/checkout@v4` + `actions/setup-python@v5` which still rely on Node 20 internals. Watch for action version bumps before then; the matrix may need a refresh.
- **`uninstall.sh` deferred.** No production demand yet — both current targets (Trainer-View, Echoes-Of-Gill) have stable installs. Will ship when there's real signal (e.g. a user trying to roll back the skeleton). Locked invariants when it lands: read `.skeleton-version`'s `files` map, prompt before deleting any locally-modified file (same `LOCALLY_MODIFIED` discipline `update.sh` uses).
- **`defaultMode` mismatch.** Template ships `"defaultMode": "default"` in `settings.json.template`; skeleton's dogfood `.claude/settings.json` uses `"defaultMode": "plan"`. Intentional — dogfood-as-meta-system needs plan-mode discipline; target projects don't necessarily. Don't conflate.
- **Existing installs ready for `update.sh`.** Trainer-View and Echoes-Of-Gill are on v1.0 baseline. v1.1.0 is the natural moment to run `bash <skeleton>/scripts/update.sh` against their `.claude/` — six-way classification handles the deltas (4 new template files: session-observer, drift-checker, task-watchdog agents + the three new scripts and hook). Update is non-destructive; local modifications stay.
- **task-watchdog deferred signals.** Three signals out of v1.1.0 scope, ordered by gating: (1) **no-progress** — same tool call returning identical output ≥N times consecutively; needs real-time hook surface CC doesn't expose. (2) **approval-waiting** — tool prompt sitting unanswered for >N minutes; same hook-surface gap. (3) **resource anomalies** — token / memory / CPU spikes; bundles with v1.2.0 `token-efficiency-monitor` proactive upgrade (same Gap #4 investigation into Claude Code's token-data exposure to agents).

## What's next

**v1.1.x opens with cruft-checker.** Third observation producer against session-observer's existing schema. Pattern is well-established now — task-watchdog set the precedent for retrospective producers writing to `.claude/observations/` using the existing 8-field schema. cruft-checker scope: dangling refs, doc-rot, stale CHANGELOG entries, deprecated patterns referenced after deprecation. Apply the **pre-build scoping rule** (5 questions from ROADMAP) before drafting the phase brief — locks interpretations before the plan-mode pass:

1. What's the input surface (the docs / code / refs to scan)?
2. What's the signal threshold (when does cruft-checker emit)?
3. What `pattern_type` value(s) does it use?
4. Is detection retrospective or live? (Almost certainly retrospective for cruft.)
5. Where does workflow-suggester route the resulting captures (artifact_type)?

After cruft-checker: **code-quality-auditor** (Layer 3 of plugin verification — reads actual source, evaluates fitness vs description; integrates with existing `integration-checker`; folds into v2.0). Then **lessons-log integration** as `suggested_artifact_type: lesson` (no separate skill — collapses into the captures surface).

After that, v1.1.x is done and **v1.2.0 meta-evolution tier opens** with `manager-optimizer`. v1.1.0 needs production miles between now and then so the manager-optimizer has real dispatch data to optimize against. Don't rush the gate.

**Standard three-commit cadence throughout.** Brief → plan → A (mechanism) → B (integration + dogfood mirror) → C (CHANGELOG bullet) → push. Bump `scenarios.sh verify_marker` atomically with file additions in Commit A (Phase 1 lesson).
