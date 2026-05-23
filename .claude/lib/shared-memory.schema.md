# shared-memory envelope schema (Phase 47b)

The wire format every cross-project producer emits. One envelope per event, written into the local shared-memory tree at `.claude/shared-memory/`. Phase 47b writes events locally only; Phase 47c clones the share remote, copies this tree in, and pushes.

Producers: `captures`, `observations`, `telemetry`, `version` (see `.claude/scripts/shared-memory-produce.sh`). The builder is `sm_build_envelope` in [`shared-memory-lib.sh`](shared-memory-lib.sh).

## Envelope fields

| Field | Type | Required | Description |
|---|---|---|---|
| `schema_version` | integer | yes | `1`. Bumped only on a breaking envelope change (matches the sentinel / share-config `schema_version`). |
| `producer` | string enum | yes | `captures` \| `observations` \| `telemetry` \| `version`. Which input class the event came from. |
| `install_uuid` | string (UUIDv4) | yes | The emitting install's `install_uuid`, from `.claude/.skeleton-version`. |
| `install_label` | string | yes | The emitting install's `install_label` (falls back to `install_uuid` when unset). |
| `version` | string | yes | The emitting install's skeleton `version` at emit time. Marker-native name — never `skeleton_version`. |
| `commit` | string | yes | The emitting install's skeleton `commit` at emit time. Marker-native name — never `skeleton_commit`. |
| `event_timestamp` | string (ISO-8601 UTC) | yes | Push-moment time the event was produced (`YYYY-MM-DDTHH:MM:SSZ`). |
| `created_at` | string (ISO-8601 UTC) | no | The source artifact's own creation timestamp where it has one (captures, observations, telemetry). **Key omitted entirely** when the source has none (version is current-state). |
| `payload` | object | yes | Producer-specific body — see below. |

Canonical JSON shape: sorted keys, 2-space indent, trailing newline, `ensure_ascii` (matches the 47a sentinel / share-config writers).

## Tree layout

```
.claude/shared-memory/
  <producer>/<install_uuid>/<YYYY-MM-DD>/<key>.json     # captures, observations, telemetry
  version/<install_uuid>/version.json                    # version — no date dir
```

`version` is **current-state, overwritten** each run — no date partition. The other three are **append-only**: one event per stable key, never rewritten.

## Per-producer payload + key

| Producer | `key` (event filename stem) | `created_at` source | payload |
|---|---|---|---|
| `captures` | capture filename stem (`source_pattern_id`) | frontmatter `created_at` | `{ status, confidence, suggested_artifact_type, created_at, body_redacted }` |
| `observations` | observation `pattern_id` | observation `first_seen` | the redacted observation JSON (whole), from `redact-observation.sh` |
| `telemetry` | session id (from `target_resource` `session:<id>`) | observation `first_seen` | the telemetry observation JSON (pass-through; it is `safe-to-share`) |
| `version` | `version` (fixed) | — (omitted) | `{ version, commit, install_uuid, install_label, install_created }` |

## Idempotency

Append-only producers are safe to re-run: before writing `<producer>/<uuid>/<date>/<key>.json`, the writer checks for `<producer>/<uuid>/*/<key>.json` across **all** date dirs and skips if any exists. So a re-run on a later day never duplicates an event. `version` is idempotent by overwrite.

## Redaction

- **captures** — no `privacy_class` field exists on captures, so every capture is treated as `share-with-redaction`: the body is text-redacted (secrets, tokens, home paths, base64, URL query strings) by `redact-capture.sh` before it is wrapped. Only terminal-state captures (`status: shipped` or `rejected`) are emitted; draft/approved are skipped.
- **observations** — routed through `redact-observation.sh` verbatim: `local-only` refused (no event), `safe-to-share` passed through, `share-with-redaction` reduced to the safe field allowlist.
- **telemetry** — the `token_telemetry` observation is `safe-to-share`; it is still routed through `redact-observation.sh` (pass-through) for a uniform gate, then written to the `telemetry/` path. Raw `telemetry/events/*.jsonl` and `telemetry/sessions/*.md` stay local (gitignored) and are never pushed.
- **version** — structural marker fields only (no project content).

## Disabled state

If share mode is not enabled (`.claude/share-config.json` absent, or present with `enabled` not `true`), producers are a no-op: no tree is created and no events are written.
