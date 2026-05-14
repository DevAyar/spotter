# ROADMAP

The sequencing doc for claude-skeleton. v1.0 → v2.0+. Living — updated as slices land. For backward-looking history see [`CHANGELOG.md`](CHANGELOG.md).

## v1.0 — what ships

Current cut is **v0.9.0**. v1.0 is one short slice away — the 6b story doc lands and the version flips. What's already in:

- **Orchestration discipline** — `template/CLAUDE_MANAGER.md.template` carries the directive layer (strategic judgment patterns, dispatch mechanics, plugin marketplace composition, three-commit cadence, recursive ownership L0/L1/L2). Read top-down at session start; the manager onboards from this file alone.
- **Baseline tooling** — 9 baseline agents (4 core helpers + 5 meta), 6 baseline skills (`schema-verify-before-edit`, `post-edit-test-suggest`, `god-file-grep-first`, `bash-safety`, `token-efficiency-monitor`, `plugin-roster-search`), 2 baseline scripts (`commit.sh`, `deploy.sh`), 4 baseline commands (`/commit`, `/audit`, `/deploy`, `/smoke-test`), 2 baseline hooks (SessionStart, PreCompact).
- **Install / update infrastructure** — `install.sh` (three modes: fresh / merge / replace), `update.sh` (six-way classification using per-file SHA-256 hashes, with backfill for legacy markers), atomic JSON `.skeleton-version` marker.
- **CI** — three-platform matrix (Ubuntu, Windows, macOS) running six install/update scenarios on every push and PR.

Remaining for v1.0 cut:
- **Story doc** — `docs/6B_OUTLINE.md` (outline lands this slice); full prose lands in 6b.

v1.0 = orchestration layer ready for daily use across multiple real projects.

## v1.0 — success criteria (informal)

claude-skeleton is at v1.0 when I and a few peers use it productively over a month, no major install bugs surface, and the patterns hold across the two active production targets — **Trainer-View** (Flutter + Firebase) and **Echoes-Of-Gill** (Godot). No SLOs. No metrics theatre. A felt threshold: when I stop noticing the skeleton's seams during normal work, it's at v1.0.

## v1.1+ — the capture / reuse loop

The centerpiece of v1.1+. Today the manager learns within a session and forgets between sessions. The capture/reuse loop closes that gap by turning recurring patterns into reusable artefacts — drafted by the system, approved by the user, then formalized into a script or helper that handles the pattern next time it shows up.

### The four autonomy gaps

The loop maps directly to the four named gaps in the current system:

| # | Gap | Closes when |
|---|---|---|
| 1 | **Auto-dispatch by intent** — the manager has to be told to dispatch a helper; it can't infer from request shape. | The manager has enough captured patterns to anticipate. Hard problem; partial closure via the loop, full closure waits on real usage data. |
| 2 | **System-proposes-own-evolution** — the meta-system can suggest captures in the abstract but doesn't draft them. | `workflow-suggester` evolves from "suggests in prose" to "drafts a concrete proposed-helper file." User approves or amends; no more "you should automate this" without a starting artefact. |
| 3 | **Clarifying-questions layer** — the manager either guesses the intent or asks one-off questions; no structured intake before non-trivial work. | `/goals` ships — broad → narrow → edge-case clarifying questions → comprehensive design doc → persisted to `/goal` artefact. |
| 4 | **Proactive token optimization** — `token-efficiency-monitor` reports after a subtask blows its envelope; warning lands too late. | The same monitor learns to flag *before* dispatch when the planned scope smells over-budget. Observational → proactive. |

### The loop's three components

The loop wires three components (one new agent, one extended existing agent, one new generator) plus the `/goals` clarifying layer:

- **`session-observer`** *(new — real-time)*. Notices repeated patterns in actual session work. Different from `monitoring-helper` (post-session retro): the observer runs alongside the session, surfaces "you've done X three times this week / month", and emits an observation that `workflow-suggester` can consume. Lightweight; no heavy summarization at runtime.
- **`workflow-suggester`** *(extending existing agent)*. Today it suggests captures in the abstract from `SESSION_LOG.md`. v1.1+ it **drafts** them — a concrete proposed-helper or proposed-script file lands on disk in a `proposed/` directory, ready for the user to approve, amend, or reject. The draft is the artefact; the suggestion is the by-product.
- **`script-builder`** *(new)*. Formalizes approved captures into reusable scripts. Honors the 5-section discipline `commit.sh` and `deploy.sh` already follow: verbatim output, path-shape guard, error handling, explicit exit codes, one-line description. Generated scripts go straight into the project's `.claude/scripts/` if approved at that scope; into a draft directory otherwise.

### `/goals` integration

