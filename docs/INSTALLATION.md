# Installation

How to install Spotter (engine `claude-skeleton`) into a target project, update an
existing install, or uninstall it.

The install flow is non-destructive by default: it adds missing files
and never overwrites existing ones unless you explicitly opt in to
`--mode=replace` with `--force` and an interactive confirmation.

## Quick install

From inside the target project (any git repository):

```bash
curl -sL https://raw.githubusercontent.com/DevAyar/spotter/main/scripts/install.sh | bash -s -- --mode=merge
```

This is the safe default — adds any missing `.claude/` content,
leaves your existing files untouched.

## Local install

If you have `claude-skeleton` checked out locally:

```bash
bash <path-to-claude-skeleton>/scripts/install.sh --mode=merge
```

The script auto-detects the skeleton checkout by walking up from its
own path, so the simpler form works too:

```bash
cd <target-project>
bash /path/to/claude-skeleton/scripts/install.sh
```

## Modes

| Mode | Behavior | Use when |
|---|---|---|
| `--mode=fresh` | Refuses unless target's `.claude/` is empty (only `.gitkeep` allowed). Then copies everything. | Brand-new project, no prior `.claude/`. |
| `--mode=merge` (default) | Copies only files that don't already exist. Skips silently when target has the file. | The common case. Safe by default. |
| `--mode=replace` | Overwrites existing files. Requires `--force` AND an interactive `YES` confirmation. | You explicitly want to refresh files you know you haven't customized. |

Top-level files (`CLAUDE.md`, `README`, `.gitignore`, etc.) are
**never** overwritten regardless of mode — only `.claude/` obeys mode
semantics. And since Phase 62, `install.sh` refuses to run at all on a
target that already has `.claude/.skeleton-version` — install is
first-time-only; updating an existing install is `update.sh`'s job.

### Skeleton-on-skeleton self-install

For developers working on `claude-skeleton` itself, the `--claude-only`
flag installs only the `.claude/` contents and skips top-level
`*.template` files (which would land as placeholder-laden `CLAUDE.md`
otherwise):

```bash
bash scripts/install.sh --mode=merge --claude-only
```

The script refuses self-install (source == target) without
`--claude-only` as a guardrail.

## Dry run

Preview the install plan without touching anything:

```bash
bash scripts/install.sh --dry-run [--mode=...] [--claude-only]
```

The output lists every file that would be copied (`+`), skipped (`=`),
or overwritten (`~`).

## Important: subagent registration requires session restart

Claude Code discovers subagents from `.claude/agents/` at session
start. Newly-installed subagents from claude-skeleton are present on
disk immediately after install but are **not** yet dispatchable in
your current Claude Code session.

To activate the newly-installed agents:

1. Complete the install (or `update.sh` run).
2. Close your current Claude Code session.
3. Reopen Claude Code in the same project.
4. Newly-installed agents now appear in the subagent registry.

Skills and slash commands **do** pick up in the same session — only
subagents need a restart.

