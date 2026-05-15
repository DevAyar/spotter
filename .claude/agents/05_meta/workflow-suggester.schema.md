# workflow-suggester capture schema

The contract for one capture markdown file under `.claude/captures/<capture_id>.md`. Each file is a self-contained review surface that the user reads and approves, rejects, or leaves on draft.

This schema is what:
- **`workflow-suggester`** (v1.1+) writes — drafts a capture per warranted observation.
- **Future X-builders** (v1.1+ — `script-builder` first, then skill/agent/command-builders) read — consumes `status: approved` captures to generate the actual artifact (script, skill, agent, slash command).
- **Manager-optimizer** (v1.2+) may eventually walk to grade decision patterns; same schema.

Lock the structure; extend the enums. New artifact-builders register a `suggested_artifact_type` value if needed; the body conventions stay stable.

## File format

UTF-8 markdown with YAML frontmatter delimited by `---` lines. Filename is `<source_pattern_id>.md` (matches the observation's `pattern_id`).

## Frontmatter — 7 required fields

| Field | Type | Description |
|---|---|---|
| `capture_id` | string (64-char lowercase hex) | Stable id for this capture. By default `capture_id == source_pattern_id` — one capture per pattern, idempotency check is direct. Future producers needing multiple captures per pattern would derive `capture_id` from `source_pattern_id + discriminator`; v1.1.0 producers should match the default. |
| `source_pattern_id` | string (64-char lowercase hex) | The `pattern_id` of the observation that triggered this draft. Foreign key into `.claude/observations/<source_pattern_id>.json`. Stable across re-runs — same pattern → same id. |
| `source_pattern_type` | string enum | Copied verbatim from the observation for at-a-glance context. v1.1.0 values: `repeated_command`, `repeated_edit`, `error_resolution`, `recurring_failure`, `other`. |
| `status` | string enum | `draft` (set by workflow-suggester on creation) \| `approved` (user-edited; downstream X-builders pick up) \| `shipped` (user-edited after promote; the artifact has been built and promoted) \| `rejected` (user-edited; do-not-re-suggest marker). All four count as "already considered" for idempotency. |
| `confidence` | string enum | Copied from observation: `low` \| `med` \| `high`. workflow-suggester's default threshold skips `low`, so captures on disk should be `med` or `high` unless thresholds were tuned. |
| `suggested_artifact_type` | string enum (extensible) | What kind of capture would address this pattern. v1.1.0 values: `script`, `skill`, `agent`, `command`, `manual_action`, `unclear`. Future X-builders may register new values; consumers ignore unknown values. |
| `created_at` | string (ISO-8601 UTC) | When workflow-suggester drafted this capture. Format: `YYYY-MM-DDTHH:MM:SSZ`. Set once on creation, never updated. |
| `shipped_to` | string (path, optional) | When the user promotes a built artifact, they add this field with the project-relative path of the promoted artifact (e.g. `.claude/scripts/count-files-by-ext.sh`). Set once at promote; never updated. Optional and only meaningful when `status: shipped`. Not set by `workflow-suggester` or any X-builder — purely user-recorded traceability. |

## Body — 4 sections

```markdown
# Capture: <short slug>

## Pattern
<one paragraph: what recurring pattern this addresses, why it
 warrants a capture>

## Evidence
<bulleted list, 3-10 entries, drawn from the observation's evidence
 array. Each: timestamp + summary (≤ 120 chars per line, matching
 the observation schema's redaction rules — secrets, paths, tokens
 stripped)>

## Suggested response
<one or two paragraphs: what kind of capture would address this —
 script / skill / agent / slash command / manual action — with a
 sketch of invocation shape if relevant. Concrete enough that the
 user can imagine the artifact; non-prescriptive enough that the
 actual X-builder retains design judgment>

## Approving / rejecting
<short instructions matching the lifecycle: edit `status` from
 `draft` to `approved` (downstream X-builders like `script-builder`
 pick it up to draft the artifact), to `rejected` (permanent
 do-not-re-suggest; file persists as a marker), or — after a
 downstream X-builder has drafted and the user has promoted the
 result — to `shipped` with a `shipped_to:` field pointing to the
 promoted artifact path. To re-open a `rejected` pattern, delete
 the file and re-dispatch workflow-suggester. See Status semantics
 below for the full transition table>
```

Target length: 30–50 lines per capture file. Compact, scannable, designed for a human to skim in 30 seconds and decide.

## Status semantics

| Value | Set by | Meaning | workflow-suggester behavior |
|---|---|---|---|
| `draft` | workflow-suggester on creation | "Drafted, awaiting human review" | Skip on re-run — idempotency. |
| `approved` | User (manually edits frontmatter) | "Yes, build this. Downstream X-builders pick up." | Skip on re-run. |
| `shipped` | User (manually edits frontmatter after promote) | "Built and promoted. The artifact lives at `shipped_to`." | Skip on re-run. Downstream X-builders also skip — work already done. |
| `rejected` | User (manually edits frontmatter) | "No, don't suggest this again." | Skip on re-run forever. File persists as a do-not-re-suggest marker. |

All four statuses count as "already considered." The agent never sees a captured pattern again unless the user deletes the file.

The `shipped` status is the **terminal success state** in the capture lifecycle: `draft` → `approved` → `shipped`. The `shipped_to` field accompanies it, recording where the promoted artifact lives. Downstream X-builders (script-builder, future skill/agent/command-builders) also filter out `shipped` captures — they've already done the work.

To re-open a rejected pattern (after some time has passed and the user reconsiders), delete the file and re-dispatch. The next run will see no existing capture for that pattern_id and draft a fresh one.

## suggested_artifact_type extensibility

v1.1.0 ships six values. Future X-builders may add new ones — e.g. `hook` (v1.2+?), `template` (some future), `documentation` (some future). The rules for adding:

- New values are added to this schema doc in the same PR that introduces the consumer.
- Existing values are never repurposed. `script` always means "shell script under `.claude/scripts/`," not "Python script" or anything else.
- Consumers that don't recognize a value should treat it as `unclear` — surface to the user for manual handling, never silently drop the capture.
- `unclear` is the explicit value for "the pattern is real but I (workflow-suggester) can't tell what kind of artifact it wants." Always valid; never deprecated.

## Complete example

A realistic capture file showing all fields populated and a body that demonstrates the density target:

```markdown
---
capture_id: a3f5b2e1c4d8f7a9b6c2e5d4f8a1b3c7e9d6f2a4b8c1e3d5f7a9c2b4e6d8f0a2
source_pattern_id: a3f5b2e1c4d8f7a9b6c2e5d4f8a1b3c7e9d6f2a4b8c1e3d5f7a9c2b4e6d8f0a2
source_pattern_type: repeated_command
status: draft
confidence: high
suggested_artifact_type: script
created_at: 2026-05-15T12:00:00Z
---

# Capture: count-godot-files

## Pattern
You've run a variation of "count `.gd` files at project root" five
times over the past week — each time landing on a slightly different
command shape. The first two missed `.godot` cache exclusions and
returned inflated counts; the third applied `bash-safety` excludes
and produced the canonical answer. The fourth and fifth re-derived
the same shape from scratch. Worth turning into a one-liner.

## Evidence
- 2026-05-08: `find . -name '*.gd' | wc -l` (no excludes — hit .godot cache)
- 2026-05-10: `find . -name '*.gd' -not -path './.godot/*' | wc -l`
- 2026-05-13: corrected to use -prune form after bash-safety review
- 2026-05-15: `find . \( -path './.git' -o -path './.godot' \) -prune -o -name '*.gd' -print | wc -l`

## Suggested response
A small shell script at `.claude/scripts/count-files-by-ext.sh` that
takes an extension argument and applies the canonical `bash-safety`
exclude list. Invocation:

    bash .claude/scripts/count-files-by-ext.sh gd

Generalizing to `<ext>` lets the same script handle `.gd`, `.cs`,
`.md`, etc. without re-deriving the find shape each time.

## Approving / rejecting
Edit `status` in the frontmatter:
- `approved` — `script-builder` picks this up to draft the actual script under `.claude/scripts/drafts/`.
- `shipped` — set this AFTER promoting a drafted artifact into `.claude/scripts/`. Add a `shipped_to:` field pointing at the promoted path (e.g. `shipped_to: .claude/scripts/count-files-by-ext.sh`). Terminal success state.
- `rejected` — workflow-suggester respects this as "do not re-suggest." Keep the file; don't delete.

To re-open a rejected pattern: delete this file and re-dispatch workflow-suggester.
```

That file is 36 lines including frontmatter — comfortably in the 30–50 target. Body density matches the bash-safety skill and observation-schema examples elsewhere in the skeleton.

## What NOT to put in captures

- Full file contents (same rule as observations).
- Secrets — same redaction rules as `session-observer.schema.md` apply transitively (the evidence section pulls from observation evidence, which is already redacted).
- The actual artifact being suggested. A capture is a *proposal* with a sketch; the artifact gets built by the appropriate X-builder after `status: approved`. Don't ship a fully-formed script body inside the Suggested response section — sketch the shape only.
- Long stack traces, full error logs, or anything > 120 chars per evidence line.

If the suggestion can't be expressed in the 4-section structure within ~50 lines, the pattern is probably under-normalized or the artifact type is `unclear` — say so explicitly rather than padding.