The clarifying-questions layer. Conversation shape: broad → narrow → edge-case → comprehensive design doc → ships to a persisted `/goal` artefact. Pairs naturally with `script-builder`: use `/goals` to spec what a script needs to do, what failure modes matter, what's explicitly out of scope, *before* generating the script. The spec is the script's commit-message body when it ships.

### How the loop closes the gaps

A concrete walk-through:

1. `session-observer` notices a recurring pattern over the last two weeks ("you've manually summarized SESSION_LOG before each retrospective four times").
2. `workflow-suggester` drafts a concrete capture — a proposed `session-summarizer` skill file in `proposed/skills/`.
3. User uses `/goals` to refine the spec: what's the input, what's the output, what's the failure mode, what's out of scope.
4. `script-builder` generates the formal script (or skill, or helper) honoring the 5-section discipline and the `/goals`-locked spec.
5. Next time the pattern recurs, the script handles it. The pattern stops being a recurring manual chore.

Each component closes one of the four autonomy gaps; together they close the meta-gap that v1.1+ targets — *the system improves itself with the user always in the approval seat*.

## v1.2+ — `manager-optimizer` (L3)

Level-3 meta-meta. Watches **how the manager decides** — which judgment patterns fire, when dispatch happens vs. direct read, where escalation thresholds land in practice, where `/goals` gets invoked vs. skipped. Suggests refinements to `CLAUDE_MANAGER.md.template` based on observed decision drift.

Explicitly post-v1.1+. The reason is empirical, not architectural: without `/goals` and the capture/reuse loop generating real usage data, `manager-optimizer` would optimize against vibes. v1.2+ is the version where the meta-system has enough self-observation to be worth tuning.

## Dependency graph

```
/goals (v1.1+) ─┬─> script-builder (uses /goals to spec scripts before generating)
                └─> manager-optimizer (v1.2+, watches /goals invocation patterns)

capture/reuse loop (v1.1+) ──> manager-optimizer (v1.2+, needs real usage data)
capture/reuse loop (v1.1+) ──> v2.0 plugin recommendation (needs stable patterns to recommend against)
```

`/goals` ships first. Everything downstream waits on it generating real signal — `script-builder` reads goal specs as input, `manager-optimizer` watches goal-invocation patterns, the plugin recommendation system uses captured pain points as match keys. v1.1+ work parallelizes within the loop but not across the v1.1 → v1.2 → v2.0 boundary.

## v2.0 — plugin recommendation system

A curated catalog matching pain points and project context to specific marketplace plugins or community-library helpers. Catalog grows month by month — recommendations get sharper as the capture/reuse loop generates usage data the recommender can match against.

The foundation is already in v1.0: `CLAUDE_MANAGER.md.template`'s plugin marketplace composition section names the seven ecosystem sources we draw from (official `/plugin` marketplace, `claude-code-templates`, `claude-agentic-framework`, `wshobson/agents`, `claude-skills`, `awesome-claude-code-subagents`, `ClaudeFast`). v2.0 turns that section from "here is the ecosystem we compose with" into "for the shape of *this* project, here are the three plugins that pair best."

Design principle (locked, verbatim from Slice A):

> **Don't be a directory; be a quality filter.**

The point isn't to list every plugin. It's to give the manager a discipline for picking the right ones for the project at hand and rejecting the wrong ones early.

## Future-future (not committed scope; logged so they don't drop)

Two ideas worth keeping visible but explicitly **outside v2.0**.

### Multi-LLM orchestration

Running the skeleton's structure across multiple LLMs — Claude + DeepSeek + others — with the manager arbitrating which model handles which subtask. Architectural identity question rather than a feature: claude-skeleton was designed against Claude Code's specific affordances (subagent dispatch, slash commands, hooks, skill discovery). Re-targeting it for general LLM orchestration would change the project's centre of gravity.

Skeleton stays Claude-Code-only through v2.0. If multi-LLM is pursued later, it's a sibling project (different name, shared lineage) or a v3.0+ direction with an explicit fork-the-identity conversation — not a feature graft.

### task-watchdog

A live monitor that pings the user when a tool call runs past N minutes. Pairs with `bash-safety` to catch the zombies the skill can't prevent — `bash-safety` is the preventive discipline (excludes, timeouts, maxdepth, wait/kill), `task-watchdog` is the reactive net. Same v1.1+ family as the capture/reuse loop, but separate from it; the watchdog is observation about runtime, the loop is observation about patterns.

## Closing — scope discipline

claude-skeleton is an orchestration layer on the Claude Code ecosystem. It composes with the `/plugin` marketplace and the six community libraries named in the directive layer. It is **not** a multi-model framework, not a directory of every available plugin, and not an autonomous AI agent. Approval-gated autonomy is the working line: thinking is autonomous, action is approved. The roadmap above is the sequence in which that line gets pushed — never erased.
