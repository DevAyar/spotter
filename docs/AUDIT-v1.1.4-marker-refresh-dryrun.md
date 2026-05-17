# Phase 32a marker refresh dry-run inventory

Snapshot at `f849fdb` (HEAD on `main` after Phase 31 codification). Read-only audit producing the apply-decision input for Phase 32b. The dogfood `.claude/.skeleton-version` is a v0.4 fossil (installed `2026-05-13T19:29:47Z`, commit `315954d`) carrying the pre-0.8.0 shell-export marker format — no `files` object, no per-file SHA-256 hashes, no `cached_skeleton_head` cache. This phase ran `update.sh --dry-run` against that fossil to capture the six-way classification + `BACKFILL_MODE` behavior. No marker write, no file write, no `.claude/` modification.

**Exact command:** `NO_COLOR=1 bash scripts/update.sh --dry-run </dev/null 2>&1 | tee /c/tmp/phase32a-dryrun.txt`

(Spec deviation: brief said `update.sh --dry-run --claude-only`. `update.sh` does NOT have a `--claude-only` flag — update.sh by design only processes `.claude/` per `update.sh:79` and state-dump §11. Surfaced in § Findings.)

---

## BACKFILL_MODE detection

Surfaced — `update.sh:534-539` `maybe_announce_backfill` fired because `MARKER_HAS_FILES_OBJECT == false` (the v0.4 marker is shell-export format, lacks the JSON `files` object that 0.8.0+ markers carry).

Verbatim output:

```
════════════════════ BACKFILL MODE ════════════════════
This marker was created before per-file hashes existed.
Cannot detect local modifications made before this migration.
Files differing from the template are classified as TEMPLATE_UPDATED.
If you have known local modifications, REVIEW INDIVIDUALLY.
═══════════════════════════════════════════════════════
```

The notice's claim "Cannot detect local modifications made before this migration" is the load-bearing risk for Phase 32b — see § Risk analysis.

---

## Classification summary

`installed: 0.4.0    current: 1.1.4`

| Bucket | Count | Notes |
|---|---|---|
| UNCHANGED | not surfaced | `print_findings()` omits UNCHANGED count from stdout; inferred ~41 of 45 template files since backfill silent-assignment forces `hash_recorded = hash_current`, so `hash_template == hash_current` implies UNCHANGED |
| TEMPLATE_UPDATED | **4** | dogfood and template bytes differ — but 3 of 4 are line-ending FP (see § Findings) |
| LOCALLY_MODIFIED | **0** | Impossible in BACKFILL_MODE — silent-assignment sets `hash_recorded = hash_current`, so the `hash_recorded != hash_current` condition can never fire |
| LOCAL_MATCHES_TEMPLATE | **0** | Same impossibility — would require `hash_recorded != hash_current && hash_current == hash_template`, but `hash_recorded` is just set to `hash_current` |
| NEW | **0** | No template files absent from dogfood — dogfood IS the source for template, so the directions match by construction |
| ORPHAN | **0** | No marker `files` object → no recorded paths to compare against template → ORPHAN detection has nothing to scan |

Total apply-candidates: **4 files** (all TEMPLATE_UPDATED).

---

## Files per bucket (full list)

### UNCHANGED

Not enumerated in stdout. Derivable from `${#UNCHANGED_FILES[@]}` if exposed (current `print_findings()` does not surface it). Estimated ~41 of 45 template-tracked files.

### TEMPLATE_UPDATED (4)

1. `.claude/agents/02_audit/audit-helper.md` — **line-ending FP**. Content byte-identical to template; template has CRLF line terminators, dogfood has LF.
2. `.claude/agents/03_monitoring/monitoring-helper.md` — **line-ending FP**. Same shape as #1.
3. `.claude/agents/05_meta/session-observer.md` — **line-ending FP**. Same shape; template has CRLF, dogfood has LF.
4. `.claude/settings.json` — **real intentional drift** (locked per CLAUDE_MANAGER § Dogfood mirror invariants + state-dump §16). Three documented drifts: `defaultMode: plan` vs `default`; `compactPrompt` resolved vs `{{COMPACT_PROMPT}}` placeholder; cruft-check.sh SessionStart entry present in dogfood, absent in template.

### LOCALLY_MODIFIED

[empty]

### LOCAL_MATCHES_TEMPLATE

[empty]

### NEW

[empty]

### ORPHAN

[empty]

---

## Risk analysis

**Reminder of `--auto-apply` discipline (`update.sh:603-614` + `:639-651` + `:712-744` + `:758-781`):**
- `--auto-apply` accepts `NEW` (treats `reply="y"`) and `TEMPLATE_UPDATED` (treats `action="A"`) automatically.
- `--auto-apply` does NOT accept `LOCALLY_MODIFIED` — iterates per-file with default `[K]eep` via `read -r reply || reply="k"`.
- `--auto-apply` does NOT accept `ORPHAN` — sets `reply="n"`.

