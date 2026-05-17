# ROADMAP

The sequencing doc for claude-skeleton. v1.0 → v2.0+. Living — updated as slices land. For backward-looking history see [`CHANGELOG.md`](CHANGELOG.md).

See [`../CLAUDE_MANAGER.md`](../CLAUDE_MANAGER.md) for orchestration mechanics, strategic judgment patterns, plugin discipline rules, and the three-commit cadence rubric. See [`STORY.md`](STORY.md) for project mission and identity.

## v1.0 — shipped (retrospective recap)

Cut at [5630caa] on 2026-05-14. The orchestration layer is in production daily use across **Trainer-View** (Flutter + Firebase) and **Echoes-Of-Gill** (Godot), with **Fitness-Website** as the third target on deck.

What landed:

- **Orchestration discipline** — `template/CLAUDE_MANAGER.md.template` carries the directive layer (strategic judgment patterns, dispatch mechanics, plugin marketplace composition, three-commit cadence, recursive ownership L0/L1/L2). Read top-down at session start; the manager onboards from this file alone.
- **Baseline tooling** — 9 baseline agents (4 core helpers + 5 meta), 6 baseline skills, 2 baseline scripts, 4 baseline commands, 2 baseline hooks (SessionStart, PreCompact).
- **Install / update infrastructure** — `install.sh` (three modes: fresh / merge / replace), `update.sh` (six-way classification using per-file SHA-256 hashes, with backfill for legacy markers), atomic JSON `.skeleton-version` marker.
- **CI** — three-platform matrix (Ubuntu, Windows, macOS) running six install/update scenarios on every push and PR.

**Success-criteria framing (retrospective):** the bar was *felt threshold*, not metrics — claude-skeleton at v1.0 when I and a few peers use it productively over a month, no major install bugs, patterns hold across the two production targets. That's what happened. See [`CHANGELOG.md`](CHANGELOG.md) `[1.0.0]` for the full per-slice breakdown.

## v1.1+ — the capture / reuse loop

The centerpiece of v1.1+. Today the manager learns within a session and forgets between sessions. The capture/reuse loop closes that gap by turning recurring patterns into reusable artefacts — drafted by the system, approved by the user, then formalized into a script or helper that handles the pattern next time it shows up.

### The four autonomy gaps

The loop still maps to the four named gaps in the system, but the resolutions have shifted as components land:

| # | Gap | Closes when |
|---|---|---|
| 1 | **Auto-dispatch by intent** — the manager has to be told to dispatch a helper; it can't infer from request shape. | Deferred to v1.2+ post-`manager-optimizer`, once real dispatch data exists. Manual dispatch via `CLAUDE_MANAGER.md.template` patterns continues to work in v1.1.0. See [Cuts](#cuts--rationale-for-whats-not-in-the-queue). <!-- cruft-check:exempt-historical --> |
| 2 | **System-proposes-own-evolution** — the meta-system can suggest captures in the abstract but doesn't draft them. | **Closed in v1.1.0** by `workflow-suggester` (rewritten to draft concrete capture files) and the first downstream X-builder `script-builder` (drafts bash scripts from approved captures). <!-- cruft-check:exempt-historical --> |
| 3 | **Clarifying-questions layer** — the manager either guesses the intent or asks one-off questions; no structured intake before non-trivial work. | **Closes in v1.2.0** via `/goals` expanded — research → targeted clarify → spec pipeline that X-builders consume natively. Merges with the clarifying-questions layer. |
| 4 | **Proactive token optimization** — `token-efficiency-monitor` reports after a subtask blows its envelope; warning lands too late. | **Closes in v1.2.0** via `token-efficiency-monitor` upgraded from observational to proactive (flags before dispatch when planned scope smells over-budget). Needs design pass on Claude Code's token-data exposure to agents. |

### v1.1.0 — tight scope (5 components)

The capture/reuse loop in its first shippable form. **All five primitives shipped; v1.1.0 cut on 2026-05-15.** No `/goals` dependency at this tier — X-builders read captures directly.

- **`session-observer`** ✓ *(shipped — Phase 1).* Real-time observation primitive. Notices repeated patterns during the session and emits structured observation files (`.claude/observations/<pattern_id>.json`) with redaction rules and a stable 9-field schema. Multi-source extensible — future producers (`cruft-checker`) write against the same schema.
- **`workflow-suggester`** ✓ *(shipped — Phase 2).* Schema-driven consumer of observations. Walks `.claude/observations/`, filters to warranted patterns (confidence threshold `med`/`high`), and drafts concrete capture files at `.claude/captures/<pattern_id>.md` with an 8-field frontmatter and a 4-section body. The four lifecycle states are `draft → approved → shipped` (terminal success) and `rejected` (do-not-re-suggest marker). Idempotent by filename.
- **`script-builder`** ✓ *(shipped — Phase 3, first X-builder).* Reads captures filtered to `status: approved AND suggested_artifact_type: script` and drafts bash files at `.claude/scripts/drafts/<pattern_id>.sh.draft`. Honors the 5-section discipline (shebang+strict-mode / constants / helpers / main / cleanup), `bash-safety` integration, path-shape guards. The `.sh.draft` extension makes drafts unexecutable until the user promotes them.
- **`drift-checker`** ✓ *(shipped — Phase 4).* `.skeleton-version` marker drift between installed projects and the latest released skeleton tag. Read-only, notification-only — no auto-apply, no auto-update. Surfaced by the SessionStart hook chain; cache refreshed via `update.sh --check-remote` (the only network path).
- **`task-watchdog`** ✓ *(shipped — Phase 5).* Retrospective observer of the prior Claude Code session. Reads `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`, pairs `tool_use`/`tool_result` events, and emits two pattern shapes via session-observer's existing schema: long-running bash calls (≥5min default, `pattern_type: other` with descriptive notes) and recurring failures (same normalized signature ≥3 times in-session, `pattern_type: recurring_failure`). Canonical producer of `recurring_failure` observations (ownership transferred from `session-observer`). Retrospective only — real-time signals deferred until Claude Code exposes a polling hook; resource-anomaly signals bundle with v1.2.0's `token-efficiency-monitor` proactive upgrade.

