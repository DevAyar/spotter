# Phase 34 — Bundle install (v1.1.4 → ecosystem composition)

**Snapshot:** 2026-05-17
**Skeleton baseline:** v1.1.4 (post-Phase-33 directive layer alignment)
**Phase scope:** Install 6 ecosystem plugins per ROADMAP § v1.1.5+ pre-pinball queue. Trust-tier-1 (Anthropic-official, from `claude-plugins-official` marketplace): `feature-dev`, `code-review`, `commit-commands`, `security-guidance`. Trust-tier-2 (community-curated): `superpowers` (`obra/superpowers-marketplace`), `claude-mem` (`thedotmack/claude-mem`).
**Discipline:** HALT-ON-FAILURE; HALT-ON-CONCERN if vetting surfaces destructive shell patterns, network-exfiltration code paths, or broad filesystem-write hooks. Partial state acceptable; blind continue not.
**Status at draft time:** Vetting complete. **claude-mem deferred to Phase 34b** (eyes-open install pending) — proceeding with 5/6. Phase 34b drafts chat-side after Phase 34 commits.

---

## Pre-flight findings

### Marketplace state (pre-install)

```
~/.claude/plugins/marketplaces/
└── claude-plugins-official/      ← already registered
```

`obra/superpowers-marketplace` NOT yet registered — user will need `/plugin marketplace add obra/superpowers-marketplace` before installing superpowers.

### Installed-plugins state (pre-install)

`~/.claude/plugins/installed_plugins.json` contains exactly one entry:

```json
{
  "42crunch-api-security-testing@claude-plugins-official": [
    {
      "scope": "user",
      "installPath": "C:\\Users\\darre\\.claude\\plugins\\cache\\claude-plugins-official\\42crunch-api-security-testing\\1.0.1",
      "version": "1.0.1",
      "installedAt": "2026-05-03T12:08:14.856Z",
      "gitCommitSha": "56273e0e20762d76640838300a7431c4260cad32"
    }
  ]
}
```

This matches the state-dump §14 baseline. Post-install (full success path) should grow to 7 entries.

### Cache directory state

`~/.claude/plugins/cache/claude-plugins-official/` contains only `42crunch-api-security-testing/1.0.1/`. Cache directory currently mirrors `installed_plugins.json` exactly — clean state for the bundle install.

### claude-mem in claude-plugins-official?

Negative. `claude-mem` does NOT appear in either `plugins/` or `external_plugins/` subdirs of `claude-plugins-official`. Its `/plugin install` path (if it exists at all) routes through a different marketplace — investigation surfaced concerns; see § Trust-tier-2 vetting.

---

## Trust-tier-1 vetting

All 4 plugins from `claude-plugins-official`, authored by Anthropic. Per Phase 34 brief, trust-tier-1 plugins still get a code-quality-auditor scan (defense-in-depth — Anthropic-curated ≠ automatically clean).

### feature-dev — CLEAN

- **Manifest:** `"Comprehensive feature development workflow with specialized agents for codebase exploration, architecture design, and quality review"` — author: Anthropic.
- **Components:** `agents/` + `commands/`. No `hooks/` directory.
- **plugin-quality-check.sh findings:** none. No hooks to validate; no destructive shell patterns in component bodies.
- **Hook conflict surface:** none (no hooks).
- **Verdict:** Install.

### code-review — CLEAN

- **Manifest:** `"Automated code review for pull requests using multiple specialized agents with confidence-based scoring"` — author: Anthropic.
- **Components:** `commands/` only. No `hooks/` directory.
- **plugin-quality-check.sh findings:** none. No hooks; commands are slash-command definitions.
- **Hook conflict surface:** none.
- **Verdict:** Install.

### commit-commands — CLEAN

