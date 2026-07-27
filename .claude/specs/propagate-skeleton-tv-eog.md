---
id: propagate-skeleton-tv-eog
status: consumed
created: 2026-07-14T04:55:00Z
schedule: 2026-07-15
goal: Propagate skeleton Phases 48-68 to Trainer-View and Echoes-of-Gill via update.sh
---

## Research findings

- The delta is every `[Unreleased]` CHANGELOG entry from Phase 48 through 68:
  token-cost surface, optimizer, artifact-fit, update-pipeline integrity
  fixes, telemetry hardening, docs truth sweep, schema cleanup, sitting-delta
  cost line, watchdog dedup, and the /goals pipeline. Template inventory is
  now 75 files (`find template/.claude -type f ! -name .gitkeep`).
- The path is `bash <skeleton-checkout>/scripts/update.sh` run from inside
  each target (docs/INSTALLATION.md). `install.sh` refuses on installed
  targets (Phase 62) — update.sh is the only route.
- The updater the targets will meet is materially safer than at their last
  update: rebase-only runs persist (62), `--check-remote` preserves install
  identity (62), stale-but-matching baselines self-heal (59), and all of it
  is CI-guarded.
- LOCALLY_MODIFIED protection is per-file `[K]eep` default — TV's
  hand-tuned surfaces survive untouched (precedent: the Phase 4f migration's
  14-file skip list matched predictions exactly).
- Phase 66 semantics shift: TV's `warn_usd_per_session: 3900` and EoG's
  `200` were tuned against CUMULATIVE lineage figures; after this propagates
  the compared quantity is the per-sitting delta, so both values should be
  re-read once sitting-scale numbers flow (CHANGELOG Phase 66 flag).
- EoG contingency (standing, from the Phase 48 propagation brief): if EoG
  has unpushed local commits, proceed with the propagation but HOLD the push.
- Phase 67 matters to both installs: their watchdogs have been silently
  double-counting on resumed lineages; the fix rides this pass.

## Locked decisions

- (Spec review, 2026-07-14) `update.sh --check-remote` runs as STEP ONE of
  each leg — Phase-62-fixed and CI-guarded, costs seconds, and silences the
  drift-checker's empty-cache nag with a truthful answer instead of a
  standing lie-by-omission.
- (Spec review, 2026-07-14) `warn_usd_per_session` retuning WAITS for
  sitting-scale data — retune per install after ~a week. Retuning at
  propagation time guesses the distribution the measurement fix exists to
  measure (the P1-rejection discipline applied to its own descendant); the
  interim over-threshold markers, or silence, are honest signal, not a
  defect.
- update.sh from inside each repo's own session; never install.sh.
- Order: Trainer-View first (largest customization surface — best early
  signal on LOCALLY_MODIFIED handling), then Echoes-of-Gill, staggered so
  the observation streams don't share noise (the Phase 35 pattern).
- The EoG hold-push contingency stands as written.
- No VERSION bump rides along — the delta is [Unreleased] on v1.1.4. <!-- cruft-check:exempt-historical -->

## Deliverable shape

Per install: one clean `update.sh` run — TEMPLATE_UPDATED applied, NEW
copied, LOCALLY_MODIFIED kept unless deliberately reviewed, ORPHANs decided
per prompt; marker `install_uuid`/`install_label`/`install_created`
byte-stable across the run; a follow-up `--dry-run` reporting zero pending;
first SessionStart afterward showing the sitting-delta cost line and the
four-job rules chain. Record what was seen (counts, kept files, cost line)
in the target's own notes.

## Constraints

- User-driven, from each target's own tab — the skeleton session never
  mutates a target repo.
- No hand-edits to either marker; all baseline writes through update.sh's
  guarded path.
- LOCALLY_MODIFIED is never auto-applied; `--auto-apply`, if used, covers
  only TEMPLATE_UPDATED + NEW (per the corrected help text).

## Open questions

None — both resolved at spec review (2026-07-14) and recorded in Locked
decisions above.

## Consumption record (2026-07-14)

- Trainer-View leg: landed at `ae642bc`.
- Echoes-of-Gill leg: landed at `7ecd96c` (LOCAL — push held per the
  standing contingency, unpushed backlog present in that repo).
- Follow-up carried by Locked decisions: per-install `warn_usd_per_session`
  re-read after ~a week of sitting-scale data.
