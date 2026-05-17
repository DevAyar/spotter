# CC-side audit of v1.1.4

Snapshot at `0760836` (HEAD on `main` after the v1.1.4 state-dump artifact landed). Read-only audit producing artifact for reconciliation with chat-side audit. Composes with `docs/AUDIT-v1.1.4-state.md` (state-dump, Phase 29) and the chat-audit handoff (architectural framing + ecosystem composition). CC owns mechanical verification + code-shape + reconciliation.

---

## Section 1: Validation pass

Six findings the chat-audit flagged for CC verification.

### Finding 1: `/goals` doesn't exist as a command — **CONFIRMED**

`ls .claude/commands/` and `ls template/.claude/commands/` both list 4 files: `audit.md`, `commit.md`, `deploy.md`, `smoke-test.md`. No `goals.md` in either tree. But `CLAUDE_MANAGER.md`'s `### Invoke /goals vs ship direct` H3 (per state-dump line 32) is registered as a TEMPLATE STUB. The H3 points at vapor — the directive layer documents a dispatch decision for a command that has never shipped. Same shape as `integration-checker`. Surfaced for Phase 33 (directive-layer alignment).

### Finding 2: `integration-checker` absent from both agent trees — **CONFIRMED**

`find .claude template -name "*integration-checker*"` returns zero hits. `CLAUDE_MANAGER.md` carries `### Apply integration-checker before any plugin install` as TEMPLATE STUB. Same vapor-pointer issue as `/goals`. Chat-audit's recommendation to reframe as DEFERRED (queued for v2.0 per ROADMAP) rather than TEMPLATE STUB is the right move — see Phase 33.

### Finding 3: Captures = 0 committed; observations = 107 gitignored — **CONFIRMED + extension**

```
.claude/captures/    1 file  (README.md only)
.claude/observations/  107 files  (gitignored *.json)
```

The capture-output side of the loop has produced zero tracked artifacts. workflow-suggester has been refined across 5+ commits (`ec26450`, `abb2a05`, `c421381`, `ca2495f`, `b74bb6e`) but its output channel is empty.

**Spot-check extension** (schema conformance per chat-audit's bonus request): opened 2 observation files. Both write `pattern_type: "other"` with `notes` field ✓, `source: "cruft-checker"` ✓, `evidence` array with `kind`/`summary`/`timestamp` ✓, `resolved_at` set to timestamps where the pattern is gone ✓. **Schema violation found:** [.claude/observations/004d4dea...json](.claude/observations/004d4dea00eaf25c605c4906e8a3f852dfc3654e8a53cfbf1b787b44ec1cfc28.json) line 13 has `"occurrences": 1`. session-observer.schema.md (line 18) says `occurrences (integer ≥ 2)` with prose "Minimum 2 (a single sighting isn't a pattern)". cruft-check.sh:108 and plugin-quality-check.sh:108 both `occurrences = 1` on new emissions. Quietly-accepted drift — see Section 4 finding H1.

### Finding 4: `.skeleton-version` is v0.4 fossil — **CONFIRMED**

```
version: 0.4.0
commit: 315954ddeb20e392cc95e857aeb852a117f93dec
installed_at: 2026-05-13T19:29:47Z
mode: merge
claude_only: true
source: /c/Users/darre/Dev/Claude-Skeleton
```

Shell-export format (pre-0.8.0). Missing `cached_skeleton_head` + `cached_skeleton_head_fetched_at` (added v1.1+ Phase 4 per state-dump line 686-689). Missing per-file `files` object. drift-checker reads this marker on every SessionStart hook fire; v0.4 fossil means drift-checker sees `version: 0.4.0` vs running off VERSION (current `1.1.4`). Whether this surfaces a drift notice depends on `cached_skeleton_head` presence — and it's absent. Per drift-checker's spec (state-dump line 245), absent cache produces a "cache empty" notice OR silent depending on the agent's branch logic. **Not directly verified in this audit** — flagged for reconciliation.

### Finding 5: Template-richer drift on 2 agents — **CONFIRMED**

```
.claude/agents/05_meta/self-audit-helper.md    73 lines
template/.claude/agents/05_meta/self-audit-helper.md   92 lines
.claude/agents/05_meta/project-tuner-helper.md  124 lines
template/.claude/agents/05_meta/project-tuner-helper.md  188 lines
```

