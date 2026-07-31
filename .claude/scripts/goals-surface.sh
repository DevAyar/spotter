#!/usr/bin/env bash
# goals-surface: SessionStart surfacer for due scheduled goals (Phase 68).
# Scans .claude/specs/*.md frontmatter; specs with status: approved AND a
# due schedule produce ONE ambient line. draft/consumed/abandoned NEVER
# surface — the approval gate is load-bearing. Due semantics (stateless,
# per goal-spec.schema.md): YYYY-MM-DD -> today >= date; daily -> always
# (this cooldown gates noise); weekly -> Mondays; monthly -> the 1st.
# --hook honors a 24h cooldown via .claude/.last-goals-surface (written
# only when something surfaced, so a quiet day never suppresses tomorrow's
# due item); manual dispatch ignores the cooldown (cruft-check convention).
# Read-only except the cooldown marker. Always exits 0 — never blocks the
# SessionStart hook chain.

set -uo pipefail

# ---- constants ----
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SPECS_DIR="$ROOT/.claude/specs"
COOLDOWN_FILE="$ROOT/.claude/.last-goals-surface"
COOLDOWN_SECS=86400
HOOK_FLAG=false

# ---- args ----
for arg in "$@"; do
  case "$arg" in
    --hook) HOOK_FLAG=true ;;
  esac
done

# ---- helpers ----
# python||python3 validated by EXECUTION, not presence — the Windows Store
# alias stub passes `command -v` but exits nonzero (the Phase 57 silent-inert
# class; probe pattern per Phase 63).
# Phase 112: delegated to the canonical probe. This script's previous
# inline probe validated by execution (safe) but tried python BEFORE
# python3 and had no version floor — consistency, not a defect fix.
# shellcheck source=../lib/detect-python.sh
. "$(cd "$(dirname "$0")/../lib" 2>/dev/null && pwd)/detect-python.sh"
PYBIN="$DETECTED_PYTHON"

# ---- main ----
[ -n "$PYBIN" ] || exit 0
[ -d "$SPECS_DIR" ] || exit 0

if [ "$HOOK_FLAG" = true ] && [ -f "$COOLDOWN_FILE" ]; then
  last=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  now=$(date +%s)
  if [ $((now - last)) -lt "$COOLDOWN_SECS" ]; then
    exit 0
  fi
fi

LINE=$("$PYBIN" - "$SPECS_DIR" <<'PYEOF' 2>/dev/null
import datetime, os, sys

specs_dir = sys.argv[1]
today = datetime.date.today()

def frontmatter(path):
    fm = {}
    try:
        # utf-8-sig: tolerate BOM-prefixed files (PowerShell rewrites emit one)
        with open(path, encoding="utf-8-sig", errors="replace") as f:
            if f.readline().strip() != "---":
                return None
            for line in f:
                if line.strip() == "---":
                    return fm
                if ":" in line:
                    k, v = line.split(":", 1)
                    fm[k.strip()] = v.strip()
    except OSError:
        return None
    return None

def due(schedule):
    s = (schedule or "").strip().lower()
    if not s:
        return False
    if s == "daily":
        return True
    if s == "weekly":
        return today.weekday() == 0
    if s == "monthly":
        return today.day == 1
    try:
        return today >= datetime.date.fromisoformat(s)
    except ValueError:
        return False

hits = []
for fn in sorted(os.listdir(specs_dir)):
    # one poisoned spec must never suppress the line: skip, not die
    try:
        if not fn.endswith(".md") or fn == "README.md" or fn.endswith(".schema.md"):
            continue
        fm = frontmatter(os.path.join(specs_dir, fn))
        if not fm:
            continue
        if fm.get("status") != "approved":
            continue
        if due(fm.get("schedule")):
            hits.append((fm.get("id") or fn[:-3], fm.get("schedule")))
    except Exception:
        continue
if hits:
    parts = ", ".join(f"{i} (due {s})" for i, s in hits)
    print(f"[goals] {len(hits)} scheduled goal(s) due: {parts} - review .claude/specs/ or dispatch the work")
PYEOF
) || LINE=""

if [ -n "$LINE" ]; then
  printf '%s\n' "$LINE"
  date +%s > "$COOLDOWN_FILE" 2>/dev/null || true
fi

# ---- cleanup ----
exit 0
