# session-observer observation schema

> **Naming note (Phase 58):** this file is the shared observation-layer contract; it keeps the name of its first producer, `session-observer`, which was retired in Phase 58 (unpopulated surface — see CHANGELOG). The schema, its fields, and all other producers are unaffected.

The wire format for one observation entry under `.claude/observations/<pattern_id>.json`.

This schema is the contract shared by:
- **Producers**: `task-watchdog` (v1.1+ Phase 5, canonical producer of `recurring_failure` observations and `other`-typed long-running-bash observations), `cruft-checker` (v1.1.x, dogfood-only), `code-quality-auditor` (v1.1.4), session-end telemetry (Phase 46), `roadmap-auditor` (Phase 75, dogfood-only — skeleton-level claim integrity). `session-observer` (v1.1.0, the original producer) retired Phase 58; its `source` enum value remains valid for historical observations. Future producers add their name to the `source` enum without breaking existing consumers.
- **Consumers**: `workflow-suggester` (v1.1+ Phase 2 extension — drafts captures from observation files). Future consumers (v2.0 plugin recommendation system, v1.2+ `manager-optimizer`) read the same schema.

Lock the schema; extend the enums. New producers register a `source` value, new pattern shapes register a `pattern_type` value. Field names and field semantics are stable surface area.

## Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `pattern_id` | string (64-char lowercase hex) | yes | Stable SHA-256 of `pattern_type + normalized_signature`. Same pattern → same id across sessions and across producers. The filename is `<pattern_id>.json`. |
| `source` | string enum (extensible) | yes | Which producer emitted this observation. v1.1.0 values: `session-observer`, `task-watchdog`, `manual`, `other`. v1.1.x adds `cruft-checker` (skeleton-doc cruft; dogfood-only). v1.1.4 adds `code-quality-auditor` (installed-plugin manifest + security audit; ships in template). Phase 46's SessionEnd telemetry emits `session-end-telemetry` (registered Phase 65). Phase 75 adds `roadmap-auditor` (skeleton-level claim integrity; dogfood-only). |
| `pattern_type` | string enum (extensible) | yes | What kind of pattern. v1.1.0 values: `repeated_command`, `repeated_edit`, `error_resolution`, `recurring_failure` (canonical producer: `task-watchdog`), `other`. v1.1.4 adds `plugin_quality` (emitted by `code-quality-auditor` for the three plugin-verification heuristics — manifest path missing/empty, hooks.json schema violation, destructive shell pattern against unguarded path). Phase 46 adds `token_telemetry` (session-end telemetry; registered Phase 65 — see the `target_resource` requirement below). |
| `occurrences` | integer (≥ 1) | yes | Count of times this pattern was observed across the producer's inspection windows. Monotonic — updates on re-observation. Minimum 2 for pattern-detection producers (`task-watchdog`; historically also the retired `session-observer`) — a single sighting isn't a pattern. Deterministic-detection producers with full-resolve-pass semantics (`cruft-checker`, `code-quality-auditor`) MAY emit at `occurrences = 1` because each scan is an independent atomic detection — the pattern's existence at scan-time is the observation, and absence in subsequent scans is signaled via `resolved_at` rather than via accumulated occurrence counts. |
| `first_seen` | string (ISO-8601 UTC) | yes | When `pattern_id` was first observed. Set once on creation. Format: `YYYY-MM-DDTHH:MM:SSZ`. |
| `last_seen` | string (ISO-8601 UTC) | yes | When `pattern_id` was most recently observed. Updates on each re-observation. |
| `resolved_at` | string (ISO-8601 UTC) or `null` | yes | Set by the producer when its scan no longer detects the underlying pattern. `null` = active (detected on most recent scan, or never re-scanned since first emission). Non-null timestamp = producer confirmed the pattern is gone as of that time. Reset to `null` on re-detection (regression). Consumers like `workflow-suggester` skip non-null entries when generating new captures. See "Resolution lifecycle" below. |
| `evidence` | array of event objects | yes | Concrete instances the pattern was extracted from. Each event: `{ timestamp, kind, summary, tool_name?, args_redacted? }`. See "Evidence" below. Capped at the 20 most recent entries to bound file size. |
| `confidence` | string enum | yes | `low` \| `med` \| `high`. Default heuristic: ≥5 occurrences → `high`; 3–4 → `med`; 2 → `low`. Producers can override when they have direct evidence (e.g. `task-watchdog` matching an exact stack trace at 2 occurrences → `high`). |
| `privacy_class` | string enum | yes (v1.1.5+) | `local-only` \| `safe-to-share` \| `share-with-redaction`. Schema-level privacy class governing what can leave the project boundary. Set by the producer at emit time per the producer's mapping. Migrated observations (pre-v1.1.5) default to `local-only` (conservative). The `redact-observation.sh` lib reads this field — refuses `local-only`, passes `safe-to-share`, strips `share-with-redaction` to the safe-to-share field allowlist (see [`redact-observation.sh`](../../lib/redact-observation.sh)). |

