# Specs — the /goals pipeline output surface

One file per goal, produced by `/goals` (research → one clarify round →
spec), following [`goal-spec.schema.md`](goal-spec.schema.md). Specs are
tracked artifacts (the captures precedent): the record of what was decided
and what a builder may consume.

## Lifecycle

- **`draft`** — pipeline output awaiting your review. NOTHING consumes a
  draft; the scheduled-goals surfacer ignores it too.
- **`approved`** — you hand-edit the frontmatter to this. X-builders and
  dispatched phases may now consume it; if it carries a `schedule`, the
  SessionStart surfacer prints one ambient line when it's due.
- **`consumed`** — set when the spec's work has been executed. Stays on disk
  as the record.
- **`abandoned`** — the do-not-resurface state. File persists as the marker;
  delete it only to genuinely re-open the goal.

## Operator notes

- Review a draft by reading it: the "Open questions" section is the signal —
  blocking unknowns there mean it isn't ready to approve.
- Approve by editing `status: draft` → `status: approved`. Add or adjust
  `schedule` at the same time if the goal is time-anchored.
- Nothing builds automatically from any status. Consumption is always a
  user-directed dispatch — the approval gate is the load-bearing line.
