# ROADMAP

The sequencing doc for claude-skeleton. v1.0 → v2.0+. Living — updated as slices land. For backward-looking history see [`CHANGELOG.md`](CHANGELOG.md). For the project's identity and locked principles in plain-English form, see [`STORY.md`](STORY.md). For orchestration mechanics, strategic judgment patterns, plugin discipline rules, and the three-commit cadence rubric, see [`../CLAUDE_MANAGER.md`](../CLAUDE_MANAGER.md).

The substrate has shipped — **v1.1.4** is the current version, with the observation layer, capture/reuse loop, audit triad, plugin bundle, and hook infrastructure all live and stable. The governance vision is now locked: claude-skeleton is a structural immune system for projects, with per-project governance as the centerpiece principle. The road ahead is the sequence by which that vision lands — onboarding next, then ecosystem integration, then per-project manager-optimization (v1.2.0), then mature plugin recommendation (v2.0), then a multi-LLM sibling at some indefinite later point.

## Where we are now (v1.1.4)

Each line below is a governance capability the substrate already supports — not a feature recap.

- **Observation layer is working.** Independent signal sources (task-watchdog, cruft-checker, code-quality-auditor, session-end telemetry) feed a shared schema in `.claude/observations/`; the original session-observer retired in Phase 58 (unpopulated surface). New producers can be added without re-architecting consumers.
- **Capture/reuse loop is working.** Patterns observed in real session work become draft capture files; the user approves; an X-builder (a builder that turns approved captures into reusable artifacts — `script-builder` is the first) drafts the artifact; the user promotes when ready.
- **Project-level audit triad is working.** `cruft-checker` (doc rot inside the project), `drift-checker` (skeleton-version drift against the upstream release), `code-quality-auditor` (installed-plugin sanity) all fire at session start with a cooldown.
- **Plugin bundle is vetted and installed.** Six ecosystem plugins (`feature-dev`, `code-review`, `commit-commands`, `security-guidance`, `superpowers`, `claude-mem`) compose with the skeleton. The eyes-open install pattern (audit the plugin, install with explicit awareness of side effects) is proven on the trust-tier-2 claude-mem case.
- **Hook infrastructure is correct.** The silent-inert failure modes that plagued earlier versions are eliminated. PreToolUse + SessionStart + SessionEnd hooks all fire as designed, with path resolution that survives CWD drift.
- **Communication discipline is codified.** Plain English by default for user-facing prose, shipped today as a strategic-judgment H3 in the manager (Model C — direct codification into the directive surface that architecturally fits, not a separate lessons doc).

## Where we're going — the v2.0 horizon

The mature form of claude-skeleton has four things in place. First, every install evolves its own discipline through a per-project manager-optimizer that watches that project's pattern of decisions over time and suggests refinements. Second, cross-install signal moves patterns into the shared template only when they prove themselves across multiple projects — the graduation mechanism. Third, plugin recommendations are tied to project context, not catalog completeness — you get suggested the plugins that fit your project, with reasons; you also get told which plugins don't fit, with reasons. Fourth, the orchestration layer composes with the broader ecosystem rather than reinventing it.

All four of those land between v1.1.5 and v2.0. v1.1.5 is the onboarding tier — what makes a new project enter the governance model cleanly. v1.5 is the ecosystem integration layer — per-project plugin recommendation foundations. v1.2.0 is the meta-evolution release — per-project manager-optimizer and the graduation mechanism. v2.0 is the mature plugin recommendation surface. A multi-LLM sibling lives at v3.0+ as a separate project entirely, not a feature graft.

## How readiness gates work

The roadmap runs in tiers, not on a calendar. Each tier opens when a specific empirical condition is met — sessions accumulated, observation cycles closed, audit corpus large enough, install base broad enough, a prior tier shipped — and there are no calendar dates anywhere in this document. Empirical readiness is the gate, not the clock.

Tiers don't ship in numeric order. v1.2.0 components and v1.1.5 phases share the timeline because their gates are independent — pure-design work opens immediately while production-signal work waits for sufficient observation cycles. v1.5 sits behind v1.1.5 because the recommendation surface needs the onboarding tier to be stable. v2.0 sits behind production maturity. v3+ sits behind broad install adoption. The tiers as labels are organizational, not chronological.

Each section below states its gate at the top: what empirical condition opens the tier and what mechanism inside it is contingent on what data. New components answer "what's the empirical signal that says the gate is open?" before they get scoped.

## Available now

Three tracks open immediately — no prior gate to wait on.

