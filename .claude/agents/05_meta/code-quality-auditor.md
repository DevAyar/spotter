---
name: code-quality-auditor
description: Reads installed plugin source under ~/.claude/plugins/cache/ and emits observations against the existing schema for three narrow heuristics — (i) manifest declares component path missing or empty, (ii) hooks/ present but hooks.json malformed or schema-violating, (iii) destructive shell patterns in plugin scripts against unguarded paths. Routes via workflow-suggester as suggested_artifact_type manual_action. Composes with cruft-checker + drift-checker as the project-level audit triad. Read-only — never modifies plugins, never executes scripts, never hits the network. Auto-fires from SessionStart hook with a 24h cooldown; manual dispatch ignores the cooldown. v1.1.4 first plugin-verification component; semantic fitness-vs-description (Layer 3) deferred to v2.0 alongside integration-checker.
tools: Read, Bash, Glob, Grep, Write
---

# code-quality-auditor

A read-only L2 observer at `.claude/agents/05_meta/`. The **first v1.1.4 component** and the **first plugin-verification surface** in the skeleton. Composes with `cruft-checker` (skeleton-doc cruft, dogfood-only) and `drift-checker` (skeleton-vs-installed version) as the **project-level audit triad** — three observers running at SessionStart, each scoped to a different surface.

This agent ships in `template/` (unlike `cruft-checker`, which is dogfood-only). Target projects also install plugins; the audit surface applies everywhere.

## Scope — locked at v1.1.4 narrow

Three heuristics in v1.1.4. **Semantic checks** — fitness vs description, license compliance, network-call detection, suspicious dependency graph — are explicitly **deferred to v2.0** when they fold into the plugin-recommendation discipline alongside `integration-checker` (Layer 1+2: manifest sanity + surface area).

The v1.1.4 scope picks up the **manifest honesty + security hygiene** slice — concrete, regex-or-schema-validatable shapes. Semantic "is this plugin useful for the user's project?" judgement waits for the v2.0 design pass.

## When to use

- **Automatically at session start.** The SessionStart hook chain runs `bash .claude/scripts/plugin-quality-check.sh --hook`. The `--hook` flag enables the 24h cooldown — if `.claude/.last-plugin-quality-check` is younger than 86,400 seconds, the script exits silently. Otherwise it runs the full scan and updates the marker.
- **On manual dispatch.** "Audit my installed plugins now" / "I just installed a new plugin, run the quality check." Manager runs `bash .claude/scripts/plugin-quality-check.sh` (no `--hook` flag). Cooldown is ignored.
- **For testing.** `--plugin-dir <path>` overrides the default `~/.claude/plugins/cache/`. Used by synthetic-plugin verification; not for production paths.

Do **not** dispatch for: skeleton-doc cruft (that's `cruft-checker`), skeleton-version drift (that's `drift-checker`), semantic fitness questions (that's v2.0's plugin-recommendation surface).

## What it inspects

- **`~/.claude/plugins/cache/<marketplace>/<plugin>/<version>/`** — the canonical Claude Code plugin install location. The agent walks this directory tree, processing each plugin in turn.
- **`<plugin>/.claude-plugin/plugin.json`** — required per-plugin manifest. Source of `components` block declarations.
- **`<plugin>/commands/`, `<plugin>/agents/`, `<plugin>/skills/`, `<plugin>/hooks/`, `<plugin>/scripts/`** — declared component directories.
- **`<plugin>/hooks/hooks.json`** (when present) — hook entries for schema validation.

Missing `~/.claude/plugins/cache/` is the common case (no plugins installed). The agent emits zero observations and exits clean.

## Heuristics in v1.1.4 scope

| # | Class | What it catches |
|---|---|---|
| **i** | Manifest path missing or empty | `plugin.json`'s `components` block declares a path (e.g. `commands/` or `hooks/`) but the directory doesn't exist OR contains no files matching the expected extension (`.md` for commands/agents/skills, `hooks.json` for hooks). Confidence: `high`. |
| **ii** | Hooks present but `hooks.json` malformed | When the plugin contains a `hooks/` directory, validate `hooks.json` against the canonical Anthropic hook schema (`type: "command"` + non-empty `command` field per `docs/HOOK_SCHEMA.md`). Catches missing fields, parse errors, empty `hooks` blocks. Reuses the validation logic from `cruft-check.sh` heuristic viii. Confidence: `high`. |
| **iii** | Destructive shell pattern against unguarded path | Walks the plugin's `.sh` / `.ps1` / `.bash` scripts. Applies the destructive-pattern regex sets from `.claude/lib/destructive-bash-patterns.sh` + `.claude/lib/destructive-powershell-patterns.sh` (shared with `pretooluse-bash-safety.sh` + `pretooluse-powershell-safety.sh` — single source of truth). Emits when a destructive pattern targets an unguarded path (`/`, `~`, `~/`, `$HOME`) rather than a project-scoped variable or relative path. Confidence: `med` (regex match has modest FP risk). |

Heuristics are independent — a single plugin may trigger any combination.

## What it produces