**Manual apply path:** prompts per file or per bucket. `apply_template_updates` offers `[A]pply all  [R]eview individually  [S]kip all`. `apply_orphans` offers `[y/N]` per the whole list.

**Backfill silent-assignment (`update.sh:431-436`):** for every template-tracked file, since `hash_recorded` is empty (no `files` object), the assignment sets `hash_recorded = hash_current` and `BACKFILL_MODE=true`. Marker rewrite via `write_version_marker` then captures CURRENT dogfood bytes as the per-file baseline for every file — including the 4 drift candidates. **Consequence:** after marker refresh, the 3 line-ending FPs and the 1 settings.json drift become the canonical baseline; any subsequent `update.sh` run shows them as UNCHANGED (since `hash_recorded == hash_current` now matches).

**Per-bucket Phase 32b apply impact:**

| Bucket | If `--auto-apply` | If manual `[A]pply all` | If manual `[S]kip all` |
|---|---|---|---|
| TEMPLATE_UPDATED (4 files) | Overwrites all 4 with template version. 3 line-ending FPs gain CRLF (Windows-only churn). settings.json gets compactPrompt unresolved + defaultMode reverted to `default` + cruft-check.sh hook entry stripped — **destroys locked intentional drift**. | Same destructive outcome. | Skips all 4. Marker still gets written with current-byte baselines (silent backfill capture). |

**Highest-risk apply path:** `--auto-apply` or `[A]pply all`. Both clobber the locked settings.json drift.

**Safe apply paths:** `[S]kip all` for TEMPLATE_UPDATED, OR `[R]eview individually` with `[K]eep` on settings.json AND each of the 3 line-ending files.

---

## Recommended Phase 32b approach

Based on this inventory: **defer or restrict scope**.

The marker refresh's primary value is migrating the v0.4 fossil to the 0.8.0+ schema with per-file hashes — enabling subsequent `update.sh` runs to detect real local modifications. The dry-run reveals the migration path can run safely with `[S]kip all` on TEMPLATE_UPDATED (the 4 apply candidates are 3 FPs + 1 locked-drift entry that MUST stay diverged).

**If Phase 32b proceeds:**
- Use `update.sh` (no `--auto-apply`) and pipe `S\nn\n` to skip TEMPLATE_UPDATED and skip ORPHAN (the latter is empty anyway). This writes the marker with current-byte baselines for all 45 tracked files, leaving the 4 drift candidates intact on disk.
- Verify marker post-write: `cat .claude/.skeleton-version` should show JSON format with `version: 1.1.4`, `files: {...}` object with 45 entries.

**If Phase 32b defers:**
- Document the v0.4 fossil as **intentional dogfood lag** (parallel to the state-dump §17 "`.skeleton-version` dogfood lag" loose-end, which already documents the fossil as accepted state). drift-checker continues to surface the version mismatch on every SessionStart, but it's a known-and-accepted notice — not a real drift.

**Either path is acceptable.** Deferral has the merit of leaving the fossil in place as documentation of the original install commit (`315954d`, 2026-05-13). Apply has the merit of giving `update.sh` real hash baselines for the next phase that touches `.claude/`.

---

## Findings

1. **`--claude-only` flag absent from `update.sh`.** Brief spec said `bash scripts/update.sh --dry-run --claude-only` but update.sh's arg parser at `scripts/update.sh:313-328` only accepts `--source`, `--target`, `--auto-apply`, `--dry-run`, `--check-remote`, `--help`. Unknown args trigger `die "unknown argument: $1 (see --help)"`. Resolution: ran without `--claude-only`; update.sh already scopes exclusively to `.claude/` per its design contract (`update.sh:79` "top-level files never updated") so the flag would be redundant. The brief's mention appears to be a transcription artifact from install.sh which DOES have this flag.

2. **Line-ending drift is dominant signal in TEMPLATE_UPDATED bucket.** 3 of 4 flagged files (`audit-helper.md`, `monitoring-helper.md`, `session-observer.md`) differ ONLY in line terminators (template = CRLF, dogfood = LF). `file(1)` confirms:
   ```
   .claude/agents/02_audit/audit-helper.md:                    UTF-8 text
   template/.claude/agents/02_audit/audit-helper.md:           UTF-8 text, with CRLF line terminators
   ```
   Root cause hypothesis: Windows Git's `core.autocrlf` setting normalizes line endings on checkout per-file based on `.gitattributes`. If template files have CRLF normalization and dogfood files don't (or vice versa), checkouts on Windows produce drift. The `.gitignore` and `.gitattributes` files were not inspected for this audit — flag for Phase 32b or a follow-up.