**v1.1.5 onboarding tier.** Five small phases. A is fully de-gated and can ship before the rest land. B-E queue sequentially after A; together they constitute v1.1.5's ship.

- **A — README.md onboarding refresh.** The first 30 seconds a new visitor spends on the repo. Currently feature-list-shaped; reframes around the governance pitch.
- **B — GETTING-STARTED.md.** The first 15 minutes after install. Walks through what just happened to the project, what to expect at session start, how to dispatch a helper for the first time.
- **C — PLUGINS-GETTING-STARTED.md.** The opt-in framing for the six-plugin bundle and the trust-tier-2 / eyes-open install pattern.
- **D — install.sh post-install message.** What the user sees in the terminal when the install completes. Currently terse; expands to point at GETTING-STARTED and the next-step dispatch.
- **E — Optional first-run SessionStart welcome hook.** Surfaces on the first session in a freshly-installed project; explains what just got added to `.claude/` and where to start.

**v1.2.0 pure-design components.** No production miles required to design schemas and pipelines; only execution / refinement needs data.

- **`/goals` expanded** — the research → targeted clarify → spec pipeline. Outputs a structured spec doc that X-builders consume natively. Closes the long-deferred clarifying-questions seam.
- **Scheduled-goals support** — `schedule` field on `/goals` plus a SessionStart surfacer for due items.

**Phase 35 evaluation window.** The v1.1.4 substrate evaluation is open now. Four observations accruing in parallel:

- **Skeleton dogfood baseline.** Claude Code restart with all six ecosystem plugins active. Observation of how the manager handles a typical session under the new substrate.
- **Pinball install (leg retired).** Pinball was the planned fresh-mode `install.sh` bootstrap-on-empty-project test case; the project was retired (2026-07) before contributing signal. The fresh-install path is covered by CI's `fresh-install` scenario instead.
- **Trainer-View update.** TV runs `bash <skeleton>/scripts/update.sh` to refresh from v1.0 to v1.1.4. This is the existing-project update test case with significant local modifications.
- **Echoes-Of-Gill update.** EoG runs the same update flow, staggered after TV so they don't share noise in the observation stream.

Phase 35 closes when empirical data from the three remaining installs (dogfood, TV, EoG) is available — when each has run for enough sessions to surface real signals. From there, Phase 36 decisions get made on data, not vibes.

After Phase 35 closes: Phase 36 handles component retire/repurpose decisions. `plan-coordinator` is on the evaluation list. `commit.sh` and `audit-helper` are already ratified as keepers per a recent CC-side audit. Phase 37 codifies the audit-as-skeleton-primitive workflow into `CLAUDE_MANAGER.md` as a `## Strategic audit cycle` section.

The skeleton itself receives every tier through direct commits — the skeleton edits itself. Target projects (TV, EoG, plus any future installs) receive each tier through `bash <skeleton>/scripts/update.sh` run from inside the project. The update mechanism classifies each file as `UNCHANGED`, `TEMPLATE_UPDATED`, `LOCALLY_MODIFIED`, `NEW`, or `ORPHAN` (a stale-but-matching baseline folds into `UNCHANGED` via match-rebaseline, Phase 59) and prompts before any destructive change. Updates are safe by default — the script refuses to overwrite local modifications without explicit user say-so.

## Gated on first-project signal sufficiency

**Gate:** ANY ONE production project has accrued enough decision-history / observation cycles to design against. Empirical, not chronological — the question is whether the data is structured enough to drive component design, not how long it's been sitting.

This is the big architectural reframe from the strategist session that opened Phase 35b. v1.2.0 was previously specced as a single manager-optimizer instance watching the skeleton's dogfood install. The new framing is per-project: each install gets its own manager-optimizer (an agent that watches how the manager decides over time, one instance per project), each watching that project's pattern of decisions, each drafting refinement suggestions for that project's `CLAUDE_MANAGER.md`. The skeleton's instance watches the skeleton; pinball's watches pinball; TV's watches TV.

This matters because the projects are different. **Pinball governs pinball. Trainer-View governs TV.** Each project's discipline diverges naturally over time because the work itself differs — a mobile app with a deployed backend has different audit needs than a game in active gameplay development, which has different needs again from a pinball prototype starting up. A single shared manager-optimizer would either over-fit to one project's patterns and force them on the others, or stay vague enough to be useless. Per-project instances let each project tune itself without contaminating its siblings.