### v1.1.x — shipped (v1.1.1 cut on 2026-05-16)

**Retrospective:** v1.1.x scope expanded mid-tier — the original 5-component polish framing grew to include the dogfood directive layer (Phase 9), observation resolution (Phase 12), and the hook infrastructure fix saga (Phases 14c–14f). v1.1.1 release boundary recognizes the delta. v1.1.2 returns to original polish scope.

**Shipped in v1.1.1:**

- **`cruft-checker`** ✓ *(shipped — Phase 7).* Third observation producer. Dogfood-only. Surfaces dangling refs, doc-rot, stale `CHANGELOG` entries, deprecated patterns still referenced in code. Feeds `workflow-suggester` like any other observation source.
- **Dogfood directive layer** ✓ *(shipped — Phase 9).* `CLAUDE.md` + `CLAUDE_MANAGER.md` + `ROUTING.md` resolved at skeleton repo root from `template/*.template`; mirror invariant locked.
- **Observation resolution** ✓ *(shipped — Phase 12).* `resolved_at` field added across producers; workflow-suggester filters resolved observations from capture generation.
- **Commit-cadence-by-phase-size rubric** ✓ *(shipped — Phase 10/10c).* Three-tier sizing (small fix / medium phase / large overhaul) + every shipped phase ships a `[Unreleased]` CHANGELOG bullet by default.
- **Permissions hardening** ✓ *(shipped — Phases 11/14/14c).* Canonical bare-tool-name allow patterns + PreToolUse hook (`pretooluse-bash-safety.sh`) replacing fragile string-pattern denies; 10 destructive Bash shapes blocked including 4 pipe-to-shell variants the deny rules couldn't catch.
- **Hook infrastructure correctness** ✓ *(shipped — Phases 14c–14f).* `type: command` wiring added to all 5 hook entries; `sessionstart-rules.sh` schema corrected to wrapped `hookSpecificOutput` envelope; hook runtime artifacts gitignored. All five hooks (PreCompact, SessionStart rules, SessionStart cruft-check, SessionEnd, PreToolUse) now fire as designed.

#### v1.1.2 — shipped (cut on 2026-05-16)

Three items landed; one deferred. Completes the captures-surface enum expansion for v1.1.x; closes the hook-schema failure mode retrospectively.

