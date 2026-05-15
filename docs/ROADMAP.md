# ROADMAP

The sequencing doc for claude-skeleton. v1.0 → v2.0+. Living — updated as slices land. For backward-looking history see [`CHANGELOG.md`](CHANGELOG.md).

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
| 1 | **Auto-dispatch by intent** — the manager has to be told to dispatch a helper; it can't infer from request shape. | Deferred to v1.2+ post-`manager-optimizer`, once real dispatch data exists. Manual dispatch via `CLAUDE_MANAGER.md.template` patterns continues to work in v1.1.0. See [Cuts](#cuts--rationale-for-whats-not-in-the-queue). |
| 2 | **System-proposes-own-evolution** — the meta-system can suggest captures in the abstract but doesn't draft them. | **Closed in v1.1.0** by `workflow-suggester` (rewritten to draft concrete capture files) and the first downstream X-builder `script-builder` (drafts bash scripts from approved captures). |
| 3 | **Clarifying-questions layer** — the manager either guesses the intent or asks one-off questions; no structured intake before non-trivial work. | **Closes in v1.2.0** via `/goals` expanded — research → targeted clarify → spec pipeline that X-builders consume natively. Merges with the clarifying-questions layer. |
| 4 | **Proactive token optimization** — `token-efficiency-monitor` reports after a subtask blows its envelope; warning lands too late. | **Closes in v1.2.0** via `token-efficiency-monitor` upgraded from observational to proactive (flags before dispatch when planned scope smells over-budget). Needs design pass on Claude Code's token-data exposure to agents. |

### v1.1.0 — tight scope (5 components)

The capture/reuse loop in its first shippable form. **All five primitives shipped; v1.1.0 cut on 2026-05-15.** No `/goals` dependency at this tier — X-builders read captures directly.

- **`session-observer`** ✓ *(shipped — Phase 1).* Real-time observation primitive. Notices repeated patterns during the session and emits structured observation files (`.claude/observations/<pattern_id>.json`) with redaction rules and a stable 8-field schema. Multi-source extensible — future producers (`cruft-checker`) write against the same schema.
- **`workflow-suggester`** ✓ *(shipped — Phase 2).* Schema-driven consumer of observations. Walks `.claude/observations/`, filters to warranted patterns (confidence threshold `med`/`high`), and drafts concrete capture files at `.claude/captures/<pattern_id>.md` with an 8-field frontmatter and a 4-section body. The four lifecycle states are `draft → approved → shipped` (terminal success) and `rejected` (do-not-re-suggest marker). Idempotent by filename.
- **`script-builder`** ✓ *(shipped — Phase 3, first X-builder).* Reads captures filtered to `status: approved AND suggested_artifact_type: script` and drafts bash files at `.claude/scripts/drafts/<pattern_id>.sh.draft`. Honors the 5-section discipline (shebang+strict-mode / constants / helpers / main / cleanup), `bash-safety` integration, path-shape guards. The `.sh.draft` extension makes drafts unexecutable until the user promotes them.
- **`drift-checker`** ✓ *(shipped — Phase 4).* `.skeleton-version` marker drift between installed projects and the latest released skeleton tag. Read-only, notification-only — no auto-apply, no auto-update. Surfaced by the SessionStart hook chain; cache refreshed via `update.sh --check-remote` (the only network path).
- **`task-watchdog`** ✓ *(shipped — Phase 5).* Retrospective observer of the prior Claude Code session. Reads `~/.claude/projects/<encoded-cwd>/<session-id>.jsonl`, pairs `tool_use`/`tool_result` events, and emits two pattern shapes via session-observer's existing schema: long-running bash calls (≥5min default, `pattern_type: other` with descriptive notes) and recurring failures (same normalized signature ≥3 times in-session, `pattern_type: recurring_failure`). Canonical producer of `recurring_failure` observations (ownership transferred from `session-observer`). Retrospective only — real-time signals deferred until Claude Code exposes a polling hook; resource-anomaly signals bundle with v1.2.0's `token-efficiency-monitor` proactive upgrade.

### v1.1.x — polish before v1.2.0

Three items that sharpen v1.1.0 without expanding the meta-evolution surface:

