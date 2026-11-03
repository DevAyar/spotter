# Evidence record: haiku run, 2026-09-06

Scope: the 9 cases the sonnet run's adjudication found validly pinned (01-08 real, 11 refuted) plus cases 09 and 10 at their corrected pre-fix pins (6c2857075d10, abbe43fadbf0). One blind refuter per case (`general-purpose`, `model: haiku`), the same prompt and blindness rules as the sonnet run. The case-11 refuter completed without returning a structured verdict; it is unscored. Verdict map (8 cases): `verdicts-haiku.json`.

## case-01: real (key: real)

EVIDENCE: File: scripts/update.sh, lines 181-189 at commit f6967faf8158

MECHANISM: The detect_json_tool function checks for python (line 182) before python3 (line 184), establishing preference. Both checks use only command -v, which verifies PATH existence but never executes the interpreter or checks version compatibility. No version verification or execution test appears anywhere in the function.

## case-02: real (key: real)

EVIDENCE: File: scripts/update.sh, lines 384 and 388. The cleanup_backups() function expands "${MODIFIED[@]}" and "${DELETED_BACKUPS[@]}" without guards or the ":–" operator for safe empty-array handling under set -u. Script line 5 enables set -u via set -euo pipefail, and lines 32-34 document the target as macOS bash 3.2.

MECHANISM: In bash < 4.4, expanding an unset or empty array with "${array[@]}" under set -u causes a fatal error. The cleanup_backups function lacks the length guards present in rollback (line 361) and the ":–" operator pattern used safely elsewhere (e.g., lines 77, 99, 117). These unguarded expansions will fail if either MODIFIED or DELETED_BACKUPS arrays remain empty at cleanup time.

## case-03: real (key: real)

EVIDENCE: File: .claude/hooks/pretooluse-bash-safety.sh at commit f6967faf8158, lines 65-71 and 126. The code checks only whether the lib file exists (line 65: `if [ ! -f "$LIB" ]`), not whether DESTRUCTIVE_BASH_PATTERNS is defined after sourcing. At line 126, the for loop uses `"${DESTRUCTIVE_BASH_PATTERNS[@]}"`, which in bash 5 expands to zero words (empty) without error even with `set -uo pipefail`, if the array is unset.

MECHANISM: If the lib file exists but is empty or syntax-broken, DESTRUCTIVE_BASH_PATTERNS is never defined. The for loop at line 126 iterates zero times because `"${arr[@]}"` with an unset array doesn't trigger unset-variable errors in bash 5. The script then reaches emit_allow (line 130), allowing all commands with no denial signal.

## case-04: real (key: real)

EVIDENCE: File: .claude/hooks/pretooluse-bash-safety.sh, lines 95–125 (the strip_bash_heredocs function), particularly line 115 where the regex pattern is applied without context checking. When set to process a line containing `echo "<<MARKER"` or `# <<MARKER`, the pattern matches and sets in_heredoc, causing all subsequent lines until the terminator to be replaced with "HEREDOC_BODY" (line 113).

MECHANISM: The regex `\<\<-?[[:space:]]*[\'\"]?([A-Za-z_][A-Za-z0-9_]*)[\'\"]?` is applied directly to each line without parsing context, so it matches `<<IDENT` patterns regardless of whether they appear in comments or quoted strings. Once matched, the function enters "heredoc mode" and blanks all subsequent lines with "HEREDOC_BODY" until finding the terminator, making those lines invisible to downstream pattern matching.

## case-05: real (key: real)

EVIDENCE: File: `.claude/lib/destructive-bash-patterns.sh`, line 20. The pattern `(^|[[:space:]])rm[[:space:]]+-rf([[:space:]]|$)` only matches the exact sequence `-rf` with required whitespace delimiters before and after.

MECHANISM: The pattern is defeated because it anchors on whitespace boundaries and the literal string `-rf`, so flag reordering (`-fr`), flag splitting (`-r -f`), long flags (`--recursive --force`), or preceding non-whitespace characters would all bypass detection.

## case-06: real (key: real)

EVIDENCE: File: .claude/scripts/share-disable.sh, lines 91 (smg_push call) and 101-115 (Python block setting enabled=False). The claim correctly identifies that if an interrupt occurs between the successful remote push and the local config update, share mode remains enabled locally.

MECHANISM: Line 91 executes the remote push that commits the deletion. Lines 101-115 update the local config to disabled. These are separate, ordered phases. An interrupt between them leaves the remote in a consistent state (deletion committed) but the local config still enabled, causing SessionEnd to re-produce and re-push the purged data from untouched local sources on next run.

## case-07: real (key: real)

EVIDENCE: `.claude/agents/03_monitoring/monitoring-helper.md` lines 3, 24, 26; `template/docs/SESSION_LOG.md.template` line 8

MECHANISM: monitoring-helper prescribes offset = total - N to read the "forward-chronological tail," but SESSION_LOG is reverse-chronological with newest at top. Using offset = total - N in a reverse-chronological log reads from the oldest entries (end of file), not recent ones (top of file), causing it to grade oldest sessions instead of newest.

