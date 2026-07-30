# Spotter full pass — every-line scrub (2026-07-30)
<!-- cruft-check:exempt-historical -->

Phase 105. Frozen working record, exempt-historical from birth. **241 tracked files, 33,064 lines.** Findings go to observations (severity in notes); NOTHING is fixed in-pass. The ledger below is the proof of coverage: a file without a reviewed-at stamp is not reviewed, and the pass is not done until every row is stamped. Mirror-parity rule: byte-identical mirror pairs (md5-verified at review time) share one review and both rows stamp with a parity note.

Severity scale: BLOCKER-for-strangers / SHOULD-FIX / COSMETIC. CLEAN is a legitimate verdict.

## Wave A — shipped scripts (33 files, 9,451 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/scripts/commit.sh | 57 | 0d28839 | 1 COSMETIC |
| .claude/scripts/cruft-check.sh | 657 | 0d28839 | 2 SHOULD-FIX |
| .claude/scripts/deploy.sh | 51 | 0d28839 | 1 SHOULD-FIX / 2 COSMETIC |
| .claude/scripts/drift-check.sh | 74 | 0d28839 | CLEAN |
| .claude/scripts/goals-surface.sh | 120 | 0d28839 | CLEAN |
| .claude/scripts/graduation-review.sh | 110 | 0d28839 | CLEAN |
| .claude/scripts/plugin-context-matcher.sh | 461 | 0d28839 | 2 SHOULD-FIX / 1 COSMETIC |
| .claude/scripts/plugin-discovery.sh | 370 | 0d28839 | CLEAN |
| .claude/scripts/plugin-quality-check.sh | 489 | 0d28839 | 2 SHOULD-FIX / 2 COSMETIC |
| .claude/scripts/receipt-render.sh | 722 | 0d28839 | 3 COSMETIC |
| .claude/scripts/share-disable.sh | 128 | 0d28839 | 2 SHOULD-FIX / 2 COSMETIC |
| .claude/scripts/share-enable.sh | 159 | 0d28839 | 2 SHOULD-FIX / 2 COSMETIC |
| .claude/scripts/share-status.sh | 64 | 0d28839 | 1 SHOULD-FIX / 1 COSMETIC |
| .claude/scripts/shared-memory-produce.sh | 112 | 0d28839 | CLEAN |
| .claude/scripts/shared-memory-push.sh | 138 | 0d28839 | 2 COSMETIC |
| .claude/scripts/task-watchdog.sh | 524 | 0d28839 | 2 SHOULD-FIX / 1 COSMETIC |
| scripts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| scripts/install.sh | 562 | 0d28839 | 5 SHOULD-FIX / 3 COSMETIC |
| scripts/update.sh | 1184 | 0d28839 | 2 BLOCKER / 5 SHOULD-FIX / 6 COSMETIC |
| template/.claude/scripts/commit.sh | 57 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/deploy.sh | 51 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/drift-check.sh | 74 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/goals-surface.sh | 120 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/plugin-context-matcher.sh | 461 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/plugin-discovery.sh | 370 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/plugin-quality-check.sh | 489 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/receipt-render.sh | 722 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/share-disable.sh | 128 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/share-enable.sh | 159 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/share-status.sh | 64 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/shared-memory-produce.sh | 112 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/shared-memory-push.sh | 138 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/scripts/task-watchdog.sh | 524 | 0d28839 | mirror-parity (byte-identical to the reviewed twin) |

## Wave B — hooks + libs (36 files, 4,770 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/hooks/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/hooks/README.md | 49 | — | — |
| .claude/hooks/precompact-backup.sh | 33 | — | — |
| .claude/hooks/pretooluse-bash-safety.sh | 157 | — | — |
| .claude/hooks/pretooluse-powershell-safety.sh | 167 | — | — |
| .claude/hooks/sessionend-cost-proposals.sh | 228 | — | — |
| .claude/hooks/sessionend-observe.sh | 55 | — | — |
| .claude/hooks/sessionstart-cost-summary.sh | 325 | — | — |
| .claude/hooks/sessionstart-rules.sh | 155 | — | — |
| .claude/lib/destructive-bash-patterns.sh | 30 | — | — |
| .claude/lib/destructive-powershell-patterns.sh | 33 | — | — |
| .claude/lib/generate-session-telemetry.sh | 526 | — | — |
| .claude/lib/migrate-observation-privacy.sh | 85 | — | — |
| .claude/lib/redact-capture.sh | 122 | — | — |
| .claude/lib/redact-observation.sh | 125 | — | — |
| .claude/lib/shared-memory-git.sh | 94 | — | — |
| .claude/lib/shared-memory-lib.sh | 146 | — | — |
| .claude/lib/shared-memory.schema.md | 55 | — | — |
| template/.claude/hooks/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/hooks/README.md | 49 | — | — |
| template/.claude/hooks/precompact-backup.sh | 33 | — | — |
| template/.claude/hooks/pretooluse-bash-safety.sh | 157 | — | — |
| template/.claude/hooks/pretooluse-powershell-safety.sh | 167 | — | — |
| template/.claude/hooks/sessionend-cost-proposals.sh | 228 | — | — |
| template/.claude/hooks/sessionend-observe.sh | 55 | — | — |
| template/.claude/hooks/sessionstart-cost-summary.sh | 325 | — | — |
| template/.claude/hooks/sessionstart-rules.sh | 155 | — | — |
| template/.claude/lib/destructive-bash-patterns.sh | 30 | — | — |
| template/.claude/lib/destructive-powershell-patterns.sh | 33 | — | — |
| template/.claude/lib/generate-session-telemetry.sh | 526 | — | — |
| template/.claude/lib/migrate-observation-privacy.sh | 85 | — | — |
| template/.claude/lib/redact-capture.sh | 122 | — | — |
| template/.claude/lib/redact-observation.sh | 125 | — | — |
| template/.claude/lib/shared-memory-git.sh | 94 | — | — |
| template/.claude/lib/shared-memory-lib.sh | 146 | — | — |
| template/.claude/lib/shared-memory.schema.md | 55 | — | — |

