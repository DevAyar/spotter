# observations/

Structured pattern observations written by `task-watchdog`, `cruft-checker`, `code-quality-auditor`, and the Phase 46 session-end telemetry. (The original producer, `session-observer`, retired Phase 58.) The capture/reuse loop's memory surface — the schema is the contract producers emit against and consumers read from.

## What lives here

One file per pattern: `<pattern_id>.json`, where `pattern_id` is a SHA-256 hash of `pattern_type + normalized_signature`. Re-observation of the same pattern updates the existing file (bumps `occurrences`, `last_seen`, appends to `evidence`) rather than creating a new one.

The directory ships empty and populates post-install. Don't pre-seed it.

## Schema

See [`../agents/05_meta/session-observer.schema.md`](../agents/05_meta/session-observer.schema.md) for the full wire format — 10 required fields, an evidence array, redaction rules, and a JSON example.

## Producers (v1.1+)

- **`task-watchdog`** — reads the prior session's transcript at session start; canonical producer of `recurring_failure` observations, plus `other`-typed long-running-bash observations.
- **`cruft-checker`** (dogfood-only) — skeleton-doc cruft (broken links, stale counts, phase refs), with a full resolve pass per scan.
- **`code-quality-auditor`** — installed-plugin manifest + security hygiene (`plugin_quality` observations).
- **Session-end telemetry** (Phase 46) — one `token_telemetry` observation per session. Same `pattern_id` ↔ same file convention across all producers.

## Consumers (v1.1+)

- **`workflow-suggester`** (v1.1+) — reads observations and drafts proposed captures (helpers, scripts, slash commands). Never modifies or deletes observation files; resolution is the producers' job via `resolved_at`.

## Operator notes

- **Safe to delete.** Deleting an observation file resets the pattern memory for that one signature. Next observation will create a fresh file with `first_seen` at the current moment.
- **Safe to inspect.** Files are JSON, human-readable. The schema redaction rules ensure no secrets or sensitive paths end up here, but verify on the rare paranoid pass.
- **Don't hand-edit.** Producers re-write these on re-observation; manual edits get clobbered. If you want to "teach" the system a pattern, use `manual` as the `source` value in a fresh file the producers will respect on next read.
