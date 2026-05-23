#!/usr/bin/env bash
# redact-capture: terminal-state capture markdown → redacted JSON envelope.
#
# Reads one capture file (.claude/captures/<id>.md). Emits the Phase 47b
# envelope to stdout ONLY for terminal-state captures (status shipped or
# rejected). Captures carry no privacy_class field — they are treated as
# share-with-redaction: the body is defensively text-redacted before it can
# leave the project boundary, and the frontmatter is reduced to a fixed
# allowlist.
#
# Models redact-observation.sh's fail-closed contract: explicit handling per
# case, refuse on anything malformed.
#
# Output (exit 0): the uniform envelope (see shared-memory.schema.md) with
#   payload = { status, confidence, suggested_artifact_type, created_at,
#               body_redacted }.
#
# Exit codes:
#   0 — envelope emitted to stdout
#   2 — SKIP: status is not terminal (draft|approved) — nothing emitted
#   3 — REFUSED: missing or malformed frontmatter / required field
#   4 — REFUSED: file does not exist or is unreadable
#   5 — REFUSED: python not available
#
# No network. Stdout-only on success (nothing written to disk).

set -uo pipefail

# ---- constants ----
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
# shellcheck source=shared-memory-lib.sh
. "$SCRIPT_DIR/shared-memory-lib.sh"
NOTICE_PREFIX="[redact-capture]"

# ---- helpers ----
emit_refuse() { printf '%s %s\n' "$NOTICE_PREFIX" "$1" >&2; }

# parse_and_redact <file>: stdout line 1 = created_at, line 2 = compact
# payload JSON. Exit 0 = emit, 2 = skip (not terminal), 3 = malformed.
parse_and_redact() {
  "$SM_PY" - "$1" <<'PY'
import json, re, sys

sys.stdout.reconfigure(newline="\n")
try:
    text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
except OSError:
    sys.exit(3)
text = text.replace("\r\n", "\n").replace("\r", "\n")

m = re.match(r"^---\n(.*?)\n---\n?(.*)$", text, re.S)
if not m:
    sys.exit(3)
fm_raw, body = m.group(1), m.group(2)

fm = {}
for line in fm_raw.split("\n"):
    mm = re.match(r"^([A-Za-z0-9_]+):\s*(.*)$", line)
    if mm:
        fm[mm.group(1)] = mm.group(2).strip()

required = ["status", "confidence", "suggested_artifact_type", "created_at", "capture_id"]
if any(not fm.get(k) for k in required):
    sys.exit(3)

if fm["status"] not in ("shipped", "rejected"):
    sys.exit(2)

def redact(s):
    s = re.sub(r"[A-Za-z_]*KEY=\S+", "KEY=<redacted>", s)
    s = re.sub(r"[A-Za-z_]*TOKEN=\S+", "TOKEN=<redacted>", s)
    s = re.sub(r"(?i)\bbearer\s+\S+", "Bearer <redacted>", s)
    s = re.sub(r"(?i)\bauthorization:\s*\S+", "Authorization: <redacted>", s)
    s = re.sub(r"/Users/[^/\s]+/", "~/", s)
    s = re.sub(r"/home/[^/\s]+/", "~/", s)
    s = re.sub(r"[A-Za-z]:\\Users\\[^\\\s]+\\", lambda _: "~\\", s)
    s = re.sub(r"[A-Za-z0-9+/]{32,}={0,2}", "<redacted-b64>", s)
    s = re.sub(r"\?[^\s)]+", "?…", s)
    return s

payload = {
    "status": fm["status"],
    "confidence": fm["confidence"],
    "suggested_artifact_type": fm["suggested_artifact_type"],
    "created_at": fm["created_at"],
    "body_redacted": redact(body).strip(),
}
sys.stdout.write(fm["created_at"] + "\n")
sys.stdout.write(json.dumps(payload))
PY
}

# ---- main ----
main() {
  local cap="${1:-}"
  if [ -z "$cap" ] || [ ! -f "$cap" ] || [ ! -r "$cap" ]; then
    emit_refuse "REFUSED: file does not exist or unreadable: ${cap:-<no path given>}"
    return 4
  fi
  sm_have_python || { emit_refuse "REFUSED: python not on PATH"; return 5; }

  local out rc created_at payload
  out="$(parse_and_redact "$cap")"
  rc=$?
  if [ "$rc" -eq 2 ]; then
    return 2
  fi
  if [ "$rc" -ne 0 ]; then
    emit_refuse "REFUSED: missing or malformed frontmatter: $cap"
    return 3
  fi

  created_at="${out%%$'\n'*}"
  payload="${out#*$'\n'}"
  printf '%s' "$payload" | sm_build_envelope captures "$created_at"
}

main "$@"
rc=$?

# ---- cleanup ----
exit "$rc"
