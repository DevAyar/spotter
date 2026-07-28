# Spotter full-system audit — original roadmap vs shipped reality (2026-07-27)
<!-- cruft-check:exempt-historical -->

Frozen dated record (Phase 89), following the `AUDIT-v1.1.4-state.md` convention: snapshot at commit `01d79c6` (HEAD on `main`, tree clean), VERSION `1.1.5`, repo **PUBLIC** (`gh repo view`, verified this pass), license BUSL-1.1 (Change Date 2030-07-23 → MIT). Point-in-time; never updated after commit; **exempt-historical from birth** — every version string and phase reference in here is a historical citation, and future cruft passes should read this file as history (candidate for `EXEMPT_VFILES` if flagged; flagged-not-fixed per this phase's constraints).

Method: evidence gathered from disk and git this session — six parallel read-only sweeps (ROADMAP census, full CHANGELOG enumeration, observations, mirror parity, Phase 86-88 claim spot-checks, git receipts) plus inline verification of CI, fleet, ledgers, and clocks. Not from memory: two working-memory errors were caught by disk during this audit and are themselves recorded (§ 3). Repo age: first commit 2026-05-13; 294 commits; 7 release tags (v1.0.0 2026-05-14 → v1.1.5 2026-07-15).

---

## 1. Roadmap census — every named item, with receipts

**Numbering note (for the total-check):** two phase-numbering eras exist. The pre-1.0 build used `Phase 4a-4h` (foundation → CI, commits `55d96ab` → `32deb41`); the v1.1+ arc restarted at Phase 1 (capture loop, `f39b0e3`) and runs to Phase 89 (this audit). Phase 54 (`e2ead6d`) and every phase named below has a commit-subject or CHANGELOG-entry receipt. v1.1+ numbers with **in-text-only** traces (no entry label of their own): 5 (task-watchdog component numbering), 7, 9 (mirror invariant), 14/14c/14e/14f, 16, 17, 18, 20, 21, 23, 25, 49 (deferred `.gitignore` propagation, later closed by the template-gitignore-parity micro-fix). Numbers with **no repo trace at all**: 13, 15, 19, 22, 26-29, 50-51 — chat-side sprint numbering from the retired handoff era that never mapped to a repo work item. **Total-check result: all 170 CHANGELOG entries across 17 version sections map into the rows below; no entry is unaccounted.**

### v1.0 substrate (0.1.0 → 1.0.0, 2026-05-13 → 05-14) — SHIPPED, all of it

| Item | Status | Receipt |
|---|---|---|
| Template baseline (agents/skills/scripts/commands/hooks + placeholder configs) | SHIPPED | Phase 4b, `35fe5f4`/`6f53f08`/`7018115` |
| project-tuner-helper (report-to-file contract) | SHIPPED | Phase 4b.5 `43a5b2f`; contract fix `69fe782` |
| Meta-management agents (system-memory, agent-slicer, workflow-suggester v0, self-audit) | SHIPPED | Phase 4b.6 `ff3d6f6` |
| install.sh / update.sh, three modes, marker | SHIPPED | Phase 4c `462d9fb`; first dogfood `20ae0de` |
| Real-target validation (Trainer-View production migration) | SHIPPED | Phase 4f `513488b` (0.7.0) |
| Per-file SHA-256 hashes + six-way classification + backfill | SHIPPED | Phase 4g `eb10d43`/`1d19073` (0.8.0) |
| Three-platform CI + scenario harness | SHIPPED | Phase 4h `5f45602` (0.9.0) |

### v1.1.x (v1.1.0 → v1.1.5 cut 2026-07-15)

| Item | Status | Receipt |
|---|---|---|
| Capture/reuse loop: workflow-suggester, script-builder, drift-checker, task-watchdog | SHIPPED | v1.1+ Phases 1-5, `f39b0e3`…; [1.1.0] 2026-05-15 |
| session-observer (the loop's namesake first producer) | **RETIRED** | Phase 58 `b3da433`-`819b12c` — never dispatched, surface dead, contract unimplementable; schema keeps its name as the shared contract |
| cruft-checker (dogfood-only, 9 heuristics) | SHIPPED | [1.1.1]; heuristics grew through 1.1.2/1.1.3 |
| PreToolUse safety hooks (bash + powershell) + shared destructive-pattern libs | SHIPPED | Phase 14c/21/24 lineage; single-source lib locked (ROADMAP:294) |
| code-quality-auditor (3 heuristics, audit-triad member) | SHIPPED | Phase 24 `43215c3` ([1.1.4]) |
| Token telemetry + observation schema privacy classes | SHIPPED | Phase 46 `e1eb39d`… |
| token-cost-monitor + gate-config surface (cost block; tiers/friction slots documented-empty) | SHIPPED | Phase 48 `af74071`… |
| Cross-project git memory (identity → producers/redaction → push → preview/purge → /graduation-review) | SHIPPED | Phases 47a-e, `95122c3` → `bebe7fb` |
| Hardening arc: watchdog resolution (57), match-rebaseline (59), directives 60/61, update-integrity (62), telemetry hardening (63), docs truth (64), schema cleanup (65), cost-line semantics (66), watchdog dedup (67) | SHIPPED | `e688289`, `523d4a5`, `7d33524`, `8a5c48f`, `02a92fd`…, `f9fa58c`…, `94db061`…, `7dbbe0f`…, `204aa9d`…, `865f3c6`… |
| /goals pipeline + scheduled-goals surfacing | SHIPPED | Phase 68 `ccb96f1`-`d56c781` |
| Onboarding tier A-E (README, GETTING-STARTED, PLUGINS-GETTING-STARTED, post-install message, first-run welcome) | SHIPPED | Phases 69-73, `305b64a` → `c57e5e3`; the [1.1.5] cut |

### v1.2.0 meta-evolution (gate: first-project signal sufficiency — OPEN and producing)

| Item | Status | Receipt / gap |
|---|---|---|
| Per-project manager-optimizer (centerpiece) | SHIPPED v1 + **3 live review cycles** | Phase 53 `043ed73`; ledger 8 proposals, 6 applied / 2 rejected (disk count this pass) |
| artifact-fit-analyzer (4 closed lanes) | SHIPPED | Phase 56 `d3f2701` |
| Gate/friction config surface (operation_tiers + friction lanes) | SHIPPED | Phase 48 slots → Phase 85 implementation `fa0080c`/`24e5722`; dogfood first tuned copy |
| infrastructure-audit (project-level) | SHIPPED **as a coordinator, not an agent** | Phase 74 `df792cc` — audits registry + session counters + due line; the roadmap row itself records the shape change |
| roadmap-auditor (skeleton-level, dogfood-only) | SHIPPED | Phase 75 `9e0553f`; 5 lanes; first dispatch 4 findings, verification pass clean |
| Loop pruning (via manager-optimizer) | **PARTIAL** | No dedicated mechanism; exercised once in substance (Phase 58 session-observer retirement pre-dates the optimizer; optimizer P3 third-pass retired a per-pass promise). ROADMAP:78 row carries no status mark |
| token-efficiency-monitor proactive upgrade | **NOT SHIPPED** | ROADMAP:79 row unmarked; the skill remains the passive v1.0 form |
| Pure-design components (/goals) | SHIPPED | Phase 68 (listed under Available-now, correctly) |

### v1.5 plugin tier (gate: v1.1.5 shipped — gate MET, tier COMPLETE)

| Item | Status | Receipt |
|---|---|---|
| recommendation.schema.md + plugin-discovery-agent | SHIPPED | Phase 76 `9dada8f`-`4d350e4` |
| plugin-context-matcher (verdicts + reasons, never scores) | SHIPPED | Phase 77 `9a4c668`-`0df36ef`; first live pass 20/14/138 (80% honest middle) |
| code-quality-auditor candidate mode | SHIPPED | Phase 77 (same arc) |
| Matcher evidence tightening (platform markers; STACK-MISMATCH first firing) | SHIPPED | Phase 78 `138573d` — corrected the gitlab mis-recommendation |
| SessionStart suggestion cadence | SHIPPED via Phase 74 registry (no new hook) | Phase 76 |
| First-install integration (offers, never runs) | SHIPPED | Phase 79 `6c89472` |
| Composition-rule documentation in the template manager | SHIPPED in substance | `template/CLAUDE_MANAGER.md.template:369` "Composition, not competition"; ROADMAP:101 row lacks its status mark (→ observation `d7a4a948`) |

### v2.0 (gate: audit corpus + project-context data + graduated patterns — NOT MET)

GATED. Contents: integration-checker (deferred here at Phase 33 `f874fa9`), code-quality-auditor Layer 3 semantic fitness (deferred at Phase 77), curated catalog (conditional on community value). Locked principle: "Don't be a directory; be a quality filter" (ROADMAP:115). **Current signal state:** 3 installs of matcher data (STACK-MISMATCH scales 1/4/5 with marker richness, 2026-07-21); two recorded design requirements — richer positive-evidence classes (fourth confirmation at the manifest review) and the functional-overlap-with-installed-governance verdict dimension (first human review, 2026-07-22); competitive-study list (claude-code-setup / claude-md-management / hookify, declined competitive-adjacent).

### Telemetry-maturity tier (design-stage; independent gate — NOT MET)

Confidence-and-fidelity engine: research bet; **resampling leg CLOSED-RED** (experiments/confidence, 2026-07 — zero agreement variance across 30 tasks, six confidently-wrong at 7/7 agreement; model self-assessment permanently banned as evidence everywhere downstream); verification-against-ground-truth leg remains the live path. your-view: not built; depends on the engine validating. Nothing from this tier is in any build queue (ROADMAP:131 scope fence).

### v3+ (gate: ≥15 installs, ≥75% adoption; target 20+/90% — NOT MET, at 3 installs)

Graduation machinery (meta-session-observer + template-promoter) waits for the install base; manual graduation is the current discipline (ROADMAP:141-143). Multi-LLM sibling (claude-skeleton-bridge): out of scope through v2.0, "out of scope as a feature graft, period" (ROADMAP:155).

### Retired / dropped / cut (decision receipts)

session-observer (Phase 58, evidenced three-leg verdict) · Pinball install leg (retired 2026-07 pre-signal; CI fresh-install covers the path, ROADMAP:52) · resampling-agreement leg (CLOSED-RED, experiments/confidence) · skill-builder + agent-builder (cut; MISFIT lane absorbed the function, Phase 56) · Model A captures-library + Model B lessons-log (cut at Phase 18) · handoff file (retired Phase 80 `6efbb5d`, history kept deliberately) · foreground CI watching (retired by directive, CHANGELOG workflow-directive entry; closed exceptions live in CLAUDE_MANAGER:363) · 3-project/66% graduation bar (cut at Phase 44 for 15/75) · claude-skeleton-auto as product (research-only) · time-based gating (cut at Phase 45; sessions-cadence only, locked) · MIT (**swapped to BUSL-1.1** pre-publication — unplanned, deliberate).

### Unplanned-shipped — where the roadmap grew

The original tiers never named any of this; all of it exists because the system watched itself run:

| Item | Phase / receipt |
|---|---|
| Friction lanes cash-out (dogfood docs_only/mechanical_fix → flow_with_receipt, derivation in commit body) | 85 `24e5722` |
| CI-diet (detect job, fast lane, weekly drift net, concurrency) | 82 `c6126e5` |
| Seam-check directive + closed exceptions | workflow-directive entry; manager H3 |
| Publication package: handoff retirement, marker privacy, BUSL swap, Spotter rebrand, README voice rules, wedge-language standing hard rule + pull | 80/81/83/84 `6efbb5d`/`0ec203c`/`8d29576`/`0e69dd5` |
| Dual-name convention (Spotter brand / claude-skeleton engine codename) | 87 `6faa1ec` |
| Fold status-preservation (silent-disposition-loss class closed; jumped the queue by standing rule) | 88 `85fecf8` |
| Truth sweeps as a genre (docs catch-up 64; five-bucket post-publication 86; truth-correction entry for the billing-arc premise errors) | `94db061`…, `bb245f8`/`ee0dc8f`, dated 2026-07-22 |
| Judgment directives: halt-on-uncertainty (55), CI-claim-vs-commit (60), recon/plan-gate boundary (61), dispatch hygiene (micro), release version-sweep (optimizer P3) | `23ff056`, `7d33524`, `8a5c48f`, ledger receipts |
| Reviewer-behavior experiment framework + spec-lifecycle amendment | experiments/reviewer-behavior; design-amendment entry |
| Cost-line sitting-delta semantics; match-rebaseline; watchdog Agent-duration | 66/59/micro-pass entries |

---

## 2. Quality evidence at tip (01d79c6)

- **Guards:** 50 scenarios defined in `scenarios.sh`, 50 wired as individual ci.yml steps (1:1, grep-counted). Fixture count 80 verified true at all three sites AND against the marker itself (len(files)=80, len(raw_template_baselines)=80, key sets identical).
- **CI:** full matrix green at `94382c5` (run 30321735653: ubuntu+windows+macos); fast lane green at tip `01d79c6` (run 30321959798). Weekly full-matrix cron Mondays 06:00 UTC; superseded pushes cancel their own runs.
- **Mirror parity (`.claude/` vs `template/.claude/`):** 73 of 74 shared paths byte-identical; the 1 differ is gate-config.json, all four hunks known per-install tuning (thresholds, lane overrides, roadmap_auditor registry row, one doc-string). Dogfood-only set is exactly the six ratified artifacts (cruft-checker ×2 files, roadmap-auditor, graduation-review ×2, settings.json); template-only is settings.json.template. Scope note: root-level `*.template` mirrors (CLAUDE_MANAGER etc.) were not hash-swept this pass; the manager mirrors were last verified at their Phase 86 edits.
- **Fleet:** TV at `3a9b490`, EoG at `159c763` — both marker v1.1.5, 80/80 baselines, both carrying the 79+85+86 bundle from skeleton `ee0dc8f`; tuned values byte-preserved (TV 275/6500, EoG 375/600, both `claude-fable-5`); lanes untuned (overrides `{}`, per-install principle). Known dirty sets: TV share-*.sh mods + SESSION_LOG + launch.json + 3 observations; EoG share-*.sh + SESSION_LOG + project.godot + 4 observations — all pre-existing, all flagged in the propagation records.
- **Observations:** 226 total (cruft-checker 164, session-end-telemetry 44, roadmap-auditor 14, task-watchdog 3, manual 1 — plus 2 manual added by this audit). Open: 45 = 44 token_telemetry per-session records (the Phase 65 never-resolves class, deliberately open) + **1 real: `ddee6613`** (drift-check cooldown attribution, fixed in docs at Phase 86, awaiting its producer's confirming pass).
- **Ledgers:** optimizer 8 proposals — 6 applied, 2 rejected, three full review cycles with dispositions on the record; **retier ledger: 0 proposals ever** (the Phase 48 pipeline has never fired live — see § 4).
- **Cost receipts (the transparency convention):** lineage ~$2,038.84 since 2026-07-07; 7d ~$573.05 — printed at `claude-opus-4-8` assumed rates, which is itself a finding (§ 3).
- **Known-residue ledger (all on record, none surprises):** DESIGN.md's three flagged-not-edited lines (:166 pre-committed verdicts, the scope-caveat line, :185 cross-ref) — pre-commit integrity outranks vocabulary; ~90 engine-register `claude-skeleton` occurrences ratified permanent (Phase 87); EoG `.claude/backups/` 4 transcript files (gitignored) + `pre-skeleton-migration-20260513` branch (local+origin); TV manifest's `sumup` external-source candidate (manifest.md:1754, gitignored runtime) — the verdict-honesty question from the 75-78 propagation; template manager lane-3 aside (:242/:251 "Phase 36 queue" phrasing, noted at Phase 86 for the next full audit).

---

## 3. Up-to-date check (surfaces touched since the July-27 clean passes)

Baseline cited: post-Phase-86 loop closure — cruft pass auto-resolved all 24 open findings; roadmap-auditor verification re-dispatch returned Lane 1 CLEAN with one residual it caught in the sweep's own fresh wording (`ddee6613`, corrected pre-push, observation left open for the producer).

Re-verified this pass (Phase 86-88 surfaces): ROADMAP truth-marks 4/4 PASS (quotes on file) · ARCHITECTURE 19-agent headline PASS (19 template files re-counted; dogfood 21 = 19 + the two dogfood-only) · GETTING-STARTED 19/13 counts PASS (13 = template scripts minus the drafts dir; the 6-skills and 10-commands context counts also re-derived true) · scenarios.sh 80 at three sites PASS and true against the marker · README ambient claim + drift bullet PASS, em-dash count = 0 (the Phase 83 claim holds) · fold-hook header states the Phase 88 exception PASS.

**Findings (→ observations, no fixes, per constraints):**
1. `917948cf` **config-drift:** dogfood `cost.assumed_model` is `claude-opus-4-8` while both installs run `claude-fable-5` and current commits are Fable 5-authored — the cost line and the cycle-three-derived 95/600 thresholds price sittings at a model this install no longer runs. (Caught by disk against my own working memory, which had recorded fable-5 for the dogfood too.)
2. `d7a4a948` **doc-staleness:** CHANGELOG:7 headnote still queues the TV/EoG propagation pass consumed at `ee0dc8f`; the honest queue is the 87+88 bundle. Rider nit: ROADMAP:101's composition-rule row carries no status mark though the substance shipped.

(Second memory-vs-disk catch for the record: the "cycle-four ≥10 tier-3 dispositions" measurement bar exists only in a session report, not on any tracked surface — § 5 states the re-measurement trigger from what IS on disk.)

---

## 4. CC's assessment — invited, no deference

**Strongest three, with evidence.**
1. **The verification culture is real, not performative.** Every mechanism fix ships a RED-demonstrated-then-GREEN guard (88's fold leg, 78's mismatch leg, 59's rebaseline scenario); wiring claims are checked against the commit diff because a phase once shipped without its ci.yml (57→59, now a directive); the system corrected its own record three separate times on the July record alone (truth-correction entry, `c26ef49`, `ddee6613`) — and the auditor that caught the last one was auditing the sweep that was fixing its previous findings. Most projects assert quality; this one demonstrates it against itself and keeps the receipts when it fails.
2. **The honest middle is engineered in, not aspirational.** 80% of matcher candidates stay unverdicted by design; insufficient-signal is a sanctioned optimizer output; model self-assessment is banned as evidence with the RED experiment on file; the optimizer's own P1 was rejected on derivation-consistency grounds. The system structurally prefers "no answer" over confident fabrication — the rarest discipline in this product category, and the one hardest to retrofit.
3. **The loop actually closes.** Observation → disposition → codified rule → guard has cycled end-to-end repeatedly on the system itself: the 7h wedge became the dispatch-hygiene directive; the watchdog's own blind spot (Agent durations) became its fix with an evidence-derived threshold; the fold's silent-disposition-loss became Phase 88 within days of the incident, retiring the manual bridge. Governance that metabolizes its own failures is the product's actual thesis, and the record supports it.

**Weakest three, with evidence.**
1. **N=1 human, N=3 installs — external validity is untested.** Every derived number (95/600 thresholds, the 60-min Agent ceiling, lane tuning, approval-pattern claims) rests on one operator's behavior in three installs, two of them the operator's own projects. The lanes ratified from "every docs plan since 2026-07-07 approved unchanged" describe one person's trust curve. The first outside user invalidates unknown fractions of this silently. Nothing in the repo can fix this; only installs can.
2. **Shipped-but-idle surfaces are accumulating, and idle paths rot.** The retier pipeline has never produced a proposal in ~2.5 months of live running (ledger: 0). Reviewer-behavior sits at 1/6 signals at N≥20 since 2026-07-21. Friction lanes have zero recorded tier-3 lane dispositions to measure. The fold bug is the cautionary receipt here: the first real traffic through a dormant path (pre-fold dispositions) hit a data-loss bug that guards never exercised. Dormancy is not neutral — it is untested surface plus false confidence.
3. **The governance spends real money governing itself, and no one audits that ratio.** ~$2,039 lineage spend since 2026-07-07, with 5-6M-output-token sessions in the telemetry, overwhelmingly on the governor rather than governed object-work. Dogfooding legitimately explains much of it — the skeleton is the product — but the optimizer, which exists to watch decision patterns, has never once been pointed at cost-per-phase versus value-shipped. The receipts exist (per-session rollups, phase-labeled commits); the question has never been asked. A system whose thesis is "attention economics" should be able to price its own attention.

**What I would build or change next, in order.** (1) **Two or three genuinely external installs** — nearly every open gate (v2.0 corpus, v3+ base, reviewer-behavior N, lane measurement) points at the same bottleneck, and one outside user teaches more than five more dogfood phases. (2) **The assumed-model fix plus a per-phase cost attribution pass** — dispose `917948cf`, then let token-cost-monitor join session rollups to phase-labeled commits; one table, real leverage on weakness 3. (3) **An exercise-or-retire pass over dormant surfaces** — give retier a live-fire fixture the way the fold now has one, or record the honest graduation-review-style "not yet, and here's why" for it; same question for the reviewer-behavior instrument if the gate stays closed through another quarter.

**A concern no brief has asked about.** The system's guarantees are two-layered: hooks (mechanical floor) and directives (prose the model honors). The floor is real, but almost everything distinctive here — lanes, plan gates, receipts, staging discipline, the trailer — lives in the directive layer, enforced by model compliance plus operator vigilance. Today that compliance is high. A different model, a degraded one, or a rushed operator erodes it *silently*, because nothing measures directive adherence itself — there is no auditor that samples recent commits and asks "were the conventions actually honored without being reminded?" The reviewer-behavior experiment watches the human's side of the gates; nothing watches the agent's side. That auditor would be cheap (a cruft-checker-shaped pass over the last N commits against a closed checklist), it fits the existing draft-only pattern, and it converts the system's central untested assumption — that the directive layer holds — into a measured one. If Spotter is ever run by someone who is not its author, this is the first thing that will quietly fail.

---

## 5. What's left — the owner's working list (2026-07-27)

**Gated, with gate + current signal:**
- v2.0 (integration-checker, CQ Layer 3, catalog) — gate: audit corpus + graduated patterns; signal: 3 installs, 2 recorded design requirements, competitive-study trio logged.
- Telemetry tier (confidence engine verification leg, your-view) — gate: telemetry maturity; resampling leg already CLOSED-RED.
- v3+ graduation machinery — gate: ≥15 installs / ≥75% adoption; at 3 installs.
- Reviewer-behavior extraction — gate: ≥3 of 6 signals at N≥20; at 1/6 (v=370 only; i=9, ii=2, iii=9, iv=5, vi=0, baseline 2026-07-21).
- Phase 85 lane measurement — trigger per the on-disk third-pass principle: measure when recorded tier-3 lane dispositions exist, not on a schedule; currently zero.
- Retier pipeline — no signal ever; see § 4 exercise-or-retire.

**Open decisions (owner):**
- Dispose `917948cf` (assumed_model: retune vs re-derive thresholds at correct rates).
- Dispose `d7a4a948` (CHANGELOG headnote + ROADMAP:101 mark) — docs_only lane when taken.
- `ddee6613` closes at the next roadmap-auditor pass (cadence: 22 sessions out) or on manual dispatch.
- This file → `EXEMPT_VFILES` if a future cruft pass flags it (one-liner, flagged here by design).
- Template manager :242/:251 lane-3 phrasing (Phase 86 aside) — next full audit.
- v2.0 competitive study (claude-code-setup / claude-md-management / hookify) — when v2.0 opens.

**Pending propagation bundle (rides the next natural pass):** Phase 87 welcome-URL + Phase 88 fold hook → TV and EoG. Verified pending at both targets this pass: 0 `spotter` hits in their rules hooks, 0 Phase-88 marks in their fold hooks.

**Standing clocks:** audit registry — artifact_fit_analyzer 3/18, roadmap_auditor 3/25, plugin_discovery 3/30 sessions; optimizer counter 3 sessions since cycle three; weekly full-matrix CI cron (Mondays 06:00 UTC); cost warn 95/600 (under `917948cf`'s cloud); BUSL Change Date 2030-07-23 → MIT.
