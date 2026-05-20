#!/usr/bin/env bash
# redact-observation: cross-install emission gate for observation files.
#
# Takes an observation JSON file path. Reads the file's privacy_class
# field and decides whether (and how) to emit a sharable version to
# stdout.
#
#   local-only             → REFUSE (exit 2). Never printed to stdout.
#   safe-to-share          → pass-through (jq-canonicalized). All fields
#                            kept as-is — the producer already asserted
#                            this observation carries no project content.
#   share-with-redaction   → strip to the safe-to-share allowlist below.
#                            Fail-closed: any field NOT explicitly named
#                            in the allowlist is dropped. New observation
#                            fields default to dropped, not passed.
#   (missing)              → REFUSE (exit 3). The producer didn't set the
#                            field — run migrate-observation-privacy.sh
#                            first.
#
# Allowlist for share-with-redaction:
#   pattern_id, source, pattern_type, occurrences, first_seen, last_seen,
#   resolved_at, confidence, privacy_class
#   target_resource — ONLY when its category prefix is NOT "file:" or
#                     "command:" (those leak project structure / args).
#   evidence — array; per-entry reduced to {timestamp, kind} ONLY.
#              summary, tool_name, args_redacted dropped.
#   notes, summary, any free-text fields → DROPPED by default.
#
# No network. Stdout-only on success (nothing written to disk). Designed
# to be called by Phase 47+ cross-install push tooling; the contract is
# the field allowlist, not the calling discipline.
#
# Exit codes:
#   0 — redacted JSON emitted to stdout
#   2 — REFUSED: privacy_class == "local-only"
#   3 — REFUSED: privacy_class field missing (run migration first)
#   4 — REFUSED: file does not exist or unreadable
#   5 — REFUSED: privacy_class value not recognized
#   6 — REFUSED: jq not available

set -uo pipefail

# ---- constants ----
# Fail-closed allowlist filter for share-with-redaction observations.
# Keep this filter in sync with the redaction policy documented in
# session-observer.schema.md ("Privacy class mapping" section).
# Adding a new shareable field is a deliberate schema change — edit
# this filter; new fields default to STRIPPED.
SAFE_FILTER='
{
  pattern_id,
  source,
  pattern_type,
  occurrences,
  first_seen,
  last_seen,
  resolved_at,
  confidence,
  privacy_class,
  evidence: ((.evidence // []) | map({timestamp, kind}))
}
+ (if (.target_resource | type) == "string"
       and ((.target_resource | startswith("file:")) | not)
       and ((.target_resource | startswith("command:")) | not)
   then {target_resource}
   else {} end)
'
NOTICE_PREFIX="[redact-observation]"

# ---- helpers ----
emit_refuse() {
  printf '%s REFUSED: %s\n' "$NOTICE_PREFIX" "$1" >&2
}

emit_redacted() {
  # -aS --indent 2 + tr -d '\r' matches producer JSON shape (Python's
  # json.dump with ensure_ascii=True + sort_keys=True + LF line endings).
  jq -aS --indent 2 "$1" "$2" 2>/dev/null | tr -d '\r'
}

# ---- main ----
main() {
  local obs="${1:-}"

  if [ -z "$obs" ] || [ ! -f "$obs" ] || [ ! -r "$obs" ]; then
    emit_refuse "file does not exist or unreadable: ${obs:-<no path given>}"
    return 4
  fi

  command -v jq >/dev/null 2>&1 || {
    emit_refuse "jq not on PATH"
    return 6
  }

  local pclass
  pclass=$(jq -r '.privacy_class // empty' "$obs" 2>/dev/null)

  if [ -z "$pclass" ]; then
    emit_refuse "missing privacy_class — run migrate-observation-privacy.sh first"
    return 3
  fi

  case "$pclass" in
    local-only)
      emit_refuse "local-only observation, never emit cross-install"
      return 2
      ;;
    safe-to-share)
      emit_redacted '.' "$obs"
      ;;
    share-with-redaction)
      emit_redacted "$SAFE_FILTER" "$obs"
      ;;
    *)
      emit_refuse "unknown privacy_class value: $pclass"
      return 5
      ;;
  esac
}

main "$@"
rc=$?

# ---- cleanup ----
exit "$rc"
