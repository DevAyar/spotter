# Evidence record: sonnet run, 2026-09-06

One blind refuter dispatch per case (`general-purpose`, `model: sonnet`), prompt = the case file's own text plus the blindness rules (git show at the pin only; no observations, key, CHANGELOG, SESSION_LOG, receipts, or later commits). Verdict map: `verdicts-sonnet.json`.

## case-01: real

EVIDENCE: scripts/update.sh lines 181-189 at commit f6967faf8158 (`detect_json_tool() { if command -v python ...; JSON_TOOL="python"; elif command -v python3 ...; JSON_TOOL="python3"; else die ...; fi }`)

MECHANISM: The function checks `command -v python` first and only falls back to `python3` if `python` is absent, so it does prefer `python` over `python3`. `command -v` only confirms a name resolves on PATH; it never executes the interpreter or inspects its version, and a grep of the whole file for any version check (`version_info`, `3.7`, `--version`, etc.) turns up nothing tied to `JSON_TOOL`, so the interpreter's runnability and version are never verified.

## case-02: real

EVIDENCE: scripts/update.sh:5 (`set -euo pipefail`), lines 21-24 (`ADDED_FILES=()`, `MODIFIED=()`, `DELETED_BACKUPS=()`), lines 33-34 (comment: bash 3.2 target), lines 360-392 (`rollback()` and `cleanup_backups()`), line 1183 (`cleanup_backups` called unconditionally on the success path).

