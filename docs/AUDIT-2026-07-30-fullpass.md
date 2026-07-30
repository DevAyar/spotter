# Spotter full pass — every-line scrub (2026-07-30)
<!-- cruft-check:exempt-historical -->

Phase 105. Frozen working record, exempt-historical from birth. **241 tracked files, 33,064 lines.** Findings go to observations (severity in notes); NOTHING is fixed in-pass. The ledger below is the proof of coverage: a file without a reviewed-at stamp is not reviewed, and the pass is not done until every row is stamped. Mirror-parity rule: byte-identical mirror pairs (md5-verified at review time) share one review and both rows stamp with a parity note.

Severity scale: BLOCKER-for-strangers / SHOULD-FIX / COSMETIC. CLEAN is a legitimate verdict.

## Wave A — shipped scripts (33 files, 9,451 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/scripts/commit.sh | 57 | — | — |
| .claude/scripts/cruft-check.sh | 657 | — | — |
| .claude/scripts/deploy.sh | 51 | — | — |
| .claude/scripts/drift-check.sh | 74 | — | — |
| .claude/scripts/goals-surface.sh | 120 | — | — |
| .claude/scripts/graduation-review.sh | 110 | — | — |
| .claude/scripts/plugin-context-matcher.sh | 461 | — | — |
| .claude/scripts/plugin-discovery.sh | 370 | — | — |
| .claude/scripts/plugin-quality-check.sh | 489 | — | — |
| .claude/scripts/receipt-render.sh | 722 | — | — |
| .claude/scripts/share-disable.sh | 128 | — | — |
| .claude/scripts/share-enable.sh | 159 | — | — |
| .claude/scripts/share-status.sh | 64 | — | — |
| .claude/scripts/shared-memory-produce.sh | 112 | — | — |
| .claude/scripts/shared-memory-push.sh | 138 | — | — |
| .claude/scripts/task-watchdog.sh | 524 | — | — |
| scripts/.gitkeep | 0 | — | — |
| scripts/install.sh | 562 | — | — |
| scripts/update.sh | 1184 | — | — |
| template/.claude/scripts/commit.sh | 57 | — | — |
| template/.claude/scripts/deploy.sh | 51 | — | — |
| template/.claude/scripts/drift-check.sh | 74 | — | — |
| template/.claude/scripts/goals-surface.sh | 120 | — | — |
| template/.claude/scripts/plugin-context-matcher.sh | 461 | — | — |
| template/.claude/scripts/plugin-discovery.sh | 370 | — | — |
| template/.claude/scripts/plugin-quality-check.sh | 489 | — | — |
| template/.claude/scripts/receipt-render.sh | 722 | — | — |
| template/.claude/scripts/share-disable.sh | 128 | — | — |
| template/.claude/scripts/share-enable.sh | 159 | — | — |
| template/.claude/scripts/share-status.sh | 64 | — | — |
| template/.claude/scripts/shared-memory-produce.sh | 112 | — | — |
| template/.claude/scripts/shared-memory-push.sh | 138 | — | — |
| template/.claude/scripts/task-watchdog.sh | 524 | — | — |

## Wave B — hooks + libs (36 files, 4,770 lines)

| file | lines | reviewed at | verdict |
|---|---|---|---|
| .claude/hooks/.gitkeep | 0 | — | — |
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
| template/.claude/hooks/.gitkeep | 0 | — | — |
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
| .claude/agents/.gitkeep | 0 | — | — |
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
| .claude/commands/.gitkeep | 0 | — | — |
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
| .claude/skills/.gitkeep | 0 | — | — |
| .claude/skills/bash-safety/SKILL.md | 94 | — | — |
| .claude/skills/god-file-grep-first/SKILL.md | 45 | — | — |
| .claude/skills/plugin-roster-search/SKILL.md | 49 | — | — |
| .claude/skills/post-edit-test-suggest/SKILL.md | 41 | — | — |
| .claude/skills/schema-verify-before-edit/SKILL.md | 37 | — | — |
| .claude/skills/token-efficiency-monitor/SKILL.md | 57 | — | — |
| CLAUDE.md | 38 | — | — |
| CLAUDE_MANAGER.md | 557 | — | — |
| ROUTING.md | 58 | — | — |
| template/.claude/agents/.gitkeep | 0 | — | — |
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
| template/.claude/commands/.gitkeep | 0 | — | — |
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
| template/.claude/skills/.gitkeep | 0 | — | — |
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
| .claude/captures/.gitkeep | 0 | — | — |
| .claude/captures/6f7e14b7176e480c04f38c4383ca09763bdc2b9015ac4eedcaeba3ca6e59cac8.md | 56 | — | — |
| .claude/captures/README.md | 42 | — | — |
| .claude/captures/fe22198210607aea481ac447d5620d9450b7f5d6e6d9dcdf3a2fd9dacb1b3f75.md | 43 | — | — |
| .claude/observations/.gitkeep | 0 | — | — |
| .claude/observations/README.md | 30 | — | — |
| .claude/scripts/.gitkeep | 0 | — | — |
| .claude/scripts/drafts/.gitkeep | 0 | — | — |
| .claude/scripts/drafts/README.md | 55 | — | — |
| .claude/specs/README.md | 27 | — | — |
| .claude/specs/propagate-skeleton-tv-eog.md | 84 | — | — |
| .claude/telemetry/README.md | 34 | — | — |
| .claude/telemetry/events/.gitkeep | 0 | — | — |
| .claude/telemetry/model-pricing.json | 22 | — | — |
| .claude/telemetry/optimizer-proposals.json | 152 | — | — |
| .claude/telemetry/retier-proposals.json | 19 | — | — |
| .claude/telemetry/sessions/.gitkeep | 0 | — | — |
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
| template/.claude/captures/.gitkeep | 0 | — | — |
| template/.claude/captures/README.md | 42 | — | — |
| template/.claude/observations/.gitkeep | 0 | — | — |
| template/.claude/observations/README.md | 30 | — | — |
| template/.claude/scripts/.gitkeep | 0 | — | — |
| template/.claude/scripts/drafts/.gitkeep | 0 | — | — |
| template/.claude/scripts/drafts/README.md | 55 | — | — |
| template/.claude/specs/.gitkeep | 0 | — | — |
| template/.claude/specs/README.md | 27 | — | — |
| template/.claude/telemetry/README.md | 34 | — | — |
| template/.claude/telemetry/events/.gitkeep | 0 | — | — |
| template/.claude/telemetry/model-pricing.json | 22 | — | — |
| template/.claude/telemetry/optimizer-proposals.json | 19 | — | — |
| template/.claude/telemetry/retier-proposals.json | 19 | — | — |
| template/.claude/telemetry/sessions/.gitkeep | 0 | — | — |
| template/PLUGINS.md.template | 27 | — | — |
| template/docs/ARCHITECTURE.md.template | 51 | — | — |
| template/docs/SESSION_LOG.md.template | 40 | — | — |
| template/docs/STATUS.md.template | 46 | — | — |

## Wave G — close

*(summary lands here at close: findings by wave and severity; the BLOCKER list as the pre-sharing punch list; ledger 100% verification)*
