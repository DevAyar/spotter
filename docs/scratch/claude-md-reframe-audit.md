---
status: open
date: 2026-05-18
scope: CLAUDE.md (dogfood, 35 lines) + template/CLAUDE.md.template (35 lines)
methodology: 5-criterion reframe audit (productivity-tool framing residue / one-size-fits-all assumptions / plain-English violations / per-project tuning context / locked-principle conflicts)
follow-up: amendments phase TBD if findings warrant — Phase 41 precedent (3 atomic commits closing Phase 40 findings)
related: docs/STORY.md § Mission + § Core principles, docs/ROADMAP.md § Locked architectural principles, Phase 40 precedent at docs/scratch/claude-manager-reframe-audit.md
---

# CLAUDE.md reframe audit — Phase 42 working draft

Read-only audit of `CLAUDE.md` (35 lines, dogfood) against the Phase 35b governance reframe — claude-skeleton as a structural immune system / governance layer, with per-project governance as the centerpiece. CLAUDE.md is the per-install constitution doc; target projects pull it via `update.sh`. Mirror invariant holds (see § Mirror parity result below), so dogfood findings apply to `template/CLAUDE.md.template` automatically.

Direction-only output. No edits in this phase. Concrete amendment phase ships separately if findings warrant — Phase 41 precedent.

## Methodology

Audited each `CLAUDE.md` section against five criteria:

- **(a) Productivity-tool framing residue** — language reading as "speed up coding work" rather than governance / structural immune system / scope discipline.
- **(b) One-size-fits-all assumptions** — language assuming the same config fits every install, vs per-project governance. Note: the placeholder mechanism (six template slots resolved per-install by `project-tuner-helper`) is the per-project tuning surface by design — not a (b) flag.
- **(c) Plain-English-rule violations** — user-facing prose with un-translated jargon. Scoped per the codified rule's carve-out at `CLAUDE_MANAGER.md` L68 ("internal reasoning stays terse").
- **(d) Missing per-project tuning context** — applied in two sub-views:
  - **(d-i) Placeholder slots** (L1, L3, L5, L9, L15, L21) — these expose per-project tuning surface by design. Their existence is positive signal, not a gap. Treated as design-aligned with the per-project governance principle.
  - **(d-ii) Locked-content sections** (L11, L17–19, L23–34, byte-identical across dogfood + template) — apply (d) here as written: does locked content reference (or fail to reference) per-project tuning context where it would clarify the reader's mental model?
- **(e) Conflicts with locked principles** — language contradicting any of the 8 core principles in STORY or the locked architectural principles in ROADMAP.

Pareto-focused: 1 high-impact finding + 2 review-needed items + 2 coverage gaps. Lighter than Phase 40 (5 findings + 3 gaps + 1 review-needed) — CLAUDE.md is 35 lines vs CLAUDE_MANAGER.md's 368, and is structurally less behaviorally load-bearing.

## Mirror parity result

`CLAUDE.md` and `template/CLAUDE.md.template` diverge ONLY at the six placeholder lines:

| Line | Dogfood | Template |
|---|---|---|
| L1 | `# claude-skeleton` | `# {{PROJECT_NAME}}` |
| L3 | `Orchestration layer on the Claude Code ecosystem.` | `{{PROJECT_TAGLINE}}` |
| L5 | `You are working with Project owner + peers — digestible, not portfolio/mass-market. Drop marketing register. Useful first, philosophy second.` | `You are working with {{WHO_YOU_ARE_WORKING_WITH}}.` |
| L9 | `Plain English with translation. Push back when wrong, don't sycophant. Prose default; bullets earn their place. ADHD scaffolding: short feedback loops, approval gates.` | `{{COMMUNICATION_STYLE}}` |
| L15 | `Bash 5-section discipline (shebang+strict-mode / constants / helpers / main / cleanup), strict mode (\`set -uo pipefail\` minimum, \`set -e\` when halting on first error), path-shape guards before mutation, \`bash-safety\` skill integration for any recursive scan. Markdown-first for docs.` | `{{CODE_STYLE}}` |
| L21 | `N/A — skeleton has no rendered UI.` | `{{DESIGN_SYSTEM_RULES}}` |

Locked-content lines (L2, L4, L6–8, L10–14, L16–20, L22–34) are byte-identical between dogfood and template. **Parity is clean modulo placeholders.** Mirror invariant intact — findings on dogfood apply to template by parity, no separate template audit needed.

### Mirror tuning surface (positive signal)

The six placeholder slots expose per-project tuning surface by design. `project-tuner-helper` resolves them at install time so each project's CLAUDE.md reflects that project's specific identity, audience, communication discipline, and code style. This is the per-project governance principle realised at the constitution-doc layer — design-aligned, not a gap.

Additional positive signal: the install-time-removal HTML comment at L19 (`<!-- Remove this section at install time if the project has no design system or UI concerns. project-tuner-helper handles the removal. -->`) explicitly references `project-tuner-helper` and structural variation per project. This is locked content (byte-identical in both files) that surfaces the per-project tuning mechanism inside the constitution doc itself.

## Findings — highest-priority sections

