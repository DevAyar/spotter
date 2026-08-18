# goal-spec schema

The contract for one spec file under `.claude/specs/<id>.md`, produced by the
`/goals` pipeline (Phase 68) and consumed by X-builders or dispatched phases.
Light by design: the schema serves consumption, not ceremony.

## File format

UTF-8 markdown with YAML frontmatter delimited by `---` lines. Filename is
`<id>.md`.

## Frontmatter — 5 fields (4 required + 1 optional)

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string (short-kebab-case slug) | yes | Derived from the goal; doubles as the filename. Stable once created. |
| `status` | string enum | yes | `draft` (pipeline output, awaiting review) \| `approved` (user-edited; consumable and schedulable) \| `consumed` (an X-builder or phase executed it) \| `abandoned` (do-not-resurface; file persists as the record). |
| `created` | string (ISO-8601 UTC) | yes | Set once by the pipeline. |
| `schedule` | string, optional | no | When an APPROVED spec should surface at session start. `YYYY-MM-DD` → due when today ≥ date. `daily` → always due (the surfacer's 24h cooldown gates noise). `weekly` → due on Mondays. `monthly` → due on the 1st. Stateless — no per-spec bookkeeping. Ignored on any status other than `approved`. |
| `goal` | string (one line) | yes | The goal statement, verbatim or lightly normalized. |

## Body — 5 sections

- `## Research findings` — what the repo-local research established, each
  finding traceable to a file actually read.
- `## Locked decisions` — clarify-round answers (attributed to the user) plus
  decisions the research settled beyond dispute.
- `## Deliverable shape` — what "done" produces: files, behaviors, commit
  shape. Concrete enough to build from; non-prescriptive where the builder
  retains judgment.
- `## Constraints` — what must NOT change; inherited design properties;
  scope fences.
- `## Open questions` — non-blocking judgment calls deferred to build time.
  A draft with blocking unknowns here isn't ready to approve — that's the
  reviewer's signal.
- `## Consumption record` (appended at consumption, not authored) — the
  landing commits for each leg. The corpus grew this section before the
  schema named it; registered Phase 127 on the Phase 123 corpus-is-the-law
  precedent.

## Lifecycle (the approval gate is load-bearing)

`draft` → (user review, hand-edit) → `approved` → (X-builder / dispatched
phase executes) → `consumed`. `abandoned` at any point stops resurfacing
forever; delete the file only to genuinely re-open the slug. Nothing ever
consumes a `draft`, and nothing builds automatically from any status —
consumption is always a user-directed dispatch.
