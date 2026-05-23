---
description: Turn off cross-project git memory for this install (Phase 47a). Optionally --purge-remote to also delete this install's files from the shared repo (Phase 47c-2).
allowed-tools: Bash(.claude/scripts/share-disable.sh:*)
argument-hint: "[--purge-remote]"
---

Disable cross-project git memory for THIS install.

**Plain disable** (default) — stop future pushes, leave already-pushed data on the
remote, no confirmation. Run:

`bash .claude/scripts/share-disable.sh`

Report the output verbatim. It flips `.claude/share-config.json` to
`enabled: false` and stamps `disabled_at`, preserving `remote_url` + `enabled_at`
as an audit trail. If share mode was never configured, it says so and exits cleanly.

**Purge** (`$ARGUMENTS` contains `--purge-remote`) — additionally DELETE this
install's own files from the shared remote (its `<producer>/<uuid>/` subtrees +
`installs/<uuid>/`), then disable. Other installs' data is untouched. Because this
removes already-committed files, it requires explicit confirmation:

1. Surface the warning and require the literal word `purge`:

   > About to permanently remove THIS install's files from the shared remote and
   > then disable share mode. Other installs' data is untouched. Reply `purge` to
   > confirm, or anything else to cancel.

2. Only after the user replies `purge`, run:

   `printf 'purge\n' | bash .claude/scripts/share-disable.sh --purge-remote`

Report the output verbatim. It clones the remote, removes this install's
uuid-keyed paths, pushes the deletion (bounded retry, fail-soft), then disables.
On a failed push it leaves the feature ENABLED so you can retry. If this install
never pushed anything, the deletion is a clean no-op and it disables normally.