## Wave C — config, schemas, fixtures, CI, seeds (21 files, 5,229 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/agents/05_meta/script-builder.schema.md | 213 | — | — |
| .claude/agents/05_meta/session-observer.schema.md | 151 | — | — |
| .claude/agents/05_meta/workflow-suggester.schema.md | 150 | — | — |
| .claude/gate-config.json | 84 | — | — |
| .claude/recommendations/recommendation.schema.md | 67 | — | — |
| .claude/settings.json | 105 | — | — |
| .claude/specs/goal-spec.schema.md | 43 | — | — |
| .gitattributes | 14 | — | — |
| .github/test-fixtures/scenarios.sh | 3076 | — | — |
| .github/workflows/ci.yml | 295 | — | — |
| .gitignore | 79 | — | — |
| template/.claude/agents/05_meta/script-builder.schema.md | 213 | — | — |
| template/.claude/agents/05_meta/session-observer.schema.md | 151 | — | — |
| template/.claude/agents/05_meta/workflow-suggester.schema.md | 150 | — | — |
| template/.claude/gate-config.json | 80 | — | — |
| template/.claude/recommendations/recommendation.schema.md | 67 | — | — |
| template/.claude/settings.json.template | 97 | — | — |
| template/.claude/specs/goal-spec.schema.md | 43 | — | — |
| template/.gitignore.template | 56 | — | — |
| template/CLAUDE.md.template | 38 | — | — |
| template/ROUTING.md.template | 57 | — | — |

## Wave D — agents, commands, skills, directive contracts (83 files, 5,986 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/agents/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/agents/01_research/research-helper.md | 42 | — | — |
| .claude/agents/02_audit/audit-helper.md | 43 | — | — |
| .claude/agents/03_monitoring/monitoring-helper.md | 42 | — | — |
| .claude/agents/04_planning/plan-coordinator.md | 44 | — | — |
| .claude/agents/05_meta/agent-slicer.md | 77 | — | — |
| .claude/agents/05_meta/artifact-fit-analyzer.md | 142 | — | — |
| .claude/agents/05_meta/code-quality-auditor.md | 118 | — | — |
| .claude/agents/05_meta/cruft-checker.md | 130 | — | — |
| .claude/agents/05_meta/drift-checker.md | 77 | — | — |
| .claude/agents/05_meta/integration-installer.md | 115 | — | — |
| .claude/agents/05_meta/manager-optimizer.md | 133 | — | — |
| .claude/agents/05_meta/plugin-context-matcher.md | 78 | — | — |
| .claude/agents/05_meta/plugin-discovery-agent.md | 88 | — | — |
| .claude/agents/05_meta/project-tuner-helper.md | 188 | — | — |
| .claude/agents/05_meta/roadmap-auditor.md | 109 | — | — |
| .claude/agents/05_meta/script-builder.md | 107 | — | — |
| .claude/agents/05_meta/self-audit-helper.md | 94 | — | — |
| .claude/agents/05_meta/system-memory-helper.md | 73 | — | — |
| .claude/agents/05_meta/task-watchdog.md | 77 | — | — |
| .claude/agents/05_meta/token-cost-monitor.md | 92 | — | — |
| .claude/agents/05_meta/workflow-suggester.md | 85 | — | — |
| .claude/commands/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/commands/audit.md | 14 | — | — |
| .claude/commands/commit.md | 11 | — | — |
| .claude/commands/deploy.md | 15 | — | — |
| .claude/commands/goals.md | 50 | — | — |
| .claude/commands/graduation-review.md | 17 | — | — |
| .claude/commands/share-disable.md | 36 | — | — |
| .claude/commands/share-enable.md | 33 | — | — |
| .claude/commands/share-preview.md | 17 | — | — |
| .claude/commands/share-push.md | 23 | — | — |
| .claude/commands/share-status.md | 13 | — | — |
| .claude/commands/smoke-test.md | 13 | — | — |
| .claude/skills/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/skills/bash-safety/SKILL.md | 94 | — | — |
| .claude/skills/god-file-grep-first/SKILL.md | 45 | — | — |
| .claude/skills/plugin-roster-search/SKILL.md | 49 | — | — |
| .claude/skills/post-edit-test-suggest/SKILL.md | 41 | — | — |
| .claude/skills/schema-verify-before-edit/SKILL.md | 37 | — | — |
| .claude/skills/token-efficiency-monitor/SKILL.md | 57 | — | — |
| CLAUDE.md | 38 | — | — |
| CLAUDE_MANAGER.md | 557 | — | — |
| ROUTING.md | 58 | — | — |
| template/.claude/agents/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/agents/01_research/research-helper.md | 42 | — | — |
| template/.claude/agents/02_audit/audit-helper.md | 43 | — | — |
| template/.claude/agents/03_monitoring/monitoring-helper.md | 42 | — | — |
| template/.claude/agents/04_planning/plan-coordinator.md | 44 | — | — |
| template/.claude/agents/05_meta/agent-slicer.md | 77 | — | — |
| template/.claude/agents/05_meta/artifact-fit-analyzer.md | 142 | — | — |
| template/.claude/agents/05_meta/code-quality-auditor.md | 118 | — | — |
| template/.claude/agents/05_meta/drift-checker.md | 77 | — | — |
| template/.claude/agents/05_meta/integration-installer.md | 115 | — | — |
| template/.claude/agents/05_meta/manager-optimizer.md | 133 | — | — |
| template/.claude/agents/05_meta/plugin-context-matcher.md | 78 | — | — |
| template/.claude/agents/05_meta/plugin-discovery-agent.md | 88 | — | — |
| template/.claude/agents/05_meta/project-tuner-helper.md | 188 | — | — |
| template/.claude/agents/05_meta/script-builder.md | 107 | — | — |
| template/.claude/agents/05_meta/self-audit-helper.md | 94 | — | — |
| template/.claude/agents/05_meta/system-memory-helper.md | 73 | — | — |
| template/.claude/agents/05_meta/task-watchdog.md | 77 | — | — |
| template/.claude/agents/05_meta/token-cost-monitor.md | 92 | — | — |
| template/.claude/agents/05_meta/workflow-suggester.md | 85 | — | — |
| template/.claude/commands/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/commands/audit.md | 14 | — | — |
| template/.claude/commands/commit.md | 11 | — | — |
| template/.claude/commands/deploy.md | 15 | — | — |
| template/.claude/commands/goals.md | 50 | — | — |
| template/.claude/commands/share-disable.md | 36 | — | — |
| template/.claude/commands/share-enable.md | 33 | — | — |
| template/.claude/commands/share-preview.md | 17 | — | — |
| template/.claude/commands/share-push.md | 23 | — | — |
| template/.claude/commands/share-status.md | 13 | — | — |
| template/.claude/commands/smoke-test.md | 13 | — | — |
| template/.claude/skills/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/skills/bash-safety/SKILL.md | 94 | — | — |
| template/.claude/skills/god-file-grep-first/SKILL.md | 45 | — | — |
| template/.claude/skills/plugin-roster-search/SKILL.md | 49 | — | — |
| template/.claude/skills/post-edit-test-suggest/SKILL.md | 41 | — | — |
| template/.claude/skills/schema-verify-before-edit/SKILL.md | 37 | — | — |
| template/.claude/skills/token-efficiency-monitor/SKILL.md | 57 | — | — |
| template/CLAUDE_MANAGER.md.template | 551 | — | — |

