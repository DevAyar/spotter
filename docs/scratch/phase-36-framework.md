---
status: working-draft
created: 2026-05-18
graduation-target: canonical location TBD when Phase 36 ships
related: docs/ROADMAP.md § Multi-project graduation (this framework is the inverse — retire is to template-removal as graduation is to template-promotion)
---

# Component retire / repurpose framework — Phase 36 working draft

## What this framework is

A decision rubric for evaluating whether a skeleton component (agent, skill, script, command, hook) stays, retires, repurposes, or gets replaced. Phase 36's named case is `plan-coordinator`, but the framework outlasts that single decision — every future audit-emergent finding of the shape "is this component still pulling its weight?" feeds through the same rubric.

The framework exists because retire decisions get expensive to relitigate. Without a written rubric, every component-on-the-evaluation-list pulls the same conversation from first principles. The rubric is the institutional memory.

The framework is the inverse of multi-project graduation criteria (ROADMAP § Multi-project graduation): graduation moves patterns *into* the shared template; retire moves components *out*. Both gate on empirical signal, not taste.

## When the rubric runs

Three triggers, all event-driven, none calendar-scheduled:

1. **CC-side or strategist-side audit surfaces a candidate.** Phase 30's audit was the canonical case — Section 5's component-list review put `plan-coordinator` on the table. Future audits will surface more.
2. **Ecosystem composition reveals overlap.** When a plugin install (or marketplace browse) shows the ecosystem now ships what a skeleton component does, the skeleton component becomes a candidate. Phase 34's bundle install made `feature-dev` ↔ `/spec` overlap legible — that's the shape.
3. **Observation history flags a component.** If `code-quality-auditor` or `cruft-checker` accumulates negative observations against a specific component over time (currently anecdotal; empirical with v1.2.0's per-project manager-optimizer), the component enters review.

## Evaluation criteria

Four signal axes, weighted by what data is available at evaluation time.

**Dispatch frequency.** How often does the component actually run? In v1.1.x this is anecdotal — the manager's memory of when it last reached for the component. In v1.2.0 the manager-optimizer makes this empirical. Low dispatch + no recent strategic reason to expect future dispatch = retire candidate.

**Ecosystem overlap.** Does a marketplace plugin or community library do what this component does, better or equivalently? If yes, default to compose-don't-compete — retire the skeleton component, document the replacement in `CLAUDE_MANAGER.md`'s ecosystem composition section. If the skeleton component does something *additional* the ecosystem version doesn't, that's a repurpose case, not a retire case.

**Structural role.** Does the component fill a load-bearing position (hook surface, audit producer, schema validator, mirror invariant enforcer)? Load-bearing components retire only with a replacement plan. Decorative components can retire cleanly.

**Per-project divergence.** Does the component get tuned per-project (in target projects' local `.claude/`) or used template-default? Heavily-tuned components signal real value — projects diverge because the component matters. Untouched components signal the opposite.

## Decision outcomes

Four shapes. The framework picks based on the signal mix.

**Keep.** No action. Document the ratification in the audit-emergent queue (CHANGELOG bullet plus a one-line entry in the relevant section). This is what happened to `commit.sh` and `audit-helper` after the Phase 30 CC audit.

**Retire.** Remove from template/ + dogfood. Add to ROADMAP § Cuts with one-paragraph rationale. CHANGELOG entry. Installed projects keep their local copy until the next `update.sh` run flags the file as `ORPHAN` (file exists locally but not in template) — `update.sh` already handles this classification and prompts before any destructive change.

**Repurpose.** Change the component's scope or responsibility while keeping its name and place. Rare — usually the better move is retire + rebuild under a new name to avoid documentation drift. If repurpose happens, it ships with explicit framing in CLAUDE_MANAGER.md and a CHANGELOG breaking-change-style entry.

**Replace.** Swap the skeleton component for an ecosystem plugin or different component. Documents the composition decision in CLAUDE_MANAGER.md's ecosystem section. Hybrid case: the skeleton component might stay temporarily as a fallback while the ecosystem replacement settles — but that's a transitional state, not a permanent shape.

## Documentation discipline

Whatever the decision, three docs touch:

- **ROADMAP.md** — Cuts section gets the rationale (retire/repurpose/replace cases); keepers get a one-line ratification under the relevant phase section.
- **CHANGELOG.md** — Removed / Changed / Added bullet per Keep-a-Changelog convention.
- **CLAUDE_MANAGER.md** — if the decision changes how the manager dispatches, the change lands in `## Strategic judgment patterns` or `## Core vs integration boundary` (or `## Strategic audit cycle` for retire decisions arising from audits).

The mirror invariant applies for any CLAUDE_MANAGER edits.

## Pre-evaluation: plan-coordinator

Applying the framework to Phase 36's canonical case, with current available data:

- **Dispatch frequency:** anecdotal. Strategist-chat recollection — rarely dispatched in the last several sessions. Empirical confirmation needs v1.2.0 manager-optimizer data, but the strategist signal is "low."
- **Ecosystem overlap:** real. `superpowers` brainstorming for in-depth questioning + `/feature-dev` for spec elicitation cover most of what `plan-coordinator` was scoped to do. The bundle install (Phase 34) made this overlap visible.
- **Structural role:** none load-bearing. `plan-coordinator` is dispatch convenience, not architecture.
- **Per-project divergence:** unknown — TV and EoG installs haven't surfaced project-specific `plan-coordinator` customization.

**Preliminary read:** retire-candidate. The Phase 36 decision wants direct empirical data from Phase 35 evaluation (TV update + EoG production miles + ideally pinball) before final call, but the framework signals point toward retire-replace-with-ecosystem.

**Open question for Phase 36 execution:** does retire happen as a clean removal (delete `plan-coordinator.md`, ROADMAP cut entry, update `update.sh` to handle the ORPHAN classification on next target-project refresh), or as a deprecation phase first (keep the file with a deprecation header for one release cycle, retire in the cycle after)? Default-recommend clean removal — deprecation cycles are valuable when there's user-visible API breakage, and dispatch happens through manager judgment, not direct user invocation. No user-visible breakage to soften.
