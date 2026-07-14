---
description: Turn a goal into a build-ready spec — repo-grounded research, ONE batched clarify round, structured spec doc at .claude/specs/<slug>.md (Phase 68). Draft-only; nothing builds from a spec without approval.
argument-hint: "<goal statement>"
---

Run the goal pipeline on the user's goal statement. Three stages, in order.
The output is a SPEC, never a build — the approval gate (user flips the spec
`draft → approved`) is the load-bearing line, and this command never crosses
it.

## Stage 1 — RESEARCH (repo-local, strictly read-only; Tier 1)

Ground the goal in this repository before asking the user anything:

- Read the relevant code, docs, `ROUTING.md`, and `CLAUDE_MANAGER.md`
  sections the goal touches.
- Check `.claude/observations/`, `.claude/telemetry/`, and existing
  `.claude/specs/` for prior signal on the same ground (an existing spec on
  the same goal means UPDATE it, not duplicate it).
- NO web access, NO mutations, NO dispatches that write. Reading to build
  the spec is thinking; everything else waits for an approved spec.

Summarize what research established as short findings — these become the
spec's "Research findings" section, each traceable to a file you actually
read.

## Stage 2 — CLARIFY (exactly ONE batched round, only the gaps)

- Ask ONLY what research could not answer. If research answered everything
  blocking, SKIP this stage — zero questions is the correct output, and
  non-blocking judgment calls go to the spec's "Open questions" section
  instead.
- One batched, numbered round. Each question offers numbered options where
  possible so the user can answer tersely ("1, 1, 2"). No avalanche; no
  second round unless the user invites one.
- Answers become "Locked decisions" in the spec, attributed to the user.

## Stage 3 — SPEC (write the doc, stop)

Write `.claude/specs/<slug>.md` following `.claude/specs/goal-spec.schema.md`
(frontmatter: `id`, `status: draft`, `created`, optional `schedule`, `goal`;
body: Research findings / Locked decisions / Deliverable shape / Constraints /
Open questions). Slug: short-kebab-case from the goal.

Then STOP and tell the user where the spec landed. Do not begin building.
The lifecycle from here is the user's: `draft → approved` by hand-editing the
frontmatter; X-builders (or a dispatched phase) consume `approved` specs and
flip them to `consumed`; `abandoned` is the do-not-resurface state. A
`schedule` value makes an APPROVED spec surface at session start when due
(see `.claude/scripts/goals-surface.sh`).