MECHANISM: `cleanup_backups()` loops `for entry in "${MODIFIED[@]}"` and `"${DELETED_BACKUPS[@]}"` with no emptiness guard and is called unconditionally after every non-dry-run apply. `rollback()` has a combined guard that only skips when ALL three arrays are empty; if just one is non-empty the loops over the other, still-empty arrays expand unguarded. None use the `"${arr[@]+"${arr[@]}"}"` idiom, and on bash before 4.4 (macOS 3.2, the script's own stated target) `"${empty_array[@]}"` under `set -u` is an unbound-variable abort.

## case-03: real

EVIDENCE: .claude/hooks/pretooluse-bash-safety.sh at f6967faf8158: line 20 (`set -uo pipefail`, no `set -e`), 32-39 (existence check + unconditional `source "$LIB"`, no post-source validation of `DESTRUCTIVE_BASH_PATTERNS`), 148-154 (`for pattern in "${DESTRUCTIVE_BASH_PATTERNS[@]}"; do ... emit_deny ...; done; emit_allow`).

MECHANISM: The script only fail-closes when the lib file is missing; if it exists but is empty or syntax-broken, `source` no-ops or fails non-fatally (no `set -e`), leaving the array unset. Verified on bash 5.2: `"${ARR[@]}"` on an unset array under `set -u` expands to zero elements without error, so the loop body never runs and control falls through to the unconditional `emit_allow` at line 154.

## case-04: real

EVIDENCE: .claude/hooks/pretooluse-bash-safety.sh:104 (at f6967faf8158), inside `strip_bash_heredocs()` (lines 83-110).

MECHANISM: The detection regex `<<-?[[:space:]]*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?` is applied to the raw line with unanchored `=~` (no `^`, no check for a preceding `#`, quote context, or word boundary), so any `<<IDENT` anywhere on a line, including inside a comment, a quoted string, or as the trailing two characters of a `<<<IDENT` here-string, sets `in_heredoc`. Every following line is then replaced with `HEREDOC_BODY` (lines 96-98) until the identifier line, so destructive patterns on those lines are invisible to the scan.

## case-05: real

EVIDENCE: `.claude/lib/destructive-bash-patterns.sh:17` at f6967faf8158: `'(^|[[:space:]])rm[[:space:]]+-rf([[:space:]]|$)'`

MECHANISM: The regex requires the literal token `-rf` immediately after `rm`, anchored by whitespace-or-start before `rm`. Reordering to `-fr`, splitting into `-r -f`, or long flags remove the contiguous `-rf`; and a non-space delimiter glued to `rm` (`;rm`, `&&rm`, `|rm`) fails the anchor. Confirmed by direct testing of the extracted regex against all these variants.

## case-06: real

EVIDENCE: `.claude/scripts/share-disable.sh` lines 90-98 (successful `smg_push` of the deletion at 91, `PURGED=1` at 94) followed unconditionally by the separate `enabled=false`/`disabled_at` config write at 100-115; lines 44-45: the only trap (`cleanup` on EXIT/INT/TERM) touches just `TMP_CLONE`. Corroborating: `.claude/scripts/shared-memory-push.sh` gates SessionEnd pushes solely on `share-config.json`'s `enabled` field, then re-runs the producer and pushes any diff.

MECHANISM: The purge and the disable are two independent, non-transactional operations with no lock or journal linking them; an interrupt or write failure after the push succeeds but before the config write leaves `enabled: true` on disk while the remote is already purged. Because the push script only checks the flag and reproduces events from local sources the purge never touched, the next SessionEnd regenerates and re-pushes what the user just purged.

## case-07: real

EVIDENCE: .claude/agents/03_monitoring/monitoring-helper.md at b7744711c43c, line 3 ("read the recent tail"), line 23 ("Reads the **forward-chronological tail**"), line 26 ("offset = total - N and limit = N ... canonical forward-chronological read pattern"); template/docs/SESSION_LOG.md.template at the same commit: "Reverse-chronological: newest at top."

MECHANISM: The read algorithm computes offset = total - N and reads the last N lines, describing this as a forward-chronological tail; but the project's documented SESSION_LOG.md convention is newest-at-top. Under that ordering the last N lines are the oldest entries, so the agent as documented grades the oldest sessions.

## case-08: real

EVIDENCE: template/.claude/scripts/receipt-render.sh lines 192-198 at e72fc478404a (`for _cand in python python3; do if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then PYBIN="$_cand"; break; fi; done`); no `source` of detect-python.sh anywhere in the file.

MECHANISM: At e72fc478404a, receipt-render.sh still runs its own inline probe rather than sourcing the canonical detector (Phase 112 A: python3-first, execution-validated, >=3.7 floor). The inline probe is the safe execution-validated form with python-first order and no version floor. Phase 112 B's commit (2d218a6) converted eight named surfaces and did not touch receipt-render.sh.

## case-09: refuted

EVIDENCE: .claude/lib/shared-memory-git.sh at c32c0ee6e446, lines 106-119 (smg_push): lines 118-119 run `git -C "$d" config user.email ...` and `... user.name ...` unconditionally, with comment lines 109-110 stating "Neutral commit identity, UNCONDITIONALLY (Phase 119). The old form set it only when `git config user.email` resolved nothing".

MECHANISM: The claim describes the conditional-fallback bug as the state of the code at this commit, but the code at c32c0ee6e446 already applies the neutral identity unconditionally; the conditional form is explicitly described in the file's own comment as the prior ("old") behavior that Phase 119 replaced. Every push at this commit sets the neutral share identity regardless of the caller's global git config.

## case-10: real

EVIDENCE: .claude/scripts/task-watchdog.sh (commit 11a270977487), lines 74-83 (`write_last_session_id`) and line 201 (`if [ "$(read_last_session_id)" = "$PRIOR_SESSION_ID" ]; then exit 0; fi`)

MECHANISM: The Phase 121 comment at lines 75-79 states verbatim that the marker was previously written with a bare `>` (truncating) redirect, that a kill mid-write left a zero-byte marker, and that an empty marker makes the prior transcript treated as unseen and re-processed, matching the claim almost word for word. Line 201's comparison confirms the mechanism: an empty read from a zero-byte marker fails to match any real session id, so the guard falls through.

## case-11: real

EVIDENCE: scripts/update.sh at e72fc478404a, lines 739-758 (Phase 59 `classify()` rebaseline branch: hash-only comparison, no dirty check) and lines 961-978 (Phase 113 comment block naming match-rebaseline as a mechanism that manufactures the marker/git divergence state and stating the guard "deliberately does NOT apply" there).

MECHANISM: In `classify()`, when a file's raw baseline differs from its current hash but current equals the live template hash, the code classifies it UNCHANGED and advances the raw baseline to the current hash (`RAW_BASELINE_REBASED`) with no call to `path_is_dirty` in that branch. The Phase 113 guard (`dirty_paths_init`/`path_is_dirty`, lines 989-1016) is wired only into the later apply-time checks on TEMPLATE_UPDATED files, and the file's own comment at 968-970 names Phase 59 match-rebaseline as one of the two ways the guarded state becomes reachable.

## case-12: real

EVIDENCE: README.md:36 ("Audits itself at session start on a 24h cooldown: doc rot, version drift, installed-plugin sanity"), docs/ROADMAP.md:13 and :260 at bb245f873e97 attribute a cooldown to drift-checker; `.claude/scripts/drift-check.sh` at the same commit has no cooldown/timestamp gate, and `.claude/hooks/sessionstart-rules.sh` invokes it unconditionally every session, unlike the explicit 24h `AUDIT_MARKER` cooldown used later in the same file.

MECHANISM: drift-check.sh only compares `version` to `cached_skeleton_head` and emits nothing when they match: silent-when-no-drift, not a time-based cooldown. sessionstart-rules.sh calls it every session with no marker-file or timestamp gate, in contrast to the audit-cadence block a few lines later which implements a real 24h cooldown via `.claude/.last-audit-nudge`.

## case-13: real

EVIDENCE: .claude/scripts/share-disable.sh:12-13,50 (at f6967faf8158)

MECHANISM: Line 12 computes `ROOT="$(cd ... 2>/dev/null && pwd)"` with the `cd` failure suppressed and no check on the substitution's status or on `ROOT` being non-empty; if that `cd` fails, `ROOT` is the empty string. Line 13 then builds `SHARE_CONFIG="$ROOT/.claude/share-config.json"`, which evaluates to `/.claude/share-config.json`, and line 50's `[ ! -f "$SHARE_CONFIG" ]` check silently prints "Share mode is not configured for this install" instead of erroring.

## case-14: real

EVIDENCE: scripts/update.sh:427 (help text: "--dry-run  Print the update plan without changing anything."); :904-914 (apply_new prints `Copy all? [Y/n]` / `read -r reply` unconditionally before the `[ "$DRY_RUN" = true ]` check at 914); :1021-1050 (apply_local_modifications loops every LOCALLY_MODIFIED file through an unconditional `read -r reply` prompt, gated by neither `$DRY_RUN` nor `$AUTO_APPLY`).

MECHANISM: `--dry-run` only skips the write side of each apply_* function; it never gates whether the `read` itself executes, so any run with pending NEW, TEMPLATE_UPDATED, LOCALLY_MODIFIED, or ORPHAN files still halts at an interactive prompt under `--dry-run` alone, contradicting the help text. LOCALLY_MODIFIED is the starkest case: `DRY_RUN` is checked only inside the overwrite branch (line 1036), not before the prompt loop.

## case-15: real

EVIDENCE: .claude/scripts/commit.sh:19,21 at f6967faf8158: `[ "$#" -lt 1 ] && usage` only rejects zero arguments, and `MSG="$1"` binds solely to the first argument; no code path inspects `$2`, `$3`, etc.

MECHANISM: Because the arg-count check only fails on `$# < 1`, any call with two or more arguments passes through, and only `$1` is assigned to `MSG` and checked by the path-shape guard. A miscall like `commit.sh "some message" some/file.sh` has its second argument (the actual path) silently discarded rather than triggering the guard.

## case-16: real

EVIDENCE: .claude/scripts/deploy.sh lines 21-23 (at f6967faf8158)

MECHANISM: The extension guard tests `$FIRST` with `grep -qE '\.(md|yaml|yml|json|...)$'`, matching purely on the tail of the string; it does not check whether the whole argument is a bare filename. `--config=deploy.yml` ends in `.yml`, so it matches and triggers `exit 2`, even though it is a legitimate `--flag=value` deploy argument.

## case-17: real

EVIDENCE: .claude/scripts/share-disable.sh:9 (`set -uo pipefail`, no `-e`), :60 (`. "$ROOT/.claude/lib/shared-memory-git.sh"` sourced with no preceding `[ -f ]` check and no `|| die`), :83-84 (`smg_ensure_clone ... || die "could not clone remote ..."`)

MECHANISM: The script sources shared-memory-git.sh unconditionally with no existence check and no failure handling on the source itself; since `set -e` is not enabled, a failed source is silently swallowed and execution continues. If the library were missing, `smg_ensure_clone` would be undefined, bash would fail with command-not-found (127), and the `|| die` at 83-84 would fire the generic "could not clone remote" message rather than any "library missing" diagnostic.