- **`cruft-checker`** — third observation producer. Surfaces dangling refs, doc-rot, stale `CHANGELOG` entries, deprecated patterns still referenced in code. Feeds `workflow-suggester` like any other observation source.
- **`code-quality-auditor`** — Layer 3 of the 3-layer plugin verification. Reads actual source code of community plugins and evaluates fitness vs description. Integrates with the existing `integration-checker`; both fold into v2.0.
- **Lessons-log integration as `suggested_artifact_type: lesson`.** Rather than a separate skill, lessons collapse into the captures surface — `workflow-suggester` drafts lesson captures, the user approves them, and they live alongside script/skill/agent/command captures in the same lifecycle.

### How the loop closes the gaps (in v1.1.0)

A concrete walk-through, no `/goals` dependency:

1. `session-observer` notices a recurring pattern over the last two weeks ("you've manually summarized SESSION_LOG before each retrospective four times") and emits an observation.
2. `workflow-suggester` walks observations, filters to warranted ones, and drafts a capture file at `.claude/captures/<pattern_id>.md` with `status: draft, suggested_artifact_type: script`.
3. User reviews the capture. Edits `status` to `approved`.
4. `script-builder` walks captures, filters to `status: approved AND suggested_artifact_type: script`, and drafts a bash file at `.claude/scripts/drafts/<pattern_id>.sh.draft`.
5. User reviews the draft, optionally edits, promotes by `mv`-ing into `.claude/scripts/<descriptive-name>.sh` + `chmod +x`. User flips the capture to `status: shipped` and adds `shipped_to:` pointing at the promoted path.
6. Next time the pattern recurs, the script handles it. The pattern stops being a recurring manual chore.

Each lifecycle stage closes one of the four autonomy gaps in part; together they close the meta-gap that v1.1+ targets — *the system improves itself with the user always in the approval seat*.

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

## v2.0 — plugin ecosystem layer

A curated discipline for matching pain points and project context to specific marketplace plugins or community-library helpers. Catalog grows month by month — recommendations get sharper as the capture/reuse loop generates usage data the recommender can match against.

v2.0 folds three pieces that previously had separate phase numbers:

- **`integration-checker`** — Layer 1+2 of plugin verification (manifest sanity, surface area).
- **`code-quality-auditor`** — Layer 3 (reads actual source, evaluates fitness vs description). Lands in v1.1.x; folds into the plugin surface here.
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

Deferred to v1.2+ post-`manager-optimizer`, once real dispatch data exists. Trying to close Gap #1 in v1.1.0 would mean inferring intent from request shape without empirical grounding — exactly the "optimize against vibes" trap that pushed `manager-optimizer` itself to v1.2+. Manual dispatch via `CLAUDE_MANAGER.md.template` patterns continues to work in v1.1.0; the gap is a known seam, not a blocker.

### Plugin recommendation as a standalone v2.0 phase

Folded into `integration-checker` + `code-quality-auditor`. The earlier framing imagined a standalone catalog phase; that framing was a partial picture of the same thing. A curated catalog without quality verification is a directory (which the principle above rules out); quality verification without a catalog is just `integration-checker`. The two only justify a v2.0 phase together.

## Dependency graph (updated)

```
v1.1.0 loop (3 shipped, 2 queued):
  observations → captures → drafts (script-builder)
                                  │
                                  ├─> task-watchdog (queued, second producer against observation schema)
                                  └─> drift-checker (queued, marker check, no auto-apply)

v1.1.x polish:
  cruft-checker (third observation producer) ──> workflow-suggester
  code-quality-auditor ──> integration-checker (both fold into v2.0)
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

`/goals` expanded ships in v1.2.0 and unlocks the meta-evolution tier. v1.1.0 work parallelizes within the loop (task-watchdog and drift-checker can land independently). v1.1.x → v1.2.0 → v2.0 is a hard sequence — each tier consumes signal that only exists once the prior tier has been in production for some weeks.

## Closing — scope discipline

claude-skeleton is an orchestration layer on the Claude Code ecosystem. It composes with the `/plugin` marketplace and the six community libraries named in the directive layer. It is **not** a multi-model framework, not a directory of every available plugin, and not an autonomous AI agent. Approval-gated autonomy is the working line: thinking is autonomous, action is approved. The roadmap above is the sequence in which that line gets pushed — never erased.
