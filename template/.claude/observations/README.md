# observations/

Structured pattern observations written by `session-observer` (v1.1+) and `task-watchdog` (v1.1+ Phase 4). The capture/reuse loop's memory surface — the schema is the contract producers emit against and consumers read from.

## What lives here

One file per pattern: `<pattern_id>.json`, where `pattern_id` is a SHA-256 hash of `pattern_type + normalized_signature`. Re-observation of the same pattern updates the existing file (bumps `occurrences`, `last_seen`, appends to `evidence`) rather than creating a new one.

The directory ships empty and populates post-install. Don't pre-seed it.

## Schema

See [`../agents/05_meta/session-observer.schema.md`](../agents/05_meta/session-observer.schema.md) for the full wire format — 8 required fields, an evidence array, redaction rules, and a JSON example.

## Producers (v1.1+)

- **`session-observer`** — scans recent `docs/SESSION_LOG.md` activity and emits observations for `repeated_command`, `repeated_edit`, `error_resolution`, `recurring_failure`, and `other` patterns. Triggered at session start when the SessionEnd hook left a `.session-ended` marker here.
- **`task-watchdog`** (Phase 4, not yet built) — emits `recurring_failure` observations against the same schema. Same `pattern_id` ↔ same file across both producers.

## Consumers (v1.1+)

- **`workflow-suggester`** (Phase 2 extension, not yet built) — reads observations and drafts proposed captures (helpers, scripts, slash commands). Doesn't modify observation files; deletes them only after the user accepts a capture.

## Operator notes

- **Safe to delete.** Deleting an observation file resets the pattern memory for that one signature. Next observation will create a fresh file with `first_seen` at the current moment.
- **Safe to inspect.** Files are JSON, human-readable. The schema redaction rules ensure no secrets or sensitive paths end up here, but verify on the rare paranoid pass.
- **Don't hand-edit.** Producers re-write these on re-observation; manual edits get clobbered. If you want to "teach" the system a pattern, use `manual` as the `source` value in a fresh file the producers will respect on next read.
- **The `.session-ended` marker file is not a regular observation** — it's an empty signal file written by the SessionEnd hook and consumed (deleted) by `session-observer` at next session start. Ignore it in any listing of "actual observations."
