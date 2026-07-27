# Spotter — the story

Spotter (engine codename `claude-skeleton`) regulates two things at once: a Claude Code project, and the person building it. On the system side it is a **governance layer** — a **structural immune system** that watches a project for scope decay, drift, and the silent erosion of the principles it was built on, orchestrating the moving parts (agents, skills, scripts, slash commands, hooks) so the project itself stays coherent as it grows. On the human side it carries the discipline a person under pressure forgets — because the hardest failure in AI-assisted building is not that the machine writes bad code, it's that people rush, approve to keep moving, and skip the steps they know pay off. System-level best practice is already well understood; making a real human actually follow it is the half nearly every tool leaves out. This is not a productivity tool. It's structural infrastructure — the thing that makes "this codebase is still maintainable six months in" a sentence that can be true, and that makes the person building it better at the work, not just faster.

## The problem we're solving

Projects decay structurally over time. A project starts clean. You know why every piece exists, what each helper does, why a particular file holds a particular role. Six months later — three features shipped, two team members rotated, four refactors and a half-done migration — the original logic has faded. Nobody remembers exactly why this script has that flag. The decay is gradual and invisible until the cleanup cost is enormous.

AI-assisted coding makes the decay faster and harder to spot. It is easy to generate volume. It is hard to maintain coherence across that volume. What lands is **AI-generated slop** — code that compiles, that passes the test, but that doesn't fit the project's shape: redundant helpers next to the originals they duplicate, leftover scaffolding from abandoned approaches, drift between what the docs claim and what the code actually does. The symptom is visible. The cause is structural.

Existing tools catch the wrong layer. Linters and formatters check syntax — does this file parse, is this brace closed, is this variable used. Plugins ship reusable skills. None of them ask the question that actually matters here: does this still belong here? Is this consistent with what the project said it was when it started? The structural question lives above the syntax check. Without a watcher at that layer, nothing catches drift.

Human discipline alone fails. The intent is always to keep things clean. Deadlines hit. Shortcuts accumulate. Context fades. By the time someone notices that the project is drifting away from its declared shape, the work to pull it back is no longer cheap. Catching drift early is a different problem than fixing it late, and almost everything in claude-skeleton exists to make the early catch possible.

## Mission