Optional fields per `pattern_type`:

| Field | Type | Required when |
|---|---|---|
| `notes` | string (≤ 120 chars) | `pattern_type == "other"`. Free-text label so the consumer knows what shape the pattern is. |
| `target_resource` | string (format `<category>:<name>`) | Optional/encouraged on all types; **required** on `pattern_type == "token_telemetry"`. Identifies the artifact the observation is about, enabling downstream stale-checker / artifact-fit-analyzer / manager-optimizer queries. Categories: `agent`, `skill`, `command`, `script`, `plugin`, `hook`, `file`, `session`. Examples: `agent:cruft-checker`, `command:goals`, `script:commit.sh`, `plugin:claude-mem`, `file:CLAUDE_MANAGER.md`, `hook:sessionend-observe.sh`, `session:<session_id>`. |

## Evidence

Each entry in the `evidence` array has these fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `timestamp` | string (ISO-8601 UTC) | yes | When this specific event happened. |
| `kind` | string | yes | What kind of event. Examples: `tool_call`, `file_edit`, `error`, `commit`, `test_failure`. |
| `summary` | string (≤ 120 chars) | yes | One-line description of the event. Plain English, no markup. |
| `tool_name` | string | when `kind == "tool_call"` | The tool that was invoked (e.g. `Bash`, `Edit`, `Read`). |
| `args_redacted` | string (≤ 120 chars) | optional | Short, redacted snapshot of the args. Secrets, full file contents, and long paths are stripped. |

**Evidence redaction rules** (load-bearing — producers MUST follow):

- Strip anything matching `[A-Z_]*KEY=...`, `[A-Z_]*TOKEN=...`, `Bearer *`, `Authorization: *`.
- Strip filesystem paths under `~/.ssh/`, `~/.aws/`, `~/.config/*/credentials*`, or anything beginning with `/Users/<u>/...` (replace with `~`).
- Strip any base64-encoded string longer than 32 characters.
- Strip query strings on URLs (replace `?...` with `?…`).
- When in doubt, redact. The schema cap of 120 chars per `summary` and `args_redacted` is also a guardrail — if the field would exceed 120 chars after redaction, truncate to 120 with a trailing `…`.

## Resolution lifecycle

The `resolved_at` field is producer-driven, not user-driven. Each producer that owns observation files runs a resolve pass alongside its detection pass:

- **Detection produces** `resolved_at: null` — every new emission, and every re-emission of an existing observation, writes `null` (which acts as a regression-reset if the observation was previously marked resolved).
- **Absence produces** a timestamp — at the end of a scan, for each existing observation owned by this producer that the scan did NOT touch, set `resolved_at` to the current time (only if it's currently `null`; already-resolved observations stay frozen at their original resolution timestamp).

The mechanism is asymmetric by producer scope:

- `cruft-checker` and `roadmap-auditor` (Phase 75) run a **full resolve pass** — every scan covers the entire scope, so absence in a scan is meaningful evidence the finding is gone.
- `task-watchdog` is **session-bounded** — each scan covers one prior session, so absence in a scan is not meaningful evidence the pattern is permanently gone. task-watchdog writes `resolved_at: null` on emissions but does NOT actively set timestamps. Older observations stay `null` indefinitely; this is intentional.
- session-end telemetry is **point-in-time / session-bounded** (registered Phase 65) — each observation describes one completed session; there is nothing to re-scan, so it emits `resolved_at: null` and never resolves. Stays `null` indefinitely; intentional, same rationale as task-watchdog.
- `session-observer` (retired Phase 58) ran a **scoped resolve pass** — resolving observations whose pattern doesn't appear in the current scan window, with the same regression-reset on re-detection.

Resolved observations stay on disk as audit trail — consumers filter them, nothing deletes them. v2.0's `manager-optimizer` is the eventual pruning surface.

## Privacy class mapping

`privacy_class` is **schema-level privacy enforcement** — the field governs what each observation can leak when cross-install aggregation happens. Producers set it at emit time per the table below; the `redact-observation.sh` lib enforces it on emission to any cross-install destination.

| Producer | pattern_type | privacy_class | Rationale |
|---|---|---|---|
| session-observer (retired Phase 58) | `repeated_command` | `local-only` | Command args contain project paths |
| session-observer | `repeated_edit` | `local-only` | File paths leak project structure |
| session-observer | `error_resolution` | `local-only` | Error context project-specific |
| session-observer | `other` | `local-only` | Conservative catch-all |
| task-watchdog | `recurring_failure` | `share-with-redaction` | Error signature shareable; command args redact |
| task-watchdog | `other` (long-bash) | `share-with-redaction` | Duration + tool shareable; command args redact |
| cruft-checker | `other` (doc_cruft) | `local-only` | Doc names + violations project-specific |
| roadmap-auditor | `other` (claim integrity, Phase 75) | `local-only` | Doc names + claims project-specific; dogfood-only producer |
| code-quality-auditor | `plugin_quality` | `share-with-redaction` | Plugin name + heuristic shareable; plugin paths may leak local user info |
| (SessionEnd telemetry) | `token_telemetry` | `safe-to-share` | Only aggregate metrics; no project content |

The three values:

- **`local-only`** — conservative default. Observation contains project-specific content/context that can't safely leave the project boundary. The redaction lib **refuses to emit** these (exit 2). Used for anything containing file paths, doc names, or project structure.
- **`safe-to-share`** — only structural / metadata signals safe for cross-install aggregation. Pass-through to redaction lib (no field stripping needed). Used for pure metric observations (token telemetry).
- **`share-with-redaction`** — shareable signal + project-specific content that gets stripped on emission. The redaction lib reduces these to the safe-to-share field allowlist. Used for failure-signature observations and plugin-quality observations.

The migration script `.claude/lib/migrate-observation-privacy.sh` backfills `privacy_class: "local-only"` on any pre-v1.1.5 observation lacking the field. Producers MUST set the field on all new emissions.

## Example

```json
{
  "pattern_id": "a3f5b2e1c4d8f7a9b6c2e5d4f8a1b3c7e9d6f2a4b8c1e3d5f7a9c2b4e6d8f0a2",
  "source": "session-observer",
  "pattern_type": "repeated_command",
  "occurrences": 5,
  "first_seen": "2026-05-08T10:14:22Z",
  "last_seen": "2026-05-15T16:42:08Z",
  "resolved_at": null,
  "evidence": [
    {
      "timestamp": "2026-05-08T10:14:22Z",
      "kind": "tool_call",
      "tool_name": "Bash",
      "args_redacted": "find . -name '*.gd' | wc -l",
      "summary": "Counting .gd files at project root"
    },
    {
      "timestamp": "2026-05-10T14:02:51Z",
      "kind": "tool_call",
      "tool_name": "Bash",
      "args_redacted": "find . -name '*.gd' -not -path './.godot/*' | wc -l",
      "summary": "Counting .gd files (excluding .godot cache this time)"
    },
    {
      "timestamp": "2026-05-15T16:42:08Z",
      "kind": "tool_call",
      "tool_name": "Bash",
      "args_redacted": "find . \\( -path './.git' -o -path './.godot' \\) -prune -o -name '*.gd' -print | wc -l",
      "summary": "Counting .gd files with bash-safety excludes"
    }
  ],
  "confidence": "high",
  "privacy_class": "local-only"
}
```

This is a `repeated_command` pattern — the same intent (counting `.gd` files at project root) tried three different command shapes over a week. `privacy_class: "local-only"` because the command args carry project-specific path shapes. A consumer like `workflow-suggester` would draft a capture (a `count-godot-files.sh` script, or a slash command) so the canonical shape is one keystroke away next time.

## Extensibility notes

- **New `source` values.** Future producers add their name to the enum. v1.2+ `manager-optimizer` might emit observations with `source: "manager-optimizer"` describing decision-pattern drift. Consumers ignore unknown `source` values — they don't fail validation, they just route to a default handler.
- **New `pattern_type` values.** Same model. v2.0's plugin recommendation system might emit `source: "manager-optimizer"` with `pattern_type: "missing_capability"` — consumers handle the known types, ignore the rest. Producers should pick names that are intent-descriptive (`recurring_failure`, not `f1`).
- **Don't repurpose existing fields.** If a future producer needs a piece of data the schema doesn't carry, add a new optional field with a clear name. Adding `pattern_subtype` is fine; overloading `notes` with semi-structured data is not.

## What NOT to put in observations

- Full file contents.
- Long stack traces (signature line + first 3 frames is enough).
- Secrets (see redaction rules above — non-negotiable).
- User-identifying info beyond what's in the producer's bounded activity surface (transcripts, project docs, plugin sources; if you're tempted to add user identity beyond what's there, stop).
- Anything > 120 chars per `summary` or `args_redacted` field. Truncate.

If a pattern can't be expressed within these constraints, the pattern itself is probably under-normalized. Tighten the normalization before adding fields.