3. **`print_findings()` omits UNCHANGED count.** Stdout shows the 4 surfaced buckets but not the count of files that classify as UNCHANGED. The information is available in-process (`${#UNCHANGED_FILES[@]}`); surfacing it would aid auditability without changing semantics. Defer to a future small-fix phase if useful.

4. **Dry-run stdin-from-`/dev/null` semantics behave correctly.** Each `apply_*` function's `read -r reply || reply="<default>"` pattern fell through cleanly: `apply_template_updates` defaulted to `action="S"` (skip all), printed `skipped all template updates`. Pattern is robust for non-interactive auditing.

5. **No ORPHAN detection possible without a `files` object.** The orphan-detection loop at `update.sh:451-465` walks `MARKER_HASH_ENTRIES` for paths absent from `in_template`. With a v0.4 fossil marker (no `files` object), `MARKER_HASH_ENTRIES` is empty → loop yields zero ORPHANs by construction. This is a structural limitation: a fossil marker cannot identify orphaned dogfood-only files via update.sh. The dogfood-only cruft-checker artifacts (agent + script + 24h marker file) would be detected as ORPHAN only AFTER the marker is refreshed to 0.8.0+ format with current `files` entries. Note that **the dogfood-only artifacts are NOT actually orphans** — they're documented intentional drift per CLAUDE_MANAGER § Dogfood mirror invariants. If Phase 32b refreshes the marker, future `update.sh` runs may then flag them as ORPHAN; downstream Phase 32b run would skip-or-keep them per the same locked-drift rules.

---

## Empirical learnings about update.sh

These observations from the dry-run behavior inform v1.5+ design and future maintenance:

1. **BACKFILL_MODE surfaces loudly + correctly.** The bordered warning block is visually unmissable in terminal output. The notice explicitly warns about the silent-assignment risk ("Cannot detect local modifications made before this migration"). v1.5+ designs can rely on the warning being seen by any user running update.sh against a pre-0.8.0 marker.

2. **`hash_recorded = hash_current` silent assignment** (`update.sh:431-436`) collapses two of the six classification buckets in BACKFILL_MODE: `LOCALLY_MODIFIED` and `LOCAL_MATCHES_TEMPLATE` become reachable-only-as-zero. Effective classification reduces to UNCHANGED, TEMPLATE_UPDATED, NEW, ORPHAN. This is by design (the v0.4-fossil case can't distinguish "intended local modification" from "template moved on") but is a useful invariant to know.

3. **Dry-run gates writes correctly but does NOT gate prompts.** `apply_*` functions execute the `read -r reply` prompt regardless of `DRY_RUN`, then short-circuit the actual write via `[ "$DRY_RUN" = true ] && return 0` (or similar). For automation, pipe stdin from `/dev/null` to trigger the `read || reply=<default>` fallback path. This pattern is portable across all four `apply_*` functions.

4. **NO_COLOR environment variable is honored.** `update.sh:95-103` checks `[ -z "${NO_COLOR:-}" ]` before initializing tput color sequences. Setting `NO_COLOR=1` produces clean unstyled stdout suitable for verbatim pasting into audit artifacts. (Brief plan considered ANSI escape stripping; setting `NO_COLOR=1` is cleaner.)

5. **Auto-apply discipline is genuinely conservative.** The dry-run confirmed via code-path tracing that `--auto-apply` does NOT touch LOCALLY_MODIFIED or ORPHAN. Phase 30 CC-side audit verified this empirically by reading the code; Phase 32a confirms it in execution-trace terms (the buckets are zero, so the conservatism cannot be falsified here — but the function-level gates match the audit reading).

6. **Output is more compact than predicted.** Plan predicted 100-200 lines of stdout; actual was 27 lines. Reason: empty NEW + LOCALLY_MODIFIED + ORPHAN + LOCAL_MATCHES_TEMPLATE buckets each suppress their per-bucket section. Only TEMPLATE_UPDATED rendered (4 files listed). The brevity is informative — a fossil marker dry-run on a self-consistent dogfood produces minimal noise.

7. **Marker write atomicity preserved in dry-run.** `cat .claude/.skeleton-version` after the dry-run shows the v0.4 fossil bytes identical to pre-run. Confirms `write_version_marker` early-returns on `DRY_RUN=true` (line 786) before touching the tmp file or rename.

8. **Implicit assumption: dogfood-as-source-for-template was VALIDATED.** Zero NEW files and zero unexpected ORPHANs confirm the dogfood mirror invariant holds AS OF this run. Template content is consistent with dogfood content (modulo the 4 drift candidates). Future audits can use this dry-run shape as a "mirror parity smoke test" on any new install — if NEW count > expected dogfood-only set, something's slipping out of mirror.

---

[End of artifact]
