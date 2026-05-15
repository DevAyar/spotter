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
| "Deploy the project" | `.claude/scripts/deploy.sh` | Script | Deploy flags. Requires `N/A — skeleton has no deploy step; published as git tags + GitHub Release` placeholder filled by `project-tuner-helper` before the script is usable. |
| "About to edit `.claude/settings.json` / `package.json` / `tsconfig.json` / workflow YAML" | `schema-verify-before-edit` | Skill | The file being edited |
| "About to Read a file > 1000 lines" | `god-file-grep-first` | Skill | Target symbol / section |
| Edit on source file under `src/` or `lib/` | `post-edit-test-suggest` | Skill | Test command |
| Recursive scan / project-wide file count (`find`, `grep -r`, `wc` on globs) | `bash-safety` | Skill | Command scope + project root |
| Session start after compact | `sessionstart-rules.sh` | Hook | `compactPrompt` from settings |
| Before auto-compact | `precompact-backup.sh` | Hook | STATUS.md, SESSION_LOG.md, CLAUDE.md |
| "Install / re-install / troubleshoot install of claude-skeleton" | `integration-installer` | Agent | Target path + desired mode |
| "Set up new project / install skeleton / tune skeleton to this project" | `project-tuner-helper` | Agent | (no preload — inspects target on dispatch) |
| "What do I have available / list installed agents / where is X" | `system-memory-helper` | Agent | (no preload — walks `.claude/` on dispatch) |
| "Find a handler for capability X" | `plugin-roster-search` | Skill | (lightweight grep across descriptions) |
| "Modify agent N's tools / scope / description" | `agent-slicer` | Agent | Target agent file |
| "Audit the meta-system for drift / orphans / dead refs" | `self-audit-helper` | Agent | (no preload — walks `.claude/` on dispatch) |
| Token usage on subtask exceeds 1.5× expected envelope | `token-efficiency-monitor` | Skill | Task type + actual cost |
| "What patterns are recurring / what should be automated" | `workflow-suggester` | Agent | `docs/SESSION_LOG.md` |
| `/commit "<message>"` | `.claude/commands/commit.md` → `commit.sh` | Slash command | Commit message |
| `/audit <doc>:<section>` | `.claude/commands/audit.md` → `audit-helper` | Slash command | Doc path + section header |
| `/deploy [flags]` | `.claude/commands/deploy.md` → `deploy.sh` | Slash command | Deploy flags. Requires `N/A — skeleton has no deploy step; published as git tags + GitHub Release` placeholder filled by `project-tuner-helper`. |
| `/smoke-test` | `.claude/commands/smoke-test.md` (T3 plugin marker) | Slash command | Last deploy target. Real impl lives in `browser-tester` plugin; manual fallback if not installed. |

<!-- Project-specific routes: project-tuner-helper extends below -->
