#!/usr/bin/env bash
# shared-memory-lib: sourced helpers for Phase 47b cross-project git memory
# producers. Defines the uniform JSON envelope builder and the local
# shared-memory tree write helpers. SOURCED, never executed — no main, no
# top-level exit. Callers own their strict mode (set -uo pipefail).
#
# The local tree lives at .claude/shared-memory/ and is a plain directory
# (no git). Producers only write JSON event files into it; Phase 47c owns
# the git clone + push. Everything no-ops unless share mode is enabled
# (.claude/share-config.json with enabled == true).
#
# Envelope shape (schema_version 1) — see shared-memory.schema.md:
#   { schema_version, producer, install_uuid, install_label, version,
#     commit, event_timestamp, created_at?, payload }
# Marker-native field names throughout (version / commit, never skeleton_*).

# ---- constants ----
SM_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
SM_ROOT="$(cd "$SM_LIB_DIR/../.." 2>/dev/null && pwd)"
SM_MARKER="$SM_ROOT/.claude/.skeleton-version"
SM_SHARE_CONFIG="$SM_ROOT/.claude/share-config.json"
SM_TREE="$SM_ROOT/.claude/shared-memory"
SM_PY=""
if   command -v python  >/dev/null 2>&1; then SM_PY="python"
elif command -v python3 >/dev/null 2>&1; then SM_PY="python3"; fi

# ---- helpers ----
sm_have_python() { [ -n "$SM_PY" ]; }

sm_now_iso()   { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
sm_today_utc() { date -u +"%Y-%m-%d"; }

# sm_json_field <file> <key> → top-level value on stdout (empty if missing).
sm_json_field() {
  [ -n "$SM_PY" ] || return 1
  "$SM_PY" - "$1" "$2" <<'PY'
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(0)
v = d.get(sys.argv[2])
sys.stdout.write("" if v is None else str(v))
PY
}

# sm_marker_field <key> → marker value on stdout.
sm_marker_field() { sm_json_field "$SM_MARKER" "$1"; }

# sm_install_uuid → install_uuid (empty if missing).
sm_install_uuid() { sm_marker_field install_uuid; }

# sm_share_enabled → 0 iff share-config.json exists AND enabled is true.
sm_share_enabled() {
  [ -f "$SM_SHARE_CONFIG" ] || return 1
  [ -n "$SM_PY" ] || return 1
  "$SM_PY" - "$SM_SHARE_CONFIG" <<'PY'
import json, sys
try:
    c = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(1)
sys.exit(0 if c.get("enabled") is True else 1)
PY
}

# sm_build_envelope <producer> <created_at-or-empty>
#   Reads producer-specific payload JSON from stdin; writes the full
#   envelope JSON to stdout (sorted keys, 2-space indent, trailing LF).
#   stdin is spooled to a temp file because the python program itself is
#   delivered on stdin via the heredoc — the two cannot share stdin.
sm_build_envelope() {
  [ -n "$SM_PY" ] || return 1
  local tmp rc
  tmp="$(mktemp 2>/dev/null)" || return 1
  cat > "$tmp"
  "$SM_PY" - "$SM_MARKER" "$1" "$2" "$(sm_now_iso)" "$tmp" <<'PY'
import json, sys
sys.stdout.reconfigure(newline="\n")
marker, producer, created_at, ts, payload_path = sys.argv[1:6]
try:
    m = json.load(open(marker, encoding="utf-8"))
except Exception:
    m = {}
try:
    payload = json.load(open(payload_path, encoding="utf-8"))
except Exception:
    sys.exit(1)
env = {
    "schema_version": 1,
    "producer": producer,
    "install_uuid": m.get("install_uuid"),
    "install_label": m.get("install_label") or m.get("install_uuid"),
    "version": m.get("version"),
    "commit": m.get("commit"),
    "event_timestamp": ts,
    "payload": payload,
}
if created_at:
    env["created_at"] = created_at
json.dump(env, sys.stdout, indent=2, sort_keys=True)
sys.stdout.write("\n")
PY
  rc=$?
  rm -f "$tmp"
  return "$rc"
}

# sm_event_exists <producer> <key> → 0 if an event for <key> already exists
# under any date dir (append-only idempotency) or at the no-date path.
sm_event_exists() {
  local producer="$1" key="$2" uuid base f
  uuid="$(sm_install_uuid)"
  [ -n "$uuid" ] || return 1
  base="$SM_TREE/$producer/$uuid"
  [ -d "$base" ] || return 1
  for f in "$base"/*/"$key.json" "$base/$key.json"; do
    [ -e "$f" ] && return 0
  done
  return 1
}

# sm_write_event <producer> <key> <date|->
#   Reads envelope JSON from stdin and writes it to
#   <tree>/<producer>/<uuid>/<date>/<key>.json via atomic temp-rename.
#   date "-" → no date dir (version current-state, always overwrite).
#   Otherwise append-only: skip silently if the key already exists.
sm_write_event() {
  local producer="$1" key="$2" date="$3" uuid dir dest tmp
  uuid="$(sm_install_uuid)"
  [ -n "$uuid" ] || { cat >/dev/null; return 1; }
  if [ "$date" = "-" ]; then
    dir="$SM_TREE/$producer/$uuid"
  else
    if sm_event_exists "$producer" "$key"; then
      cat >/dev/null
      return 0
    fi
    dir="$SM_TREE/$producer/$uuid/$date"
  fi
  mkdir -p "$dir" 2>/dev/null || { cat >/dev/null; return 1; }
  dest="$dir/$key.json"
  tmp="$dest.tmp.$$"
  cat > "$tmp" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$dest" || { rm -f "$tmp"; return 1; }
}