- **cruft-checker heuristic viii** ✓ *(shipped — Phase 16).* Validates `hooks[*]` entries in `.claude/settings.json` and `template/.claude/settings.json.template` against the canonical Anthropic hook schema. Catches missing `type: "command"` / `command` fields — the 14c→14f silent-inert failure mode. Paired with new `docs/HOOK_SCHEMA.md` reference doc.
- **Plan amendment behavior** ✓ *(shipped — Phase 17).* New `### Plan amendment behavior` H3 under `## Strategic judgment patterns` in `CLAUDE_MANAGER.md`. Codifies: apply user-amendment input as a delta to the existing plan file; do not regenerate from scratch. Canonical precedent for the v1.1.x lesson-codification flow that Phase 18 then formalized.
- **Lessons-log integration as `suggested_artifact_type: lesson`** ✓ *(shipped — Phase 18, surface only).* Added `lesson` to `workflow-suggester`'s enum + routing for `"lesson: "` prefix observations + a Lesson codification flow paragraph. No producer heuristics ship (autonomous detection deferred until grounding data exists — same discipline as task-watchdog's deferred resource-anomaly signals); no X-builder ships (lessons codify manually into the directive surface that architecturally fits — Phase 17 precedent).
- **`code-quality-auditor` deferred.** Originally scoped as Layer 3 of plugin verification (reads actual source, evaluates fitness vs description). Home stays open between v1.1.3 standalone and a direct v2.0 fold — the architectural question (useful standalone, or only inside v2.0's plugin-recommendation stack?) gets answered at v2.0 design open.

#### v1.1.3 — shipped (cut on 2026-05-17)

Two items landed. Operational-friction relief — no new component scope, no schema changes; both items are tightening on existing primitives. Closes the v1.1.x polish arc that started post-v1.1.0 (capture/reuse loop) and ran through v1.1.1 (hook infrastructure correctness) and v1.1.2 (captures-surface enum completion + lesson codification flow).

- **cruft-checker heuristic-x scope tuning** ✓ *(shipped — Phase 20).* Extended `EXEMPT_VFILES` and added `EXEMPT_VDIRS` to cover `.claude/agents/05_meta/` + `template/.claude/agents/05_meta/` (agent and schema docs), `CLAUDE_MANAGER.md`, `template/.claude/captures/README.md`; added `<!-- cruft-check:exempt-historical -->` inline marker convention (same-line OR preceding-line) and applied it to README / handoff / ROADMAP stragglers. Drops ~55 FPs against legitimate historical version annotations without losing the catch on actual stale forward refs.
- **Bare-tool allows broadening + PowerShell safety parity** ✓ *(shipped — Phase 21).* Added `PowerShell` to bare `permissions.allow` (covers the Windows tool-ID gap; PowerShell is a separate `tool_name` from Bash). New `pretooluse-powershell-safety.sh` hook mirrors `pretooluse-bash-safety.sh` shape with PowerShell-specific destructive patterns (Remove-Item recursive+force + aliases, Format-Volume / Clear-Disk, Set-ExecutionPolicy Unrestricted / Bypass, iwr|iex pipe-to-shell, force-push / hard-reset-to-origin). Same locked default-allow design. Drops recurring "Always allow" prompts on routine PowerShell work without loosening the destructive deny surface.

**Rolled forward:**

- `code-quality-auditor` home decision resolved in v1.1.4 (Phase 24) — narrow-scope landing as a standalone v1.1.x component; Layer 3 semantic fitness-vs-description checks stay deferred to v2.0. See v1.1.4 below.
- bash-safety commit-message FP exemption — kept in handoff loose-ends as a low-priority maintenance item. Manifests when a commit message contains literal destructive-pattern tokens as prose; current workaround is rewording. Not promoted to ROADMAP scope.

#### v1.1.4 — shipped (cut on 2026-05-17)

One concrete component landed. Plugin-verification surface now open. Composes with `cruft-checker` + `drift-checker` as the **project-level audit triad** firing at SessionStart. Phase 24 also piggybacked a destructive-pattern shared-lib extraction so real-time blocking (PreToolUse hooks) and retrospective audit (`plugin-quality-check.sh`) operate against a single source of truth.

- **`code-quality-auditor`** ✓ *(shipped — Phase 24).* First plugin-verification component. Reads installed plugin source under `~/.claude/plugins/cache/` and emits observations against the existing schema for three narrow heuristics — (i) manifest-declared component path missing or empty, (ii) `hooks/` present but `hooks.json` malformed (reuses Phase 16 viii hook-schema validation), (iii) destructive shell patterns in plugin scripts against unguarded paths (reuses Phase 14c / Phase 21 destructive-pattern sets via shared `.claude/lib/` extraction). Routes via `workflow-suggester` as `suggested_artifact_type: manual_action`. Composes with `cruft-checker` + `drift-checker` as the project-level audit triad. Ships in `template/` (target projects also install plugins). Semantic Layer 3 fitness-vs-description checks remain deferred to v2.0 alongside `integration-checker`.
- **Destructive-pattern shared lib extraction** ✓ *(shipped — Phase 24 piggyback).* Moved the `DESTRUCTIVE_BASH_PATTERNS` / `DESTRUCTIVE_POWERSHELL_PATTERNS` arrays from inline declarations in `pretooluse-bash-safety.sh` / `pretooluse-powershell-safety.sh` into shared `.claude/lib/destructive-{bash,powershell}-patterns.sh` files. Both PreToolUse hooks AND the new `plugin-quality-check.sh` heuristic iii source the libs — single source of truth across real-time blocking and retrospective audit.

**Rolled forward:**

- bash-safety commit-message FP exemption — still queued (low-priority maintenance, no change since v1.1.3). Phase 24 hit the FP twice during synthetic-plugin planting; both worked around via Write tool — additional data point but not yet warranting prioritization.

### How the loop closes the gaps (in v1.1.0) <!-- cruft-check:exempt-historical -->

A concrete walk-through, no `/goals` dependency:

1. `session-observer` notices a recurring pattern over the last two weeks ("you've manually summarized SESSION_LOG before each retrospective four times") and emits an observation.
2. `workflow-suggester` walks observations, filters to warranted ones, and drafts a capture file at `.claude/captures/<pattern_id>.md` with `status: draft, suggested_artifact_type: script`.
3. User reviews the capture. Edits `status` to `approved`.
4. `script-builder` walks captures, filters to `status: approved AND suggested_artifact_type: script`, and drafts a bash file at `.claude/scripts/drafts/<pattern_id>.sh.draft`.
5. User reviews the draft, optionally edits, promotes by `mv`-ing into `.claude/scripts/<descriptive-name>.sh` + `chmod +x`. User flips the capture to `status: shipped` and adds `shipped_to:` pointing at the promoted path.
6. Next time the pattern recurs, the script handles it. The pattern stops being a recurring manual chore.

Each lifecycle stage closes one of the four autonomy gaps in part; together they close the meta-gap that v1.1+ targets — *the system improves itself with the user always in the approval seat*.

## v1.1.5+ pre-pinball queue

Buildable-without-data work for the window between v1.1.4 ship and pinball-game start. TV / EoG stay on v1.0 until pinball wraps; update.sh against them happens at context-switch time. Data-gated v1.2.0 components (`manager-optimizer`, `artifact-fit-analyzer`, etc.) stay deferred until real observation data flows.

### Locked decisions

- **Install `claude-mem`.** Persistent-memory plugin for Claude Code (`thedotmack/claude-mem`, 46K+ GitHub stars). Captures session activity, compresses with AI, injects context into future sessions. Highest-leverage ecosystem integration. Install via `npx claude-mem install`.
- **Audit before integration.** Two-stage audit (chat-side strategist audit, then CC-side reconciliation audit with small handoff) lands before any ecosystem integration. Audit informs which plugins/skills compose vs conflict.
- **Update TV / EoG deferred to post-pinball.** They produce no observation data while idle; update.sh interactive prompts deserve context-switch attention.

### Buildable in this window (data-independent)

In priority order:

1. `/goals` expanded — research → clarify → spec pipeline. Highest pinball leverage. SEE naming-collision note below before building.
2. bash-safety FP exemption — `git commit -m` parser only first (heredoc as separate phase if friction continues). Two empirical FP hits across Phase 21 + 24.
3. `roadmap-auditor` (skeleton-only doc auditor). Static analysis, no data dependency.
4. Scheduled-goals support (`schedule` field on `/goals` + SessionStart surfacing). Mechanism foundation.
5. `infrastructure-auditor` partial (dispatches cruft + drift + code-quality on schedule; `artifact-fit-analyzer` slot deferred until data exists).
6. `token-efficiency-monitor` investigation (doc-read into Claude Code's token-data exposure; writeup decides whether upgrade is possible).

### Backlog — pending audit-informed decisions

- **`/goal` (Anthropic) vs `/goals` (skeleton) naming collision.** Anthropic ships `/goal` (singular) as a built-in Claude Code v2.1.139+ command that sets a completion condition and continues turns autonomously until met (autonomous execution primitive). The skeleton ships `/goals` (plural) as a baseline command for research → clarify → spec elicitation (intake primitive). They are complementary, not overlapping — natural composition is `/goals` produces spec → user approves → `/goal` runs until spec satisfied. But the names differ by one letter, which will confuse anyone using both. Three options for audit decision: (a) rename skeleton's `/goals` to `/spec` or `/intake` or `/plan`; (b) keep `/goals`, document composition with `/goal` explicitly in CLAUDE_MANAGER; (c) defer — no rename, document only if it becomes a real-world friction.
- **`/superpowers` plugin** (`obra/superpowers-marketplace`). Mature plugin with significant philosophical overlap with the skeleton (brainstorming = `/goals` shape; TDD enforcement; plan-execution-with-review). Compose-vs-compete question is the v2.0 plugin recommendation surface playing out for real. Audit decides whether to install + integrate as a manager-dispatched composition target, or defer to v2.0.
- **First-install plugin suggestion flow (net-new design).** When the skeleton is installed in a project, the system should suggest relevant plugins/skills/commands based on project context. Implies a `project-tuner-helper` upgrade or new component. Net-new design surface; not currently in v1.2.0 or v2.0 scope. Audit identifies placement (v1.2.0 fold, v2.0 fold, or separate phase tier).
- **Other plugins from the `/plugin` marketplace.** No specific candidates locked. Audit identifies what would compose well with the existing baseline.
- **Additional skills beyond the 6 baseline.** Audit identifies gaps.
- **The 6 community libraries named in CLAUDE_MANAGER.md.template's plugin marketplace composition section.** Currently referenced but not installed. Audit clarifies integration intent — are they composition targets the manager dispatches, or just reference material in the directive layer?

### Deferred — needs data flow

- `manager-optimizer` observer-only — could ship now but watches one install (skeleton dogfood) with no other producers active. Defer until TV / EoG / pinball are running v1.1.5+.
- All other v1.2.0 components (`artifact-fit-analyzer`, `meta-session-observer` + `template-promoter`, `token-efficiency-monitor` upgraded, loop pruning).

### Roadmap notes — surfaced during v1.1.4 retrospective

- **Multi-session-cumulative friction detection (v1.2.0+ candidate).** Real gap: the bash-safety FP hit twice across Phase 21 + 24 (different sessions, different days), but no observer caught it autonomously. `task-watchdog` is prior-single-session. `session-observer` is in-session. `meta-session-observer` is cross-install. Cross-session-cumulative middle ground has no producer. Worth designing a producer that watches user-side workarounds across session boundaries.
- **Mental-model-vs-roadmap drift is a real surface.** Strategic chat work surfaced that user mental model has been carrying integration assumptions (e.g. `/superpowers` as already-agreed) not reflected in locked docs. Audit must explicitly check for this drift as part of its scope — what other strategic decisions are held informally that should be in ROADMAP / handoff / CLAUDE_MANAGER?
- **Roadmap velocity question.** User's architectural framing of skeleton-as-plugin-curator is the v2.0 vision but treated as more imminent than current roadmap reflects. Audit assesses whether some v2.0 surface should pull forward.

## v1.2.0 — meta-evolution release

Where the system grows hands. Opens with `manager-optimizer` (the Level-3 meta-meta framing preserved from earlier roadmap cuts), then expands to nine components that turn the v1.1.0 primitives into a self-tuning surface.

### `manager-optimizer` (L3)

Level-3 meta-meta. Watches **how the manager decides** — which judgment patterns fire, when dispatch happens vs. direct read, where escalation thresholds land in practice, where `/goals` gets invoked vs. skipped. Suggests refinements to `CLAUDE_MANAGER.md.template` based on observed decision drift.

Post-v1.1.0 for the same empirical reason cited in the earlier roadmap: without `/goals` expanded and the capture/reuse loop generating real usage data, `manager-optimizer` would optimize against vibes. v1.2.0 is the version where the meta-system has enough self-observation to be worth tuning.

### `artifact-fit-analyzer`

Detects redundancy, inefficiency, and missing combinations across the project's existing agents / skills / scripts / commands / hooks. Drafts consolidation captures when two helpers overlap, missing-coverage captures when a recurring pattern has no artefact, or removal captures when an artefact never gets dispatched. Manager executes consolidation edits directly — no new builder needed for "rename, merge, or delete an existing artefact."

### `/goals` expanded

Research → targeted clarify → spec pipeline. Merges with Gap #3 (clarifying-questions layer). Pause-only-on-big-questions tuning — the conversation shape stays broad → narrow → edge-case → spec, but the system asks fewer one-off questions and instead surfaces the open spec gaps in a single batch. Outputs a structured spec doc that X-builders consume natively (script-builder reads it as input rather than re-deriving scope from the capture alone).

### Loop pruning (via `manager-optimizer`)

Retires captures that never get approved or scripts that never get dispatched. Driven by observation data — if a capture sits in `status: draft` for 60+ days, or a promoted script gets zero dispatch hits over a month, `manager-optimizer` surfaces a pruning suggestion. Same human-in-the-loop discipline as everything else; the system suggests, the user approves.

### `meta-session-observer` + `template-promoter`

The multi-project graduation mechanism. `meta-session-observer` runs at a higher tier than `session-observer` — it sees patterns *across installed projects*, not within one. When a pattern hits the graduation threshold (see [Locked architectural principles](#locked-architectural-principles)), `workflow-suggester` drafts a graduation capture (`suggested_artifact_type: graduation`). On approval, `template-promoter` executes: moves the artefact into `template/`, updates `install.sh` manifests, regenerates baseline hashes, updates CI scenarios. The skeleton learns from its own deployments.

### `token-efficiency-monitor` (upgraded)

Closes Gap #4. Today the monitor is observational — reports after a subtask blows its envelope. v1.2.0 makes it proactive: flags before dispatch when the planned scope smells over-budget, suggests narrower framings, recommends alternative helpers with smaller surface area. Needs design pass on Claude Code's token-data exposure to agents (what's readable at dispatch time vs. only post-hoc).

### `infrastructure-auditor` (project-level)

Scheduled audit coordinator that lives in `template/` — installed in every project. Dispatches `cruft-checker` + `drift-checker` + `artifact-fit-analyzer` against THIS project's `.claude/` on a cadence (weekly default, configurable via `/goals` `schedule` field). Surfaces a single consolidated report instead of three independent ones.

### `roadmap-auditor` (skeleton-level)

The skeleton's own auditor. ONLY in the dogfood `.claude/`, **not** in `template/`. Audits the roadmap docs, schemas, cross-phase contracts. Surfaces drift between what the roadmap claims and what the codebase actually does. Same scheduled cadence as `infrastructure-auditor`, but scoped to the skeleton's own meta-evolution surface.

### Scheduled-goals support in `/goals`

New `schedule` field on goals. Goals with a schedule live under `.claude/goals/scheduled/`. A session-start hook surfaces due items so they don't drop. The mechanism that drives `infrastructure-auditor` and `roadmap-auditor` cadence.

### Gating

v1.2.0 opens when v1.1.x has been running on Trainer-View / Echoes-Of-Gill for ≥2 weeks of active use. **Precise framing:** v1.1.x has been single-install (skeleton dogfood) for its entire lifetime; the "production daily use" claim from the v1.0 retrospective applies to v1.0 baseline only. v1.1.x production miles begin when `update.sh` runs against TV/EoG. Dogfood data informs but does not satisfy the bake gate.

## Locked architectural principles

Decisions that hold across all v1.2+ work. Captured here so future slices don't relitigate them.

### Multi-project graduation

A pattern graduates from one project's `.claude/` into `template/` (i.e. ships to every installation) when it crosses a hard threshold:

- **≥66% of installed projects** show the same pattern (the bar is broad adoption, not narrow taste).
- **Minimum 3 projects** in the sample (one or two installs is anecdote).
- **≥4 weeks stable** — the pattern hasn't been edited or reverted recently in any of the contributing projects.
- **Zero negative observations** in the same 4-week window (no project has flagged the pattern as broken, noisy, or contraindicated).

v1.2+ mechanism: `meta-session-observer` watches the cross-install signal → `workflow-suggester` drafts a graduation capture (`suggested_artifact_type: graduation`) → user approves → `template-promoter` executes the move, updates `install.sh` manifests, regenerates baseline hashes, updates CI scenarios. The threshold and mechanism together prevent the skeleton from inheriting one project's idiosyncrasies.

### Two distinct audit surfaces

The skeleton runs audits at two scopes; mixing them would muddy the discipline.

- **Project-level (`infrastructure-auditor` in `template/`).** Audits a single project's `.claude/`. Installed everywhere. Dispatches the project-level checkers (`cruft-checker`, `drift-checker`, `artifact-fit-analyzer`). Findings are local to the project.
- **Skeleton-level (`roadmap-auditor` in dogfood only).** Audits the skeleton's own roadmap, schemas, cross-phase contracts. Lives ONLY in the skeleton's dogfood `.claude/`, never in `template/`. Findings are about the skeleton itself — drift between roadmap claims and codebase reality.

Shared mechanics (cruft detection, doc-rot catches), different scope. Both are scheduled via `/goals` expanded `schedule` field.

### Captures-surface enum stability

The `suggested_artifact_type` enum on `workflow-suggester.schema.md` has nine stable values:

<!-- cruft-check:exempt-historical -->
- **Baseline (6):** `script`, `skill`, `agent`, `command`, `manual_action`, `unclear`. Established in v1.1.0 Phase 2 (workflow-suggester rewrite).
- **v1.1.x additions (3):** `doc-fix` (Phase 7, paired with cruft-checker doc-rot observations); `infrastructure-fix` (Phase 16, paired with cruft-checker heuristic viii config-schema observations); `lesson` (Phase 18, surface-only — no producer heuristics, no X-builder, manual codification per Model C).

v1.1.4 reused the existing `manual_action` baseline value as the routing target for `pattern_type: plugin_quality` observations emitted by `code-quality-auditor` (Phase 24) — no new enum value added. Future additions follow the **prefix-routing convention** established in Phase 16 + 18: observation notes starting `"<value>: "` route to `suggested_artifact_type: <value>`. Authors who hand-author captures may set the field directly. Adding a new enum value requires (a) edit the enum list in `workflow-suggester.schema.md`, (b) extend the routing block in `workflow-suggester.md`, (c) optionally add a producer heuristic if autonomous detection earns scope. Defer producer + X-builder until grounding data exists (same discipline as task-watchdog's deferred resource-anomaly signals; Phase 18 set the precedent).

### Model C lesson codification

Lessons codify directly into the directive surface that architecturally fits — `CLAUDE_MANAGER.md` for strategic-judgment patterns, `docs/ROADMAP.md` for sequencing constraints, `claude-skeleton-handoff.md` for sprint-state continuity, or whichever artefact carries the rule's natural authority.

**NOT a separate lessons-log document.** The two alternatives were considered and cut:

- **Model A (captures-as-library):** lessons live as a queryable library under `.claude/captures/`. Cut — captures are draft-then-ship work-items, not durable reference. Library accumulates stale captures.
- **Model B (parallel lessons-log doc):** lessons live in a dedicated `LESSONS.md` doc with their own schema. Cut — duplicates content with the directive layer; readers consult two docs for one rule; drift between `LESSONS.md` and the directive layer becomes a real maintenance cost.

Model C wins because every lesson eventually shapes a directive — codifying directly into the directive is the single-source-of-truth move. Phase 17 was the canonical first execution (plan-amendment behavior codified into `CLAUDE_MANAGER.md` H3); Phase 18 formalised the flow via the `lesson` capture-surface enum value (capture → manual codification → `shipped_to:` records the codified location).

### Billing-pool design constraint for v1.2.0

Scheduled mechanisms in v1.2.0 — `schedule` field on `/goals`, session-start surfacing of due items, `infrastructure-auditor` and `roadmap-auditor` cadence — must fire via **SessionStart hooks**, NOT out-of-band cron + `claude -p` invocations.

**Why:** Anthropic's subscription billing splits subscription-pool quota from API-pool quota on 2026-06-15. Interactive Claude Code sessions consume subscription pool; `claude -p` headless invocations from cron consume API pool. A scheduled mechanism that fires via cron + `claude -p` would silently consume API quota even when the user is otherwise inside subscription scope; users would discover the spend only on the next bill. SessionStart-hook firing keeps scheduled work inside the same subscription quota as the active session — no quota-surface surprise.

**How to apply:** when designing v1.2.0's scheduled mechanisms, wire them through the SessionStart hook chain (precedent: drift-checker, cruft-check, task-watchdog, plugin-quality-check already fire there). Real-time scheduling shapes that need cron-style firing get deferred to a separate v1.2.0+ phase that explicitly designs the cross-pool quota story; don't ship them inside v1.2.0's first cut.

### Single source of truth for safety patterns

Destructive-pattern arrays live in `.claude/lib/destructive-bash-patterns.sh` and `.claude/lib/destructive-powershell-patterns.sh`, sourced by:

- **Real-time blocking surfaces:** `pretooluse-bash-safety.sh` (Phase 14c), `pretooluse-powershell-safety.sh` (Phase 21). Both PreToolUse hooks fail-closed if their lib is missing.
- **Retrospective audit surface:** `plugin-quality-check.sh` heuristic iii (Phase 24).

New destructive patterns get added in ONE place — the lib file — and propagate to all enforcement surfaces automatically. **When future audit surfaces emerge** (e.g. CI-time plugin scan, project-tuner-helper safety review, an `artifact-fit-analyzer` security pass), they source the same lib rather than duplicating patterns. The Phase 24 refactor was the canonical move from inline-array-per-script to shared-lib; the rule locks the architecture going forward.

The same single-source-of-truth principle does NOT apply to the hook-schema validation logic — that's currently duplicated between `cruft-check.sh` heuristic viii and `plugin-quality-check.sh` heuristic ii because both scripts use inline Python heredocs and sharing across heredoc scopes would mean introducing a separate Python lib file (diverging from the established self-contained-script pattern). Duplication is acceptable when the canonical reference is small and the underlying spec (Anthropic hook schema) is stable. Revisit if the hook-schema validation grows significantly.

### Ever-evolving being

The skeleton ships a baseline; `project-tuner-helper` shapes it per-project; `workflow-suggester` catches new patterns. Not "install and forget" — the skeleton evolves with its installations. The capture/reuse loop, observation infrastructure, and meta-agents in `05_meta/` all exist to support this evolution. **How it applies:** every new component asks "does this enable ongoing evolution, or freeze a snapshot?" The skeleton refuses snapshot-locking.

### Approval-gated autonomy

Thinking is autonomous; action is approved. The skeleton can suggest captures, surface plugin recommendations, detect drift, draft scripts — all autonomously. None of those become installed/applied artifacts without explicit user approval. Plan-mode discipline, capture-lifecycle states (`draft → approved → shipped`), and X-builder draft mechanics all enforce this line. **How it applies:** new mechanisms maintain the line by default; "auto-apply" is a deliberate carve-out (e.g. `--auto-apply` in `update.sh` accepts only TEMPLATE_UPDATED + NEW, never LOCALLY_MODIFIED or ORPHAN — the autonomy is bounded).

### Define-everything-upfront

Brief specs lock interpretations before code; plan-mode surfaces them. The pre-build scoping rule (5 questions before any v1.1+ component prompt) forces upfront definition. Narrow-scope-by-design phases ratify it. **How it applies:** ambiguous briefs get the honing conversation BEFORE prompt drafting, not during execution. Plan-mode catches scope drift before commits.

### Narrow-scope-by-design

Each phase locks scope at brief time; "out of scope" sections in plans are load-bearing. The three-commit cadence prevents scope creep into single commits. The Phase 10 commit-cadence-by-phase-size rubric formalizes this. **How it applies:** when a phase surfaces work outside its locked scope (Phase 30b's emergent hook-CWD fix), the work either folds thematically OR queues for a separate phase — it doesn't expand the current phase silently.

### Composition not competition

The skeleton composes with the `/plugin` marketplace + named community libraries. It is NOT a multi-LLM framework, NOT a directory of every plugin, NOT an autonomous AI agent. v2.0 plugin recommendation surface realizes this principle by name; v1.5 ecosystem integration tier prepares the orchestration brain to dispatch ecosystem plugins. **How it applies:** when the ecosystem ships what the skeleton would build (e.g. Anthropic's `feature-dev` replacing `/spec`; `superpowers` TDD as net-new value), the skeleton composes. Building from scratch requires empirical evidence the ecosystem doesn't already serve the need.

### Compose-with-available-surfaces, defer-on-unavailable

Don't ship retrospective signals or mechanisms that require Claude Code instrumentation surfaces that don't exist yet. Phase 5 (task-watchdog 2-signal scope vs 5-signal candidate) and Phase 18 (lesson-detection deferral) set the precedent: when a brief proposes a signal whose detection requires unavailable instrumentation, defer to the version where the relevant investigation lands (typically v1.2.0 for token data, future for real-time hooks) — explicitly note the deferral in the brief's locked decisions. **How it applies:** new components check "does this require CC surface X that exists today?" before locking scope. Unavailable-surface dependencies cause scope cut, not feature shipping with conditional code paths.

## v2.0 — plugin ecosystem layer

A curated discipline for matching pain points and project context to specific marketplace plugins or community-library helpers. Catalog grows month by month — recommendations get sharper as the capture/reuse loop generates usage data the recommender can match against.

v2.0 folds three pieces that previously had separate phase numbers:

- **`integration-checker`** — Layer 1+2 of plugin verification (manifest sanity, surface area). Planned for v2.0; not yet shipped. v1.1.4's `code-quality-auditor` picked up the manifest-honesty slice (heuristics i + ii) as standalone scope; the remainder of Layer 1+2 folds in here.
- **`code-quality-auditor`** — Layer 3 (reads actual source, evaluates semantic fitness vs description). Layer 3 lands in v2.0. **Narrow-scope manifest honesty + security hygiene heuristics already shipped in v1.1.4** (Phase 24): 3 heuristics covering manifest path missing/empty (i), hooks.json schema violation (ii), destructive shell patterns against unguarded paths (iii). Semantic fitness-vs-description checks remain deferred to v2.0.
- **Curated catalog** — only if community-curation value materializes. The standalone-phase framing is gone; a static catalog without a quality filter is just a directory.

The foundation is already in v1.0: `CLAUDE_MANAGER.md.template`'s plugin marketplace composition section names the seven ecosystem sources the manager draws from. v2.0 turns that section from "here is the ecosystem we compose with" into "for the shape of *this* project, here are the three plugins that pair best — and here are five that don't, with reasons."

Design principle (locked, verbatim):

> **Don't be a directory; be a quality filter.**

The point isn't to list every plugin. It's to give the manager a discipline for picking the right ones for the project at hand and rejecting the wrong ones early.

## v3.0+ / future-future (out of v2.0 scope)

One idea kept visible but explicitly **outside v2.0**.

### Multi-LLM orchestration

Running the skeleton's structure across multiple LLMs — Claude + DeepSeek + others — with the manager arbitrating which model handles which subtask. Architectural identity question rather than a feature: claude-skeleton was designed against Claude Code's specific affordances (subagent dispatch, slash commands, hooks, skill discovery). Re-targeting it for general LLM orchestration would change the project's centre of gravity.

Skeleton stays Claude-Code-only through v2.0. If multi-LLM is pursued later, it's a **sibling project** (different name, shared lineage — e.g. `claude-skeleton-bridge`) or a v3.0+ direction with an explicit fork-the-identity conversation — not a feature graft.

## Cuts — rationale for what's not in the queue

Three pieces were on earlier candidate lists and have been explicitly cut. Logged so the rationale doesn't have to be re-derived.

### `skill-builder` and `agent-builder`

Cut from the v1.1+ X-builder sequence. Markdown writing is cheap — no automation gain from a builder that just stamps frontmatter and a body. `/goals` expanded (v1.2.0) produces the spec; manual write handles execution. The recommendation/analysis function for "should this be a skill, agent, script, or command?" moves to `artifact-fit-analyzer` (v1.2.0).

`script-builder` stays because bash has real discipline beyond markdown — strict-mode, path-shape guards, error handling, `bash-safety` integration. The X-builder pattern earns its keep on artefacts with non-trivial structural constraints.

### Gap #1 — auto-dispatch by intent

<!-- cruft-check:exempt-historical -->
Deferred to v1.2+ post-`manager-optimizer`, once real dispatch data exists. Trying to close Gap #1 in v1.1.0 would mean inferring intent from request shape without empirical grounding — exactly the "optimize against vibes" trap that pushed `manager-optimizer` itself to v1.2+. Manual dispatch via `CLAUDE_MANAGER.md.template` patterns continues to work in v1.1.0; the gap is a known seam, not a blocker.

### Plugin recommendation as a standalone v2.0 phase

Folded into `integration-checker` (planned for v2.0) + `code-quality-auditor` (narrow scope shipped v1.1.4; Layer 3 semantic checks planned for v2.0). The earlier framing imagined a standalone catalog phase; that framing was a partial picture of the same thing. A curated catalog without quality verification is a directory (which the principle above rules out); quality verification without a catalog is just `integration-checker`. The two only justify a v2.0 phase together.

## Dependency graph (updated)

```
v1.1.0 loop (3 shipped, 2 queued):
  observations → captures → drafts (script-builder)
                                  │
                                  ├─> task-watchdog (queued, second producer against observation schema)
                                  └─> drift-checker (queued, marker check, no auto-apply)

v1.1.x polish:
  cruft-checker (third observation producer) ──> workflow-suggester
  code-quality-auditor (v1.1.4 narrow scope: 3 heuristics) ──> workflow-suggester
                                              └─> v2.0 Layer 3 fold (semantic)
  integration-checker (planned for v2.0) ──> Layer 1+2 fold
  lessons → suggested_artifact_type: lesson (no separate skill)

v1.2.0 meta-evolution:
  /goals expanded ──> X-builders consume spec docs natively
  manager-optimizer ──> watches dispatch patterns, suggests CLAUDE_MANAGER updates
                  └─> loop pruning (retires unused captures and scripts)
  meta-session-observer ──> cross-install signal ──> template-promoter
                                                ──> graduation captures
  infrastructure-auditor ──> dispatches cruft-checker + drift-checker + artifact-fit-analyzer
  roadmap-auditor (skeleton dogfood only) ──> roadmap / schema / contract drift
  scheduled-goals support ──> session-start hook surfaces due items

v2.0:
  Plugin recommendation surface ──> folds integration-checker + code-quality-auditor + catalog
```

<!-- cruft-check:exempt-historical -->
`/goals` expanded ships in v1.2.0 and unlocks the meta-evolution tier. v1.1.0 work parallelizes within the loop (task-watchdog and drift-checker can land independently). v1.1.x → v1.2.0 → v2.0 is a hard sequence — each tier consumes signal that only exists once the prior tier has been in production for some weeks.

## Closing — scope discipline

claude-skeleton is an orchestration layer on the Claude Code ecosystem. It composes with the `/plugin` marketplace and the six community libraries named in the directive layer. It is **not** a multi-model framework, not a directory of every available plugin, and not an autonomous AI agent. Approval-gated autonomy is the working line: thinking is autonomous, action is approved. The roadmap above is the sequence in which that line gets pushed — never erased.
