---
description: Turn off cross-project git memory for this install (Phase 47a). Stops future pushes; data already on the remote is untouched.
allowed-tools: Bash(.claude/scripts/share-disable.sh:*)
---

Disable cross-project git memory for THIS install. Run:

`bash .claude/scripts/share-disable.sh`

Report the output verbatim. This flips `.claude/share-config.json` to
`enabled: false` and stamps `disabled_at`, preserving `remote_url` and
`enabled_at` as an audit trail. No future pushes occur. Data already on the
remote is NOT removed — a `--purge-remote` flag is deferred to a future phase
(47c+). If share mode was never configured, the script says so and exits cleanly.
