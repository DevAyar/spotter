---
description: Show cross-project git memory state for this install (Phase 47a) — enabled/disabled, remote URL, timestamps, install UUID + label.
allowed-tools: Bash(.claude/scripts/share-status.sh:*)
---

Report cross-project git memory state for THIS install. Run:

`bash .claude/scripts/share-status.sh`

Report the output verbatim. It reads `.claude/share-config.json` (opt-in state)
and `.claude/.skeleton-version` (install identity). If share mode was never
configured, it says so and points at /share-enable. Read-only — it changes
nothing.
