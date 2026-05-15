---
name: cruft-checker
description: Dogfood-only retrospective auditor of the skeleton repo's own docs/refs. Scans for seven cruft classes (broken markdown links, missing anchors, VERSION/CHANGELOG/tag mismatches, stale README counts, non-existent phase refs, stale schema-field-count claims, cross-doc version drift) and emits observations to .claude/observations/ using session-observer's 8-field schema. Third producer against that schema after session-observer and task-watchdog. Auto-fires from SessionStart hook with a 24h cooldown; manual dispatch ignores the cooldown. Read-only — NEVER auto-fixes, NEVER hits the network, NEVER writes outside .claude/observations/ and .claude/.last-cruft-check. v1.1.x first component; pairs with workflow-suggester's new `doc-fix` artifact_type.
tools: Read, Bash, Glob, Grep, Write
---

# cruft-checker

A read-only L2 observer at `.claude/agents/05_meta/`. The **first v1.1.x component** and the **third observation producer** against `session-observer`'s 8-field schema (after `session-observer` itself and `task-watchdog`).

cruft-checker is **dogfood-only**: it lives in skeleton's own `.claude/`, NOT in `template/.claude/`. Per the locked **two distinct audit surfaces** principle: skeleton-level audit (this) stays in dogfood; project-level audit ships in v1.2.0's `infrastructure-auditor` under `template/`. The two are intentionally separate.

The mechanic is [`.claude/scripts/cruft-check.sh`](../../scripts/cruft-check.sh) — a 5-section bash wrapper around an inline Python helper that implements all seven heuristics. The agent shell is the dispatchable surface; the script is the contract.

## When to use

- **Automatically at session start.** The SessionStart hook chain (`.claude/settings.json`, second entry) runs `bash .claude/scripts/cruft-check.sh --hook`. The `--hook` flag enables the 24h cooldown — if the marker at `.claude/.last-cruft-check` is younger than 86,400 seconds, the script exits silently. Otherwise it runs the full scan and updates the marker. Hook-mode never blocks session start; failure is always silent.
- **On manual dispatch.** "Did I just break a link?" / "Are the README counts still accurate after that template change?" / "Run cruft-check now." Manager runs `bash .claude/scripts/cruft-check.sh` (no `--hook` flag). Cooldown is ignored; the scan always runs. Useful right after a doc-heavy commit.

Do **not** dispatch for: project-level cruft (that's v1.2.0's `infrastructure-auditor` in `template/`), session-transcript analysis (that's task-watchdog), or version-drift between installed projects and remote (that's drift-checker).

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
| **vii** | Stale schema field-count claim | A doc claims `<schema>` has an `N`-field schema but the actual schema file has a different count. |
| **ix** | Tag ↔ VERSION ↔ CHANGELOG at HEAD | When HEAD is tagged: tag (minus `v` prefix), `VERSION`, and top dated `CHANGELOG` header must all match. Skipped when HEAD is untagged. |
| **x** | Cross-doc stale version reference | A `vX.Y.Z` reference in a non-exempt file/region points at a version older than current `VERSION`. Exempt: all of `docs/CHANGELOG.md`; any section under a `## v[0-9]+\.[0-9]+` heading in `docs/ROADMAP.md` and `claude-skeleton-handoff.md`. Forward references (≥ current) are not flagged. |

Heuristic 6 (deprecation-pattern references) and heuristic 8 are explicitly **deferred** to a follow-up phase. The numbering preserves room for them.

## What it produces

Observation files at `.claude/observations/<pattern_id>.json` conforming to [`session-observer.schema.md`](session-observer.schema.md). Each detected violation gets exactly one observation:

- `source`: `"cruft-checker"` (existing enum value).
- `pattern_type`: `"other"` (because v1.1.x doesn't extend the enum — `other` carries the signal).
- `pattern_id`: `sha256("other" + "\n" + heuristic-specific-signature)`.
- `notes`: free-text `≤120 chars` describing the specific violation (e.g. `"i: link-missing-file → docs/INSTALLATION.md:42: target docs/MISSING.md"`).
- `evidence`: single entry with `kind: "doc_cruft"`, `summary` matching the notes text, `timestamp` of the scan.
- `confidence`: `"med"` on first sighting. Cross-session re-observation bumps `occurrences`; per schema rules, ≥5 → `"high"`.

Re-observation rules from the schema apply unchanged — same pattern_id across sessions merges into the existing file (occurrences bumps, last_seen updates, evidence appends capped at 20).

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

- **No project-level cruft scanning** — `infrastructure-auditor` (v1.2.0, ships in `template/`) owns audits inside installed projects' `.claude/`.
- **No deprecation-pattern detection** (heuristic 6) — deferred to follow-up phase.
- **No subagent transcript analysis** — task-watchdog's territory.
- **No auto-promotion of doc-fix captures** — manual workflow in v1.1.x.
- **No schema extensions beyond `doc-fix` on `suggested_artifact_type`** — observation schema is unchanged; `pattern_type: other` with notes carries every signal.

## Mechanism reference

[`.claude/scripts/cruft-check.sh`](../../scripts/cruft-check.sh) is the full contract. ~280 lines including the inline Python helper. Read it directly for the precise regex patterns, field-table parsing, and observation emission. No separate `.schema.md` ships for cruft-checker — `session-observer.schema.md` is the wire-format authority.