- **Manifest:** `"Streamline your git workflow with simple commands for committing, pushing, and creating pull requests"` — author: Anthropic.
- **Components:** `commands/` only. No `hooks/` directory.
- **plugin-quality-check.sh findings:** none.
- **Hook conflict surface:** none.
- **Overlap-with-skeleton note:** This plugin's commit/push/PR-open slash commands will sit alongside the skeleton's `.claude/scripts/commit.sh` mechanical wrapper. **Not a conflict** (slash command vs script — different invocation surfaces) but a candidate for Phase 36 retire/repurpose evaluation: if `commit-commands` covers the skeleton's three-commit-cadence discipline (Commit A / B / C per Phase 10), the skeleton's `commit.sh` could be retired in favor of the plugin. Defer the decision to the 2–3 week evaluation window per Phase 35 brief.
- **Verdict:** Install.

### security-guidance — CLEAN (with observations)

- **Manifest:** `"Security reminder hook that warns about potential security issues when editing files, including command injection, XSS, and unsafe code patterns"` — author: Anthropic.
- **Components:** `hooks/` only (no commands or agents).
- **hooks.json (verbatim):**
  ```json
  {
    "PreToolUse": [
      {
        "hooks": [
          { "type": "command", "command": "python3 ${CLAUDE_PLUGIN_ROOT}/hooks/security_reminder_hook.py" }
        ],
        "matcher": "Edit|Write|MultiEdit"
      }
    ]
  }
  ```
  - `type: "command"` — schema-valid (heuristic ii passes).
  - `${CLAUDE_PLUGIN_ROOT}` — plugin-relative path resolution (good citizen — won't break if cache layout shifts).
  - `matcher: "Edit|Write|MultiEdit"` — scoped to file-editing tools.
- **Hook script:** `hooks/security_reminder_hook.py` — pattern-match on path + content + emit reminder strings. No destructive shell, no network, no file writes outside `/tmp/security-warnings-log.txt` (debug log; silently ignores write failures).
- **plugin-quality-check.sh findings:** none. Hook is `type: "command"` (validates heuristic ii); script body has no destructive shell patterns against unguarded paths (heuristic iii passes); manifest's declared `hooks/` component exists and is populated (heuristic i passes).
- **Hook conflict surface:** **No conflict with skeleton's PreToolUse `bash-safety` / `powershell-safety` hooks** — those match `Bash|PowerShell`, security-guidance matches `Edit|Write|MultiEdit`. Different tool scope, no overlap. Both run on PreToolUse, but on disjoint tool sets.
- **Observation (non-blocking):** Hook logs to `/tmp/security-warnings-log.txt` unconditionally — on Windows + Git Bash, `/tmp` is remapped (typically to `$TEMP`); on a fresh Windows session without Git Bash mapping, the log write silently fails (intentional per the script's `except: pass`). Not a security concern; just a portability note.
- **Verdict:** Install.

---

## Trust-tier-2 vetting

### superpowers — CLEAN

- **Source:** `obra/superpowers-marketplace` on GitHub.
- **Marketplace structure:** Standard CC marketplace shape — `.claude-plugin/marketplace.json` lists `superpowers` plugin entry.
- **plugin.json:** name: superpowers; author: Jesse Vincent (obra). Description: bundle of agentic skills + hooks for plan-mode, brainstorming, root-cause-analysis, etc.
- **Components:** `agents/`, `commands/`, `skills/`, `hooks/`.
- **hooks.json structure:**
  ```json
  {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          { "type": "command", "command": "<bash script under ${CLAUDE_PLUGIN_ROOT}/hooks/>" }
        ]
      }
    ]
  }
  ```
  - `type: "command"` — schema-valid.
  - `${CLAUDE_PLUGIN_ROOT}` — plugin-relative path (good citizen).
  - `matcher: "startup|clear|compact"` — fires on session start, post-clear, post-compact.
- **Hook conflict surface with skeleton:** **Potential additive load on SessionStart hook chain.** Skeleton's `SessionStart` chain currently runs (per `.claude/settings.json`): drift-check.sh → cruft-checker (24h cooldown) → code-quality-auditor (24h cooldown) → session-rules emitter. superpowers adds one more entry. Order is determined by CC's hook ordering rules (TBD post-install). Worst case: superpowers' bootstrap output gets interleaved with skeleton's session-rules emitter, producing a noisier session-start preamble. Not a deny/block surface; informational only.
- **plugin-quality-check.sh findings (anticipated):** Pending post-install scan. Source spot-check shows no destructive shell patterns, no network exfiltration in hook body; `type: "command"` validates heuristic ii.
- **Verdict:** Install — but verify the post-install hook-chain ordering in Step 6.

### claude-mem — **DEFERRED TO PHASE 34B** (eyes-open install pending)

Multiple findings exceed the HALT-ON-CONCERN bar (`destructive shell patterns in hooks, network exfiltration, broad filesystem access`). claude-mem is **not abandoned** — Phase 34b (drafts chat-side after Phase 34 commits) will install it eyes-open with explicit acknowledgement of the concerns below. The 4 concerns below are documented verbatim as **Phase 34b's input contract**:

#### Concern 1 — `npx claude-mem install` auto-installs Bun + uv globally

The primary install path advertised in `thedotmack/claude-mem` README is `npx claude-mem install`. This is NOT a `/plugin install`-style CC plugin install — it's a Node CLI invocation that:
- Installs **Bun** as a global runtime (modifies `~/.bun/`, prepends to `PATH` via shell rc files).
- Installs **uv** (Python package manager) as a global dependency (modifies `~/.local/bin/uv`).
- Edits shell rc files (`~/.bashrc`, `~/.zshrc`, possibly `$PROFILE` on Windows) to extend `PATH`.

**Skeleton-scope impact:** These side effects are global filesystem state outside `~/.claude/`. The skeleton's audit infrastructure (`drift-checker`, `cruft-checker`, `code-quality-auditor`) only inspects `~/.claude/` and the project directory — it has NO visibility into `~/.bun/`, `~/.local/bin/`, or shell rc files. Once installed via this path, claude-mem's continued presence is invisible to the skeleton's audit triad.

#### Concern 2 — Background worker service

`claude-mem` runs a Bun-based worker process in the background — long-running ambient state, similar in shape to a daemon. Skeleton has no mechanism today to detect or audit ambient daemons.

#### Concern 3 — Optional opt-in network destinations

Per README: claude-mem can be configured to feed memory state to **Telegram, Discord, or Slack**. Opt-in (not on-by-default), but the network-exfiltration code path exists in the codebase regardless of whether it's configured. This crosses the HALT-ON-CONCERN "network exfiltration" bar by code-path existence, even though it's gated.

#### Concern 4 — OpenClaw install uses `curl ... | bash`

A related tool (`OpenClaw`) advertised alongside claude-mem uses the `curl ... | bash` pipe-to-shell install pattern. Not claude-mem itself, but indicates a pattern the upstream author considers acceptable.

#### Open question (Phase 34b investigation candidate) — `/plugin install claude-mem` path semantics

The README also mentions installing via `/plugin install claude-mem`. UNCERTAIN whether this path:
- (a) Bypasses the Bun/uv global installs (delivers a constrained, CC-plugin-shaped artifact only)
- (b) Triggers the same side effects (Bun/uv install runs via the plugin's post-install hook)
- (c) Doesn't exist at all (README is forward-referencing a future option)

claude-mem is NOT in `claude-plugins-official`. Its `/plugin install` path would require a marketplace registration we have NOT yet performed — investigation surfaced no clear marketplace pointer for it. The README's `/plugin install claude-mem` claim cannot be verified against a known marketplace without further investigation.

This is an **open question** to be answered by Phase 34b investigation, not a CONCERN per se. The 4 concerns above are the canonical input contract.

#### Phase 34 disposition

**Decision (user, 2026-05-17):** Defer claude-mem to **Phase 34b** (drafts chat-side after Phase 34 commits). Phase 34 ships 5/6.

**Rationale:**
1. The HALT-ON-CONCERN bar fired on multiple independent triggers. Per Phase 34 brief: "Concerning ≠ 'I don't fully understand'; concerning = 'this looks risky.'" Concerns 1–4 each meet that bar independently and warrant a dedicated phase.
2. The other 5 plugins are clean and ship now without entangling them in the claude-mem decision.
3. Phase 34b will install claude-mem eyes-open — explicit acknowledgement of the 4 concerns, install via a chosen path, and post-install audit instrumentation tailored to the concerns (e.g. record `~/.bun` + `~/.local/bin/uv` baselines if Concern 1 fires; document the worker-daemon footprint if Concern 2 fires).
4. Phase 35 (2–3 week evaluation window) runs on the 5 plugins on schedule; claude-mem joins the evaluation pool once Phase 34b lands.

**Phase 34b input contract:** The 4 concerns above are the canonical input for Phase 34b drafting. Phase 34b must address each by name and either (a) confirm it's no longer applicable, (b) accept the side effect with documented mitigation, or (c) document why the chosen install path avoids it.

**Candidate install paths for Phase 34b to evaluate** (carried forward from this vetting; not pre-decided):
- `/plugin install claude-mem@<marketplace>` — requires marketplace discovery first. Verify post-install whether Bun/uv side effects fire.
- `npx claude-mem install` — accept Bun + uv as global deps with documented baselines + rollback procedure.
- Hybrid — install constrained subset via plugin path, opt out of features that require Bun/uv.

---

## Install commands (autonomous bash CLI path)

**Mechanism update (mid-execution):** `/plugin` slash commands aren't available in Claude Code Desktop / web (known issue: GitHub #42142, #56623). The bash form `claude plugin install <name>@<marketplace>` works in all environments and is the documented workaround per GitHub #18088. Phase 34 switched from slash-command user-handoff to autonomous bash invocation.

**Claude binary used:** `/c/Users/darre/AppData/Roaming/Claude/claude-code/2.1.138/claude.exe` (Claude Code Desktop install). Not on `PATH` by default — Phase 34 invoked via absolute path. **Phase 34b should expect the same: `claude` is not in PATH in this environment; invoke via absolute path.**

### Trust-tier-1 (4 plugins — marketplace already registered)

```bash
CLAUDE="/c/Users/darre/AppData/Roaming/Claude/claude-code/2.1.138/claude.exe"
"$CLAUDE" plugin install feature-dev@claude-plugins-official --scope user
"$CLAUDE" plugin install code-review@claude-plugins-official --scope user
"$CLAUDE" plugin install commit-commands@claude-plugins-official --scope user
"$CLAUDE" plugin install security-guidance@claude-plugins-official --scope user
```

### Trust-tier-2 — superpowers (register marketplace, then install)

```bash
"$CLAUDE" plugin marketplace add obra/superpowers-marketplace
"$CLAUDE" plugin marketplace list   # confirm the registered token
"$CLAUDE" plugin install superpowers@superpowers-marketplace --scope user
```

**Empirical:** `obra/superpowers-marketplace` registered as `superpowers-marketplace` (not `obra-superpowers-marketplace`). Confirm via `marketplace list` post-add to extract the actual token before the `install` call.

### Trust-tier-2 — claude-mem — **DEFERRED TO PHASE 34B**

Not installed in this phase. Phase 34b (drafts chat-side after Phase 34 commits) will install eyes-open against the 4 documented concerns in § Trust-tier-2 vetting.

### HALT-ON-FAILURE protocol

Sequential install with `set -e` halt-on-failure. If any `claude plugin install` exits non-zero, the chain stops; partial state documented in § Failures; commit reflects what actually succeeded.

**Phase 34 empirical:** all 5 installs succeeded; no halt fired.

---

## Post-install verification

### `installed_plugins.json` (post-install)

7 entries total (pre-install 42crunch + 5 new from Phase 34):

| Plugin | Version | `gitCommitSha` | Notes |
|---|---|---|---|
| 42crunch-api-security-testing@claude-plugins-official | 1.0.1 | 56273e0e… | unchanged (pre-existing) |
| feature-dev@claude-plugins-official | **unknown** | (none) | trust-tier-1 |
| code-review@claude-plugins-official | **unknown** | (none) | trust-tier-1 |
| commit-commands@claude-plugins-official | **unknown** | (none) | trust-tier-1 |
| security-guidance@claude-plugins-official | **unknown** | (none) | trust-tier-1 |
| superpowers@superpowers-marketplace | **5.1.0** | f2cbfbef… | trust-tier-2 |

**Observation — version field gap:** The 4 trust-tier-1 plugins record `"version": "unknown"` because their `plugin.json` manifests don't declare a `version` field (verified in pre-flight). 42crunch + superpowers ship versions in their manifests, so they get recorded properly. Not a defect of `claude plugin install` — it's a manifest-shape question for the trust-tier-1 plugins. **Phase 35 watch item:** does `plugin update` work correctly on plugins recorded as `version: "unknown"`?

### `settings.json` enabled-plugins gap (GitHub #20661)

**No gap.** All 6 plugins (1 pre-existing + 5 new) appear in BOTH `installed_plugins.json` AND `enabledPlugins` in `~/.claude/settings.json`. The known CC quirk (plugin lands in `installed_plugins.json` but stays disabled in `enabledPlugins`) did NOT reproduce in this environment with `claude plugin install --scope user`. Possibly resolved upstream by 2.1.138, or specific to a different install path (e.g. manual `installed_plugins.json` edits).

`settings.json` also grew an `extraKnownMarketplaces` field listing both `claude-plugins-official` + `superpowers-marketplace` with their GitHub repo metadata. This field did NOT exist pre-install — added by `plugin marketplace add` and the install machinery.

### `plugin-quality-check.sh` (3-heuristic scan on each new plugin)

```bash
QC=.claude/scripts/plugin-quality-check.sh
bash "$QC" --plugin-dir ~/.claude/plugins/cache/claude-plugins-official/feature-dev/unknown        # exit 0, no findings
bash "$QC" --plugin-dir ~/.claude/plugins/cache/claude-plugins-official/code-review/unknown        # exit 0, no findings
bash "$QC" --plugin-dir ~/.claude/plugins/cache/claude-plugins-official/commit-commands/unknown    # exit 0, no findings
bash "$QC" --plugin-dir ~/.claude/plugins/cache/claude-plugins-official/security-guidance/unknown  # exit 0, no findings
bash "$QC" --plugin-dir ~/.claude/plugins/cache/superpowers-marketplace/superpowers/5.1.0          # exit 0, no findings
```

All 5 plugins pass the 3 heuristics:
- **i** (manifest declared component path exists + populated)
- **ii** (`hooks.json` schema-valid: `type: "command"`)
- **iii** (no destructive shell patterns against unguarded paths)

No observations files emitted to `.claude/observations/` for any new plugin.

### Hook chain analysis

| Hook event | Pre-Phase-34 entries | New entries (Phase 34) | Total post-install |
|---|---|---|---|
| **SessionStart** | 5 (user: rules-reminder, SESSION_LOG-tail; project: drift-check, cruft-check, code-quality-auditor) | +1 (superpowers `session-start`) | 6 |
| **PreToolUse** | 2 (bash-safety on `Bash`, powershell-safety on `PowerShell`) | +1 (security-guidance on `Edit\|Write\|MultiEdit`) | 3 |
| **PreCompact** | 1 (rules-reminder) | 0 | 1 |

**No conflicts:**
- Security-guidance PreToolUse matches `Edit|Write|MultiEdit` — **disjoint** from skeleton's `Bash|PowerShell` matchers. No interleaved deny/allow surface.
- Superpowers SessionStart emits `hookSpecificOutput.additionalContext` JSON via stdout (standard contract); doesn't fight skeleton's SessionStart hooks which use `cat` / `node -e ...` to print plain stdout.

**superpowers SessionStart payload:** reads `skills/using-superpowers/SKILL.md` (~indeterminate size), wraps in `<EXTREMELY_IMPORTANT>` block declaring "You have superpowers", emits as `additionalContext`. Adds context-tokens to every session start; magnitude TBD (Phase 35 watch item).

**superpowers hook execution model:** invokes `run-hook.cmd` (polyglot batch/bash wrapper) which detects Windows + locates Git Bash via standard install paths or PATH probe, then `exec`s the extensionless `session-start` bash script. Defensive engineering — handles bash-on-PATH absence by silently exiting 0 (plugin still works, just without context injection). `set -euo pipefail` in the bash script.

### Cache directory footprint

```
~/.claude/plugins/cache/
├── claude-plugins-official/
│   ├── 42crunch-api-security-testing/1.0.1/
│   ├── code-review/unknown/
│   ├── commit-commands/unknown/
│   ├── feature-dev/unknown/
│   └── security-guidance/unknown/
└── superpowers-marketplace/
    └── superpowers/5.1.0/
```

Total disk footprint: not measured precisely; superpowers cache is the heaviest (skills + tests + assets + docs).

### Components catalogue (Phase 35 input)

| Plugin | Agents | Commands | Skills | Hooks |
|---|---|---|---|---|
| feature-dev | code-architect, code-explorer, code-reviewer | feature-dev | — | — |
| code-review | — | code-review | — | — |
| commit-commands | — | clean_gone, commit, commit-push-pr | — | — |
| security-guidance | — | — | — | PreToolUse (Edit\|Write\|MultiEdit) |
| superpowers | — | — | brainstorming, dispatching-parallel-agents, executing-plans, finishing-a-development-branch, receiving-code-review, requesting-code-review, subagent-driven-development, systematic-debugging, test-driven-development, using-git-worktrees, using-superpowers, verification-before-completion, writing-plans, writing-skills (14 total) | SessionStart (startup\|clear\|compact) |

### Other observations

- **superpowers ships `CLAUDE.md`** at plugin root — this is the plugin's GitHub contributor guidelines (PR submission rules), NOT a CC-directive-layer injection. It's not loaded as project CLAUDE.md. **No collision with skeleton's `CLAUDE.md`.**
- **superpowers ships `package.json`** — minimal (4 fields), `"main": ".opencode/plugins/superpowers.js"` is opencode (Sourcegraph) metadata, vestigial for CC. No npm deps pulled in.
- **superpowers ships `scripts/`** — `bump-version.sh` + `sync-to-codex-plugin.sh` — plugin-maintainer artifacts, not runtime invocations. Not invoked during normal use.
- **security-guidance hook script** logs to `/tmp/security-warnings-log.txt` unconditionally. On Windows + Git Bash, `/tmp` is remapped; on a fresh Windows session without Git Bash, the log write silently fails (intentional `except: pass`). Portability note, not a security concern.

## Cumulative observations

### What changed in `~/.claude/` globally

| Surface | Pre-Phase-34 | Post-Phase-34 | Delta |
|---|---|---|---|
| `~/.claude/plugins/marketplaces/` | 1 (`claude-plugins-official`) | 2 (+`superpowers-marketplace`) | +1 marketplace |
| `~/.claude/plugins/cache/` | 1 plugin (42crunch) | 6 plugins | +5 |
| `~/.claude/plugins/installed_plugins.json` | 1 entry | 6 entries | +5 |
| `~/.claude/settings.json` `enabledPlugins` | 1 entry | 6 entries | +5 |
| `~/.claude/settings.json` `extraKnownMarketplaces` | absent | present (2 entries) | new field |

### Unexpected behavior

None during install. All 5 installs completed without prompts, conflicts, or errors. Total install time approx 30 seconds (4 trust-tier-1 installs finished within ~3 seconds; marketplace add + superpowers install took ~20 seconds dominated by `git clone` of the superpowers-marketplace repo).

### Rollback procedure

```bash
CLAUDE="/c/Users/darre/AppData/Roaming/Claude/claude-code/2.1.138/claude.exe"
"$CLAUDE" plugin uninstall feature-dev@claude-plugins-official
"$CLAUDE" plugin uninstall code-review@claude-plugins-official
"$CLAUDE" plugin uninstall commit-commands@claude-plugins-official
"$CLAUDE" plugin uninstall security-guidance@claude-plugins-official
"$CLAUDE" plugin uninstall superpowers@superpowers-marketplace
"$CLAUDE" plugin marketplace remove superpowers-marketplace
```

## Phase 35 evaluation guidance

**Evaluation window:** 2–3 weeks of normal skeleton work (per Phase 35 brief).

### Command overlap with skeleton primitives — track dispatch decisions

| Skeleton primitive | Bundle plugin overlap | Dispatch decision data point |
|---|---|---|
| `.claude/scripts/commit.sh` (three-commit cadence A/B/C mechanical wrapper) | `commit-commands:/commit`, `/commit-push-pr` | When does Claude dispatch each? Does `/commit` cover Phase 10 three-commit cadence semantics or does `commit.sh` retain unique discipline? **Phase 36 retire candidate if `/commit` is strictly broader.** |
| `Plan` agent + plan-mode | `feature-dev:/feature-dev` workflow; `superpowers:writing-plans`, `executing-plans` skills | When does Claude reach for `Plan` vs `feature-dev` vs `writing-plans`? Track 5–10 plan-mode dispatches and surface patterns. |
| `Explore` agent (broad codebase research) | `feature-dev:code-explorer` agent | Same query class — track which gets picked. |
| `code-quality-auditor` helper | `feature-dev:code-reviewer` agent, `code-review:/code-review` command, `superpowers:receiving-code-review`/`requesting-code-review` skills | Code-quality-auditor is post-install plugin-source audit; the bundle's "code review" surfaces are pre-merge change review. **Disjoint roles** — track whether Claude conflates them. |
| `plan-coordinator` helper (Explore/Plan/Review/Final-plan dispatcher) | `superpowers:subagent-driven-development`, `dispatching-parallel-agents` skills | Skeleton's wrapping vs superpowers' built-in patterns. **Phase 36 retire candidate if superpowers covers the territory.** |
| Skeleton's three-commit cadence + bash-safety + path-shape guards | `superpowers:verification-before-completion` skill | Track whether the skill captures all the discipline or just a subset. |

### Hook chain timing

Skeleton's SessionStart chain was already 5 entries (rules-reminder, SESSION_LOG-tail, drift-check, cruft-check, code-quality-auditor). superpowers adds 1 more for 6 total. Track:
- End-to-end SessionStart latency before vs after the bundle (subjective at first; quantify if it becomes noticeable).
- Whether the cruft-check + code-quality-auditor 24h cooldowns continue to gate correctly with the new entry interleaved.

### Performance impact

- Token budget: superpowers SessionStart injects skill-system intro text on every startup/clear/compact. Watch context budget vs pre-bundle baseline.
- security-guidance fires on every Edit/Write/MultiEdit. Watch reminder-noise level (how often it surfaces vs how often it's actionable).

### Phase 36 retire/repurpose candidates (carried forward from this artifact)

1. `.claude/scripts/commit.sh` → retire if `commit-commands:/commit-push-pr` covers Phase 10 three-commit-cadence semantics.
2. `plan-coordinator` helper → retire if `superpowers:subagent-driven-development` + `dispatching-parallel-agents` cover the dispatch territory.
3. Skeleton's `self-audit-helper` → re-evaluate: does `code-review` plugin's audit surface overlap? (Likely no — code-review is pre-merge change review, self-audit-helper is meta-system drift detection — but verify empirically.)
4. Skeleton's "three-commit cadence" CLAUDE_MANAGER subsection → keep (this is dispatch discipline, not a tool); but consider whether `commit-commands` slash commands obviate the manual cadence enforcement.

### Phase 34b inputs

Phase 34b (claude-mem install) inherits:
- The 4 concerns documented in § Trust-tier-2 vetting → `claude-mem` (verbatim input contract).
- The autonomous-bash-CLI install path (no slash command available; absolute `claude.exe` path documented above).
- The version-field gap observation (`installed_plugins.json` records `"version": "unknown"` if the plugin's manifest doesn't declare one — verify claude-mem's manifest behavior).
- The `extraKnownMarketplaces` field shape — if Phase 34b adds a new marketplace, expect this field to grow.

## Failures (if any)

None. All 5 installs completed cleanly. claude-mem deferred to Phase 34b per § Trust-tier-2 vetting → § Phase 34 disposition.
