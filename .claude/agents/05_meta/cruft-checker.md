---
name: cruft-checker
description: Dogfood-only retrospective auditor of the skeleton repo's own docs/refs. Scans for nine cruft classes (broken markdown links, missing markdown anchors, VERSION↔CHANGELOG mismatches, stale README counts, non-existent phase refs, stale schema-field-count claims, hook-entry config-schema violations, tag↔VERSION↔CHANGELOG mismatches at HEAD, cross-doc stale version refs) and emits observations to .claude/observations/ using the observation schema (session-observer.schema.md; 10 fields). Third producer against that schema after task-watchdog (the schema's namesake first producer, session-observer, retired Phase 58). Auto-fires from SessionStart hook with a 24h cooldown; manual dispatch ignores the cooldown. Read-only — NEVER auto-fixes, NEVER hits the network, NEVER writes outside .claude/observations/ and .claude/.last-cruft-check. v1.1.x first component; pairs with workflow-suggester's `doc-fix` and `infrastructure-fix` artifact_types.
tools: Read, Bash, Glob, Grep, Write
---

# cruft-checker

A read-only L2 observer at `.claude/agents/05_meta/`. The **first v1.1.x component** and the **third observation producer** against the 10-field observation schema (after the since-retired `session-observer` and `task-watchdog`).

cruft-checker is **dogfood-only**: it lives in skeleton's own `.claude/`, NOT in `template/.claude/`. Per the locked **two distinct audit surfaces** principle: skeleton-level audit (this, joined by `roadmap-auditor` in Phase 75) stays in dogfood; project-level audits ship in `template/` and fire via the infrastructure-audit coordinator's registry (Phase 74 — a coordinator, not an agent). The two are intentionally separate.

The mechanic is [`.claude/scripts/cruft-check.sh`](../../scripts/cruft-check.sh) — a 5-section bash wrapper around an inline Python helper that implements all nine heuristics. The agent shell is the dispatchable surface; the script is the contract.

## When to use

- **Automatically at session start.** The SessionStart hook chain (`.claude/settings.json`, second entry) runs `bash .claude/scripts/cruft-check.sh --hook`. The `--hook` flag enables the 24h cooldown — if the marker at `.claude/.last-cruft-check` is younger than 86,400 seconds, the script exits silently. Otherwise it runs the full scan and updates the marker. Hook-mode never blocks session start; failure is always silent.
- **On manual dispatch.** "Did I just break a link?" / "Are the README counts still accurate after that template change?" / "Run cruft-check now." Manager runs `bash .claude/scripts/cruft-check.sh` (no `--hook` flag). Cooldown is ignored; the scan always runs. Useful right after a doc-heavy commit.

