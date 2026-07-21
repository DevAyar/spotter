# Reviewer-behavior experiment — design (Phase 54)

**DESIGN LOCKED 2026-07-07 — pre-data; no extraction has run.** Successor to
the confidence experiment (`experiments/confidence/`, resolved RED per its
pre-committed gate — see `ANALYSIS.md` there). Same house rule applies:
**write/read this first** — the verdict language below governs how results
may and may not be used, and it is locked before any data exists precisely
so the data cannot bend it. Design only: nothing in this phase ships
instrumentation, extraction scripts, or optimizer changes. Dogfood-only
(`experiments/` is skeleton-root; no template mirror, no propagation).

## The question

Does the skeleton's approval friction produce **genuine review**, or
**reflexive approval**? Every draft-only surface this project ships —
captures, re-tier proposals, optimizer proposals, update.sh decisions,
plan-mode gates — rests on the same assumption: that a human at the gate
is *deciding*, not just clicking through. That assumption is the wedge's
proof point: the regulate-the-human half of the system is only worth
building if friction at the gates actually buys deliberation. This
experiment tests whether the assumption is *measurable from this install's
own history* — not whether it is true in general (see the scope caveat
under the verdicts).

## Two phases

**Phase 1 — RETROSPECTIVE.** Extract approval events from history that
already exists: status flips in the git history of the proposal ledgers
and captures files, update.sh accept/reject traces, and plan-mode approval
timing from transcript-derived timestamps (task-watchdog's surface —
consumed, as always, via what already lands in telemetry and observations,
never by reading transcripts directly here). The key property: this
baseline is **Hawthorne-clean** — the behavior predates any measurement
intent, so the act of measuring cannot have changed it. (Hawthorne effect,
plain English: people behave differently when they know they're being
watched.)

Phase 1 extraction does **not** run at design time. Several surfaces are
younger than the question (current event counts are in the feasibility
table below); the baseline accrues as the ledgers get used. Locking the
design now is what makes the verdict language predate the data.

**Phase 2 — PROSPECTIVE.** The same closed signal set, computed over a
live window and compared against the Phase 1 distributions. Stated
plainly: Phase 2 is **Hawthorne-exposed** — by then the reviewer knows
these signals exist (this document is in the repo they review). A
Phase 1 / Phase 2 divergence is therefore itself a finding about
measurement exposure, not only about friction.

## Mechanical signal set (closed list — these six, nothing else)

Model self-assessment is banned as an evidence source in this experiment,
as everywhere in this surface (recorded basis:
`experiments/confidence/ANALYSIS.md`, zero-variance RED verdict, 2026-07).
Every signal names its file-level source. Every approval event carries a
**stakes tag** from the operation-tier classification (`docs/ROADMAP.md`
§ Appendix — operational design principles), so latency-vs-stakes
correlation is computable. Coarse tag mapping: ledger status flips and
gate-config value edits → the tier of the change they authorize (directive
edits ≈ tier 3); update.sh overwrite accepts → tier 3; hook disables →
tier 3 by the published classification (a repo-file write), noting that
their guard-rail semantics argue for reading them with elevated attention
regardless of tier. The mapping is part of this design and can be refined
before Phase 1 runs — but only toward the published tier definitions,
never ad hoc.

1. **Decision latency** *(latency-class)* — time from surfaced to flip per
   approval event. Surfaced = the commit that folds a proposal into its
   ledger (or lands a capture as `draft`); flip = the commit that changes
   its `status`. Source: `git log` over
   `.claude/telemetry/optimizer-proposals.json`,
   `.claude/telemetry/retier-proposals.json`, `.claude/captures/*.md`, and
   `.claude/specs/*.md` status flips *(admitted by the 2026-07-21
   amendment below)*.