claude-skeleton is a **structural immune system** for projects. The frame is borrowed deliberately from biology: the system watches for things that don't belong, surfaces them while they're still small, and lets the human decide what to do. Think of it in three pieces — a constitutional framework (the locked principles each project commits to), an executive branch (the manager that runs decisions during work), and watchdogs (the auditors firing on a cadence to check that the project hasn't drifted away from the constitution). Together they form the layer that catches structural problems before they become structural rewrites.

The center of the system is one rule. In a claude-skeleton project, **scope is actively governed, not passively hoped for.** Every project that ships in this system defines what it is — which problem it's solving, which patterns it commits to, which lines it won't cross. The skeleton enforces that definition through the project's lifetime. The discipline is not a one-time setup move at install; it's a recurring check that the project still resembles what its constitution says it is.

Beside that rule sits a second one: claude-skeleton regulates the **human** as much as the system. System-level best practice — typed code, real tests, a defined architecture, security checks — is already well understood; what's been missing is anything that makes a real person, working under deadline pressure, actually follow it. People rush, approve to keep the workflow moving, and skip the planning they know would pay off. So the skeleton carries that discipline for them — holding the line at the moments that genuinely matter and staying out of the way everywhere else, so a session ends with the work done properly rather than hurried past the parts that bite later. The system half keeps the project coherent; the human half keeps the person in command of work they would otherwise rush through. Neither half is the whole, and the human half is the one nearly everyone forgets.

Each install evolves its own brain. This is what **per-project governance** means in practice. claude-skeleton ships a template — a seed configuration — but every project tunes itself from there. **Pinball governs pinball. Trainer-View governs TV.** The skeleton runs in production today on a small set of real projects of mine — Trainer-View (Flutter + Firebase mobile app), Echoes-Of-Gill (Godot game in active development), and the skeleton's own dogfood install — each with different needs, different rhythms, different things worth watching. The shared template carries only what proves itself across multiple installs; idiosyncratic patterns stay local to the project they belong to.

The discipline runs in the background of normal work. The manager handles decisions for you during a session so you stay in flow — when to dispatch a helper (an agent that does a focused piece of work and returns), when to read directly, when to ask before doing something destructive. Audits run on a cadence (a few times a session, at session start, on a cooldown), not after every prompt, so the work itself isn't interrupted. This is **flow + safety, both** — the system isn't a tradeoff between speed and discipline; it's an architecture that gets both. Over time, as the system watches what you keep saying yes and no to, **the approval gate gets smarter, not more annoying** — friction at the gate decreases as patterns earn trust.

The system also makes the project handoff-ready. Someone inheriting the codebase — a collaborator joining the team, a buyer evaluating an acquisition, future-you in three months who has forgotten the context — can read the project's constitution and understand how it was meant to work, what was deliberate, what was just-this-once. The skeleton is what makes the inheritance possible. Without a written-down structure, handoff collapses to "ask the person who built it" — and that person might not be available, or might be you with a blank slate.

Drift is prevented **before it becomes irreversible**. The longer scope problems sit, the more they cost. A redundant helper caught in the same session it appears is a five-minute delete. The same helper caught six months later, after two features have built on top of it, is a partial rewrite. The system's job is to catch the problem at the cheap stage. The cost curve is steep — catching it early is the entire game; catching it late is a different game entirely.

The human stays in control throughout. The system **enforces transparency, not rigidity.** Guard rails exist; they can be turned off. But turning them off is always explicit. There is no silent escape from the principles you committed to. If you want to step outside the discipline for a particular session or a particular task, you can — and the system tells you, plainly, that you've done it. The full sequencing of how this comes together lives in [`ROADMAP.md`](ROADMAP.md).

The system half and the human half each get their own surface. The constitution — the locked principles, the manager's directives, the rules the machine reads and obeys — faces the system; it's where the project's standard is written down and enforced. Its counterpart faces the person: a human-facing surface (call it your-view) whose job is not to constrain the machine but to keep the person oriented, informed, and in command — the place the receipts, the plain-English explanations, the record of what changed and why, and the confidence behind each call come together, so the human at the approval gate is deciding with sight rather than clicking blind. That surface is still being built; its shape and sequencing live in ROADMAP.md. The architecture has two halves by design, one per side of regulate-both: the constitution holds the machine to the standard, and your-view raises the person toward command of it.

## Core principles

Twelve principles flow from the mission and from the two halves it regulates. Some hold the **system** to its standard — approval-gated autonomy, scope actively governed, multi-project graduation. Some keep the **human** in command and unburdened by needless friction — flow + safety, usefulness is the floor, guard rails configurable but transparent. Each is non-negotiable; every roadmap decision composes against this list.

### Approval-gated autonomy

Thinking is automated; action is approved. The system can read, plan, observe, audit, and draft suggestions on its own — none of that requires permission. But anything that changes the project — a commit, a script that runs, a file that gets installed — waits for the user. This line holds across every version of the skeleton and every plugin it composes with.

### Per-project governance

Each install evolves its own discipline. The shared template is a seed, not a final form. Every project tunes its own audit cadence, its own approval thresholds, its own sense of when to suggest a refactor. A v1.2.0 component called the manager-optimizer (an agent that watches how the manager decides over time, one instance per project) is the mechanism that makes per-project tuning real; the full design lives in [`ROADMAP.md`](ROADMAP.md).

### Empirical readiness, not the clock

Every gate in the roadmap is signal-based — sessions accumulated, observation cycles closed, audit corpus large enough, install count growing, prior tier shipped. Calendar dates never lock a tier. The question is always "what's the empirical signal that says the gate is open?" — not "has enough time passed?"

### Soft gates vs hard safeguards

Two distinct classes of gating live in the system. Soft gates ask "should we automate this pattern?" or "should we apply this update?" — they're configurable, flippable per-install, and can loosen as trust accrues. Hard safeguards block destructive operations: destructive bash patterns, trust-tier-3 plugin gating, file ops outside the project, credential or financial or PII exposure. Hard safeguards are not configurable, not flippable, not loosened — they stay rigid forever. The two classes don't share a configuration surface.

### Multi-project graduation

Patterns graduate from a single project's `.claude/` into the shared template only when they prove themselves across multiple projects. The bar is 75%+ adoption with a 15-project floor (target 20+ projects / 90%+ adoption), stable behavior across sufficient consecutive sessions in each contributing project, and zero negative observations across that window. One project liking a pattern is not enough; idiosyncrasies stay local.

### Flow + safety, both

The manager protects flow during active work — it doesn't interrupt every prompt for permission, it doesn't ask three clarifying questions before a one-line change, it doesn't surface every observation as a blocking event. Audits run on a cadence, not per-action. The architecture refuses the speed-vs-discipline tradeoff: flow + safety, both, as the default state.

### Guard rails, configurable but transparent

Every protection in the system can be turned off. None of them can be turned off silently. When a user crosses out of the protective shape — disabling a hook, skipping an audit, overriding a deny rule — the system says it, in plain language: **You're now outside Claude Code's jurisdiction.** The user is never trapped by the system, and the user is also never lied to about the state of the system.

### Scope actively governed

Every claude-skeleton install defines its scope explicitly through its own `CLAUDE.md`, `CLAUDE_MANAGER.md`, and locked principles. The system audits that scope continuously through the watchdog cadence. When scope erodes, the system surfaces it; the user decides what to do. This is the center of mission — scope is actively governed, not passively hoped for.

### Compose, don't compete

claude-skeleton sits on top of Claude Code's plugin marketplace. It does not try to replicate every plugin or replace every helper. The first move when a need shows up is to look at what the ecosystem already ships — `/feature-dev`, `code-review`, `superpowers`, claude-mem, and the rest — and compose with it. Building from scratch happens only when the ecosystem doesn't serve the need; the cost of duplicating something good is much higher than the cost of pulling it in.

### Ever-evolving being

The skeleton ships a baseline; `project-tuner-helper` shapes it per-project; `workflow-suggester` catches new patterns. Not "install and forget" — the skeleton evolves with its installations. The capture/reuse loop, observation infrastructure, and meta-agents in `05_meta/` all exist to support this evolution.

### Token-cost as design driver

Optimize for useful output per token, not for token minimization. The user's subscription quota IS the constraint; every layer — observation, dispatch, context loading, agent output — gets measured and designed against cost. Cost optimization stops where usefulness drops. Mechanisms that minimize tokens at the cost of output quality fail design review.

### Usefulness is the floor

Every discipline mechanism in the skeleton — audits, observation cycles, capture lifecycles, token efficiency, plan-mode discipline — serves usefulness. None replaces it. If a mechanism makes the skeleton less useful, it gets cut or redesigned. Usefulness is empirical: did the user get more useful work done because the skeleton exists, or less? The answer must always be "more."

## How it prevents scope decay

The discipline runs through a loop with several stages. None of them is novel on its own — observers, audits, manager judgment, builders, all exist in various places in the ecosystem. What's specific to claude-skeleton is that they're connected into a coherent pipeline, with the user's approval at the load-bearing center.

Stage one is observation. Independent watchers — the task-watchdog (retrospectively reads the last session's transcript for recurring failures and long-running commands), the cruft-checker (catches stale references in the project's own docs), the code-quality-auditor (checks installed plugins), and the session-end telemetry (records each session's token spend) — write structured observation files into `.claude/observations/` against a shared schema. Four sources, one format. The schema makes it possible to add new producers later without re-architecting the consumers.

Stage two is capture. A consumer called the workflow-suggester (an agent that walks observations and drafts proposals from them) writes capture files into `.claude/captures/`. A capture has frontmatter (status, confidence, suggested artifact type) and a body explaining the pattern. Status flows: `draft → approved → shipped`, or `rejected` to mark a do-not-suggest-again pattern. The user reviews every capture before it leaves draft state.

Stage three is the approval gate. The user reads the capture, decides whether the pattern is worth automating, and flips the status. The gate is the locus of human judgment — the system surfaces; the human decides. There is no auto-approval at this layer because the choice is structural, not mechanical: should this pattern become permanent?

Stage four is the builder. For approved captures, a script-builder (the first instance of a builder-that-turns-captures-into-artifacts — call it an X-builder, where the X is the artifact type) drafts a bash file at `.claude/scripts/drafts/<pattern>.sh.draft`. The draft is unexecutable until the user promotes it. The pattern stops being a recurring manual chore once the script lands. This is the capture/reuse loop closing — the system notices a repeated piece of work, drafts a fix, and the user promotes it when they're ready.

Stage five is audit. The project-level audit triad (cruft-checker for doc rot inside the project, drift-checker for skeleton-version drift against the upstream, code-quality-auditor for installed-plugin sanity) fires at session start with a cooldown, surfaces findings as observations, and feeds them back into the loop. Findings are not interrupts — they accumulate as observations the manager batches into the same approval surface as everything else.

Stage six is per-project manager-optimization (v1.2.0). Each install gets its own manager-optimizer that watches how the project's manager actually decides over time and drafts refinement suggestions for the project's `CLAUDE_MANAGER.md`. Stage seven is graduation — patterns that prove themselves across the install base move into the shared template, so every project that runs `update.sh` inherits them on its next refresh. Today this happens manually via strategist judgment; at v3+ (when claude-skeleton's install base supports cross-install pattern detection — 15+ projects, 75%+ adoption of candidate patterns), `meta-session-observer` + `template-promoter` formalize the discipline. The formal mechanism is the formalization of graduation, not the introduction of it. The loop is self-improving without ever taking the user out of the approval seat.

## What claude-skeleton is NOT

A few things claude-skeleton is **not**, said plainly so expectations are right:

- **Not a productivity plugin.** Discipline is the point. Speed is a byproduct of not having to clean up messes later.
- **Not autonomous without approval.** The human stays in the seat of judgment, always. Anything that changes a file or runs a command waits for the user.
- **Not multi-LLM.** claude-skeleton is Claude Code-only by design. If a multi-LLM version is pursued in the future, it lives as a sibling project (working name: `claude-skeleton-bridge`), not a feature graft into this one.
- **Not a plugin directory.** Recommendations are vetted, scoped per-project, quality-filtered. **Don't be a directory; be a quality filter.**
- **Not one-size-fits-all.** Per-project tuning is core architecture, not an edge case. A pinball game and a mobile app should not feel identical under the hood.
- **Not opaque governance.** Every guard rail can be turned off, with explicit warning. The user is never trapped by the system.

## Who this is for

Solo developers and small teams shipping projects worth maintaining longer than three months. Games, frameworks, mobile apps, deployed services, anything where structural coherence matters more than throwing one-shot scripts together. The skeleton's overhead — defining what the project is, what discipline applies, what gets audited — pays back as soon as the project hits the "I came back to this six months later" stage.

Anyone planning to hand off or sell their work also benefits. The skeleton makes inheritance readable. A buyer or collaborator can read the constitution, understand the discipline the previous author committed to, and make informed decisions about what to keep, what to change, and where the load-bearing pieces live.

Who this is not for: throwaway scripts, single-session experiments where nothing survives the afternoon, people who want zero discipline and pure flow (flow + safety, both, is a deliberate stance — the safety half adds friction that some workflows simply don't need), and people committed to a non-Claude-Code workflow. The skeleton is opinionated about Claude Code's specific affordances (subagent dispatch, slash commands, hooks, skills) and would lose most of its value retargeted to a different host.
