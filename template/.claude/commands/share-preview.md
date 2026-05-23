---
description: Dry-run preview of the next cross-project push (Phase 47c-2) — what shared-memory events would be sent, without committing or pushing.
allowed-tools: Bash(.claude/scripts/shared-memory-push.sh:*)
---

Preview what the next cross-project shared-memory push would include — WITHOUT
committing or pushing anything. Run:

`bash .claude/scripts/shared-memory-push.sh --preview`

Report the output verbatim. It runs the same flow as a real push (ensure the
local clone, run the producer) but stops before the commit/push and instead
reports the would-include file count, a per-producer breakdown, and one sample
path — then discards the working changes, so the remote is untouched. Because
preview is the real flow minus the final step, the report is exact.

If share mode is not enabled it says so and exits 0.