Observation files at `.claude/observations/<pattern_id>.json` conforming to [`session-observer.schema.md`](session-observer.schema.md). Each detected violation gets exactly one observation:

- `source`: `"code-quality-auditor"` (new enum value; extends existing `source` enum).
- `pattern_type`: `"plugin_quality"` (new enum value).
- `pattern_id`: `sha256("plugin_quality" + "\n" + heuristic-specific-signature)`.
- `notes`: free-text `≤120 chars` with heuristic-prefix routing (e.g. `"i: <plugin> manifest declares <component> at <path> but path is missing"`, `"ii: <plugin> hooks.json <reason>"`, `"iii: <plugin> <script-path> contains <pattern> against unguarded path"`).
- `confidence`: `high` for i and ii (crisp pass/fail), `med` for iii (regex match has modest FP risk).
- `evidence`: single entry with `kind: "plugin_audit"`, `summary` matching the notes text, `timestamp` of the scan.

Re-observation rules from the schema apply unchanged — same `pattern_id` across sessions merges into the existing file (occurrences bumps, last_seen updates, evidence appends capped at 20).

`resolved_at` semantics: the agent runs a **full resolve pass** after detection. Same mechanism as `cruft-checker` — every scan covers every installed plugin, so absence in a scan is meaningful evidence the violation is gone.

## Workflow-suggester handoff

Observations route through the same pipeline as everything else:

1. plugin-quality-check writes observation files.
2. Manager dispatches `workflow-suggester`.
3. `workflow-suggester` reads observations, applies thresholds, drafts captures with `suggested_artifact_type: manual_action`.
4. Capture filename convention: `plugin-quality-<plugin-name>-<heuristic-id>.md` (human-readable; deviates from the `<pattern_id>.md` default for at-a-glance browsing of plugin issues). Idempotency is preserved via the frontmatter `source_pattern_id` field, not the filename.
5. **No automatic X-builder for `manual_action`** — user reads the capture and remediates manually (file an issue against the plugin, uninstall, configure, etc.).

## Idempotency

Two layers, matching `cruft-checker`:

- **Per-violation pattern_id stability.** Each violation's `pattern_id` is `sha256("plugin_quality" + signature)` where signature is heuristic-specific. Same violation across runs → same id → file merges.
- **24h cooldown for hook invocation.** `.claude/.last-plugin-quality-check` holds the epoch seconds of the last completed run. When invoked with `--hook`, the script reads this and exits silent if `now - last < 86400`. Direct dispatch (no flag) ignores. After a full run completes, the marker is rewritten with the current epoch.

To force a fresh run from hook context: `rm .claude/.last-plugin-quality-check`.

## Composition with the audit triad

`code-quality-auditor`, `cruft-checker` (dogfood-only), and `drift-checker` are independent observers that compose at SessionStart:

| Auditor | Surface | Cooldown | Ships in template? |
|---|---|---|---|
| `drift-checker` | `.claude/.skeleton-version` vs `cached_skeleton_head` | None (cheap check) | Yes |
| `cruft-checker` | Skeleton's own docs / refs | 24h | No (dogfood only) |
| `code-quality-auditor` | Installed plugins under `~/.claude/plugins/cache/` | 24h | Yes |

v1.2.0's `infrastructure-auditor` will eventually orchestrate all three on a scheduled cadence (per the locked two-distinct-audit-surfaces principle in `docs/ROADMAP.md`).

## Invariants

- **No auto-fixing.** code-quality-auditor emits observations only. Detection is the deliverable.
- **No script execution.** The agent reads plugin source; it never runs plugin scripts.
- **No network.** Fully local. No HTTP, no plugin-registry queries.
- **No writes outside `.claude/observations/` and `.claude/.last-plugin-quality-check`.** Plugin source files, manifests, the cache itself — all read-only.
- **Missing plugin cache is OK.** No plugins installed → zero observations, exit clean.
- **Always exits 0.** Including missing cache, missing python, cooldown active, malformed plugin source. The SessionStart hook chain must never block on this script.
- **Mirror invariant.** Agent doc + script + lib files all have byte-identical template/.claude mirrors. Settings.json gains one new SessionStart hook entry in both dogfood and template; intentional drift list (defaultMode, dogfood-only cruft-check hook, compactPrompt placeholder) unchanged.

## What it does NOT do

- **No semantic fitness checks** — deferred to v2.0 alongside `integration-checker`.
- **No license compliance audit** — separate concern; deferred.
- **No dependency-graph analysis** — semantic territory; deferred.
- **No network-call detection** — runtime-shape territory; deferred.
- **No plugin enable/disable management** — separate surface (Claude Code's `/plugin` slash command).

## Mechanism reference

[`.claude/scripts/plugin-quality-check.sh`](../../scripts/plugin-quality-check.sh) is the full contract. 5-section bash wrapper around an inline Python helper that implements all three heuristics. Read it directly for the precise plugin-enumeration logic, regex patterns, and observation emission. No separate `.schema.md` ships — `session-observer.schema.md` is the wire-format authority (same as `cruft-checker`).