2. **Batch-flip detection** — k status flips inside one edit window (one
   commit). **Worked example — and the signal's confound demonstration:**
   `d8c6277` flips 3 statuses in a single commit, so batch-flip flags it;
   but the codified apply-after-approval flow *batches flips into the
   landing commit by design*, so k-flips-per-commit conflates workflow
   shape with reviewer behavior. The same commit's disposition mix
   (1 rejected, reason recorded) and draft-edit distance (1 applied
   recalibrated ≠ draft) exonerate it as considered review. **Design rule:
   batch-flip is never read alone — it routes to joint reading with
   signals (iii) and (iv).** Source: per-commit diffs of the ledger and
   capture files, and of `.claude/specs/*.md` *(admitted by the 2026-07-21
   amendment below)*.
3. **Disposition mix per surface** — approve / reject / modify rates for
   each gate surface. A surface that only ever approves is a
   rubber-stamp candidate; a mix with recorded rejections and
   modifications is review-shaped. Source: `status` and `review_note`
   fields in the ledgers; capture frontmatter statuses; spec frontmatter
   statuses *(admitted by the 2026-07-21 amendment below)*; update.sh
   traces (see feasibility — partial).
4. **Draft-edit distance** — the applied text versus the original draft:
   verbatim application vs engaged modification. The existing
   `review_note` convention (verbatim vs recalibrated-per-review) is the
   worked example. Source: ledger `draft` fields vs the applied text in
   the git history of the target files; spec body at `draft` vs at
   `approved` *(admitted by the 2026-07-21 amendment below)*.
5. **Plan-mode dwell** *(latency-class)* — gaps between ExitPlanMode
   events and the next tool event, from telemetry event timestamps.
   Known confound, named at design time: the gap conflates deliberation
   with walk-away in multi-day sessions, so dwell is read jointly with
   event context, or not at all. (The raw material exists: the optimizer
   ledger's evidence lines record 80 ExitPlanMode events in the current
   window — `.claude/telemetry/optimizer-proposals.json`.) Source:
   `.claude/telemetry/events/*.jsonl` (`timestamp`, `tool_name`).
6. **Override / disable events** — hand-edits to `.claude/gate-config.json`
   (git history), hook removals or disables (diffs of `settings.json`
   hook entries), and `--force`-class bypasses. This is the key metric the
   risk-calibrated-friction mechanics need (override/disable rate).
   Source: git history of the two config surfaces; `--force` detection is
   **DEFERRED** — telemetry events carry no command arguments (see
   feasibility), and approximating it from another signal is prohibited.

### Amendment — 2026-07-21 (pre-extraction; gate language unchanged)

Recorded before any extraction has run. **The N ≥ 20 / ≥ 3-of-6 /
latency-class gate language below is UNCHANGED** — this amendment adds
surface, it never lowers the bar. Prompted by the first minimum-N gate
check (2026-07-21), which surfaced two boundary facts the 2026-07-07 lock
predates:

1. **ADMITTED — spec lifecycle flips** (`.claude/specs/*.md` status
   transitions `draft → approved → consumed / abandoned`) into signals
   (i), (ii), (iii), (iv). These are reviewer decisions at a real approval
   gate: `draft → approved` is the human flip by design (nothing consumes
   a draft), `approved → consumed` is a dispatch decision, `abandoned` is
   a rejection-shape. The surface shipped in Phase 68 — five phases after
   design lock — so its absence from the source lists was an artifact of
   timing, not intent.
2. **EXCLUDED — observation dispositions.** `session-observer.schema.md`
   defines the field: "The `resolved_at` field is producer-driven, not
   user-driven." Machine-driven resolutions are not reviewer decisions;
   counting them would pollute the latency class. The ≈27 resolution
   events in the current window stay out of every signal.

**Restated per-signal Ns (2026-07-21 gate-check baseline, specs
included):** i = 9 (7 + the one spec's 2 flips — `b878a66` approved,
`d56c781` consumed), ii = 2 (both spec flip commits are single-flip),
iii = 9 (7 + the spec's approve/consume dispositions), iv = 5 (4 + one
spec draft→approved distance event: `b878a66` landed both open-question
dispositions as recorded edits), v = 370 ExitPlanMode events, vi = 0.
**Gate: still NOT OPEN — 1 of 6 signals at N ≥ 20 (v only; the gate
needs ≥ 3).** This is the clean baseline for the next check.

