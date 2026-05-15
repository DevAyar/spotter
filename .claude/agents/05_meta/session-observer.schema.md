# session-observer observation schema

The wire format for one observation entry under `.claude/observations/<pattern_id>.json`.

This schema is the contract shared by:
- **Producers**: `session-observer` (v1.1.0, all pattern types except `recurring_failure`), `task-watchdog` (v1.1+ Phase 5, canonical producer of `recurring_failure` observations and `other`-typed long-running-bash observations). Future producers add their name to the `source` enum without breaking existing consumers.
- **Consumers**: `workflow-suggester` (v1.1+ Phase 2 extension — drafts captures from observation files). Future consumers (v2.0 plugin recommendation system, v1.2+ `manager-optimizer`) read the same schema.

Lock the schema; extend the enums. New producers register a `source` value, new pattern shapes register a `pattern_type` value. Field names and field semantics are stable surface area.

## Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `pattern_id` | string (64-char lowercase hex) | yes | Stable SHA-256 of `pattern_type + normalized_signature`. Same pattern → same id across sessions and across producers. The filename is `<pattern_id>.json`. |
| `source` | string enum (extensible) | yes | Which producer emitted this observation. v1.1.0 values: `session-observer`, `task-watchdog`, `manual`, `other`. |
| `pattern_type` | string enum (extensible) | yes | What kind of pattern. v1.1.0 values: `repeated_command`, `repeated_edit`, `error_resolution`, `recurring_failure` (canonical producer: `task-watchdog`), `other`. |
| `occurrences` | integer (≥ 2) | yes | Count of times this pattern was observed across the producer's inspection windows. Monotonic — updates on re-observation. Minimum 2 (a single sighting isn't a pattern). |
| `first_seen` | string (ISO-8601 UTC) | yes | When `pattern_id` was first observed. Set once on creation. Format: `YYYY-MM-DDTHH:MM:SSZ`. |
| `last_seen` | string (ISO-8601 UTC) | yes | When `pattern_id` was most recently observed. Updates on each re-observation. |
| `evidence` | array of event objects | yes | Concrete instances the pattern was extracted from. Each event: `{ timestamp, kind, summary, tool_name?, args_redacted? }`. See "Evidence" below. Capped at the 20 most recent entries to bound file size. |
| `confidence` | string enum | yes | `low` \| `med` \| `high`. Default heuristic: ≥5 occurrences → `high`; 3–4 → `med`; 2 → `low`. Producers can override when they have direct evidence (e.g. `task-watchdog` matching an exact stack trace at 2 occurrences → `high`). |

Optional fields per `pattern_type`:

| Field | Type | Required when |
|---|---|---|
| `notes` | string (≤ 120 chars) | `pattern_type == "other"`. Free-text label so the consumer knows what shape the pattern is. |

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

## Example

```json
{
  "pattern_id": "a3f5b2e1c4d8f7a9b6c2e5d4f8a1b3c7e9d6f2a4b8c1e3d5f7a9c2b4e6d8f0a2",
  "source": "session-observer",
  "pattern_type": "repeated_command",
  "occurrences": 5,
  "first_seen": "2026-05-08T10:14:22Z",
  "last_seen": "2026-05-15T16:42:08Z",
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
  "confidence": "high"
}
```

This is a `repeated_command` pattern — the same intent (counting `.gd` files at project root) tried three different command shapes over a week. A consumer like `workflow-suggester` would draft a capture (a `count-godot-files.sh` script, or a slash command) so the canonical shape is one keystroke away next time.

## Extensibility notes

- **New `source` values.** Future producers add their name to the enum. v1.2+ `manager-optimizer` might emit observations with `source: "manager-optimizer"` describing decision-pattern drift. Consumers ignore unknown `source` values — they don't fail validation, they just route to a default handler.
- **New `pattern_type` values.** Same model. v2.0's plugin recommendation system might emit `source: "manager-optimizer"` with `pattern_type: "missing_capability"` — consumers handle the known types, ignore the rest. Producers should pick names that are intent-descriptive (`recurring_failure`, not `f1`).
- **Don't repurpose existing fields.** If a future producer needs a piece of data the schema doesn't carry, add a new optional field with a clear name. Adding `pattern_subtype` is fine; overloading `notes` with semi-structured data is not.

## What NOT to put in observations

- Full file contents.
- Long stack traces (signature line + first 3 frames is enough).
- Secrets (see redaction rules above — non-negotiable).
- User-identifying info beyond what's in the activity log surface (the agent reads `SESSION_LOG.md`; if you're tempted to add user identity beyond what's there, stop).
- Anything > 120 chars per `summary` or `args_redacted` field. Truncate.

If a pattern can't be expressed within these constraints, the pattern itself is probably under-normalized. Tighten the normalization before adding fields.