For self-audit-helper, template has extended Severity rubric: explicit HIGH/MEDIUM/LOW with example findings + "escalate if unsure" rule at template lines 61-81. Dogfood (.claude/agents/05_meta/self-audit-helper.md:61-65) has a flat one-line listing. For project-tuner-helper, template has the Phase 4f additions (`## Output contract` + `## --report-only mode` per state-dump line 922-924). Both drifts are **template ahead of dogfood**. Mirror-invariant pattern is for them to be byte-identical modulo placeholder resolution (per CLAUDE_MANAGER § Dogfood mirror invariants). Direction question — back-mirror to dogfood, or accept asymmetric (template adds advanced behavior dogfood doesn't need)? Resolution: queue for Phase 31 amendment or Phase 33 alignment.

### Finding 6: No `.claude/agent-memory/` directory — **CONFIRMED**

`ls .claude/agent-memory/` → `No such file or directory`. PreCompact hook (`precompact-backup.sh`) creates the dir on first fire via `mkdir -p` (line 16). Directory absence proves PreCompact has never fired in this dogfood checkout. Two interpretations: (a) no auto-compact event ever triggered (dogfood sessions stay under the context window — plausible), (b) hook is registered correctly but the trigger has just never been hit. Settings.json:21-31 registers the PreCompact hook with `matcher: "auto"` + `type: "command"` — registration is correct. Confirms the chat-audit's interpretation: PreCompact is wired but untested in dogfood.

---

## Section 2: Code-shape audit

### `scripts/install.sh` (465 lines)

**Shape:** Clean 5-section discipline; `set -euo pipefail`; rollback trap on EXIT/INT/TERM. Atomic marker write via `<file>.tmp.$$` + `mv -f` (line 124). Three-mode design (fresh/merge/replace) with top-level file safety (top-level files NEVER overwritten regardless of mode — line 307). Color handling honors `NO_COLOR`. JSON-tool detection and SHA-256 command detection at startup.

**Findings:**
- **install.sh:394-402 — `replace` mode interactive confirm.** Reads stdin for "YES" confirmation. In non-interactive environments (CI, curl-pipe install) this hangs. CI doesn't test replace mode. **LOW** — by design, but limits CI coverage. See Section 4 H7.
- **install.sh:244 — `i < 5` ancestor search cap.** The skeleton-source auto-detection walks up to 5 parent dirs. Sufficient for normal layouts; insufficient if script is buried deep (rare).
- **install.sh:236, 263 — `pwd -P` canonicalization.** On Windows Git Bash returns POSIX paths like `/c/Users/...`. Error messages may display unexpected path shapes to Windows users — cosmetic.
- **install.sh:282 — `find ... | head -1`.** Pipefail not bypassed inside `$(...)`; `head` SIGPIPE on find could theoretically propagate. Negligible in practice — find walks one directory.
- **Mid-install cancel (Ctrl+C):** trap on INT/TERM → cleanup → rollback ✓. Rollback removes ADDED_FILES via `rm -f` and ADDED_DIRS via `rmdir 2>/dev/null` (non-empty dirs intentionally not removed).

### `scripts/update.sh` (857 lines)

**Shape:** Same strict-mode discipline. Two trap-based recovery primitives (`MODIFIED` for backup-on-overwrite, `DELETED_BACKUPS` for orphan deletes). Bash 3.2-compatible map emulation via `MARKER_HASH_ENTRIES` parallel-arrays helpers (lines 44-80) — macOS compatibility. Atomic marker write via `<file>.tmp.$$` + `mv -f` (line 214).

**Six-way classification correctness (lines 438-447):** verified by trace.

| recorded | current | template | Result | Line |
|---|---|---|---|---|
| r=c=t (all equal) | UNCHANGED | 438 |
| r=c, t differs | TEMPLATE_UPDATED | 440 |
| r=t, c differs | LOCALLY_MODIFIED | 442 (`r != c` AND `c != t`) |
| c=t, r differs | LOCAL_MATCHES_TEMPLATE | 444 (else) |
| all differ | LOCALLY_MODIFIED | 442 |
| file in template, absent in target | NEW | 422 |
| marker has entry, template doesn't | ORPHAN | 451-465 |

All 7 reachable cases covered correctly.

**`--auto-apply` discipline (chat-audit prediction verification):**
- apply_new (line 603-604): AUTO_APPLY → reply="y" → accepts NEW ✓
- apply_template_updates (line 639-640): AUTO_APPLY → action="A" → accepts TEMPLATE_UPDATED ✓
- apply_local_modifications (line 712-714): AUTO_APPLY → warns but still iterates with per-file prompt; `read -r reply || reply="k"` defaults to keep on EOF — NEVER auto-overwrites ✓
- apply_orphans (line 758-760): AUTO_APPLY → reply="n" → NEVER auto-deletes ✓

**`--check-remote` (lines 474-523):** `timeout 10 git ls-remote --tags ...` with semver-tag parse via inline Python. Atomic marker write preserves all other fields ✓.

**Findings:**
- **update.sh:483 — `timeout` not POSIX-portable.** macOS without coreutils lacks `timeout`; the inline `if !` catches non-zero exit but the error message ("failed to fetch tags from URL (timeout or network error)") hides the actual cause. **MEDIUM** — see Section 4 H4.
- **update.sh:431-436 — silent backfill assignment.** When `hash_recorded` is empty (no marker entry), assigns `hash_current` to `hash_recorded` AND sets `BACKFILL_MODE=true`. The `maybe_announce_backfill` warning (line 534) surfaces this loudly ✓. Pre-existing local modifications get silently treated as the baseline in this path — fundamentally ambiguous, but the warning + disabling auto-apply mitigates.
- **update.sh:716-744 — `apply_local_modifications` loop runs even when AUTO_APPLY=true.** The loop still iterates and prompts; `read -r reply || reply="k"` defaults to keep on EOF. Sub-optimal UX (one prompt per file in non-interactive context, all defaulting to keep) but not a bug.
- **`mid-update SIGINT`:** trap → cleanup → rollback. Restores MODIFIED via backup and DELETED_BACKUPS via backup ✓. Backup files in same directory → atomic-on-same-filesystem.
- **Concurrent update race:** PID-suffixed `.bak.$$` files don't collide; target file write isn't atomic if two updates target same path. Edge case — not real-world concern.

### `.claude/hooks/*.sh` (5 scripts)

| Hook | Shape | Fail-mode | `hookSpecificOutput` |
|---|---|---|---|
| `sessionstart-rules.sh` (76 lines) | Read settings → invoke drift-check + task-watchdog → fold into single additionalContext | Silent no-op if jq/settings missing; sub-script failures suppressed via `\|\| true` | Wraps additionalContext in `{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: ...}}` ✓ |
| `pretooluse-bash-safety.sh` (86 lines) | Stdin JSON → parse tool_name + tool_input.command → match against destructive-bash-patterns | **Fail-closed**: jq missing, empty input, unparseable, missing fields → deny ✓ | `{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "allow\|deny", permissionDecisionReason: ...}}` ✓ |
| `pretooluse-powershell-safety.sh` (96 lines) | Same shape as bash variant; enables `shopt -s nocasematch` for case-insensitive match | Same fail-closed posture; disables nocasematch after loop (line 87, 91) — clean state handling ✓ | Same shape ✓ |
| `precompact-backup.sh` (33 lines) | Copy STATUS.md / SESSION_LOG.md / CLAUDE.md to timestamped backup dir | `mkdir -p` for backup dir; never fired in dogfood (Section 1 #6) | N/A — output to filesystem, not stdout |
| `sessionend-observe.sh` (33 lines) | `${CLAUDE_PROJECT_DIR:?}` guard; write timestamp marker + append SESSION_LOG entry | No-op if SESSION_LOG missing | N/A |

**Findings:**
- **Concurrent SessionStart firings.** dogfood has 3 SessionStart entries (sessionstart-rules + cruft-check --hook + plugin-quality-check --hook). Whether Claude Code runs them sequentially or in parallel is undocumented in the hook scripts themselves. Each script writes to its OWN marker (`.last-cruft-check`, `.last-plugin-quality-check`), so they don't collide. The observations directory could see two producers writing simultaneously, but per-file `os.replace` is atomic — patterns sharing a `pattern_id` would race but be self-correcting on the next scan. **LOW** — see Section 4 H9.
- **`sessionstart-rules.sh:46, 51` — stderr suppressed on sub-script failures.** Diagnostic loss on drift-check / task-watchdog failure. Acceptable for SessionStart context where blocking the session is worse than losing diagnostics.
- **PreCompact registration verified** at settings.json:21-31 with `matcher: "auto"` + `type: "command"` ✓; agent-memory dir absence (Section 1 #6) proves the hook hasn't fired but is correctly wired.

### `.claude/lib/destructive-{bash,powershell}-patterns.sh`

**bash patterns (6 regexes, 10 shapes):**
```
rm -rf
git push --force / -f
git reset --hard origin/
chmod -R 777
(curl|wget) ... | (bash|sh)
```

POSIX ERE; anchored with `(^|[[:space:]]) ... ([[:space:]]|$)` for portability (avoids `\b` non-portability) ✓.

**PowerShell patterns (8 regexes):**
```
Remove-Item -Recurse -Force (and aliases ri/rm/del/erase, short flags either order — 2 patterns for r-then-f and f-then-r)
Format-Volume / Clear-Disk
Set-ExecutionPolicy Unrestricted|Bypass
(iwr|Invoke-WebRequest|curl|wget) | (iex|Invoke-Expression)
git push --force / -f
git reset --hard origin/
```

Case-insensitive via consumer `shopt -s nocasematch` ✓.

**Pattern-completeness findings (Section 4 H6):**
- Bash misses: `rsync --delete /`, `dd of=/dev/*`, `mkfs.* /dev/*`, `truncate -s 0 /etc/*`, `> /etc/*` shell redirect overwrites, `find / -delete`, `shred / srm` against load-bearing paths.
- PowerShell misses: `Stop-Computer -Force` / `Restart-Computer -Force`, `Set-Acl` privilege escalation, `Compress-Archive -Force` overwrite, `wmic` destructive shapes.

Patterns are POSIX ERE-correct; regex shape is fine.

### `.claude/agents/05_meta/*.schema.md` (3 files)

**`session-observer.schema.md` (120 lines):** 9 required + 1 conditional fields. Field constraints documented (pattern_id = SHA-256 of `pattern_type + normalized_signature`; ISO-8601 UTC for timestamps; ≥120 char caps on summary/args_redacted). Producers (4): session-observer, task-watchdog, cruft-checker, code-quality-auditor. Consumers (1+): workflow-suggester. Resolution lifecycle documented with per-producer scope semantics (full / session-bounded / scoped resolve passes). Extensibility carve-outs documented.

**Schema-violation finding** (Section 4 H1): `occurrences` field constraint is `≥ 2` but cruft-check.sh:108 and plugin-quality-check.sh:108 emit at `occurrences = 1` on new observations. The cruft-check.sh comment at line 111 explicitly acknowledges this. Either tighten producers (breaks deterministic single-sighting semantics) OR amend schema with a carve-out for deterministic-detection producers (cruft-checker, code-quality-auditor).

**`workflow-suggester.schema.md` (148 lines):** 7 required + 1 optional frontmatter fields, 4 body sections. `suggested_artifact_type` enum has 9 values (script/skill/agent/command/manual_action/unclear/doc-fix/infrastructure-fix/lesson). Producer (1): workflow-suggester. Consumers: script-builder (script-typed only); manual resolution for doc-fix/infrastructure-fix/lesson; plugin_quality routed to existing `manual_action` value (Phase 24 design — no new enum value needed).

**`script-builder.schema.md` (213 lines):** Documents 5-section bash discipline, not a frontmatter schema. Constraints: `set -uo pipefail` floor, `set -e` when halting on first error, `trap '...' ERR` when mutating state, path-shape guards, bash-safety integration for recursive scans, filename `<pattern_id>.sh.draft`, 30-80 line target. Includes complete realistic example.

All three schemas internally consistent. Producer/consumer enumerations match the agent docs.

### `.claude/scripts/cruft-check.sh` (631 lines)

**Shape:** Bash wrapper (5-section) around inline Python helper. Cooldown logic (lines 31-42) only enforced with `--hook` flag. Python helper emits to observations dir via `os.replace` atomic write. Resolution pass walks all existing cruft-checker observations and marks unsighted ones as resolved.

**9 heuristics implemented:**
- **i** (link-missing-file): walks markdown links, checks file existence, line 226-247.
- **ii** (link-missing-header): for `.md` targets with anchors, checks header exists, line 249-259.
- **iii** (VERSION ↔ CHANGELOG mismatch): equality check, line 264-267.
- **iv** (README count claims): regex pulls 5 numbers; counts actual under `template/.claude/`, line 269-318.
- **v** (phase references): valid set built from CHANGELOG + handoff + git log; EXEMPT_PHASE_FILES skipped, line 320-357.
- **vii** (schema field-count claims): parses field tables in `*.schema.md`, looks for `<schema-name>... N-field` mismatches, line 359-421.
- **viii** (hook entry config schema): validates `type: "command"` + non-empty `command` on all settings.json hook entries, line 423-473.
- **ix** (tag ↔ VERSION ↔ CHANGELOG at HEAD): only fires when HEAD is exact-tag-match, line 475-493.
- **x** (cross-doc stale version refs): most complex; EXEMPT_VFILES + EXEMPT_VDIRS + EXEMPT_VREGION_FILES + inline marker, line 495-616.

Heuristic vi is deferred (per state-dump line 395).

**Findings:**
- **Header undercount.** Line 3 says "Implements 7 heuristics (i, ii, iii, iv, v, vii, ix, x)" — lists 8, omits viii (which is implemented at line 423), real count is 9. Documentation drift inside the script. **LOW** — see Section 4 H2.
- **Confidence assignment deviates from schema default.** Lines 106-111: `med` at 1-4 occurrences, `high` at ≥5. Skips `low` tier. Schema default (session-observer.schema.md line 23) is `2=low, 3-4=med, ≥5=high`. Schema permits producer override; deviation not documented in cruft-check.sh. **LOW** — see Section 4 H3.
- **Exemption logic is sophisticated and correct.** `find_exempt_regions` (line 520-555) handles V-prefixed headings at H2/H3 level with same-or-shallower-level closing semantics. `find_exempt_lines` (line 563-578) handles on-line vs preceding-line marker placement. EXEMPT_VFILES (7 entries) and EXEMPT_VDIRS (2 prefixes) cover documented historical-content files.
- **Cooldown discipline correct.** `--hook` gate at line 32; epoch comparison at line 38-41; cooldown marker write only on Python helper success (line 624-630) — failure leaves cooldown un-touched so a retry next session is possible. ✓

---

## Section 3: CI + permissions audit

### `.github/workflows/ci.yml` (65 lines)

**Matrix:** 3 OS × 6 scenarios = 18 scenario runs per push. `fail-fast: false`. All scenarios use `shell: bash` — important for Windows (Git Bash). Setup: `actions/checkout@v4`, `actions/setup-python@v5` (3.11), environment show, then 2 `--help` smoke tests, then 6 scenarios.

**Three-platform parity:** All 6 scenarios are listed identically for each OS via the matrix. ✓

**Coverage gaps:**
- No scenario for `update.sh --check-remote` — network-touching flow is untested. **MEDIUM** — see Section 4 H5.
- No scenario for `install.sh --mode=replace` — interactive confirmation flow untestable as currently written. **MEDIUM** — see Section 4 H7.
- No scenario testing hook execution (sessionstart-rules / pretooluse-bash-safety / pretooluse-powershell-safety / sessionend-observe). A hook regression would land silently.
- No scenario testing destructive-pattern matching (no PreToolUse hook firing in CI).
- No scenario for `plugin-quality-check.sh` fixture-based testing.
- No scenario for `cruft-check.sh` fixture-based testing.
- No explicit scenario for the `LOCAL_MATCHES_TEMPLATE` classification class (line 444 of update.sh).

CI is solid for install/update happy paths and for the documented `local-mod-detect` + `local-mod-preserve` flows. The gaps are real but quantifiable.

### `.claude/settings.json` allow/deny patterns

**Allows (11 entries):** Bare tool identifiers: Bash, PowerShell, Edit, Write, Read, Glob, Grep, WebFetch, WebSearch, NotebookEdit, Agent.

**Denies:** None. Permission denials rely entirely on the PreToolUse safety hooks (bash + powershell).

**Security gap assessment:**
- If PreToolUse hooks are removed from settings.json (manual edit or merge accident), there is no destructive-pattern blocking. Hooks fail-closed if the lib is missing, but if the hook ENTRY is missing, there's no fail-closed posture. This is a structural risk inherent to the design choice (single-source-of-truth via hooks, no schema-level deny lists). Documented in CLAUDE_MANAGER `## Plugin discipline` and `## Dogfood mirror invariants`.
- **No allow-by-command-pattern grants** (e.g. `Bash(git status:*)`). Means every Bash command goes through the PreToolUse hook → match against destructive patterns → allow if no match. Tighter than command-pattern allows because the path is uniform.

### `.claude/settings.json` hook entries (Phase 14d verification)

**Hook entries verified `type: "command"` ✓:**

```
PreCompact:      1 entry (matcher: "auto")              precompact-backup.sh
PreToolUse:      2 entries (Bash + PowerShell)          bash-safety + powershell-safety hooks
SessionStart:    3 entries (no matcher — fire on all)   sessionstart-rules + cruft-check --hook + plugin-quality-check --hook
SessionEnd:      1 entry                                 sessionend-observe.sh
TOTAL:           7 entries
```

All entries use `bash "$CLAUDE_PROJECT_DIR/..."` — proper env-var quoting ✓. No bare-relative paths.

**Template parity:** `template/.claude/settings.json.template` has 6 entries (same as dogfood minus cruft-check.sh SessionStart — dogfood-only). Verified at line 52-78 of the template.

**Output-shape conformance:** All scripts that emit JSON wrap output in `hookSpecificOutput` per the Phase 14e lesson (verified in Section 2 hook table).

---

## Section 4: Findings CC adds

Line-by-line surface review surfaced ten items chat-audit did not.

**H1 — Schema violation: `occurrences: 1` in cruft-checker + code-quality-auditor emissions.** [.claude/scripts/cruft-check.sh:108](.claude/scripts/cruft-check.sh) and [.claude/scripts/plugin-quality-check.sh:108](.claude/scripts/plugin-quality-check.sh) both write `occurrences = 1` on new observations. [.claude/agents/05_meta/session-observer.schema.md:18](.claude/agents/05_meta/session-observer.schema.md) constrains `occurrences (integer ≥ 2)`. Confirmed via [.claude/observations/004d4dea...json:13](.claude/observations/004d4dea00eaf25c605c4906e8a3f852dfc3654e8a53cfbf1b787b44ec1cfc28.json) which carries `"occurrences": 1`. **Severity: HIGH** (schema contract violation visible in committed wire format). **Suggested fix:** amend session-observer.schema.md with a carve-out for deterministic-detection producers ("producers with full-resolve-pass semantics MAY emit at `occurrences = 1` because each scan is an independent atomic detection"). Alternative — tighten producers to count repeated scan-emissions — breaks the resolve-on-absence semantics and gains nothing.

**H2 — `cruft-check.sh` header heuristic undercount.** [.claude/scripts/cruft-check.sh:3](.claude/scripts/cruft-check.sh) says "Implements 7 heuristics" but lists 8 (`i, ii, iii, iv, v, vii, ix, x`) and the body implements `viii` at line 423. Real implemented count: 9. **Severity: LOW** (cosmetic, doesn't affect behavior). **Suggested fix:** update header comment to "9 heuristics (i, ii, iii, iv, v, vii, viii, ix, x; vi deferred)".

**H3 — `cruft-check.sh` confidence assignment skips `low` tier.** [.claude/scripts/cruft-check.sh:106-111](.claude/scripts/cruft-check.sh) emits `med` at 1-4 occurrences, `high` at ≥5. session-observer.schema.md:23 default is `2=low, 3-4=med, ≥5=high`. Schema permits producer override but cruft-check.sh's deviation isn't documented in either file. **Severity: LOW**. **Suggested fix:** add one-line comment near line 111 noting "cruft-checker confidence override: med-floor because every cruft sighting is deterministic-detected; schema default's `low` tier doesn't apply".

**H4 — `timeout` command not POSIX-portable.** [scripts/update.sh:483](scripts/update.sh) uses `timeout 10 git ls-remote --tags ...`. On macOS without coreutils, `timeout` is missing. The error message "failed to fetch tags (timeout or network error)" hides the actual cause. **Severity: MEDIUM** (degraded UX on a real platform; affects the drift-cache refresh path that the SessionStart hook depends on). **Suggested fix:** detect `timeout` availability at startup with `command -v timeout`; fall back to backgrounded `git ls-remote` + `kill` after sleep (Bash-portable), OR explicitly surface "timeout command missing (install coreutils on macOS)" rather than the generic message.

**H5 — CI gaps: `--check-remote`, hook execution, destructive-pattern matching, fixture-based audit testing.** [.github/workflows/ci.yml](.github/workflows/ci.yml) covers install/update happy paths but doesn't exercise: network-touching `--check-remote`, hook fail-closed behavior, destructive-pattern blocking, `cruft-check.sh` or `plugin-quality-check.sh` fixture runs, or `LOCAL_MATCHES_TEMPLATE` classification explicitly. **Severity: MEDIUM** (real coverage gaps but no urgent regression risk; the missing scenarios are edge-case-heavy). **Suggested fix:** add 3-4 scenarios: `check-remote-cached` (verify marker updates), `hook-fail-closed-bash-safety` (lib-missing path), `cruft-check-fixture` (synthetic doc with broken link asserts heuristic-i fires).

**H6 — Destructive-pattern lib gaps.** [.claude/lib/destructive-bash-patterns.sh](.claude/lib/destructive-bash-patterns.sh) and [.claude/lib/destructive-powershell-patterns.sh](.claude/lib/destructive-powershell-patterns.sh). Bash misses: `rsync --delete /`, `dd of=/dev/sd*`, `mkfs.* /dev/*`, `truncate -s 0 /etc/*`, `> /etc/*` (shell redirect overwriting system files), `find / -delete`, `shred / srm` patterns. PowerShell misses: `Stop-Computer -Force`, `Restart-Computer -Force`, `Set-Acl` privilege escalation against system ACL, `Compress-Archive -Force` overwrites against user dirs, `wmic` destructive shapes. **Severity: LOW** (none are routine commands; gap is small). **Suggested fix:** add patterns; document the addition in the lib comment block. Each addition costs ~3 lines + a regression test.

**H7 — `install.sh --mode=replace` untestable in CI.** [scripts/install.sh:394-402](scripts/install.sh) reads stdin for "YES" confirmation. CI matrix doesn't include a replace scenario. If the replace path breaks (e.g. file overwrite races, marker write failure), nobody knows until a user manually runs it. **Severity: MEDIUM**. **Suggested fix:** add scenario `replace-with-yes-piped` that does `printf 'YES\n' | bash scripts/install.sh --mode=replace --force --target $TMP` and verifies expected overwrites.

**H8 — `.skeleton-version` v0.4 fossil functional integration test gap.** [.claude/.skeleton-version](.claude/.skeleton-version) carries v0.4 schema. drift-checker has been reading this against the running v1.1.4 every SessionStart for ~4 days (per `installed_at: 2026-05-13`). Whether the agent surfaces a drift notice depends on absent `cached_skeleton_head` — verify behavior by running `bash .claude/scripts/drift-check.sh` directly OR dispatching drift-checker. **Severity: LOW** (cosmetic if no notice fires; potentially MEDIUM if notice spam has been muted from session start banners). **Suggested fix:** run drift-check.sh against current marker and observe; either tolerate or refresh via Phase 32.

**H9 — No write-lock on observations directory across concurrent producers.** Multiple producers (cruft-check, plugin-quality-check, task-watchdog, session-observer) can write to `.claude/observations/` simultaneously during SessionStart hook chain or manual dispatch. Per-file `os.replace` is atomic, but two producers emitting the same `pattern_id` (sha256-collision-resistant, so realistic only if two producers normalize signatures identically) would race. Per-pattern_id idempotency guards (same observation = same id) make this self-correcting on next scan. **Severity: LOW** (very low collision probability; self-healing). **Suggested fix:** none required; document the assumption in session-observer.schema.md's "Producers" subsection.

**H10 — `commit.sh` path-shape guard too aggressive.** [.claude/scripts/commit.sh:24](.claude/scripts/commit.sh) rejects ANY commit message containing `/`. Catches the mistake of passing a file path, but rejects legitimate messages like `feat(scripts/install.sh): foo`. In practice the repo's commit-message format is `<type>(<scope>): <subject>` without filesystem paths, so this works; but the implementation overshoots the documented intent. **Severity: LOW**. **Suggested fix:** narrow the guard to "first arg is a path that exists on disk OR ends in code-file extension" (the second check already exists at line 28).

---

## Section 5: Findings CC disputes

### Dispute 1 — Capture/reuse loop is "theoretical from stage 3 onward"

**Chat-audit position:** the autonomous capture-drafting half of the loop has never produced a tracked artifact.

**CC position: AGREE.** Reviewed git log (`git log --all --oneline | grep -iE "workflow.suggester|capture"`) — found 5+ commits refining workflow-suggester (`ec26450 fix(workflow-suggester): correct field count 7→8`, `abb2a05 feat: filter observations with non-null resolved_at`, `c421381 feat: infrastructure-fix enum`, `ca2495f feat: lesson enum`, `b74bb6e docs(roadmap): extract 4 locked principles ... captures enum`). The agent surface evolved but `.claude/captures/` remains empty. Chat-audit's interpretation is correct: the agent and schema exist; the output channel is unused. No dispute.

### Dispute 2 — Retire/repurpose plan-coordinator + audit-helper + commit.sh after bundle install

**Chat-audit position:** post-bundle-install of feature-dev + code-review + commit-commands, these skeleton baselines are retire/repurpose candidates due to overlap.

**CC position: DISPUTE FOR commit.sh AND audit-helper; NEUTRAL FOR plan-coordinator (surface for joint resolution).**

- **`commit.sh` — DISPUTE.** [.claude/scripts/commit.sh:33-55](.claude/scripts/commit.sh) emits 5 verbatim sections to stdout (PRE-COMMIT STATUS / STAGE COMMAND / COMMIT STDOUT / POST-COMMIT STATUS / NEW COMMIT HASH). The 5-section verbatim output is a load-bearing contract — the manager quotes them back without paraphrasing (per ROUTING.md "Commit the staged changes" row and `/commit` slash command). commit-commands likely produces a more sophisticated commit-message format (subject + body + Conventional Commits scope hinting), which is a different value proposition. The verbatim-contract value is skeleton-specific. **Recommend KEEP, route commit-commands for message-drafting and commit.sh for the verbatim mechanics.** They compose, not compete.

- **`audit-helper` — DISPUTE.** [.claude/agents/02_audit/audit-helper.md](.claude/agents/02_audit/audit-helper.md) does drift detection between project state and project records (docs claim vs code reality). code-review (Anthropic plugin) is presumably about PR-quality review and inline code-quality concerns. Different scopes. audit-helper's "Claim / Reality / Severity / Suggested fix" output shape is specific to doc-vs-code drift and is consumed by the `/audit` slash command. **Recommend KEEP** — code-review and audit-helper cover non-overlapping surfaces.

- **`plan-coordinator` — NEUTRAL.** [.claude/agents/04_planning/plan-coordinator.md](.claude/agents/04_planning/plan-coordinator.md) runs the 4-step Explore/Plan/Review/Final-plan workflow with a specific output shape (Context / Approach / Critical files / Verification / Non-goals). The output shape is a contract the manager pattern relies on. feature-dev may produce a similar shape OR a different one. **CC cannot dispute without testing feature-dev** — surface for reconciliation. If feature-dev produces a different shape, plan-coordinator has skeleton-specific value; if the same, then yes retire.

### Dispute 3 — Don't build `/spec`

**Chat-audit position:** Defer /spec; use feature-dev + superpowers/brainstorming first; evaluate gaps empirically.

**CC position: NO DISPUTE.** There is no existing `/spec` to compare against. CC has no evidence that a skeleton-specific spec format wouldn't be covered by feature-dev. Defer to chat-audit's framing — empirical evaluation post-bundle-install is the right gate.

---

## Section 6: Reconciliation queue

| # | Item | Chat-audit position | CC-audit position | Suggested resolution |
|---|---|---|---|---|
| R1 | `occurrences = 1` schema violation (Section 4 H1) | Not specifically flagged | HIGH severity; producer-vs-schema drift | User decides: amend schema with deterministic-producer carve-out, OR tighten producers (and accept the resulting semantic shift) |
| R2 | `.skeleton-version` v0.4 fossil drift-checker behavior (Finding 4 + Section 4 H8) | Phase 32 marker refresh | Drift-checker behavior against v0.4 fossil not empirically verified | Run `bash .claude/scripts/drift-check.sh` against current marker; if drift notice fires, Phase 32 also closes a real user-facing gap |
| R3 | Self-audit-helper + project-tuner-helper template > dogfood drift (Finding 5) | Not specifically resolved | Template ahead of dogfood; direction question | Decide as part of Phase 31 or Phase 33: back-mirror to dogfood OR document as locked asymmetry |
| R4 | plan-coordinator retire/repurpose decision (Dispute 2) | Retire candidate | NEUTRAL — depends on feature-dev output shape | Empirical comparison during Phase 35 evaluation window; defer Phase 36 decision |
| R5 | commit.sh and audit-helper retire/repurpose (Dispute 2) | Retire candidates | DISPUTE — verbatim contract + non-overlapping scope | Recommend joint review before Phase 36; CC's dispute reasoning needs strategist counter-argument or acknowledgment |
| R6 | CI coverage gaps (Section 4 H5) | Not in scope of chat-audit | MEDIUM — real but quantifiable | Stand alone phase between Phase 33 and Phase 34 to add 3-4 scenarios |
| R7 | Concurrent SessionStart hook firing model | Not in scope | Documented unknown — sequential vs parallel | User to verify with Anthropic docs OR direct observation; document the answer in `.claude/hooks/README.md` |
| R8 | `replace` mode CI gap (Section 4 H7) | Not in scope | MEDIUM | Add scenario in CI-gap-closing phase |
| R9 | Destructive-pattern lib gaps (Section 4 H6) | "Single source of truth" principle locked | LOW — gap small, addition cheap | Optional Phase 32-adjacent: extend libs; benefits both PreToolUse hooks and plugin-quality-check heuristic iii in one extraction |
| R10 | `commit.sh` path-shape guard aggression (Section 4 H10) | Not in scope | LOW | Defer; not breaking current workflow |

---

## Section 7: CC's confidence in audit-emergent phase queue

16 phases from chat-audit Part 7 (Phases 31–46+).

| # | Phase | Confidence | Rationale |
|---|---|---|---|
| 31 | Bulk codification (5 principles to ROADMAP + 3 sprint rules to CLAUDE_MANAGER + mission to STORY.md + production-miles reframe + handoff simplification) | **CONFIDENT** | Doc-shuffle of well-defined content. Add R3 (template drift) to scope if appropriate. |
| 32 | Marker refresh (`update.sh` against self) | **CONCERN** | Dogfood marker is v0.4 fossil; running update.sh against it triggers BACKFILL_MODE (update.sh:431-436 + maybe_announce_backfill). Backfill mode silently assigns `hash_current` as the recorded baseline — for any file with local modifications since v0.4, those become "the baseline" silently. CC recommends a `--dry-run` pass first to inventory expected reclassifications, especially for self-audit-helper.md / project-tuner-helper.md (Section 1 #5 confirms template ≠ dogfood). **Suggested modification:** Phase 32a = `update.sh --dry-run --source . --target . --claude-only`; review classifications; Phase 32b = approval-gated apply. |
| 33 | Directive layer alignment (remove /goals stub + integration-checker reframe + code-quality-auditor dispatch H3 + core-vs-integration section + cross-refs + L0=L2 note) | **CONFIDENT** | Mechanically straightforward. Depends on Phase 31. |
| 34 | Bundle install (6 plugins + pre-install code-quality vetting + `docs/PLUGIN-INSTALLS-v1.1.4.md`) | **NEUTRAL** | Pre-install code-quality-auditor vetting is the right gate (state-dump §14). Each plugin install is a discrete action; suggest sequential install with `--plugin-dir` synthetic vetting per plugin OR direct heuristic-i/ii/iii scan post-install before activation. |
| 35 | Bundle evaluation window (2-3 weeks active use; observation accumulation; manual eval log) | **CONFIDENT** | Pure observation-accumulation phase. Low risk. Per Phase 24's empirical-audit principle. |
| 36 | Composition rules + skeleton baseline retire/repurpose decisions | **CONCERN** | Decision-point phase; CC's Section 5 dispute on commit.sh + audit-helper (R5) needs joint resolution before this phase commits to retirement. Suggested modification: scope as approval-gated, one decision per commit, with explicit chat+CC sign-off on each retirement candidate. |
| 37 | Audit-as-skeleton-primitive codification (CLAUDE_MANAGER "Strategic audit cycle" section + `strategic-audit-coordinator` queued for v1.2.0+) | **CONFIDENT** | Doc-shuffle. Can run parallel with Phase 36. |
| 38 | v1.5-A: `recommendation.schema.md` + `.claude/recommendations/` storage | **NEUTRAL** | Schema-design phase. CC suggests this phase enter plan-mode before commit — schema design benefits from explicit dispatch shape decisions (does this consume observations, captures, or directly read plugin scans?). |
| 39 | v1.5-B: `code-quality-auditor` --candidate mode + trust-tier logic | **NEUTRAL** | Medium phase modifying an existing agent. CC suggests confirming whether `--candidate` is a flag on the agent or on `plugin-quality-check.sh`. Trust-tier logic should compose with code-quality-auditor's existing 3 heuristics, not replace them. |
| 40 | v1.5-C: `plugin-discovery-agent` + `plugin-discovery.sh` (multi-tier discovery) | **CONCERN** | "Multi-tier discovery" implies a sophisticated agent. CC recommends per-phase plan-mode entry; this is the v1.5 series' biggest new surface. What's the discovery scope? `~/.claude/plugins/cache/`? Network? GitHub topic search? |
| 41 | v1.5-D: `plugin-context-matcher` agent + skeleton-baseline-map reference | **CONCERN** | "Skeleton-baseline-map" is undefined. Suggest Phase 41a defines the data shape before Phase 41 commits to the agent. |
| 42 | v1.5-E: SessionStart hook entry + 7-day cooldown wiring | **CONFIDENT** | Small-fix; analogous to existing cruft-check / plugin-quality-check entries. 7-day cooldown vs 24h current pattern is the design decision. |
| 43 | v1.5-F: First-install integration (install.sh hook into pipeline) | **NEUTRAL** | Modifies install.sh — load-bearing infrastructure. CC recommends per-phase plan-mode entry + ensure install.sh atomic-write discipline is preserved. |
| 44 | v1.5-G: Composition-rule documentation pattern | **CONFIDENT** | Doc-shuffle; informed by Phase 36 outputs. |
| 45 | v1.5.0 release cut | **CONFIDENT** | Standard release-cut shape (per ROADMAP §v1.0 — shipped + § Cuts). |
| 46+ | TV / EoG update + v1.2.0 design opens | **NEUTRAL** | Multi-phase, dependencies on v1.5 outputs and pinball completion. Far-future. |

**Summary:** 5 CONFIDENT, 6 NEUTRAL, 4 CONCERN, 1 split (R1 is HIGH-severity but doesn't map to a phase yet — it's an open finding for queue insertion).

**CC's overall sequencing observation:** Phases 31-33 are tight doc-shuffle work that can ship in 1-2 sessions. Phases 38-44 (v1.5 series) are heavier and each warrants its own plan-mode entry. Recommend a Phase 30b "audit-finding closure phase" between this audit and Phase 31 to address R1 (schema violation), H2/H3 (cruft-check.sh doc fixes), and H7+H5 (CI gap closure) — these are LOW-MEDIUM mechanical fixes that don't depend on the broader v1.5 design and can land cleanly before the codification cascade.

---

[End of artifact]
