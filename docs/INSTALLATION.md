# Installation

How to install `claude-skeleton` into a target project, update an
existing install, or uninstall it.

The install flow is non-destructive by default: it adds missing files
and never overwrites existing ones unless you explicitly opt in to
`--mode=replace` with `--force` and an interactive confirmation.

## Quick install

From inside the target project (any git repository):

```bash
curl -sL https://raw.githubusercontent.com/DevAyar/claude-skeleton/main/scripts/install.sh | bash -s -- --mode=merge
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
semantics. Re-running install never clobbers project-level docs.

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
| **UNCHANGED** | Recorded hash == current == template. | Skip silently. |
| **TEMPLATE_UPDATED** | You haven't touched it; template moved on. | `[A]pply all / [R]eview / [S]kip all`. |
| **LOCALLY_MODIFIED** | You've changed it since install. | Per-file prompt, default `[K]eep`. Never auto-updated. |
| **NEW** | Template has it; you don't. | `Copy all? [Y/n]`. |
| **ORPHAN** | You have it (in marker); template no longer ships it. | `Delete? [y/N]`. |

`--auto-apply` accepts `TEMPLATE_UPDATED` and `NEW` automatically.
It **never** applies to `LOCALLY_MODIFIED` or `ORPHAN` — those
always require explicit input.

Top-level files (`CLAUDE.md`, etc.) are not updated by `update.sh` —
they're project-specific. Re-run `install.sh` manually if you want
to refresh them.

### Per-file hashes in `.skeleton-version`

`install.sh` records a SHA-256 hash of every `.claude/` file it
writes into `.skeleton-version`. `update.sh` uses three hashes per
file — recorded-at-install, current-on-disk, current-in-template —
to distinguish your local edits from upstream changes precisely.
That's what makes "this file is safe to update" vs "you've changed
this, review first" a reliable distinction.

The marker is JSON; parsing requires `python` (or `python3`) on
`PATH`. Git Bash for Windows ships with Python 3 in most installs;
if missing, install Python 3 and rerun. `jq` is **not** required.

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

## Uninstall

There is no `uninstall.sh` in v1. To remove:

```bash
rm -rf .claude/
rm -f CLAUDE.md CLAUDE_MANAGER.md ROUTING.md
# also any docs/STATUS.md, docs/SESSION_LOG.md created during install
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
  install, recommends placeholder fills for the nine `{{...}}`
  placeholders in `CLAUDE.md`, `CLAUDE_MANAGER.md`, `ROUTING.md`,
  and `settings.json`, generates approved customizations.

Both are documented in [`ARCHITECTURE.md`](ARCHITECTURE.md#install-flow).

## Related

- [`ARCHITECTURE.md`](ARCHITECTURE.md) — project layout and the
  two-stage install flow.
- [`PHILOSOPHY.md`](PHILOSOPHY.md) — the non-destructive install
  rule and other principles.
- [`CHANGELOG.md`](CHANGELOG.md) — version history.