Per-project mechanisms don't need cross-install validation — that's a v3+ concern. The previous monolithic gating was over-gating for per-project mechanisms whose design only needs one project's data. Trainer-View (mobile-deployed Firebase) + Echoes-Of-Gill (Godot game) remain the canonical first samples for per-project component design — they cover real structural variation between a deployed mobile backend and a game in active development. A third sample was anticipated from Pinball, but that project was retired (2026-07) before contributing — additional installs enrich the per-project mechanism's reach; none gate its design.

The bar separation matters: v1.2.0 design start is per-project mechanism design (one project's data suffices); v3+ graduation needs broad install-base evidence (≥15 projects, 75%+ adoption). Conflating the two bars over-gates v1.2.0 work that doesn't depend on cross-install signal.

Components in scope (per-project class):

- **Per-project manager-optimizer (centerpiece — SHIPPED v1, Phase 53)** — one instance per installed project; watches two layers: the project's pattern of *AI decisions* and the *human's* pattern of interaction at the gates (rushing, rubber-stamping, overriding). Routing splits by layer. AI-decision findings draft refinements to that project's `CLAUDE_MANAGER.md` (the AI-facing directive surface). Human-interaction findings draft adjustments to that project's **gate/friction config** (the operation-tier surface — § Appendix; Phase 48 implements), surfaced for the user's approval on the human-facing side (your-view, forthcoming) — never written into `CLAUDE_MANAGER.md`. Both layers draft only; approval-gated autonomy holds across both. This names the mechanism behind a promise STORY already makes: the gate getting smarter, not more annoying, as it watches what the user keeps saying yes and no to.
- **`artifact-fit-analyzer` (SHIPPED, Phase 56)** — surfaces redundancy, inefficiency, and missing combinations across the project's agents / skills / scripts / commands / hooks. Drafts consolidation, missing-coverage, or removal captures.
- **Loop pruning (via manager-optimizer)** — retires captures that never get approved and scripts that never get dispatched.
- **`token-efficiency-monitor` proactive upgrade** — flags before dispatch when planned scope smells over-budget, not just after the fact.
- **`infrastructure-auditor` (project-level)** — scheduled audit coordinator that dispatches the project-level checkers on a cadence.
- **`roadmap-auditor` (skeleton-level, dogfood only)** — the skeleton's own auditor of its roadmap, schemas, and cross-phase contracts.

(Pure-design components — `/goals` expanded, scheduled-goals — are in § Available now.)

(`meta-session-observer` + `template-promoter` are no longer in v1.2.0 scope; canonical home is § Gated on broad install base below.)

## Gated on v1.1.5 ship

**Gate:** v1.1.5 onboarding tier has shipped (phases A through E landed). The recommendation surface needs the onboarding tier as foundation — without onboarding, a new project doesn't have the context for plugin recommendations to land usefully.

v1.5 ecosystem integration introduces per-project plugin recommendation foundations — the system that watches a project's context and suggests ecosystem plugins (or rejects them) with reasons. It composes with v1.1.4's `code-quality-auditor` rather than replacing it.

Components in scope:

- **`recommendation.schema.md`** — the per-project plugin recommendation manifest. Frontmatter for project context (stack, audience, discipline preferences), body for recommendation rationale.
- **`code-quality-auditor` candidate mode** — pre-install vetting against the v1.1.4 heuristics, so the recommender can flag plugins likely to fail the post-install audit before they get installed.
- **`plugin-discovery-agent`** — surfaces ecosystem candidates relevant to the project's current state.
- **`plugin-context-matcher`** — scores discovered candidates against the project's recommendation manifest.
- **SessionStart hook for plugin-aware suggestions** with a cooldown so the suggestion stream doesn't become noise.
- **First-install integration** — when `install.sh` finishes, the recommendation flow can run as an optional next step.
- **Composition-rule documentation** in `CLAUDE_MANAGER.md.template`.

v1.5 sits between v1.1.5 and v1.2.0 because per-project tuning (v1.2.0) needs the recommendation surface as one input — the per-project manager-optimizer watching dispatch patterns is more useful when the project has a clear sense of which plugins it composes with and why.

## Gated on production maturity (empirical)

**Gate:** Sufficient audit corpus + project-context data + graduated patterns. Maturity is empirical — the question is whether the recommendation surface has enough signal to score plugins meaningfully, not how long the substrate has been running.

v2.0 is the mature plugin recommendation surface — a curated discipline for matching pain points and project context to specific marketplace plugins or community-library helpers. The tier folds three pieces that previously had separate phase numbers: `integration-checker` (Layer 1+2 of plugin verification — manifest sanity, surface area), `code-quality-auditor` Layer 3 (semantic fitness-vs-description; the layer beyond the narrow-scope heuristics that shipped in v1.1.4), and a curated catalog tied to project context (only if community-curation value materializes — a static catalog without a quality filter is a directory, which the principle below rules out).

The foundation is in v1.0 already: `CLAUDE_MANAGER.md.template`'s plugin marketplace composition section names the ecosystem sources the manager draws from. v2.0 turns that section from "here is the ecosystem we compose with" into "for the shape of this specific project, here are three plugins that pair well — and five that don't, with reasons for each." Design principle (locked, verbatim):

> **Don't be a directory; be a quality filter.**

The point is not to list every plugin available. The point is to give the manager a discipline for picking the right ones for the project at hand and rejecting the wrong ones early.

## Gated on telemetry maturity

**Gate:** the substrate produces enough real telemetry to validate an uncertainty engine against and to feed visibility surfaces with actual data. Empirical, not chronological — the question is whether real session telemetry is rich enough to calibrate against and display, not how long the substrate has run. Independent of the v2.0 and v3+ gates; this tier could open before or after either, consistent with tiers not shipping in numeric order.

This is the human-facing horizon — the tier that builds the surface through which the person sees and steers the work, as distinct from the surface through which the AI is governed. It composes with the substrate's existing observation and gate infrastructure rather than replacing it.

**Confidence-and-fidelity engine (research bet — may not pan out).** This is an unvalidated hypothesis, not a planned mechanism, and it is placed here precisely so that distinction stays visible. The idea: measure **confidence** (how likely a claim is correct — via resampling for agreement plus verification against constitution, tests, and sources, never the model's self-report, which is systematically over-calibrated) and **fidelity** (whether output stayed faithful to its source or flattened the nuance — checked against the uncompressed original). The reason it is not built is not sequencing — it is that the approach may not survive contact with real data. An uncalibrated confidence score is worse than none, because it manufactures false trust; resampling carries a real per-call cost that needs a cheap deterministic pre-filter to be viable; fidelity scoring works best on structured sources and degrades elsewhere; and cheap checks (tests pass, source opens, types check) must run before any of the expensive machinery earns its place. Each of those is a way the bet could fail, and each has to be answered by a working prototype before this becomes a mechanism rather than a hope. First prototype answer (experiments/confidence/, 2026-07): the resampling-agreement leg resolved **RED** on structured skeleton tasks — zero agreement variance across 30 scored tasks, six confidently-wrong answers at full 7/7 agreement — so resampling drops, per the gate pre-committed before capture. The verification-against-ground-truth leg (cheap deterministic checks) is unaffected by that result and remains the live path. If it validates, it routes the gates (a low score escalates the ladder, a persistently low score after human review triggers the get-a-human rung) and feeds your-view's confidence display. That payoff is real — but it is downstream of a research question that is genuinely open.

**your-view (not built — surfaces scattered or nonexistent today).** The structural home for the human-facing half of the system: the surface that equips the person rather than constraining the machine. It unifies the visibility surfaces — receipt, weekly report, post-prompt change view, confidence/fidelity display, plain-English translation, impact map — into one container, both a standing plain-English view openable anytime and a stream of surfaced moments at the right times. Today these surfaces are scattered or unbuilt; this tier names the container, it does not ship it. your-view carries an internal dependency on the confidence-and-fidelity engine validating first, since its confidence display has nothing to show until the engine exists. The *identity* weight of your-view — why it is half of what skeleton is — lives in STORY; ROADMAP carries it as a sequenced tier with honest build status.

**Routing closure.** This tier is where the optimizer's two-layer split (§ Gated on first-project signal sufficiency) pays off: human-interaction findings surface for the user's approval *in* your-view and land *in* the gate/friction config — never in `CLAUDE_MANAGER.md`. The "your-view, forthcoming" reference in the optimizer bullet resolves here.

*Scope fence:* this entire tier is design-stage — nothing in it is in the v1.1.5, v1.2.0, or v2.0 build queue. The operate-layer, security-watch, going-live, and locked-record surfaces are **not** part of this tier; they live in the implementation guide and are out of ROADMAP scope.

## Gated on broad install base

**Gate:** ≥15 projects installed with ≥75% adoption of candidate patterns (target 20+ / 90%+). Below that threshold, cross-install pattern detection surfaces noise, not signal.

This is the v3+ ecosystem maturity tier. Two pieces live here: cross-install graduation machinery (the formal mechanism for moving patterns from one project's `.claude/` into `template/`), and the multi-LLM sibling project (a separate project that ships when API-cost concerns become material at scale).

### Cross-install graduation machinery

`meta-session-observer` (cross-install pattern watcher) + `template-promoter` (executes graduation moves) formalize what's currently a manual discipline. Before this tier ships, graduation happens via strategist judgment — patterns get promoted from one project's `.claude/` to `template/` based on human-curated assessment. The formal mechanism waits for a real install base (15+ projects with 75%+ adoption of candidate patterns; target 20+ / 90%+) because cross-install pattern detection without enough installs surfaces noise, not signal.

When the threshold is reached: `meta-session-observer` watches cross-install signal → `workflow-suggester` drafts a graduation capture (`suggested_artifact_type: graduation`) → user approves → `template-promoter` executes the move (updates `install.sh` manifests, regenerates baseline hashes, updates CI scenarios). The mechanism is the FORMALIZATION of graduation, not the introduction of it. Manual graduation is the v1.2.0-through-v2-era discipline; formal mechanism is the v3+ unlock.

### Multi-LLM sibling project

Running the skeleton's structure across multiple LLMs — Claude + DeepSeek + others — with the manager arbitrating which model handles which subtask. claude-skeleton was designed against Claude Code's specific affordances (subagent dispatch, slash commands, hooks, skill discovery). Re-targeting it for general LLM orchestration would change the project's center of gravity, not extend it.

The motivation for the sibling project is concrete and cost-shaped. API spend at scale runs into a split that's increasingly hard to ignore: bulk code execution doesn't need Claude-grade judgment, but Claude-grade judgment is what you're paying for. A bridge architecture would dispatch execution work to cheaper models — MiniMax, Kimi-K2, Gemini Flash, DeepSeek, GLM, Qwen-Coder, others in that tier — while Claude handles planning, review, conflict resolution, and any judgment call where mistakes get expensive. The manager's arbitration role expands from "which helper handles this subtask" to "which model handles this subtask" — the same shape, applied across a wider surface.

The reference design comes from a Reddit pattern doing the rounds: lock-file coordination between agents plus a tmux grid for parallel multi-agent dispatch. That's the architectural seed, not a spec — bridge will design its own concrete architecture when the project opens, but the lock-file + grid shape is what makes the cost split real instead of theoretical.

The scaling caveat is worth naming up front. At 1 person × small-N projects, review is cheap and the cost savings compound. At multi-person × multi-project, review becomes the bottleneck — a Reddit user running 1 person × 100 sites hasn't hit it yet; 5 people × 5 projects would. The governance discipline transfers directly from skeleton to bridge — approval-gated autonomy, batched audit cadence, per-project tuning — that's the lineage. But bridge will need its own answer to review-at-scale; it doesn't get that for free from skeleton's design.

The skeleton stays Claude Code-only through v2.0. If multi-LLM is pursued later, it lives as a **sibling project** — different name (working title `claude-skeleton-bridge`), shared lineage, separate identity. Out of scope through v2.0; out of scope as a feature graft, period. The decision to fork the identity for a multi-LLM target is itself a strategic decision that gets made on its own merits, not absorbed into a version bump.

## Locked architectural principles (core)

Decisions that hold across all v1.2+ work. Captured here so future slices don't relitigate them. Operational design principles that shape mechanism design rather than project identity live in § Appendix below.

### Approval-gated autonomy

Thinking is autonomous; action is approved. The skeleton can suggest captures, surface plugin recommendations, detect drift, draft scripts — all autonomously. None of those become installed/applied artifacts without explicit user approval. Plan-mode discipline, capture-lifecycle states (`draft → approved → shipped`), and X-builder draft mechanics all enforce this line. **How it applies:** new mechanisms maintain the line by default; "auto-apply" is a deliberate carve-out (e.g. `--auto-apply` in `update.sh` accepts only TEMPLATE_UPDATED + NEW, never LOCALLY_MODIFIED or ORPHAN — the autonomy is bounded).

### Per-project governance

Each install evolves its own discipline. The shared template is a seed, not a final form. Every project tunes its own audit cadence, its own approval thresholds, its own sense of when to suggest a refactor. v1.2.0's per-project manager-optimizer (one instance per installed project, each watching its own context) is the mechanism that makes per-project tuning real. **How it applies:** new components ask "does this freeze the discipline at the template level, or let each project diverge?" Per-project divergence is the default; shared-template behavior is the carve-out that requires graduation evidence.

### Empirical readiness, not the clock

Every gate in the roadmap is signal-based — sessions accumulated, observation cycles closed, audit corpus large enough, install count growing, prior tier shipped. Calendar qualifiers never the lock. **How it applies:** new mechanisms answer "what's the empirical signal that says the gate is open?" Calendar-time gates fail design review.

### Soft gates vs hard safeguards

Two distinct gating classes. **Soft gates** = discipline-layer: "should we automate this pattern?" / "should we apply this update?" Configurable, flippable per-install, can loosen as trust accrues. **Hard safeguards** = user-safety-layer: destructive-bash blocking, trust-tier-3 plugin gating, file ops outside project, credential/financial/PII exposure. NOT configurable; not flippable; not loosened. The two classes don't share a configuration surface. **How it applies:** new gates answer "soft or hard?" Soft gates earn looseness; hard safeguards stay rigid forever.

*Vocabulary clarification:* "action" in approval-gated-autonomy means "operations that modify state visible outside the assistant's scratchpad." Public-info reads don't qualify — they're thinking with external memory.

### Multi-project graduation

A pattern graduates from one project's `.claude/` into `template/` (i.e. ships to every installation) when it crosses a hard threshold:

- **≥75% of installed projects** show the same pattern (target 90%+). The 75% floor exists because broad adoption — not narrow majority — is the bar; at small N, even 66% can be 2-of-3-projects coincidence.
- **Minimum 15 projects** in the sample (target 20+). Small-sample variance across 3 projects is too high to call any pattern "broadly proven"; the 15-project floor exists to prevent small-N coincidence promotion. 20+ projects is the target where graduation decisions become statistically meaningful.
- **Stable through sufficient consecutive sessions and observation cycles** — the pattern hasn't been edited or reverted recently in any of the contributing projects.
- **Zero negative observations** in the same window (no project has flagged the pattern as broken, noisy, or contraindicated).

This tier of mechanism — cross-install pattern detection — ships in **v3+** when claude-skeleton's install base supports it. v1.2.0 mechanisms are per-project (one instance per install, each watching its own context) and do not depend on graduation. Before the v3+ threshold, graduation happens manually via strategist judgment; the formal mechanism (`meta-session-observer` + `template-promoter`) is the FORMALIZATION of that discipline, not the introduction of it. See § Gated on broad install base for the formal mechanism's shape.

### Flow + safety, both

The manager protects flow during active work — no per-action interruptions, no permission prompts on reversible changes inside a feature branch, no clarifying-question avalanches on simple requests. Audits run on a cadence (at session start with a cooldown), not per-prompt. The architecture refuses the speed-vs-discipline tradeoff: flow + safety, both, as the default state. **How it applies:** new mechanisms designed against this principle must not introduce per-action friction; if a mechanism's value depends on real-time interrupts, it gets redesigned to fire on a cadence, or it gets deferred to a tier where the cadence-vs-interrupt design tradeoff is explicitly negotiated.

### Guard rails, configurable but transparent

Every protection in the system can be turned off. None of them can be turned off silently. Disabling a hook, skipping an audit, overriding a deny rule — the user gets explicit language ("You're now outside Claude Code's jurisdiction") before the action lands. The principle locks an architectural shape: there is no design freedom to add silently-defeatable guards. **How it applies:** when a phase scopes a new protection, the brief must answer "how does the user step outside this, and what language tells them they have?" Protections without an explicit escape hatch — or with a silent one — fail the design review.

### Scope actively governed, not passively hoped for

Every claude-skeleton install defines its scope explicitly through its own `CLAUDE.md`, `CLAUDE_MANAGER.md`, and locked principles. The system audits that scope continuously: cruft-checker for doc rot, drift-checker for version drift, code-quality-auditor for installed-plugin sanity, per-project manager-optimizer for decision drift (v1.2.0). When scope erodes, the system surfaces it; the user decides what to do. **How it applies:** every new audit producer asks "what specific scope question does this answer?" Producers that don't tie back to a scope question are decorative, not load-bearing.

### Composition not competition

The skeleton composes with the `/plugin` marketplace + named community libraries. It is NOT a multi-LLM framework, NOT a directory of every plugin, NOT an autonomous AI agent. v2.0 plugin recommendation surface realizes this principle by name; v1.5 ecosystem integration tier prepares the orchestration brain to dispatch ecosystem plugins. **How it applies:** when the ecosystem ships what the skeleton would build (e.g. Anthropic's `feature-dev` replacing `/spec`; `superpowers` TDD as net-new value), the skeleton composes. Building from scratch requires empirical evidence the ecosystem doesn't already serve the need.

### Ever-evolving being

The skeleton ships a baseline; `project-tuner-helper` shapes it per-project; `workflow-suggester` catches new patterns. Not "install and forget" — the skeleton evolves with its installations. The capture/reuse loop, observation infrastructure, and meta-agents in `05_meta/` all exist to support this evolution. **How it applies:** every new component asks "does this enable ongoing evolution, or freeze a snapshot?" The skeleton refuses snapshot-locking.

### Token-cost as design driver

Optimize for useful output per token, not for token minimization. The user's subscription quota IS the constraint; every layer — observation, dispatch, context loading, agent output — gets measured and designed against cost. Telemetry required; estimation required; budget enforced. The token-cost agent ranks alongside the manager as a top-sophistication peer, with its own auditing/editing surface — same investment level, same review discipline. **How it applies:** new components answer "what's the token cost per useful unit of output?" Cost optimization stops where usefulness drops. Components that minimize tokens at the cost of output quality fail design review.

### Usefulness is the floor

Every discipline mechanism in the skeleton — audits, observation cycles, capture lifecycles, token efficiency, plan-mode discipline — serves usefulness. None replaces it. If a mechanism makes the skeleton less useful, it gets cut or redesigned. This is the floor every other principle stands on. When a layer drifts past usefulness (audits over-firing, gates over-tight, context over-loaded, optimization over-cutting), the layer gets corrected, not justified by reference to its own discipline value. Usefulness is empirical: did the user get more useful work done because the skeleton exists, or less? The answer must always be "more."

## Cuts — what's NOT in the roadmap

Pieces that were on earlier candidate lists and have been explicitly cut. Logged so the rationale doesn't have to be re-derived.

Carry-overs from earlier sessions:

- **skill-builder and agent-builder cut.** Markdown writing is cheap — no automation gain from a builder that just stamps frontmatter and a body. `/goals` expanded (v1.2.0) produces the spec; manual write handles execution. The recommendation function for "should this be a skill, agent, script, or command?" moves to `artifact-fit-analyzer` (v1.2.0).
- **Gap #1 auto-dispatch by intent deferred.** Deferred to v1.2+ post-manager-optimizer. Trying to close it earlier would mean inferring intent from request shape without empirical grounding — the same "optimize against vibes" trap that pushed manager-optimizer itself to v1.2+.
- **Plugin recommendation as a standalone phase cut.** Folded into v2.0. A curated catalog without quality verification is a directory; quality verification without a catalog is just `integration-checker`. The two only justify a tier together.
- **Lessons-log as a separate parallel doc (Model B) cut at Phase 18.** Duplicates content with the directive layer; readers consult two docs for one rule; drift between them becomes a real maintenance cost.
- **Captures-as-lessons-library (Model A) cut at Phase 18.** Captures are draft-then-ship work items, not durable reference. The library accumulates stale captures.
- **User-pause-on-plugin-install assumption cut at Phase 34.** The bundle install ran autonomously and cleanly; no user-pause was needed mid-stream.
- **claude-mem indefinite deferral cut at Phase 34b.** claude-mem installed cleanly via the marketplace path; the eyes-open install pattern was proven on a trust-tier-2 case.

New cuts from the Phase 35b reframe session:

- **Single-manager-optimizer (dogfood-only watching) cut.** Per-project manager-optimizer is the new lock. Each install evolves its own discipline; a single instance watching one project's patterns would force-fit those patterns onto every install regardless of fit.
- **One-size-fits-all install cut.** Per-project tuning is core architecture, not an opt-in feature. The template is a seed, not a frozen final form. The previous framing left room for "skeleton ships a fixed config" — that framing is gone.
- **"AI productivity tool" framing cut.** claude-skeleton is governance infrastructure, not a speed-up plugin. The product question is "does this preserve coherence over time," not "does this make me type faster." Speed is a byproduct of not having to clean up messes; it is not the deliverable.
- **Cross-install graduation as a v1.2.0 component cut.** Moved to v3+. The mechanism (`meta-session-observer` + `template-promoter`) requires a real install base (15+ projects, 75%+ adoption of candidate patterns) to operate against; v1.2.0 cannot supply it. Until then graduation happens manually via strategist judgment; the formal mechanism waits. Graduation threshold raised from 3 projects / 66% adoption to 15 projects / 75% adoption (target 20+ / 90%+) — small-sample variance across 3 projects is too high to call any pattern "broadly proven."

New cuts from the Phase 45 restructure:

- **3-project / 66% graduation threshold cut at Phase 44** (replaced with 15-project / 75% floor). Small-sample variance across 3 projects was too high; ≥66% adoption at small N could be 2-of-3 coincidence. Locked atomically here for navigability; rationale already captured in the Phase 44 umbrella cut above.
- **v1.2.0 monolithic tier gating cut at Phase 44.** Per-component gating split (per-project / pure-design / cross-install classes) replaced the single "≥2-3 weeks miles on TV + EoG" gate that over-gated per-project mechanisms whose design only needs one project's data.
- **claude-skeleton-auto as shipped product variant cut.** Research experiment only — never ships as a product variant. The approval-gated-autonomy principle is non-negotiable for any released skeleton; an autonomous variant would conflict with the core line.
- **Time-based gating across roadmap tiers cut at Phase 45.** Every gate signal-based: sessions accumulated, observation cycles closed, audit corpus large enough, install count growing, prior tier shipped. Calendar qualifiers fail design review.

## Closing — scope discipline

claude-skeleton is an orchestration layer on the Claude Code ecosystem. It composes with the `/plugin` marketplace and the named community libraries. It is **not** a multi-model framework, not a directory of every available plugin, and not an autonomous AI agent. Approval-gated autonomy is the working line: thinking is autonomous, action is approved. Each project draws its own line on top of that shared base — per-project governance means the skeleton's defaults are the seed, not the ceiling.

The roadmap above is the sequence in which that working line gets pushed — tier by tier, the discipline gets richer, the audits get sharper, the per-project tuning gets real. The user's role at the approval gate never disappears. Scope is governed actively; it is never erased.

## Appendix — operational design principles

These are operational principles — they shape how mechanisms get designed and how phases get scoped. They sit one layer below the locked core: equally non-negotiable, but more specific to mechanism shape than to project identity.

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

### Define-everything-upfront

Brief specs lock interpretations before code; plan-mode surfaces them. The pre-build scoping rule (5 questions before any v1.1+ component prompt) forces upfront definition. Narrow-scope-by-design phases ratify it. **How it applies:** ambiguous briefs get the honing conversation BEFORE prompt drafting, not during execution. Plan-mode catches scope drift before commits.

### Narrow-scope-by-design

Each phase locks scope at brief time; "out of scope" sections in plans are load-bearing. The three-commit cadence prevents scope creep into single commits. The Phase 10 commit-cadence-by-phase-size rubric formalizes this. **How it applies:** when a phase surfaces work outside its locked scope (Phase 30b's emergent hook-CWD fix), the work either folds thematically OR queues for a separate phase — it doesn't expand the current phase silently.

### Compose-with-available-surfaces, defer-on-unavailable

Don't ship retrospective signals or mechanisms that require Claude Code instrumentation surfaces that don't exist yet. Phase 5 (task-watchdog 2-signal scope vs 5-signal candidate) and Phase 18 (lesson-detection deferral) set the precedent: when a brief proposes a signal whose detection requires unavailable instrumentation, defer to the version where the relevant investigation lands (typically v1.2.0 for token data, future for real-time hooks) — explicitly note the deferral in the brief's locked decisions. **How it applies:** new components check "does this require CC surface X that exists today?" before locking scope. Unavailable-surface dependencies cause scope cut, not feature shipping with conditional code paths.

### Operation tier classification

Five-tier op classification, sourced from the soft-gates-vs-hard-safeguards principle.

- **Tier 1 (free):** pure reads, no leakage risk — file views, web search, web fetch of public URLs, grep, ls. No approval.
- **Tier 2 (light gate):** writes to scratch / observations / drafts. Visibility, no ceremony.
- **Tier 3 (plan-mode gate):** writes to repo files, schema changes. Current default.
- **Tier 4 (explicit confirm):** destructive bash, git, external system calls, file ops outside project.
- **Tier 5 (hard rail, never):** credentials, financial, PII. Permanently blocked.

Tiers 1-3 are soft gates; Tier 4 is mixed (operation class configurable, destructive patterns hard-blocked); Tier 5 is a hard safeguard. **How it applies:** new mechanisms classify their operations into one of the five tiers; tier assignment drives gate selection. Phase 48 shipped the implementation (the `gate-config.json` cost block + `token-cost-monitor`); the operation-tier / friction slots ship documented-empty pending optimizer-proposed values.
