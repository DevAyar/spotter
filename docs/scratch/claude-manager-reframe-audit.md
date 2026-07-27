---
status: working-draft
created: 2026-05-18
related: docs/STORY.md governance framing, docs/ROADMAP.md § Locked architectural principles, latest reframe commit a78e7be (governance reframe pair: 16f879f + a78e7be)
---

# CLAUDE_MANAGER reframe audit — Phase 40 working draft

Read-only audit of `CLAUDE_MANAGER.md` (368 lines after Phase 37 + Phase 35a additions) against the Phase 35b governance reframe. Findings target the directive layer's alignment with the new framing: claude-skeleton as a structural immune system / governance layer, per-project governance as core architecture, productivity-tool framing explicitly cut. Mirror invariant means dogfood findings apply to `template/CLAUDE_MANAGER.md.template` automatically — no separate template audit needed.

Direction-only output. No edits this phase. Concrete amendment phase ships separately if warranted after chat-side triage.

## Methodology

Audited each `CLAUDE_MANAGER.md` section against five criteria:

- **(a) Productivity-tool framing residue** — language reading as "speed up coding work" rather than governance / immune system / scope discipline.
- **(b) One-size-fits-all assumptions** — language assuming the same config fits every install, vs per-project governance.
- **(c) Plain-English-rule violations** — user-facing prose with un-translated jargon. Scoped to user-facing prose only per the codified rule's carve-out at L68 ("internal reasoning stays terse").
- **(d) Missing per-project tuning references** — dispatch / decisions / discipline language that should reference per-project context but doesn't.
- **(e) Conflicts with locked principles** — language contradicting any of the 16 locked architectural principles in `docs/ROADMAP.md`.

Pareto-focused: top 5 highest-impact findings + 1 review-needed item.

**Sections skipped (already verified aligned with reframe):**

- L62–68 `### User-facing communication: plain English by default` (Phase 35a — codified this rule).
- L157–189 `## Strategic audit cycle` + 3 H3s (Phase 37 — drafted post-reframe).

## Findings — top 5 highest-priority sections

### Opening (L1–7) — `# Manager session — claude-skeleton`

**Flags:** [a]

**Direction:** The opening introduces the manager mechanically ("owns the conversation, decides when to act directly...") without anchoring it in the governance system. Per STORY's mission framing, the manager is the **executive branch** of a three-piece governance shape (constitutional framework + executive branch + watchdogs). Add a one-sentence frame at the top tying the manager to that role — readers should see "this is the executive branch of the project's governance system" before they see "this is who owns the conversation."

### `## What this manager is` (L12–14)

**Flags:** [a]

**Direction:** "An ever-evolving being, not a fixed install" reads as adaptive-tool framing — manager adds helpers when recurring work appears, removes them when they stop earning keep, tunes contracts when the manager learns what works. Reframe to anchor in scope-discipline: the manager evolves because the project's scope evolves and the manager has to keep the discipline current to that scope. Keep the "ever-evolving" language; replace the skill-accretion framing with a governance-evolution framing.

### `## Manager pattern` (L29–34)

**Flags:** [b], [d]

**Direction:** The pattern is described as universal — reads STATUS / ROUTING, decides tier, dispatches helper, runs script. No mention that the specific judgment patterns vary per-project. Per `### Per-project governance` locked principle, each install tunes its own audit cadence, approval thresholds, dispatch rules. Add one sentence noting the pattern's shape is universal but the content tunes per-project: `project-tuner-helper` shapes it at install; v1.2.0's per-project manager-optimizer refines it from observed decisions over time.

### `### How a plugin gets installed` (L329–331)

**Flags:** [e]