If you dispatch a newly-installed subagent before restarting, Claude
Code falls back to the `general-purpose` agent with the agent's
contract inlined. This works but costs more tokens (the contract
isn't cached as a registered agent).

Validated by three real-world migrations: Phase 3 PolyClaude trial in
Trainer-View, Phase 4c skeleton-on-skeleton dogfood in this repo,
Phase 4f Trainer-View migration to claude-skeleton.

## Update an existing install

```bash
bash <path-to-claude-skeleton>/scripts/update.sh
```

The updater reads `.claude/.skeleton-version`, classifies every
file in `.claude/` against the current template using SHA-256
hashes, and walks you through each category.

### How `update.sh` classifies changes

Each installed file is one of:

| Class | Meaning | Default action |
|---|---|---|
| **UNCHANGED** | Matches its raw template baseline and the current template. | Skip silently. |
| **TEMPLATE_UPDATED** | Matches its install baseline; template moved on. | `[A]pply all / [R]eview / [S]kip all`. |
| **LOCALLY_MODIFIED** | Differs from the template it was installed from — whoever changed it (you, the tuner, or both). | Per-file prompt, default `[K]eep`. Never auto-updated. |
| **NEW** | Template has it; you don't. | `Copy all? [Y/n]`. |
| **ORPHAN** | You have it (in marker); template no longer ships it. | `Delete? [y/N]`. |

`--auto-apply` accepts `TEMPLATE_UPDATED` and `NEW` automatically.
It **never** applies to `LOCALLY_MODIFIED` or `ORPHAN` — those
always require explicit input.

Top-level files (`CLAUDE.md`, etc.) are not updated by `update.sh` —
they're project-specific. Refreshing them on an installed target is
currently **manual** (copy what you want from the skeleton's
`template/` by hand): `install.sh` refuses to re-run on an installed
target (Phase 62). If a from-scratch reinstall is genuinely intended,
the escape hatch is deleting `.claude/.skeleton-version` first — be
aware this mints a new install identity, resets per-file baselines,
and orphans any shared-memory history keyed to the old uuid. The
missing top-level refresh path is a known limitation.

### Per-file baselines in `.skeleton-version`

`install.sh` records, for every `.claude/` file it writes, the SHA-256
of the template version it was installed from — the file's **raw
template baseline** (`raw_template_baselines` in `.skeleton-version`).
`update.sh` compares three hashes per file — that baseline, the
current on-disk content, and the current template — so "safe to
update" vs "you've changed this, review first" is a reliable
distinction.

`LOCALLY_MODIFIED` therefore means a file differs from the template
version it was installed from, regardless of who changed it
(`project-tuner-helper`, you, or both) — which is what keeps tuner
customizations from being overwritten by a generic template.

The baseline is immutable per file (re-stamped only when a file is
written from the template on apply). An older `files` map is retained
as a deprecated back-compat alias, no longer used for classification;
removal is queued for a later release. Markers created before
`raw_template_baselines` existed are migrated once, inline, on the next
`update.sh` run by re-hashing the template at the recorded install
commit.

The marker also carries three **install-identity** fields (Phase 47a):
`install_uuid` (a UUID v4 generated once at install time, immutable),
`install_label` (human-readable, defaults to the install directory's
basename — edit it by hand in `.skeleton-version` for now), and
`install_created` (ISO-8601 timestamp of first write). `install.sh`
writes all three on a fresh install; `update.sh` backfills them once,
inline and silently, for markers created before Phase 47a, and never
regenerates an `install_uuid` that is already present. They identify
this install to the optional cross-project memory bus (see § Share mode
opt-in) and are otherwise inert.

The marker is JSON; parsing requires `python` (or `python3`) on
`PATH`. Git Bash for Windows ships with Python 3 in most installs;
if missing, install Python 3 and rerun. `jq` is **not** required by
`install.sh` / `update.sh`, but **is** required by the SessionStart
hook (`sessionstart-rules.sh`) — missing jq just disables rule
re-injection and drift surfacing; the session still starts cleanly.

### Drift cache (`cached_skeleton_head`)

The marker carries two optional fields used by `drift-checker`:

- `cached_skeleton_head` — last known remote release as a semver
  string (e.g. `"1.0.0"`), or `null` if never refreshed.
- `cached_skeleton_head_fetched_at` — ISO-8601 timestamp of when the
  cache was last refreshed, or `null`.

Both default to `null` on fresh installs and after legacy-marker
backfill. They are read by `.claude/scripts/drift-check.sh` at
session start to surface a "you're behind, run update.sh" notice
when the installed `version` differs from the cached value.

**`drift-checker` and `drift-check.sh` never hit the network and
never write the marker.** The exclusive path that touches the
network for drift purposes is:

```bash
bash <path-to-claude-skeleton>/scripts/update.sh --check-remote
```

This runs `git ls-remote --tags` against the skeleton repo
(10-second timeout), picks the highest semver tag, writes
`cached_skeleton_head` + `cached_skeleton_head_fetched_at`, and
prints what it found. No diff/classification flow runs in
`--check-remote` mode — it's a single-purpose, explicit, user-
invoked refresh. Network failure leaves the marker untouched.

Refresh the cache periodically (weekly is a reasonable cadence);
drift-checker reads whatever was last cached.

### First update after 0.8.0 (one-time backfill)

Markers created by claude-skeleton < 0.8.0 use a shell-format
key:value schema with no per-file hashes. On first run with such a
marker, `update.sh` enters **BACKFILL MODE**:

- Prints a prominent warning that pre-existing local modifications
  cannot be detected.
- Force-disables `--auto-apply` for this run.
- Treats every currently installed file as if it were pristine
  (recorded := current hash).
- Files differing from the template are classified as
  `TEMPLATE_UPDATED` — **including** any local modifications you
  made before 0.8.0. Review individually if you have known local
  changes.
- After the run, the marker is migrated to JSON with per-file
  hashes. Subsequent runs use precise classification.

If you have important local modifications and want to preserve
them across the 0.8.0 migration, either commit them before
running `update.sh` (so you can see them in the diff) or accept
the warning and use `[R]eview individually` to spot them.

## Share mode opt-in

claude-skeleton can optionally feed a **cross-project git memory bus** —
a git remote, controlled by you, that your installs push install-identity
sentinels to. The trust model is single-user-multi-install: one person's
installs to one of that person's own remotes. It is **off by default**;
nothing is shared until you opt in.

Phase 47a shipped identity + opt-in; **47b** the producers; **47c** the
push cadence. When share is enabled,
`.claude/scripts/shared-memory-produce.sh` writes redacted JSON events
into a local staging tree at `.claude/shared-memory/`
(`<producer>/<install_uuid>/<date>/`) for captures, observations,
telemetry, and version — and at every **SessionEnd**, the
`sessionend-observe.sh` hook runs
`.claude/scripts/shared-memory-push.sh`, which pushes those events to
your remote **only if something changed** since the last push. The push
is fail-soft: an unreachable remote never blocks or delays session end —
the next SessionEnd (or a manual `/share-push`) retries and catches up.
Nothing beyond the redacted envelopes is sent. Envelope contract:
`.claude/lib/shared-memory.schema.md`.

Five commands manage it:

- `/share-enable <remote-url>` — opt in. Clones the remote, initializes
  the shared tree if it is an empty bare repo, writes a sentinel at
  `installs/<install_uuid>/sentinel.json`, and — after you type the
  literal word `enable` — commits and pushes it, then writes
  `.claude/share-config.json`. Needs `install_uuid` in the marker (run
  `update.sh` first if it is missing).
- `/share-push` — push now instead of waiting for the SessionEnd push.
  Same on-change gate, same fail-soft behavior — it only changes *when*
  the push runs.
- `/share-preview` — dry-run of the next push: runs the real flow but
  stops before the commit/push, reporting the would-include file count,
  a per-producer breakdown, and one sample path. The remote is
  untouched.
- `/share-disable` — stop future pushes. Flips `share-config.json` to
  `enabled: false` and stamps `disabled_at`, preserving `remote_url` and
  `enabled_at`. Plain disable leaves data already on the remote
  untouched; `--purge-remote` additionally deletes **this install's**
  `installs/<install_uuid>/` subtree from the remote after you type the
  literal word `purge` — other installs' data is never touched.
- `/share-status` — report current state (configured / enabled /
  disabled, remote URL, timestamps, install UUID + label). Read-only.

`.claude/share-config.json` is created on the first successful
`/share-enable` and is **not** part of the installed template — its
absence means "not configured." Schema:

```json
{
  "schema_version": 1,
  "enabled": true,
  "remote_url": "<git-pushable-URL>",
  "enabled_at": "2026-01-01T00:00:00Z",
  "disabled_at": null
}
```

The sentinel written to the remote carries `schema_version`,
`install_uuid`, `install_label`, the skeleton `version` / `commit`
(marker-native field names — no translation layer), and a
`sentinel_timestamp`.

## Uninstall

There is no `uninstall.sh` in v1. To remove:

```bash
rm -rf .claude/
rm -f CLAUDE.md CLAUDE_MANAGER.md ROUTING.md PLUGINS.md
# also any docs/STATUS.md, docs/SESSION_LOG.md, docs/ARCHITECTURE.md
# created during install
```

Project-level customizations (anything `project-tuner-helper`
generated) live in those same files, so uninstall is irreversible
unless you've committed first.

## Troubleshooting

**"not a git repository"** — `install.sh` requires the target to be a
git repo. Either run `git init` first, or pass `--target <path>`
pointing to a different git repo.

**"--mode=fresh refused: target .claude/ already has content"** —
working as intended. `--mode=fresh` is strict by design. Use
`--mode=merge` (default) instead.

**"source == target ... use --claude-only"** — you're running the
installer with the skeleton repo as both source and target. The
guardrail is intentional. Add `--claude-only` for the dogfood case.

**"target has no .claude/.skeleton-version — not a claude-skeleton
install"** — `update.sh` only operates on installs that have a
version marker. Run `install.sh` first.

**Bash refuses to execute `install.sh`** — Windows editors may rewrite
LF line endings to CRLF, breaking the shebang line. The skeleton's
`.gitattributes` forces LF for `*.sh` to prevent this. If you copied
the script through a non-git path, check with `file install.sh`; if
it reports CRLF, re-checkout with `git checkout --renormalize`.

**Mid-install error** — `install.sh` rolls back every file it added
before exiting non-zero. Your `.claude/` returns to its pre-install
state. Diagnose the error, fix, re-run.

## After install

Two follow-up agents handle the post-install customization:

- **`integration-installer`** — handles judgment-driven aspects of
  the install (mode selection, conflict resolution). Optional;
  `install.sh` is self-contained.
- **`project-tuner-helper`** — inspects the target project after
  install, recommends placeholder fills for the seven `{{...}}`
  placeholders in `CLAUDE.md`, `CLAUDE_MANAGER.md`, and `ROUTING.md`
  (`settings.json` ships a generic compactPrompt default the tuner
  refines rather than a placeholder, Phase 72), and generates
  approved customizations.

Both are documented in [`ARCHITECTURE.md`](ARCHITECTURE.md#install-flow).

## CI

The `install.sh` / `update.sh` install path is exercised on every
push to `main` and every PR via GitHub Actions, across
`ubuntu-latest`, `windows-latest`, and `macos-latest` runners. The
scenarios live in
[`.github/test-fixtures/scenarios.sh`](../.github/test-fixtures/scenarios.sh)
and cover: fresh install, `--mode=fresh` refusal on a populated
target, `--mode=merge` re-adding a deleted file without touching
neighbors, `LOCALLY_MODIFIED` detection in `update.sh --dry-run`,
`[K]eep` actually preserving local bytes, and the 0.8.0 backfill
migration from the legacy shell-format marker to JSON.

If you change either script or the template, CI catches it before
merge. The current state of `main` is shown by the badge at the top
of [`README.md`](../README.md).

## Related

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — project layout and the
  two-stage install flow.
- [`PHILOSOPHY.md`](PHILOSOPHY.md) — the non-destructive install
  rule and other principles.
- [`CHANGELOG.md`](CHANGELOG.md) — version history.