## Feasibility gate per signal

Rule: a signal without an existing surface is marked **DEFERRED**, never
approximated — compose with available surfaces, don't invent them.

| # | Signal | Surface today | Status | Events today |
|---|---|---|---|---|
| i | Decision latency | git history of 2 ledgers + captures | **AVAILABLE** | 1 review event (3 proposals, one commit); captures: 0 |
| ii | Batch-flip | per-commit ledger/capture diffs | **AVAILABLE** (joint-read rule applies) | 1 (the `d8c6277` worked example) |
| iii | Disposition mix | ledger statuses + review_notes; captures; update.sh | **PARTIAL** — ledgers/captures yes; update.sh keeps/rejects leave no trace, and overwrite backups are ephemeral (deleted on successful completion) | ledger: 3 dispositions; update: not reconstructable |
| iv | Draft-edit distance | ledger drafts vs applied-text git history | **AVAILABLE** | 2 applied (1 verbatim, 1 recalibrated) |
| v | Plan-mode dwell | telemetry event timestamps | **AVAILABLE** (walk-away confound named) | ~80 gaps measured by the optimizer's first pass |
| vi | Override/disable | gate-config + settings git history; `--force` | **PARTIAL** — config-edit and hook-disable detection yes; `--force` DEFERRED (no args in telemetry) | gate-config hand-edits: 0; hook disables: 0 |
| +i–iv | Spec lifecycle flips (2026-07-21 amendment) | git history of `.claude/specs/` | **AVAILABLE** | 2 flips, 1 spec (`b878a66` approved, `d56c781` consumed) |

## Pre-committed verdicts (locked 2026-07-07, before any data)

> **INSTRUMENTATION-INFEASIBLE** — fewer than **3 of the 6 signals**
> extract reliably at **N ≥ 20 events each**, or no latency-class signal
> (i or v) reaches that N. Consequence: **no human-layer instrumentation
> gets built.** The optimizer's inputs stay existing-sources-only until a
> new Claude Code surface reopens the question. This is a complete,
> acceptable outcome — not a failure to be argued around.

> **INSTRUMENT-VALIDATED** — at least 3 signals (including at least one
> latency-class) extract reliably at N ≥ 20, and their Phase 1
> distributions are analyzable (non-degenerate, stakes-taggable).
> Consequence: ship an **instrumentation spec** as a *candidate*
> optimizer-v2 input. This is explicitly **NOT a verdict on the market
> claim**.

**Scope caveat (load-bearing):** everything here runs against one
founder-operated install. **N=1 validates the instrument, never the
wedge.** A green verdict means "this can be measured here," not "friction
works," and no downstream artifact may cite it as the latter.

## What this gates

- **Optimizer human-layer inputs.** The per-project manager-optimizer's
  input list is closed
  (`.claude/agents/05_meta/manager-optimizer.md` — "Inputs — a closed
  list; nothing else"). It expands beyond existing sources **only** on an
  INSTRUMENT-VALIDATED verdict here, and then only via the instrumentation
  spec that verdict produces. The reference is one-way in the dependency
  sense: this document points at the optimizer, and the optimizer
  **consumes nothing from this experiment**. (The agent definition does
  name this experiment once — its Phase 53 deferral note, "dedicated
  gate-interaction instrumentation is deferred pending the
  reviewer-behavior experiment" — which is the gate stated from the other
  side, not an input.)
- **Risk-calibrated-friction mechanics.** Their key metric —
  override/disable rate — is signal (vi). If (vi) stays PARTIAL/DEFERRED
  at verdict time, that metric has no honest source, and the mechanics
  wait with it.

## Out of scope

- **NO extraction scripts** — Phase 1 tooling is a later phase, gated on
  this design surviving review.
- **NO live instrumentation** — nothing ships into hooks, telemetry, or
  settings from this phase.
- **NO optimizer changes** — the closed input list is untouched.
- **NO venture-facing artifacts** — nothing here is a market claim, a
  pitch input, or evidence about users other than the founder.
- **NO template propagation** — dogfood-only, update-neutral.
