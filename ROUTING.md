# Routing — claude-skeleton

The routing table maps task patterns to handlers. The manager consults this at session start to know "for X, dispatch Y."

This table is the mechanical "for X, dispatch Y" map. The strategic "when to dispatch a helper vs read files directly, when to escalate vs propose, when to question the user's framing vs execute" judgment patterns live in `CLAUDE_MANAGER.md` — the routing table assumes the dispatch decision has been made and answers "to whom."

## Baseline routes

| Task pattern | Handler | Type | Context to load |
|---|---|---|---|
| "Look up X in docs / library / API" | `research-helper` | Agent | Question scope + expected output shape |
| "Check if doc section X is still accurate" | `audit-helper` | Agent | Doc path + section header |
| "Grade the last N sessions" | `monitoring-helper` | Agent | Rubric + session count |
| "Plan a multi-file change to X" | `plan-coordinator` | Agent | Goal + constraints |
| "Commit the staged changes" | `.claude/scripts/commit.sh` | Script | Commit message |
| "Deploy the project" | `.claude/scripts/deploy.sh` | Script | Deploy flags. Deploy command resolved by `project-tuner-helper` as N/A — the skeleton has no deploy step (releases publish as git tags + GitHub Release), so the script is unused in this install. |
| "About to edit `.claude/settings.json` / `package.json` / `tsconfig.json` / workflow YAML" | `schema-verify-before-edit` | Skill | The file being edited |
| "About to Read a file > 1000 lines" | `god-file-grep-first` | Skill | Target symbol / section |
| Edit on source file under `src/` or `lib/` | `post-edit-test-suggest` | Skill | Test command |
| Recursive scan / project-wide file count (`find`, `grep -r`, `wc` on globs) | `bash-safety` | Skill | Command scope + project root |
| Session start after compact | `sessionstart-rules.sh` | Hook | `compactPrompt` from settings |
| Before auto-compact | `precompact-backup.sh` | Hook | STATUS.md, SESSION_LOG.md, CLAUDE.md |
| Bash / PowerShell tool call (destructive-pattern gate, fail-closed) | `pretooluse-bash-safety.sh` / `pretooluse-powershell-safety.sh` | Hook | Pattern libs in `.claude/lib/` |
| Session start (plugin-source audit, 24h cooldown) | `.claude/scripts/plugin-quality-check.sh --hook` | Hook | Installed plugin cache |
| Session start (ambient cost line + optimizer nudge) | `sessionstart-cost-summary.sh` | Hook | `.claude/telemetry/` + `gate-config.json` |
| Session end (telemetry + shared-memory push) | `sessionend-observe.sh` | Hook | CC stdin payload → `generate-session-telemetry.sh` |
| Session end (retier/optimizer draft fold) | `sessionend-cost-proposals.sh` | Hook | Staged `.claude/telemetry/*.draft.json` |
| "Install / re-install / troubleshoot install of claude-skeleton" | `integration-installer` | Agent | Target path + desired mode |
| "Set up new project / install skeleton / tune skeleton to this project" | `project-tuner-helper` | Agent | (no preload — inspects target on dispatch) |
| "What do I have available / list installed agents / where is X" | `system-memory-helper` | Agent | (no preload — walks `.claude/` on dispatch) |
| "Find a handler for capability X" | `plugin-roster-search` | Skill | (lightweight grep across descriptions) |
| "Modify agent N's tools / scope / description" | `agent-slicer` | Agent | Target agent file |
| "Audit the meta-system for drift / orphans / dead refs" | `self-audit-helper` | Agent | (no preload — walks `.claude/` on dispatch) |
| Token usage on subtask exceeds 1.5× expected envelope | `token-efficiency-monitor` | Skill | Task type + actual cost |
| "What patterns are recurring / what should be automated" | `workflow-suggester` | Agent | `.claude/observations/` (+ existing captures for idempotency) |
| "Am I up to date with skeleton?" | `drift-checker` | Agent | (no preload — reads `.claude/.skeleton-version`) |
| "Did the prior session have anything slow or failing?" | `task-watchdog` | Agent | (no preload — reads the prior session's transcript) |
| "Build the approved script capture(s)" | `script-builder` | Agent | Approved `script` captures in `.claude/captures/` |
| "Vet plugin X / audit installed plugin source" | `code-quality-auditor` | Agent | Plugin name or cache path |
| "What did that session cost / which helpers burn tokens / should anything re-tier?" | `token-cost-monitor` | Agent | (no preload — reads `.claude/telemetry/`) |
| "What should this project's manager do differently / review the gates" | `manager-optimizer` | Agent | (no preload — closed input list per its definition) |
| "Audit artifact fit / overlap / gaps across the artifact set" | `artifact-fit-analyzer` | Agent | (no preload — walks `.claude/` on dispatch) |
| "What plugins are out there for this project / refresh the plugin manifest" | `plugin-discovery-agent` | Agent | (no preload — runs `plugin-discovery.sh` over marketplace clones + installed registry) |
| "Which plugins fit this project / verdict the manifest" | `plugin-context-matcher` | Agent | Draft manifest at `.claude/recommendations/manifest.md` (refresh via discovery first if stale) |
| `/commit "<message>"` | `.claude/commands/commit.md` → `commit.sh` | Slash command | Commit message |
| `/audit <doc>:<section>` | `.claude/commands/audit.md` → `audit-helper` | Slash command | Doc path + section header |
| `/deploy [flags]` | `.claude/commands/deploy.md` → `deploy.sh` | Slash command | Deploy flags. Deploy command resolved as N/A — the skeleton has no deploy step (releases publish as git tags + GitHub Release), so the command is unused in this install. |
| `/smoke-test` | `.claude/commands/smoke-test.md` (T3 plugin marker) | Slash command | Last deploy target. Real impl lives in `browser-tester` plugin; manual fallback if not installed. |
| `/share-enable <remote-url>` | `.claude/commands/share-enable.md` → `share-enable.sh` | Slash command | Remote URL + typed `enable` confirmation |
| `/share-disable [--purge-remote]` | `.claude/commands/share-disable.md` → `share-disable.sh` | Slash command | (typed `purge` confirmation for the purge path) |
| `/share-status` | `.claude/commands/share-status.md` → `share-status.sh` | Slash command | (read-only) |
| `/share-push` | `.claude/commands/share-push.md` → `shared-memory-push.sh --manual` | Slash command | (no input — on-change gate) |
| `/share-preview` | `.claude/commands/share-preview.md` → `shared-memory-push.sh --preview` | Slash command | (no input — dry-run) |
| `/goals <goal statement>` | `.claude/commands/goals.md` (research → one clarify round → spec) | Slash command | Goal statement; writes `.claude/specs/<slug>.md` draft |
| Session start (due scheduled goals, 24h cooldown) | `goals-surface.sh` via `sessionstart-rules.sh` | Hook | `.claude/specs/` approved+scheduled frontmatter |

<!-- Project-specific routes: project-tuner-helper extends below -->