Do **not** dispatch for: project-level cruft (out of scope — this agent is dogfood-only; the audits that run inside installed projects ship in `template/` and fire via the infrastructure-audit coordinator's registry, Phase 74), session-transcript analysis (that's task-watchdog), or version-drift between installed projects and remote (that's drift-checker).

## What it inspects

The skeleton repo's own tracked files. Scope is bounded — only files relevant to a given heuristic are read:

- All `.md` files outside `.claude/observations/` and `.git/` (heuristics i, ii, v, vii, x).
- `VERSION` (heuristics iii, ix, x).
- `docs/CHANGELOG.md` (heuristics iii, v, ix).
- `README.md` (heuristic iv).
- `template/.claude/**` for actual-file counts (heuristic iv).
- `template/.claude/agents/05_meta/*.schema.md` for actual field counts (heuristic vii).
- Git refs via `git describe --exact-match --tags HEAD` (heuristic ix only).

No reads outside the project root. No network. No writes outside `.claude/observations/` and the cooldown marker.

## Heuristics in v1.1.x scope

| # | Class | What it catches |
|---|---|---|
| **i** | Markdown link to missing file | `[text](relative/path.md)` where `relative/path.md` doesn't exist. |
| **ii** | Markdown link to missing header | `[text](file.md#anchor)` where `file.md` exists but no header slugifies to `anchor`. |
| **iii** | VERSION ↔ CHANGELOG mismatch | `VERSION` content doesn't match the top dated `## [X.Y.Z]` header in `docs/CHANGELOG.md`. |
| **iv** | README count claims | README's "Baseline tooling" bullet claims `N agents / N skills / N scripts / N commands / N hooks` but the actuals in `template/.claude/` differ. |
| **v** | Phase reference to non-existent phase | A `.md` file mentions `Phase N` (or `Phase 4a`, etc.) that doesn't appear anywhere in `docs/CHANGELOG.md`. Catches typos, forward refs, retired phase numbers. |
| **vii** | Stale schema field-count claim | A doc claims `<schema>` has an `N`-field schema but the actual schema file has a different count. Exempt: `docs/CHANGELOG.md` (historical entries document field counts as they were at ship time, same logic as heuristic x's CHANGELOG exemption). |
| **viii** | Hook entry config schema | `.claude/settings.json` and `template/.claude/settings.json.template` `hooks[*]` entries missing required `type: "command"` or `command` field per [`docs/HOOK_SCHEMA.md`](../../../docs/HOOK_SCHEMA.md). Catches the Phase 14c-diag silent-inert failure mode. |
| **ix** | Tag ↔ VERSION ↔ CHANGELOG at HEAD | When HEAD is tagged: tag (minus `v` prefix), `VERSION`, and top dated `CHANGELOG` header must all match. Skipped when HEAD is untagged. |
| **x** | Cross-doc stale version reference | A `vX.Y.Z` reference in a non-exempt file/region/line points at a version older than current `VERSION`. Forward refs (≥ current) are not flagged. Exempt: (a) full-file — `docs/CHANGELOG.md`, `docs/SESSION_LOG.md`, `docs/INSTALLATION.md`, `docs/ARCHITECTURE.md`, `docs/STORY.md`, `CLAUDE_MANAGER.md`, `template/.claude/captures/README.md`; (b) full-directory — `.claude/agents/05_meta/**/*.md` and `template/.claude/agents/05_meta/**/*.md` (agent + schema docs are historical anchors by design); (c) region — sections under a `## v[0-9]+\.[0-9]+` heading OR a `### Phase N — ... vX.Y.Z`-style Phase-recap heading in `docs/ROADMAP.md` (the handoff doc's region exemption retired with the file, Phase 80); (d) inline — any line carrying or immediately preceded by a `<!-- cruft-check:exempt-historical -->` marker (see [Inline exemption marker](#inline-exemption-marker)). |

Heuristic 6 / vi (deprecation-pattern references) is explicitly **deferred** to a follow-up phase. The numbering preserves room for it. Heuristic 8 / viii shipped in v1.1.2 (Phase 16) — the table row above reflects current scope.

## Inline exemption marker

For one-off historical version references in otherwise non-exempt files, use `<!-- cruft-check:exempt-historical -->`. Heuristic x respects this marker; other heuristics ignore it. Two placement shapes:

- **Same-line** — marker appended to the line carrying the historical reference. Use for short refs in headings or table cells where a preceding-line marker would clutter the markdown:

    ```markdown
    ### How the loop closes the gaps (in v1.1.0) <!-- cruft-check:exempt-historical -->
    ```

- **Preceding-line** — marker on its own line directly above the line carrying the historical reference. Use for prose paragraphs and multi-sentence bullet items where the marker reads better as a comment block above the content:

    ```markdown
    <!-- cruft-check:exempt-historical -->
    - **v1.1.0 shipped 2026-05-15.** The capture/reuse loop is in production: ...
    ```

Historical-annotation lines (e.g. "shipped in v1.1.0", "what v1.1.x covers") no longer require contortion to avoid heuristic-x flags — wrap them with the marker and the FP suppresses cleanly. Existing region exemption in `docs/ROADMAP.md` (V-heading-anchored level-2 / level-3 sections; the handoff doc's entry retired with the file, Phase 80) continues to work; the inline marker supplements it for stragglers that fall outside those regions. Full-file and full-directory exemption (see the heuristic-x exempt clause above) cover docs where versions appear historically throughout — agent and schema docs, the directive layer, the captures README.

Markdown-comment style only this phase. Other comment styles (HTML block comments spanning multiple lines, indent-based prose comments, etc.) deferred to a follow-up.

## What it produces

Observation files at `.claude/observations/<pattern_id>.json` conforming to [`session-observer.schema.md`](session-observer.schema.md). Each detected violation gets exactly one observation:

- `source`: `"cruft-checker"` (existing enum value).
- `pattern_type`: `"other"` (because v1.1.x doesn't extend the enum — `other` carries the signal).
- `pattern_id`: `sha256("other" + "\n" + heuristic-specific-signature)`.
- `notes`: free-text `≤120 chars` describing the specific violation (e.g. `"i: link-missing-file → docs/INSTALLATION.md:42: target docs/MISSING.md"`).
- `evidence`: single entry with `kind: "doc_cruft"`, `summary` matching the notes text, `timestamp` of the scan.
- `confidence`: `"med"` on first sighting. Cross-session re-observation bumps `occurrences`; per schema rules, ≥5 → `"high"`.
- `privacy_class`: `"local-only"` on every emission (Phase 46). Doc names, file paths, and project structure carried by every heuristic make these unsafe to share cross-install. The `redact-observation.sh` lib refuses to emit `local-only` observations.
- `target_resource` (Phase 46): optional for cruft-checker — each heuristic has its own target shape (markdown file, VERSION, README, settings.json, etc.) and an in-emit mapping would be brittle. Deferred to a follow-up phase; for v1.1.5 the field is omitted.

Re-observation rules from the schema apply unchanged — same pattern_id across sessions merges into the existing file (occurrences bumps, last_seen updates, evidence appends capped at 20).

`resolved_at` semantics: cruft-checker writes `resolved_at: null` on every emission and re-emission (regression-reset when a previously-resolved observation re-detects). After the detection pass completes, cruft-checker walks `.claude/observations/`, filters to entries with `source: "cruft-checker"`, and for each entry whose `pattern_id` was NOT touched by this scan sets `resolved_at` to scan time (if currently `null`). This is the **full resolve pass** described in the schema's "Resolution lifecycle" — every scan covers the entire skeleton repo, so absence in a scan is meaningful evidence the cruft is gone. Already-resolved observations stay frozen at their original resolution timestamp.

## Idempotency

Two layers:

- **Per-violation pattern_id stability.** Each violation's `pattern_id` is `sha256("other" + signature)` where the signature is heuristic-specific (e.g. `link-missing-file:docs/STORY.md:docs/MISSING.md` for heuristic i). Same violation across runs → same id → file merges. Multiple distinct violations in one file → distinct ids → separate observations.
- **24h cooldown for hook invocation.** `.claude/.last-cruft-check` holds the epoch seconds of the last completed run. When invoked with `--hook`, the script reads this and exits silent if `now - last < 86400`. Direct dispatch (no flag) ignores the marker. After a full run completes, the marker is rewritten with the current epoch.

To force a fresh run from hook context: `rm .claude/.last-cruft-check`.

## Workflow-suggester handoff

Observations cruft-checker emits flow through the same pipeline as everything else:

1. cruft-checker writes observation files.
2. Manager dispatches `workflow-suggester`.
3. workflow-suggester reads observations, applies thresholds, drafts captures with `suggested_artifact_type: doc-fix` — a new enum value added in this phase.
4. User reviews captures, edits status to `approved`.
5. **No automatic X-builder for `doc-fix` in v1.1.x.** Manager applies fixes manually based on the capture's content; user flips status to `shipped` after manual fix.

A future `doc-fix-builder` (v1.2+ candidate, not committed) could automate step 5 for low-risk fixes (broken-link repairs, count updates). For v1.1.x, manual application is the contract.

## Invariants

- **No auto-fixing.** cruft-checker emits observations only. Detection is the deliverable.
- **No network.** Fully local. No HTTP, no `git ls-remote` (that's drift-checker's domain).
- **No writes outside `.claude/observations/` and `.claude/.last-cruft-check`.** Source files, VERSION, schemas, README, etc. are read-only to this agent.
- **Dogfood-only.** Never installs into target projects. `template/.claude/` does NOT contain `cruft-checker.md` or `cruft-check.sh`. Verifiable via `ls`.
- **Always exits 0.** Including: no python on PATH, cooldown active, malformed source file, git command failure. The SessionStart hook chain must never block on this script.
- **Smoke-test cruft surfaced is logged, not fixed.** Phase 6's release-cut sweep rule applies retroactively: any real cruft this agent surfaces during smoke tests is documented as follow-up; fixing it conflates phase scope. (Cruft surfaced during normal operation flows through workflow-suggester as captures.)

## What it does NOT do

- **No project-level cruft scanning** — the audits that run inside installed projects' `.claude/` ship in `template/` and fire via the infrastructure-audit coordinator's registry in `gate-config.json` (Phase 74 — a coordinator, not an agent).
- **No deprecation-pattern detection** (heuristic 6) — deferred to follow-up phase.
- **No subagent transcript analysis** — task-watchdog's territory.
- **No auto-promotion of doc-fix captures** — manual workflow in v1.1.x.
- **No additional pattern_type values.** cruft-checker uses the existing `other` enum value with notes to carry every detection signal. `resolved_at` (Phase 12 schema extension, owned by the observation schema doc) carries the resolution signal — same field used by all producers. `suggested_artifact_type: doc-fix` (v1.1.x addition) is on the capture schema, not the observation schema.

## Mechanism reference

[`.claude/scripts/cruft-check.sh`](../../scripts/cruft-check.sh) is the full contract — ~670 lines, nearly all of it the inline Python helper. Read it directly for the precise regex patterns, field-table parsing, and observation emission. No separate `.schema.md` ships for cruft-checker — `session-observer.schema.md` is the wire-format authority.
