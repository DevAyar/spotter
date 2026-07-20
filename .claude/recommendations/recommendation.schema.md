# recommendation schema

The contract for one per-install plugin recommendation manifest at
`.claude/recommendations/manifest.md`, created and refreshed by
`plugin-discovery-agent` via `scripts/plugin-discovery.sh` (Phase 76) and
judged later by the plugin-context-matcher (Phase 77). Design principle:
**not a directory, a quality filter — the schema exists to carry reasons,
both directions.** A recommendation without a reason is noise; a rejection
without a reason fails the schema.

## File format

UTF-8 markdown with YAML frontmatter delimited by `---` lines. One manifest
per install, refreshed in place. The manifest is **runtime output, not
source-of-truth** — gitignore `.claude/recommendations/manifest.md` in the
consuming repo (a full refresh rewrites hundreds of entries; the diff churn
carries no information). This schema file beside it is the tracked contract.

## Frontmatter

| Field | Type | Required | Description |
|---|---|---|---|
| `status` | string enum | yes | `draft` (discovery output, unjudged) \| `reviewed` (a human has been through it). Discovery always writes `draft`; only a human review flips `reviewed`, and the next refresh honestly resets it to `draft`. |
| `generated` | string (ISO-8601 UTC) | yes | Timestamp of the last refresh. |
| `generator` | string | yes | Producing mechanism + phase, e.g. `plugin-discovery.sh (Phase 76)`. |
| `marketplaces_scanned` | int | yes | Count of marketplace clones actually read. `0` with a note in the body is an honest output — an empty machine is not an error. |
| `plugins_indexed` / `candidates` / `installed` | int | yes | Entry counts by disposition. After a matcher pass (Phase 77) the frontmatter also carries `recommended` and `not_recommended` counts. |
| `stack_markers` | list of strings | yes | Stack-evidence **files found at the project root** (e.g. `package.json`, `pyproject.toml`, `VERSION`, `.github/workflows`). Mechanical file-evidence only — never inferred from prose. An empty list is honest. |
| `claude_inventory` | map | yes | Counts of this install's `.claude/` tree: `agents`, `scripts`, `hooks`, `skills`, `commands`, `audits_registered` (keys under gate-config `audits`). |
| `observation_profile` | map | yes | Producer → count histogram over `.claude/observations/*.json` `source` fields. `{}` when no observations exist. |
| `discipline_preferences` | string (block) | yes | **User-owned free text.** What disciplines should plugins respect here (e.g. "no network at session seams", "draft-only writers"). Discovery writes a placeholder once at manifest creation and **never touches the block again** — every refresh preserves it verbatim. This is the human's channel into Phase 77 matching. |

## Body — one entry per plugin, grouped by marketplace

Each plugin is a `### <name>` block of `- key: value` lines.

| Field | Required | Description |
|---|---|---|
| `status` | yes | `candidate` \| `recommended` \| `not_recommended` \| `installed`. **Discovery emits only `candidate` and `installed`** — the verdict statuses are matcher territory (Phase 77), applied with human review, never by inventory. An installed plugin enters as `installed`, never `candidate`. |
| `source_class` | yes | `repo_hosted` (marketplace.json `source` is an in-repo path string; the plugin's full source is readable pre-install inside the marketplace clone) \| `external_sha` (`source` is an object — `git-subdir` / `github` / `url` — pinning an external repo at a sha; the source is **not** readable offline) \| `unindexed` (installed-only: the plugin's marketplace clone is absent, so its source declaration is unreadable — claiming either other class would be invented evidence). |
| `version` | no | **Optional by design.** Most official plugins publish no version (155 of 168 at Phase 76 recon); absence is normal and never an error. Installed entries carry the version from the install registry when it exists. |
| `category` | no | Verbatim from the marketplace entry when present. |
| `evidence` | yes | Where this entry mechanically comes from: the marketplace.json path plus entry name, or (for installed) the installed_plugins.json key. Every entry is traceable to a file actually read. |
| `summary` | no | Marketplace description, truncated. Evidence for the matcher, not judgment. |
| `reason` | conditional | **REQUIRED on `recommended` AND `not_recommended`** — a rejection without a reason fails the schema exactly as a recommendation without one does. Absent on `candidate` and `installed` (nothing has been judged yet). |
| `candidate_audit` | no | Written by the matcher (Phase 77): `clean (i/ii/iii pass on pre-install source)` \| `N finding(s)` (repo-hosted, from `plugin-quality-check.sh --candidate-plugin`) \| `deferred (source_not_inspected_offline)` (external-sha / unindexed — never guessed) \| `error (…)` when the audit could not run. |

`external_sha` entries additionally carry all three of:

- `source_url` — the external repo (from `url` or `repo`).
- `pinned_sha` — the pinned commit.
- `source_not_inspected_offline: true` — the honesty marker. This class
  cannot be read pre-install without a network fetch, and discovery never
  fetches; any later verdict on such an entry must disclose that limit.

Installed entries carry `installed_at` and `install_scope` from the
registry when present. Installed plugins whose marketplace clone is absent
still appear, under an "installed (unindexed)" group — installed state
comes from the registry, not from the index.

## Lifecycle (the approval gate is load-bearing)

Discovery (Phase 76) creates and refreshes: everything enters as
`candidate` or `installed`, `status: draft`. The matcher (Phase 77)
proposes verdicts **with reasons**, still draft. A human reviews;
`/plugin` remains the only install path — no component of this pipeline
installs, enables, or fetches anything, ever.