**Direction:** L329 claims "Every plugin install path — official marketplace or community library — goes through `integration-checker` first. No exceptions." But L82–84 declares `integration-checker` DEFERRED to v2.0 — the agent doesn't exist. The v1.1.4 reality is `code-quality-auditor` performs narrow-scope plugin verification at SessionStart (three heuristics: manifest path, hooks.json schema, destructive-pattern detection). Update this H3 to describe the actual gate (code-quality-auditor at SessionStart with cooldown; eyes-open install pattern for trust-tier-2 cases per Phase 34b) and reference `integration-checker` as the planned v2.0 expansion rather than a current gate. Internal contradiction between L82–84 (deferred) and L329–331 (in effect) is the strongest principle-conflict in the file. <!-- cruft-check:exempt-historical -->

### `## Template-content vs template-stubs map` (L352–362)

**Flags:** [b], [e]

**Direction:** L362 says "Resist the urge to edit the manager pattern, strategic-judgment patterns, dispatch mechanics, tier system, three-commit cadence, plugin marketplace section, or plugin discipline rules during install. They're stable surface area; if a target project needs different rules, that's a real change that belongs in a PR against claude-skeleton, not a per-project override." This DIRECTLY contradicts the per-project governance principle (each install evolves its own discipline; template is a seed, not a final form; per-project divergence is the default). Reframe to distinguish two layers: **locked architectural principles** carry over universally (approval-gated autonomy, three-commit cadence, multi-project graduation criteria, scope-actively-governed) — those don't flex per-project. **Tuning surface** — audit cadence, dispatch heuristics, approval thresholds, dispatch-cluster H3s — flexes per-project by design. The "stable surface area" framing currently treats everything as locked; the new framing locks only the locked principles and explicitly invites per-project tuning everywhere else. Cross-reference the Per-project governance + Multi-project graduation principles in ROADMAP for the graduation path from local-tune to template-promote.

## Review-needed items

### `### Dispatch a helper vs read files directly` (L36–44)

**Flags:** [a] (marginal)

**Ambiguity:** The heuristic frames helper-dispatch around token economy — "burn >5k tokens of context," "94% token savings on Phase 4b → 4b.6," "helpers return a structured summary; the manager keeps the summary, not the raw scan." The substance of the rule is sound — context-budget protection prevents the manager from losing working memory mid-task, which is governance-adjacent. But the framing ("token savings") reads as efficiency-as-virtue, which the reframe explicitly cuts ("Speed is a byproduct of not having to clean up messes; it is not the deliverable"). Direction-optional: re-frame the token-savings language as "preserve the manager's judgment-capacity for work that needs judgment" rather than "save tokens." Or leave as-is — the rule is empirically grounded and the framing is borderline. Defer to chat-side triage.

## Additional context — coverage gaps surfaced but not flagged

Two of STORY's 8 core principles have no explicit `CLAUDE_MANAGER.md` anchor; one has the strongest violation:

- **Per-project governance** — zero direct strategic-judgment-pattern coverage in CLAUDE_MANAGER, plus the direct contradiction at L352–362 (already flagged above). Adding a `### Per-project governance` H3 under Strategic judgment patterns would close the gap.
- **Flow + safety, both** — covered implicitly through dispatch heuristics + audit-cadence framing + bash-safety, but never framed explicitly as a principle anchor. Optional addition.
- **Guard rails, configurable but transparent** — the "You're now outside Claude Code's jurisdiction" language from STORY/ROADMAP doesn't appear in CLAUDE_MANAGER. When the manager dispatches a hook-disable or audit-skip pathway, the explicit-language requirement isn't codified.

These are coverage gaps rather than reframe-violations. Chat-side triage decides whether to surface them as new H3s in a separate amendment phase.

## Out of audit scope

Per brief: implementation-detail issues (specific agent names, file paths, count mismatches) were not flagged. The audit caught one implementation-detail oddity adjacent to a flag (L270–276 tier system enumerates "two hooks (SessionStart/PreCompact)" but current state ships five hook entries) — surfaced here only to record that the audit saw it; reframe-amendment phase doesn't need to address it.