### Opening (L1–5) — dogfood prose at the placeholder slots, with `# claude-skeleton` + `Orchestration layer on the Claude Code ecosystem.` tagline

**Flags:** [e]

**Direction:** The dogfood tagline at L3 anchors the project as "an orchestration layer" — STORY's locked framing reframes claude-skeleton as "a structural immune system / governance layer for Claude Code projects." The current tagline carries the older v1.1.x framing, predating the Phase 35b reframe. Direction: re-anchor the dogfood L3 tagline to surface the structural-immune-system / governance framing. (Template L3 stays as `{{PROJECT_TAGLINE}}` — each target project fills its own; the constitution-doc *role* doesn't carry over verbatim, but the framing of what claude-skeleton-as-base-system *is* should be aligned in the dogfood install.) Note: Phase 41 made the analogous reframe-alignment moves at CLAUDE_MANAGER.md opening (L3 executive-branch framing); CLAUDE.md opening hasn't received the equivalent treatment yet.

## Review-needed items

### `L5 working-with prose` — `"Useful first, philosophy second"` (dogfood-only — placeholder slot)

**Flags:** [a] (marginal)

**Ambiguity:** "Useful first, philosophy second" reads as utility-prioritized framing. STORY explicitly cuts productivity-tool framing ("Discipline is the point. Speed is a byproduct of not having to clean up messes later. It is not the deliverable."). The current dogfood phrasing risks reading as "discipline / principles are secondary to utility" — opposite of the reframe. But the surrounding context ("Drop marketing register") suggests the intended meaning is "drop philosophy-as-marketing, lead with the useful framing of the work" — which aligns with the reframe rather than opposing it. The phrase is borderline. Direction-optional: rephrase to surface that discipline-and-utility are aligned, not opposed (e.g. "utility through discipline, not marketing voice"); or leave as-is and trust the surrounding sentence. Defer to chat-side triage.

### `L25 Manager + helper architecture` paragraph — `"L0 / L1 / L2 framing"` jargon (locked content)

**Flags:** [c] (marginal)

**Ambiguity:** The paragraph references "the recursive ownership **L0 / L1 / L2** framing" without translating the L0/L1/L2 levels inline. Per the codified plain-English rule, user-facing prose translates jargon on first use. Counter-argument: the paragraph's purpose is to point readers at CLAUDE_MANAGER.md, where the L0/L1/L2 framing is explained in full; the term is name-of-thing-to-look-up rather than concept-to-grok-here. A reader who follows the pointer gets the translation. Borderline — defer to chat-side triage. If amended, the translation needs to be short (one phrase): something like "recursive ownership across the skeleton (L0), per-project installs (L1), and per-project subtask scopes (L2)" — currently no canonical phrasing in CLAUDE_MANAGER.md to copy from, so this would require coordination between CLAUDE.md and CLAUDE_MANAGER.md if pursued.

## Coverage gaps surfaced

CLAUDE.md is the per-install constitution doc, but doesn't say so in the file itself. Two reframe anchors from STORY have no presence in CLAUDE.md:

- **Constitutional-framework / executive-branch / watchdogs three-piece governance shape.** STORY § Mission frames claude-skeleton as three pieces: "a constitutional framework (the locked principles each project commits to), an executive branch (the manager that runs decisions during work), and watchdogs (the auditors firing on a cadence)." CLAUDE.md IS the constitutional framework per install, but doesn't anchor itself to that role. CLAUDE_MANAGER.md L23 now (post-Phase-41c) opens with the executive-branch frame. A symmetric move at CLAUDE.md L23 or earlier would close the gap — one sentence near the top tying CLAUDE.md's role to the constitutional-framework piece of the three-piece shape. Closing the gap is small and high-leverage: the reader sees "this is the constitution" before reading the body.

- **"Scope is actively governed, not passively hoped for" anchor.** STORY's center-of-mass principle. CLAUDE.md's existence + structure implies it (the file declares the project's scope via its sections), but the phrase doesn't appear. Direction-optional: a one-line anchor in the opening would surface the principle to the reader explicitly. Marginal — the implicit signal may suffice. Defer to chat-side triage.

These are coverage gaps rather than reframe-violations. Chat-side triage decides whether they surface as new content in a separate amendment phase.

## Out of audit scope

Per brief, the following were NOT covered:

- **Implementation-detail issues.** No flagging of file paths, agent counts, version refs, or surface-mismatch oddities. Phase 40 precedent: surfaced one such item as a record-only note, not a finding.
- **The template mirror as a separate audit subject.** Mirror invariant (parity clean modulo placeholders) means dogfood findings apply to template by parity; no separate audit needed. Verified in § Mirror parity result.
- **Amendments to CLAUDE.md or template/CLAUDE.md.template.** Audit-only phase. Concrete amendment phase ships separately if findings warrant.
- **Promotion of this scratch doc to canonical location.** Deferred — Phase 40 doc still in `docs/scratch/`; retention/promotion decision deferred to a future phase.
- **Other directive / framing docs.** STATUS.md, ARCHITECTURE.md, ROUTING.md, README.md — different docs, different audit phases.
