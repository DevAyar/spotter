---
description: Maintainer review of cross-project shared-memory events (skeleton dogfood only, Phase 47d) — grouped report for manual graduation pattern-spotting. Read-only.
allowed-tools: Bash(.claude/scripts/graduation-review.sh:*)
---

Skeleton-maintainer tool (dogfood only — not shipped to installs). Read the
cross-project shared-memory events across installs and print a grouped review
report. Run:

`bash .claude/scripts/graduation-review.sh`

Report the output verbatim. It reuses the share clone, then groups captures by
`suggested_artifact_type` and observations by `pattern_type`, with per-install
counts and overlap stated against the 15-install / 75% graduation threshold.
Read-and-report ONLY — it drafts no captures, promotes nothing, suggests nothing;
the maintainer does the pattern-spotting. If share mode is off it says so and
exits 0.