## Wave E — public docs (9 files, 1,488 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| COMMERCIAL.md | 21 | — | — |
| LICENSE | 102 | — | — |
| README.md | 95 | — | — |
| docs/ARCHITECTURE.md | 185 | — | — |
| docs/CHANGELOG.md | 353 | — | — |
| docs/GETTING-STARTED.md | 160 | — | — |
| docs/PLUGINS-GETTING-STARTED.md | 123 | — | — |
| docs/ROADMAP.md | 329 | — | — |
| docs/STORY.md | 120 | — | — |

## Wave F — everything remaining (59 files, 6,140 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/.skeleton-version | 180 | — | — |
| .claude/captures/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/captures/6f7e14b7176e480c04f38c4383ca09763bdc2b9015ac4eedcaeba3ca6e59cac8.md | 56 | — | — |
| .claude/captures/README.md | 42 | — | — |
| .claude/captures/fe22198210607aea481ac447d5620d9450b7f5d6e6d9dcdf3a2fd9dacb1b3f75.md | 43 | — | — |
| .claude/observations/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/observations/README.md | 30 | — | — |
| .claude/scripts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/scripts/drafts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/scripts/drafts/README.md | 55 | — | — |
| .claude/specs/README.md | 27 | — | — |
| .claude/specs/propagate-skeleton-tv-eog.md | 84 | — | — |
| .claude/telemetry/README.md | 34 | — | — |
| .claude/telemetry/events/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/telemetry/model-pricing.json | 22 | — | — |
| .claude/telemetry/optimizer-proposals.json | 152 | — | — |
| .claude/telemetry/retier-proposals.json | 19 | — | — |
| .claude/telemetry/sessions/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| VERSION | 1 | — | — |
| docs/AUDIT-2026-07-27-spotter-state.md | 167 | — | — |
| docs/AUDIT-v1.1.4-cc-side.md | 338 | — | — |
| docs/AUDIT-v1.1.4-marker-refresh-dryrun.md | 159 | — | — |
| docs/AUDIT-v1.1.4-state.md | 962 | — | — |
| docs/HOOK_SCHEMA.md | 50 | — | — |
| docs/INSTALLATION.md | 380 | — | — |
| docs/PHILOSOPHY.md | 97 | — | — |
| docs/PLUGIN-INSTALLS-v1.1.4.md | 701 | — | — |
| docs/scratch/claude-manager-reframe-audit.md | 82 | — | — |
| docs/scratch/claude-md-reframe-audit.md | 91 | — | — |
| docs/scratch/phase-36-framework.md | 71 | — | — |
| experiments/confidence/.gitignore | 5 | — | — |
| experiments/confidence/ANALYSIS.md | 92 | — | — |
| experiments/confidence/MANIFEST_HEADER.md | 28 | — | — |
| experiments/confidence/README.md | 13 | — | — |
| experiments/confidence/analysis.py | 369 | — | — |
| experiments/confidence/harness.py | 167 | — | — |
| experiments/confidence/real_manifest.json | 713 | — | — |
| experiments/confidence/scatter_agreement_all.png | 172 | — | — |
| experiments/confidence/scatter_agreement_gap.png | 115 | — | — |
| experiments/reviewer-behavior/DESIGN.md | 211 | — | — |
| template/.claude/captures/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/captures/README.md | 42 | — | — |
| template/.claude/observations/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/observations/README.md | 30 | — | — |
| template/.claude/scripts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/scripts/drafts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/scripts/drafts/README.md | 55 | — | — |
| template/.claude/specs/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/specs/README.md | 27 | — | — |
| template/.claude/telemetry/README.md | 34 | — | — |
| template/.claude/telemetry/events/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/telemetry/model-pricing.json | 22 | — | — |
| template/.claude/telemetry/optimizer-proposals.json | 19 | — | — |
| template/.claude/telemetry/retier-proposals.json | 19 | — | — |
| template/.claude/telemetry/sessions/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/PLUGINS.md.template | 27 | — | — |
| template/docs/ARCHITECTURE.md.template | 51 | — | — |
| template/docs/SESSION_LOG.md.template | 40 | — | — |
| template/docs/STATUS.md.template | 46 | — | — |

