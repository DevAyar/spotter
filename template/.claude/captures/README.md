# captures/

Draft captures written by `workflow-suggester` (v1.1+) and consumed by future X-builders (v1.1+: `script-builder` first, then skill / agent / command / hook builders). The capture/reuse loop's review surface — where recurring patterns become reviewable proposals before they become actual artifacts.

## What lives here

One markdown file per capture: `<source_pattern_id>.md`. The filename matches the `pattern_id` of the observation that triggered the draft (so capture files and observation files share an id, and idempotency is direct).

The directory ships empty and populates post-install when `workflow-suggester` is dispatched against accumulated observations.

## Schema

See [`../agents/05_meta/workflow-suggester.schema.md`](../agents/05_meta/workflow-suggester.schema.md) for the full capture markdown contract — YAML frontmatter (7 required fields), 4-section body convention, and a complete realistic example.

## Status field

Each capture's `status` frontmatter field controls its lifecycle:

- **`draft`** — set by `workflow-suggester` on creation. Awaiting human review. X-builders ignore.
- **`approved`** — user manually edits the frontmatter to this. X-builders pick the capture up to generate the actual artifact.
- **`rejected`** — user manually edits to this. workflow-suggester respects as "do not re-suggest." The file persists as a do-not-re-suggest marker; don't delete it.
- **`shipped`** — terminal success state (see `workflow-suggester.schema.md`): the artifact the capture proposed has landed. Set alongside a `shipped_to:` field naming the artifact path when the promotion happens.

All four values count as "already considered" for `workflow-suggester`'s idempotency check. Re-running the agent against the same observations + the same captures produces zero new files.

## Operator notes

- **Review captures by reading the file.** The body has 4 sections (Pattern, Evidence, Suggested response, Approving / rejecting). 30 seconds per capture is typical.
- **Approve by editing.** Open the file, change `status: draft` to `status: approved` in the frontmatter, save. The next time the appropriate X-builder runs, it picks this up.
- **Reject by editing.** Same shape: change `status: draft` to `status: rejected`. The file stays on disk forever as a "no thanks, don't re-suggest" marker. workflow-suggester silently skips it.
- **Re-opening a rejected pattern.** Delete the capture file; the next workflow-suggester run will see no existing capture for that pattern_id and draft a fresh one.
- **Safe to inspect.** Files are plain markdown; the schema's redaction rules ensure no secrets or sensitive paths end up in the Evidence section.
- **Don't hand-edit fields other than `status`.** workflow-suggester treats the file as immutable once drafted; the user's contract is just the `status` field. Other edits get clobbered if the capture's source pattern recurs and the agent ever decides to refresh (it doesn't in v1.1.0, but the field semantics keep that option open).

## Producers (v1.1+)

- **`workflow-suggester`** — drafts captures from observations under default thresholds (`occurrences >= 3 AND confidence >= medium`). v1.1+ Phase 2.

## Consumers (v1.1+, in sequence)

- **`script-builder`** (Phase 3, shipped) — reads captures with `status: approved` AND `suggested_artifact_type: script`. Drafts a shell script at `.claude/scripts/drafts/<source_pattern_id>.sh.draft` following the 5-section discipline; the user reviews, renames it into `.claude/scripts/`, and optionally flips the capture to `shipped` with `shipped_to:`.
- Future `skill-builder` / `agent-builder` / `command-builder` — same shape, different `suggested_artifact_type` values.
