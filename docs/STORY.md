# claude-skeleton — the story

## What this is

claude-skeleton is an orchestration skeleton for Claude Code projects. Install it into a target project and you inherit a working manager-and-helpers setup — agents, skills, scripts, slash commands, hooks — already tuned, non-destructive, with safe automated updates. Current version: **v1.1.1**. The capture/reuse loop is live (five components closing autonomy Gap #2), built on top of v1.0's install / update / CI foundation with the three-platform matrix green on every push and PR. Used in production today on two real projects with very different stacks: Trainer-View (Flutter + Firebase) and Echoes-Of-Gill (Godot). The audience is small — me and a few peers — and that's the audience this doc is written for.

## Why it exists

The skeleton exists because variable attention forces system-design discipline that turns out to be generally useful.

I have ADHD. Some days my attention is a laser; some days it's a flashlight with a dying battery. The flashlight days are where most "smart agent" workflows break — the agent assumes you remember what you decided three sessions ago, where the helper lives, why this script has that flag. On a laser day that's fine. On a flashlight day the project goes sideways. So I started writing things down: who owns what, how the manager should think, what to do when X. Persistent state instead of in-head state. Explicit handoffs instead of "you'll remember." Written-down judgment instead of vibe-based decisions.

The unexpected part: every peer I showed it to also wanted it. Not because they have ADHD, but because LLM-collaboration over weeks has the same shape as a flashlight day — you don't remember what last week's session decided either, and the agent definitely doesn't. The constraint-forced discipline (explicit rules, persistent markers, structured intake) generalises. It's a fixed-attention crutch that turns out to be a long-context tool. The bit that should be obvious in retrospect: anything that survives my worst attention day will survive anyone's normal one.

The patterns themselves came from Trainer-View — a Flutter+Firebase project where I spent Phases 1 through 3 grinding through "what does a Claude Code session actually need to know on startup, and what's the cheapest way to put it there." The manager + helper split, the routing table, the section-routing read discipline, the three-commit cadence — all field-tested in a production project before they got generalised into the skeleton. claude-skeleton is the second version of "the thing I wished I'd had on day one of Trainer-View."

## How it works

A claude-skeleton install has four layers. Each is small enough to hold in your head.

**Runtime.** The manager owns the conversation. It reads `CLAUDE_MANAGER.md` on session start to know what kind of work it does and what discipline applies. When work would burn context — heavy multi-file reads, cross-file pattern scans — it dispatches a helper from `.claude/agents/`. Helpers do focused work and return; they don't own the conversation. For mechanical things where verbatim output matters (commits, deploys), the manager runs a script from `.claude/scripts/` rather than re-implementing the work each time. Skills are behavioural conventions the manager honours without a hook — they're rules, not enforcers. Four moving parts, each with a clear role.

**Approval gates.** The skeleton runs approval-gated autonomy. Reversible-and-cheap things — editing source files in a feature branch, running tests, writing to project docs — the manager proposes and executes. Destructive, shared-state, or high-blast-radius things — pushing to a shared branch, dropping data, sending external messages, modifying CI or auth — the manager proposes and waits. The line is drawn by blast radius, not prestige. A two-character commit message typo that's already been pushed is shared-state and warrants a check-in; a 200-line refactor in a feature branch is reversible-and-cheap and ships.

**Recursive ownership.** The skeleton has explicit responsibility levels. **L0** is the project work itself — code, content, features the team ships. **L1** is the helpers watching project work: `audit-helper`, `research-helper`, `monitoring-helper`, `plan-coordinator`. **L2** is the helpers watching the meta-system itself: `self-audit-helper`, `agent-slicer`, `system-memory-helper`, `workflow-suggester`. **L3** is reserved for v1.2+ — a `manager-optimizer` that will watch how the manager itself decides. The levels go outward from the work; each higher level watches the one below. Naming them makes them designable rather than emergent. Most orchestration projects have meta-management as a thing that shows up when someone files an issue; L0/L1/L2 says "the meta-management is a layer, here's where it is."

**Install / update mechanism.** `install.sh` (three modes: fresh / merge / replace) writes a JSON `.skeleton-version` marker that records a SHA-256 hash of every installed file. `update.sh` uses those hashes to classify each file against the current template — `TEMPLATE_UPDATED` (template moved, you didn't touch it), `LOCALLY_MODIFIED` (you changed it since install), `UNCHANGED`, `NEW`, `ORPHAN`. Updates are safe because the script can tell, file by file, what's a real template change versus your local edit. Pre-0.8.0 shell-format markers backfill to JSON on first run with a prominent warning. The persistence story is what makes "I'll come back in a month and update" a normal sentence instead of "I'll come back in a month and probably break something."

## How to use it

**Install.** From inside a target git repo:

```bash
curl -sL https://raw.githubusercontent.com/DevAyar/claude-skeleton/main/scripts/install.sh | bash -s -- --mode=merge
```

Or, with a local checkout: `bash <path-to-claude-skeleton>/scripts/install.sh --mode=merge`. The default merge mode adds missing files and never overwrites existing ones — safe by default. After the script finishes, dispatch `project-tuner-helper` to inspect the target project, fill in the placeholders (`{{PROJECT_NAME}}`, `{{TEST_COMMAND}}`, and so on), and recommend any project-specific helpers worth adding. The full reference lives in [`INSTALLATION.md`](INSTALLATION.md), including the update path, modes, dry-run, and the per-file-hash mechanism.

**A session.** Open Claude Code in the installed project. The manager reads `STATUS.md` (what was last touched), `ROUTING.md` (which task goes to which handler), and `CLAUDE_MANAGER.md` (how to think) at session start. From there it's normal work: you describe what you want, the manager decides — using the strategic judgment patterns in `CLAUDE_MANAGER.md` — whether to do it directly, dispatch a helper, or run a script. When you finish a slice, three-commit cadence: commit A is the work, commit B is docs and config, commit C is the VERSION + CHANGELOG bump, then push. Small work collapses to one commit; large work expands. The cadence isn't a rule the skeleton enforces; it's the rhythm the directive layer documents so future sessions inherit it.

## What's distinctive

Three things actually distinguish claude-skeleton from the rest of the ecosystem. (A fourth, the ADHD-driven design rationale, is up in *Why it exists*.)

**Composition with the ecosystem, not competition.** claude-skeleton is the orchestration layer. The Claude Code plugin ecosystem provides the components — official `/plugin` marketplace, `claude-code-templates`, `claude-agentic-framework`, `wshobson/agents`, `claude-skills`, `awesome-claude-code-subagents`, `ClaudeFast`. A target project running claude-skeleton can — and should — pull from any of those. The skeleton's job is to make the choices coherent, not to ship every helper itself. The verbatim design principle, locked at the directive layer: *"Don't be a directory; be a quality filter."* The point isn't to list every available plugin; it's to give the manager a discipline for picking the right ones for the project at hand and rejecting the wrong ones early.

**Recursive ownership as an explicit principle.** Most orchestration projects have meta-management as an emergent property — somebody notices a helper is misbehaving and files an issue, somebody else writes the audit. L0 / L1 / L2 names the levels up front: project work, helpers watching project work, helpers watching the meta-system. L3 is reserved for the `manager-optimizer` that v1.2+ will land, which will watch how the manager itself decides. Naming the levels makes them designable. It's not that the levels emerged and got documented after the fact; they were planned and the helpers were assigned to them. The difference matters because designable means you can add a level cleanly when v1.2+ ships, instead of refactoring an emergent mess.

**Per-file SHA-256 update mechanism, validated in production.** The `.skeleton-version` marker records a hash of every installed file at install time. `update.sh` compares three hashes — recorded, current-on-disk, current-template — to classify each file. The result is that "safe automated updates" actually mean something: you can run `update.sh` knowing it will apply template updates, refuse to touch your local modifications, and prompt only on the ambiguous cases. The mechanism has been validated across two real targets at different stack profiles: Trainer-View (Flutter + Firebase, mobile app shipping features) and Echoes-Of-Gill (Godot, a game in active development). Two stacks, two team sizes, two update cadences — the mechanism survives both.

## What it's not

A few things claude-skeleton is **not**, said plainly so expectations are right.

It's not a directory of every available plugin — the marketplace composition section names seven sources and trusts the manager to pick well. It's not a multi-LLM framework — Claude Code only through v2.0; if multi-model orchestration is pursued later, it's a sibling project, not a feature graft. It's not an autonomous AI agent that ships changes on its own; the line is approval-gated autonomy — *thinking is autonomous, action is approved*. And it's not a portfolio or marketing artefact: the audience is me and a few peers using it on real projects. If it ever became a thing pitched to teams, that's a different project under a different name.

## Where it's going

The full sequencing doc is [`ROADMAP.md`](ROADMAP.md). The three landmarks past v1.0:

**v1.1+ — capture / reuse loop.** A `session-observer` notices recurring patterns in real session work, `workflow-suggester` evolves from "suggests in prose" to "drafts a concrete proposed-helper or proposed-script file," `/goals` becomes the clarifying-questions layer for refining the spec, `script-builder` formalises an approved capture into a reusable script. Closes the four named autonomy gaps in one named loop.

**v1.2+ — `manager-optimizer`.** L3 meta-meta. Watches how the manager decides over time and suggests refinements to `CLAUDE_MANAGER.md.template`. Explicitly post-v1.1+ — it needs real usage data from the loop first, or it'd be optimising against vibes.

**v2.0 — plugin recommendation system.** A curated catalog matching pain points and project context to specific marketplace plugins or community libraries. Foundation is already in v1.0's marketplace composition section.

## Peer projects

claude-skeleton sits in a populated ecosystem. Same problem space, different implementation choices — these are the projects worth knowing about:

- **`claude-code-templates`** — stack-by-stack template projects. Useful as a starting point you then tune.
- **`claude-agentic-framework`** — higher-level multi-agent orchestration patterns. When project work crosses multiple agent loops.
- **`wshobson/agents`** — curated subagent collection. Strong baselines for code review, refactoring, and domain-specific tasks.
- **`claude-skills`** — behavioural-skill library. Same shape as our `.claude/skills/`; pull individual skills as needed.
- **`awesome-claude-code-subagents`** — community discovery surface.
- **`ClaudeFast`** — performance-oriented agent patterns. Tight loops, minimal token use.
- **`storybloq`** — adjacent in problem space; worth citing for completeness.

These are the ecosystem claude-skeleton composes with, not competitors to displace. Different projects make different bets — `claude-code-templates` bets on per-stack scaffolding, `claude-agentic-framework` bets on multi-agent orchestration, claude-skeleton bets on a directive layer + recursive ownership + safe automated updates. The right choice depends on what you're building, and a real project may end up using two or three of these together. That's the design.