## case-08: real (key: real)

EVIDENCE: template/.claude/scripts/receipt-render.sh, lines 384-407 at commit e72fc478404a

MECHANISM: The file defines a hardcoded FIELDS tuple (lines 384-385) and implements an inline probe loop (lines 401-407) that checks if each input line starts with one of these field patterns followed by a colon. This is a direct pattern-matching probe embedded in the file itself, not sourced from a canonical detector shared across consumers, confirming the consistency gap the filing describes.

# Re-pinned re-runs (both candidates)

## case-09 at 6c2857075d10 on haiku: real (expected: real)

EVIDENCE: .claude/lib/shared-memory-git.sh, lines 110-111: `git -C "$d" config user.email >/dev/null 2>&1 || git -C "$d" config user.email "share@claude-skeleton.local"` and similar for user.name

MECHANISM: The config check uses no --local flag, so git resolves the hierarchy (local → global → system). On normally configured machines with global git config already set, the check succeeds on the global email, the || fallback never executes, and commits carry the user's real identity in metadata rather than the neutral share identity.

## case-09 at 6c2857075d10 on sonnet: real (expected: real)

EVIDENCE: .claude/lib/shared-memory-git.sh at commit 6c2857075d10, lines 110-111 (inside smg_push()):
  git -C "$d" config user.email >/dev/null 2>&1 || git -C "$d" config user.email "share@claude-skeleton.local"
  git -C "$d" config user.name  >/dev/null 2>&1 || git -C "$d" config user.name  "claude-skeleton share"

MECHANISM: `git config <key>` with no scope flag resolves the effective value across the config hierarchy (local falling back to global falling back to system), not just the clone directory `$d`. The clone has no local user.email/user.name, so this check succeeds whenever the machine's global git config has any user.email set — the normal state for a configured dev/CI machine — meaning the `||` fallback to the neutral share@claude-skeleton.local identity is skipped and the ensuing `git -C "$d" commit` uses the resolved global identity (the user's real name/email) instead.

## case-10 at abbe43fadbf0 on haiku: real (expected: real)

EVIDENCE: File `.claude/scripts/task-watchdog.sh` at commit abbe43fadbf0, lines 75, 71, and 194. The bare truncating redirect in the `write_last_session_id()` function (line 75: `printf '%s\n' "$1" > "$LAST_SESSION_MARKER"`) writes to the marker file. The `read_last_session_id()` function (line 71) returns empty string if the file is zero-byte. The idempotence check (line 194) compares this output to the current session ID; a zero-byte marker returns empty string, failing the equality check.

MECHANISM: When the `.last-watchdog-session` marker file is zero-byte, `read_last_session_id()` outputs empty string instead of a session ID. The comparison at line 194 evaluates to false (empty string ≠ non-empty session ID), so the early-exit branch is skipped. The script proceeds to process the prior session transcript and re-emit its observations. This breaks idempotence: zero-byte marker state triggers re-processing.

## case-10 at abbe43fadbf0 on sonnet: refuted (expected: real)

EVIDENCE: At commit abbe43fadbf0, .claude/scripts/task-watchdog.sh:75 writes the idempotence marker with `printf '%s\n' "$1" > "$LAST_SESSION_MARKER"` — a bare truncating redirect, and read_last_session_id() (lines 69-71) does `cat` on that file, so a zero-byte marker reads back as an empty string. The equality check against PRIOR_SESSION_ID (line ~508) then fails and the script does re-run the Python transcript scan — so far the claim tracks. cruft-check.sh and plugin-quality-check.sh likewise write their cooldown files with `now_epoch > "$COOLDOWN_FILE" 2>/dev/null || true`, so "three markers, bare truncating redirect" is accurate, and all three scripts' observation JSON writes use the tmp-file+os.replace pattern (atomic), matching the "right about observation JSON" half. But the decisive claim — that reprocessing causes observations to be RE-EMITTED — is refuted by write_observation() itself, lines 401-424: `def _ident(e): ... seen = {_ident(e) for e in prior_evidence ...}; kept = [e for e in new_evidence if _ident(e) not in seen]; if not kept: return` (comment at 403-408 explicitly: "Pre-67 this branch appended blindly — occurrences doubled and evidence arrived twice... Merge by event identity: only genuinely new evidence counts").

MECHANISM: A zero-byte .last-watchdog-session does make the "already processed" check miss and the prior transcript gets rescanned — but rescanning does not duplicate stored observations, because write_observation() dedupes every newly-extracted evidence entry against what's already on disk by (timestamp, kind, tool_name, summary) identity and silently no-ops ("a pure replay... do not rewrite the file") when nothing is genuinely new. That merge logic was added specifically to stop exactly this kind of double-emission (the comment names the pre-fix symptom as "occurrences doubled and evidence arrived twice"), so at this commit a corrupted marker wastes a rescan but does not re-emit duplicate observations, refuting the claim's central "bites" mechanism.