### Wave A findings

- **BLOCKER-for-strangers** — `scripts/update.sh:182` — detect_json_tool prefers `python` over `python3` and never verifies the interpreter actually runs or is Python >= 3.7
  - evidence: On stock Windows the WindowsApps `python.exe` stub satisfies `command -v python` but exits 9009 (Store nag), so dump_marker dies with the misleading 'failed to parse .skeleton-version'. On systems where `python` is Python 2, dump_marker's f-strings are a SyntaxError; on 3.6, sys.stdout.reconfigure (line 203) is AttributeError. Should try python3 first and probe with e.g. `"$t" -c 'import sys; sys.exit(0 if sys.version_info>=(3,7) else 1)'`.
- **BLOCKER-for-strangers** — `scripts/update.sh:384` — cleanup_backups/rollback expand empty arrays unguarded; fatal under set -u on bash < 4.4 (macOS 3.2, the script's stated target)
  - evidence: Lines 366/369/374/384/388 use "${MODIFIED[@]}" etc. without the :- guard used everywhere else (cf. lines 77, 609, 1108). cleanup_backups is called unconditionally at line 1183; a run where MODIFIED and DELETED_BACKUPS are empty (e.g. only NEW files applied) dies with 'unbound variable' AFTER write_version_marker, then the EXIT trap's rollback deletes the just-applied files while the marker keeps their hashes — corrupted install state. rollback itself has the same landmine (MODIFIED non-empty but ADDED_FILES empty crashes at line 366 mid-restore, leaving overwritten files and stray .bak.$$ litter).
- **SHOULD-FIX** — `.claude/scripts/cruft-check.sh:16` — All paths are cwd-relative with no CLAUDE_PROJECT_DIR anchor — invoked from any other directory it plants a stray .claude/observations/ tree there
  - evidence: COOLDOWN_FILE/OBS_DIR and every heuristic path ('VERSION', 'docs/CHANGELOG.md', template/ globs) resolve against $PWD; `mkdir -p "$OBS_DIR"` (line 49) then succeeds in the wrong cwd and the scan reports a phantom-clean repo. Sibling goals-surface.sh:17 anchors on ${CLAUDE_PROJECT_DIR:-$PWD} for exactly this reason
- **SHOULD-FIX** — `.claude/scripts/cruft-check.sh:48` — Bare `command -v python` probe: no python3 fallback and no execution validation — auditor silently never runs on python3-only machines and Windows-Store-stub machines
  - evidence: On stock macOS/Linux (python3 only) line 48 exits 0 forever; with the WindowsApps stub, `command -v python` passes but the heredoc exits nonzero and line 650-653 bails silent. goals-surface.sh:34-40 documents this exact class ('Phase 57 silent-inert; probe pattern per Phase 63') and fixes it with the PYBIN execution loop — cruft-check never got the fix, so one leg of the advertised session-start audit triad is a permanent no-op for most outside installs
- **SHOULD-FIX** — `.claude/scripts/deploy.sh:38` — No guard that {{DEPLOY_COMMAND}} was actually configured — an unconfigured run fails with a cryptic 'command not found' (127) instead of a clear message
  - evidence: Run `bash .claude/scripts/deploy.sh` on a clean tree in this install (placeholder still literal): both guards pass, then bash executes the literal token `{{DEPLOY_COMMAND}}` → `{{DEPLOY_COMMAND}}: command not found`, exit 127. A one-line `case "{{DEPLOY_COMMAND}}" in '{{'*) echo not-configured; exit 4;; esac`-style check would fail honestly
- **SHOULD-FIX** — `.claude/scripts/plugin-context-matcher.sh:362` — Candidate audit subprocess inherits caller's cwd while quality-check's pattern libs are cwd-relative — from a non-root cwd, heuristic iii runs with zero patterns yet the manifest records 'clean (i/ii/iii pass)'
  - evidence: Matcher anchors everything on ${CLAUDE_PROJECT_DIR:-.} (line 38) so non-root invocation is supported, but subprocess.run(['bash', quality_check, ...]) passes no cwd; plugin-quality-check.sh:35-36 resolves .claude/lib/destructive-*-patterns.sh against $PWD and read_patterns_from_lib silently returns [] when absent — findings list empty → line 377-378 stamps the audit clean
- **SHOULD-FIX** — `.claude/scripts/plugin-context-matcher.sh:421` — Re-running the matcher on an already-verdicted manifest duplicates frontmatter keys and per-block candidate_audit lines
  - evidence: Blocks that stayed `status: candidate` are re-evaluated every run and edits always append a fresh `- candidate_audit:` line (line 425-430); the frontmatter loop (line 437-442) matches `candidates: N` unconditionally and inserts a second `recommended:`/`not_recommended:` pair. Two consecutive manual runs (nothing prevents this; only discovery regenerates the file) → duplicated keys in .claude/recommendations/manifest.md
- **SHOULD-FIX** — `.claude/scripts/plugin-quality-check.sh:210` — Missing/unreadable pattern libs silently disable heuristic iii with no warning — the audit still runs and (in candidate mode) reports as clean
  - evidence: read_patterns_from_lib returns [] when .claude/lib/destructive-*-patterns.sh is absent (line 210-212, and libs are cwd-relative per lines 35-36); BASH_REGEX/PS_REGEX become empty, check_heuristic_iii iterates nothing, no observation or stderr note marks the degradation
- **SHOULD-FIX** — `.claude/scripts/plugin-quality-check.sh:380` — is_unguarded_target treats Windows drive-letter and $env:/%USERPROFILE% paths as 'guarded' — Remove-Item/rm -rf against C:\... or $env:USERPROFILE is never flagged, on a Windows-first install
  - evidence: A plugin .ps1 containing `Remove-Item -Recurse -Force C:\Users\x` yields target 'C:\Users\x': no '/' or '~' or '$HOME' prefix → falls through to `return False` ('assumed guarded'); `$env:USERPROFILE` hits the line-390 `startswith('$')` branch → also assumed guarded. The broad-set at line 383 is POSIX-only while the PS pattern lib exists precisely for Windows shapes
- **SHOULD-FIX** — `.claude/scripts/share-disable.sh:26` — detect_python is presence-only; Windows Store python stub passes `command -v` but fails on execution, so on a no-python Windows box the script dies with misleading messages instead of 'python is required'
  - evidence: task-watchdog.sh:33-45 documents this exact class and validates by execution (`"$_cand" -c 'pass'`); here json_field returns empty on stub failure, so the purge path dies at line 63 with 'marker has no well-formed install_uuid' — a wrong diagnosis
- **SHOULD-FIX** — `.claude/scripts/share-disable.sh:91` — Purge and disable are not atomic: an interrupt or config-write failure between the successful purge push (line 91) and the enabled=false write (line 101-115) leaves share enabled, and the next SessionEnd re-produces events from untouched local sources and silently re-pushes everything the user just typed 'purge' to delete
  - evidence: Ctrl-C after 'Removed this install's files' but before the python config update: share-config still enabled=true -> shared-memory-push.sh pulls the purge commit, shared-memory-produce.sh regenerates all events from .claude/observations|captures, push restores them to the remote
- **SHOULD-FIX** — `.claude/scripts/share-enable.sh:27` — detect_python presence-only probe: with the Windows Store python stub (or python2 as `python`), marker_field yields empty and the script actively misdiagnoses at line 57 — 'marker has no install_uuid — run bash scripts/update.sh to backfill' — sending a stranger down a wrong fix path
  - evidence: Contrast task-watchdog.sh:39-45 which execution-validates (`"$_cand" -c 'pass'`) citing exactly this stub; here `command -v python` alone selects the stub and every $PY call fails quietly inside command substitution
- **SHOULD-FIX** — `.claude/scripts/share-enable.sh:44` — cleanup() rm -rf's TMP_CLONE while the process cwd is inside it on cancel/die paths after `cd "$TMP_CLONE"` (line 74); Windows refuses to delete a process's cwd, leaving the temp clone behind and spraying rm errors on the user-cancel path
  - evidence: Type anything but 'enable' -> die at line 131 fires the EXIT trap with cwd=$TMP_CLONE; MSYS rm cannot remove the in-use directory (`cd /` first in cleanup fixes it); the happy path is safe only because line 138 cd's back to $ROOT
- **SHOULD-FIX** — `.claude/scripts/share-status.sh:18` — Same presence-only detect_python as share-enable/disable: Windows Store stub or python2 as `python` passes the probe and then the single $PY invocation fails (python2 also lacks sys.stdout.reconfigure), so status errors out instead of reporting or saying 'python 3 required'
  - evidence: task-watchdog.sh:33-45 documents the stub passing `command -v` while exiting nonzero; the fix pattern (execution-validated probe, python3-first) already exists in this repo
- **SHOULD-FIX** — `.claude/scripts/task-watchdog.sh:130` — The cwd-match fallback can scan the wrong session: it only counts transcripts with a cwd event in the first 40 lines, so a just-created current transcript (no cwd event yet) is excluded and candidates[1] becomes the session BEFORE the prior one — the actual prior session is skipped and the marker never records it that cycle
  - evidence: Primary path (line 95) assumes the newest file IS the current session and takes the 2nd; the fallback applies the same [1] index to a list that may already exclude the current session — the two branches encode contradictory assumptions about whether the current transcript is a candidate
- **SHOULD-FIX** — `.claude/scripts/task-watchdog.sh:217` — Redaction and signature normalization only match forward-slash paths — `~?/(?:Users|home)/...` and `/\S+` never match `C:\Users\darre\...` — so on Windows (this repo's primary platform) home-directory usernames and full local paths survive verbatim into observation evidence, summaries, and signatures
  - evidence: A failing `bash C:\Users\darre\secret-project\run.sh` lands unredacted in args_redacted/summary; blast radius is local-only (`.claude/observations` is gitignored and the share gate in redact-observation.sh strips evidence to {timestamp, kind}) but the schema's own redaction rule is violated on the platform it runs on
- **SHOULD-FIX** — `scripts/install.sh:60` — detect_json_tool trusts `command -v` without running the interpreter: the Windows-Store `python`/`python3` stub passes detection then fails at gen_uuid/write_marker_json (after all files copied, forcing rollback with a cryptic Store message); a python2 `python` also fails because write_marker_json uses `open(..., newline="\n")` (Python-3-only builtin kwarg).
  - evidence: On this machine `command -v python3` resolves to the WindowsApps stub (`.../Microsoft/WindowsApps/python3`); a stock Windows box with no real Python has the same stub for `python`, so detection succeeds and the clean die at line 65 never fires. Fix: validate candidates with `"$cand" -c 'import json, uuid'` before accepting.
- **SHOULD-FIX** — `scripts/install.sh:95` — Unquoted prefix strip `${tgt#$TARGET_PATH/}` (and `${src#$skel_claude/}` at line 419) treats the path as a glob pattern, so a target path containing `[`, `]`, `?`, or `*` fails to strip and records absolute machine paths as relpaths in the marker, silently breaking update.sh classification.
  - evidence: With TARGET_PATH=/tmp/proj[1], pattern `proj[1]/` matches literal `proj1/` not `proj[1]/`, so rel stays the full absolute path and both marker maps get absolute keys. Line 120 (`${csrc#"$HOME"}`) already uses the correct quoted form — apply it here: `${tgt#"$TARGET_PATH"/}`.
- **SHOULD-FIX** — `scripts/install.sh:194` — rollback expands "${ADDED_FILES[@]}" / "${ADDED_DIRS[@]}" (line 197) without the `:-` guard: under `set -u` on bash < 4.4 (macOS default 3.2) an empty array aborts rollback with 'unbound variable' whenever exactly one array is empty.
  - evidence: Merge install into a repo whose .claude dirs all exist: ensure_dir never fires, ADDED_DIRS stays empty; a mid-copy failure enters rollback (length check at 189 passes because ADDED_FILES is non-empty), removes files, then dies at line 197 before printing 'rollback complete'. Line 487 already uses the safe "${INSTALLED_HASHES[@]:-}" form — 194/197 should match.
- **SHOULD-FIX** — `scripts/install.sh:314` — MSYS-vs-Windows path-form split: default TARGET_PATH from `git rev-parse --show-toplevel` is `C:/...` while SOURCE_PATH is canonicalized to `/c/...`, so the `SOURCE_PATH = TARGET_PATH` self-install guard (line 325) and portable_source_path's `<self>` detection (line 116) both silently fail on Git Bash.
  - evidence: Verified live in this repo: `git rev-parse --show-toplevel` prints `C:/Users/darre/Dev/Claude-Skeleton`, `pwd -P` prints `/c/Users/darre/Dev/Claude-Skeleton`; string compare fails, so a Windows user who deletes the marker (as the line 334 die message itself instructs) and re-runs without --claude-only bypasses the guard. Fix: canonicalize the git-derived path with `cd ... && pwd -P` like the --target branch does (line 312).
- **SHOULD-FIX** — `scripts/install.sh:524` — Latent post-success rollback: under `set -o pipefail`, if any of the five counted dirs is ever absent, `find ... | wc -l` in the summary assignment exits nonzero, errexit fires inside summary(), and cleanup rolls back a fully completed install.
  - evidence: find's stderr is suppressed but its exit code still poisons the pipeline; `n_agents=$(find ... | wc -l | tr -d ' ')` failing triggers set -e after write_version_marker succeeded. Currently unreachable (verified all five template dirs contain real files) but one template reorganization away; append `|| true` inside each substitution.
- **SHOULD-FIX** — `scripts/update.sh:581` — Marker `commit` value is passed unvalidated to `git fetch origin "$commit"` — a hand-edited/hostile marker like `--upload-pack=<cmd>` becomes a git option
  - evidence: dump_marker accepts any string for commit; migrate_raw_baselines feeds it to `git fetch --quiet --depth 1 origin "$commit"` (line 581) and `worktree add ... "$commit"` (line 596), where a leading-dash value is parsed as an option (git fetch honors --upload-pack=<cmd> → arbitrary command execution from repo-tracked state). Guard with a hex check ([0-9a-f]{7,40}) or `--end-of-options`.
- **SHOULD-FIX** — `scripts/update.sh:658` — Unquoted pattern in prefix strip `${src#$skel_claude/}` — glob metacharacters in the source path corrupt relative paths
  - evidence: A checkout path containing [, ?, or * (e.g. ~/dev/skel[1]/) makes $skel_claude a glob pattern, so rel is mis-stripped and every file misclassifies/mis-targets. Everywhere else the script quotes pattern expansions (e.g. line 119 ${entry%%"$tab"*}). Fix: ${src#"$skel_claude"/}.
- **SHOULD-FIX** — `scripts/update.sh:815` — --check-remote on a pre-0.8.0 legacy marker silently upgrades it to JSON with `files: {}`, permanently defeating BACKFILL MODE
  - evidence: write_marker_json always emits out["files"] = files even when empty (line 334). After a legacy-marker user runs --check-remote, the next real update sees a files dict (dump_marker line 215 → HAS_FILES true), so maybe_announce_backfill (line 829) never sets BACKFILL_MODE: no warning, no forced interactive review, no 'marker migrated' notice, and orphan detection starts from an empty map. The R-lines get the non-empty guard for exactly this reason (comment lines 294-297) but F-lines don't.
- **SHOULD-FIX** — `scripts/update.sh:839` — BACKFILL MODE banner misstates current behavior: differing files are now classified LOCALLY_MODIFIED, not TEMPLATE_UPDATED
  - evidence: In backfill mode there are no raw baselines, so classify's fallback (lines 682-689) sets baseline = current-template hash; a file differing from the template then hits the line-695 branch → LOCALLY_MODIFIED. The banner ('Files differing from the template are classified as TEMPLATE_UPDATED') describes pre-Phase-52 behavior and tells the user to fear auto-apply for the wrong reason; help text lines 436-442 has the same stale claim.
- **SHOULD-FIX** — `scripts/update.sh:909` — With stdin at EOF (CI, piped run) the 'Copy all?' prompt for NEW files defaults to yes — files are applied non-interactively without --auto-apply
  - evidence: `read -r reply || reply="y"` (line 909): running `bash update.sh </dev/null` applies every NEW file with zero interaction, while all other prompts default to the safe choice (skip/keep/no). Inconsistent failure-mode default; EOF should mean skip, matching lines 948, 1029, 1069.
- **COSMETIC** — `.claude/scripts/commit.sh:19` — Extra args beyond $1 are silently dropped, defeating the guard's purpose for a common miscall shape
  - evidence: `commit.sh "msg" README.md` passes the guards (arg 2 never checked) and commits with just "msg" — the exact manager mistake the path-shape guard exists to catch, but only when the path lands in arg 1
- **COSMETIC** — `.claude/scripts/deploy.sh:21` — Extension guard rejects legitimate flag values, e.g. `--config=deploy.yml` as the first deploy flag
  - evidence: `echo '--config=deploy.yml' | grep -qE '\.(yml)$'` matches → exit 2, though the arg is a flag (contains '='), not a stray filename
- **COSMETIC** — `.claude/scripts/deploy.sh:28` — git diff-index without a preceding `git update-index --refresh` can false-positive on stat-dirty (touched-but-identical) files, blocking a genuinely clean deploy
  - evidence: After a checkout/clone tool touches mtimes, `git diff-index --quiet HEAD --` returns nonzero on content-identical files until the index stat cache refreshes; script then refuses with 'uncommitted changes' while `git status` shows clean
- **COSMETIC** — `.claude/scripts/plugin-context-matcher.sh:163` — Malformed manifest (missing frontmatter fences) dies via assert/StopIteration raw traceback rather than the script's own error style
  - evidence: A manifest without a closing '---' makes `next()` at line 164 raise StopIteration; the wrapper reports only 'verdict pass failed (python rc=1)' plus a traceback — loud, but off-register for a dispatched tool that elsewhere prints prefixed one-liners
- **COSMETIC** — `.claude/scripts/plugin-quality-check.sh:84` — Candidate mode with no working python exits 0 with zero output, which a standalone caller cannot distinguish from a clean audit
  - evidence: `[ -n "$PYBIN" ] || exit 0` applies in candidate mode too; the header (lines 74-76) names this exact misreport risk but the no-python branch still takes the silent path rather than an error line to stderr (in practice masked when invoked by the matcher, which needs python itself)
- **COSMETIC** — `.claude/scripts/plugin-quality-check.sh:178` — resolve_untouched with --plugin-dir override wrongly resolves real installed-plugin observations
  - evidence: A test run `--plugin-dir /tmp/synthetic` emits only synthetic pattern_ids, then the full resolve pass (installed mode, line 474-475) stamps resolved_at on every genuine code-quality-auditor observation absent from the synthetic scan — test flag mutates production observation state
- **COSMETIC** — `.claude/scripts/receipt-render.sh:75` — launch_url is interpolated into a PowerShell single-quoted string without the ''-escaping applied to ps_text — a project path containing an apostrophe breaks the toast
  - evidence: ps_text gets `sed "s/'/''/g"` (line 62) but launch_url (derived from $OUT_DIR, i.e. the project path) does not; a path like C:\Users\O'Brien\proj makes the PS command a syntax error, swallowed by `|| true` — silent toast loss, no injection beyond the user's own path
- **COSMETIC** — `.claude/scripts/receipt-render.sh:659` — chafa image leg runs before the python render, so it displays the previous receipt's stale latest-tight.png next to the new ANSI card
  - evidence: Line 659 shows $OUT_DIR/latest-tight.png, then line 665 renders the new receipt — when a PNG producer eventually exists, --ansi output pairs an old image with new text (dormant today per the comment, but the ordering is already wrong)
- **COSMETIC** — `.claude/scripts/receipt-render.sh:688` — cut -c1-120 truncates the toast text at a byte-agnostic character boundary that can split a UTF-8 multibyte sequence
  - evidence: A verdict whose 120th column lands mid-em-dash (receipts here use '—' routinely) hands PowerShell a mangled trailing byte in the notification text
- **COSMETIC** — `.claude/scripts/share-disable.sh:12` — No guard on ROOT: if the `cd` in the command substitution fails, ROOT is empty and the script silently reports 'not configured' against /.claude/share-config.json
  - evidence: ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)" with errors discarded; line 50's -f check on "/.claude/share-config.json" then exits 0 with a wrong message
- **COSMETIC** — `.claude/scripts/share-disable.sh:60` — shared-memory-git.sh is sourced without an existence check; if missing, `smg_ensure_clone` becomes command-not-found (127) and the user sees the misleading 'could not clone remote' die instead of 'library missing'
  - evidence: `. "$ROOT/.claude/lib/shared-memory-git.sh"` under set -uo (no -e) continues past a failed source; line 83's || die masks the real cause
- **COSMETIC** — `.claude/scripts/share-enable.sh:34` — marker_field has no try/except (unlike share-disable's json_field), so a corrupt or hand-edited .skeleton-version dumps a raw python traceback to stderr followed by the misleading 'no install_uuid — backfill' die
  - evidence: echo 'not json' > .claude/.skeleton-version; run share-enable.sh <url> -> json.JSONDecodeError traceback, then die at line 57 with the wrong remedy
- **COSMETIC** — `.claude/scripts/share-enable.sh:71` — git clone stderr is discarded (2>/dev/null), so auth failures, DNS errors, and URL typos all collapse into the generic 'could not clone remote' with no actionable detail
  - evidence: With GIT_TERMINAL_PROMPT=0 an auth-required HTTPS remote fails; the user can't distinguish bad-URL from bad-credentials from offline
- **COSMETIC** — `.claude/scripts/share-status.sh:36` — Corrupt share-config.json produces an unguarded json.load traceback and nonzero exit rather than a friendly one-line error, unlike every other failure mode in the share suite
  - evidence: echo '{' > .claude/share-config.json; bash share-status.sh -> JSONDecodeError traceback; the marker read at lines 39-45 is try/except-guarded but the config read is not
- **COSMETIC** — `.claude/scripts/shared-memory-push.sh:9` — Header usage block documents only the no-arg and --manual modes; --preview (implemented at line 29 and shipped as /share-preview) is missing from the usage comment
  - evidence: Lines 9-11 list two usages; `case "${1:-}" in --manual|--preview` accepts three
- **COSMETIC** — `.claude/scripts/shared-memory-push.sh:55` — record_last_push stores `git ls-files | wc -l` — total tracked files in the whole shared tree (all installs' events) — under the key 'files_pushed', which share-status.sh then renders as 'Files pushed: N', overstating what this install pushed once multiple installs share the remote
  - evidence: The say message honestly reads 'N file(s) tracked' but the marker key and share-status.sh line 60 label ('Files pushed') claim per-push semantics
- **COSMETIC** — `.claude/scripts/task-watchdog.sh:293` — One malformed numeric field (e.g. durationMs as a decimal string) raises ValueError and aborts the whole PYIMPL scan; the warning is emitted but the marker is not written, so the same poison transcript re-fails at every session start until a newer session displaces it as 'prior'
  - evidence: int('123.4') raises; no per-event try around the int() coercions at lines 293/317, unlike the json.loads and timestamp parsing which are guarded
- **COSMETIC** — `scripts/install.sh:200` — After a failed --mode=replace run, rollback prints 'rollback complete' but files destroyed by the overwrite path (line 392, no backup taken) are not restored, and rmdir only removes the leaf dir recorded by ensure_dir so `mkdir -p` intermediate parents linger.
  - evidence: process_file overwrite does `cp -p` with no backup and records nothing in ADDED_FILES; rollback loops only over added files/dirs, so the target is left in a mixed old/new state while the message implies full restoration.
- **COSMETIC** — `scripts/install.sh:316` — In the default-target branch, git is invoked at line 314 before the `command -v git` existence check at line 316, so a machine without git dies with the misleading 'not in a git repository' instead of 'git not on PATH'.
  - evidence: Line 314 `git rev-parse --show-toplevel 2>/dev/null` fails with exit 127 when git is absent; the || die fires first with the wrong diagnosis. Move the command -v check above the branch.
- **COSMETIC** — `scripts/install.sh:560` — The gitignored `.first-run` flag is written before summary() but never tracked in ADDED_FILES, so an interrupt/failure during summary rolls back the marker and all files yet leaves an orphan `.first-run`, which can trigger the one-time SessionStart welcome in a repo with no actual install.
  - evidence: Ctrl-C between line 560 and end of summary: cleanup rollback removes ADDED_FILES (including the marker via line 494) but `.first-run` survives; append it to ADDED_FILES on the non-dry-run write.
- **COSMETIC** — `scripts/update.sh:79` — marker_hash_* embed literal TAB characters in parameter expansions (lines 79, 89, 101, 717) while raw_baseline_* deliberately use tab=$'\t'
  - evidence: The comment at line 114 acknowledges the safer style ('avoid embedding literal tabs'); an editor retab or copy-paste of the older helpers silently breaks the path→hash map. Align the older helpers with the quoted-$tab style.
- **COSMETIC** — `scripts/update.sh:366` — ADDED_DIRS is tracked (lines 23, 871) but rollback never removes created directories
  - evidence: After a failed run that added new files in new dirs, rollback rm's the files but leaves the empty directories behind; either rmdir them in rollback or drop the dead bookkeeping.
- **COSMETIC** — `scripts/update.sh:394` — On Ctrl-C the cleanup trap runs twice (INT handler's `exit` re-triggers the EXIT trap)
  - evidence: trap cleanup EXIT INT TERM (line 394) + `exit "$exit_code"` at line 357: rollback re-runs and 'update failed — restoring previous state' prints twice; the [ -f ] guards make it functionally harmless. Standard fix: `trap - EXIT` inside cleanup, or trap INT/TERM to `exit` only.
- **COSMETIC** — `scripts/update.sh:908` — --dry-run still blocks on interactive prompts despite help text promising 'print the update plan without changing anything'
  - evidence: apply_new/apply_template_updates/apply_orphans prompt before consulting DRY_RUN (e.g. line 908 vs. 914), so a dry run over a real terminal requires answering questions; also apply_orphans in dry-run returns without counting APPLIED (line 1073), inconsistent with apply_new's dry-run counting (line 914).
- **COSMETIC** — `scripts/update.sh:1116` — After a clone-based update, marker `source` records the deleted TMP_CLONE_DIR path
  - evidence: resolve_skeleton_root sets SOURCE_PATH to a mktemp dir that cleanup deletes; write_version_marker persists it via portable_source_path (a temp path is neither <self> nor under $HOME on most systems), so the migration fallback at line 578 can never use it. Harmless but misleading provenance.
- **COSMETIC** — `scripts/update.sh:1137` — Typo 'entrie(s)' in user-facing output (lines 1137 and 1174)
  - evidence: printf 'match-rebaseline: %s entrie(s)…' — should be 'entry(ies)' or just 'entries'.

## Wave G — close

*(summary lands here at close: findings by wave and severity; the BLOCKER list as the pre-sharing punch list; ledger 100% verification)*
