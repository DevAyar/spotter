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

## Update an existing install

```bash
bash <path-to-claude-skeleton>/scripts/update.sh
```

The updater reads `.claude/.skeleton-version`, compares each file in
`.claude/` against the current template, and walks you through:

- **New files** in the template → "copy all?" prompt.
- **Differing files** → "[A]pply all / [R]eview individually /
  [S]kip all" — review mode shows a `diff -u` per file before deciding.

Add `--auto-apply` to skip the per-category prompt and apply all
template diffs without asking (new files still confirm once;
conflicts still prompt).

### v1 limitation

`update.sh` cannot reliably distinguish "you modified this file" from
"the template moved on since your install" without per-file hashes in
`.skeleton-version`. v1 treats any diff as "needs review" — the diff
is always shown before any overwrite. Per-file hashing lands in v2.

Top-level files (`CLAUDE.md`, etc.) are not updated by `update.sh` —
they're project-specific. Re-run `install.sh` manually if you want
to refresh them.

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
