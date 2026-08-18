#!/usr/bin/env bash
# sessionend-cost-proposals: the BATCH-AT-SEAMS seam for staged draft
# proposals. Phase 48 folds retier-*.draft.json into retier-proposals.json;
# Phase 53 extends the same seam (same file - the chain is extended, not
# widened) to fold optimizer-*.draft.json into optimizer-proposals.json and
# to increment the sessions_since_last_run counter in the gitignored runtime
# file optimizer-state.json. Entries enter their ledger as status "draft",
# EXCEPT a draft carrying a recorded human disposition — a disposed status
# plus a review_note (Phase 88) — which folds in with the disposition
# preserved; a draft whose id is already in the ledger is consumed without
# touching the ledger entry (the ledger is the authority). Consumed drafts
# are removed only AFTER the ledger write lands;
# unparseable drafts are renamed *.malformed (kept for human review, never
# silently deleted, never retried). DRAFT-ONLY: this seam writes the two
# ledgers and the counter file, nothing else - it never touches a model pin,
# a directive surface, settings, or any live component. No-op per family
# when nothing is staged. Idempotent by entry id (ids for id-less drafts
# derive from filename + content hash, so retries after a failed cleanup
# cannot duplicate). Fail-soft: always exits 0 so the SessionEnd hook chain
# never blocks.

set -uo pipefail

# ---- constants ----
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
TELEM="$ROOT/.claude/telemetry"
OPT_STATE="$TELEM/optimizer-state.json"
AUDIT_STATE="$TELEM/audit-state.json"
GATECONF="$ROOT/.claude/gate-config.json"
# family table: <staging-prefix> <ledger-file> <timestamp-field>
FAMILIES=(
  "retier    retier-proposals.json    created_at"
  "optimizer optimizer-proposals.json timestamp"
)

# ---- helpers ----
# (none - the python blocks below own the merge + counter lifecycles)

# ---- main ----
# Phase 126: the canonical probe (python3-first, execution-validated, 3.7
# floor — .claude/lib/detect-python.sh, Phase 112) replaces the inline
# python-first copy. Still exits 0 — the SessionEnd chain must never
# block — but says why on stderr instead of vanishing (the cruft-check
# precedent). Exit contract unchanged.
# shellcheck source=../lib/detect-python.sh
. "$(cd "$(dirname "$0")/../lib" 2>/dev/null && pwd)/detect-python.sh"
PYBIN="$DETECTED_PYTHON"
if [ -z "$PYBIN" ]; then
  printf 'sessionend-cost-proposals: skipped — %s\n' "$(python_required_message)" >&2
  exit 0
fi

# Phase 53: mechanical session counter (runs every session end, fail-soft).
[ -d "$TELEM" ] && "$PYBIN" - "$OPT_STATE" <<'PYEOF' 2>/dev/null
import json, os, sys

state_path = sys.argv[1]
state = {}
try:
    if os.path.exists(state_path):
        loaded = json.load(open(state_path, encoding="utf-8"))
        if isinstance(loaded, dict):
            state = loaded
except Exception:
    state = {}                       # malformed state: recreate, don't die
count = state.get("sessions_since_last_run")
if not (isinstance(count, int) and not isinstance(count, bool) and count >= 0):
    count = 0
state["sessions_since_last_run"] = count + 1
state.setdefault("last_run_at", None)
state.setdefault("last_nudge_count", None)
tmp = state_path + f".tmp.{os.getpid()}"
try:
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp, state_path)
except Exception:
    try:
        os.remove(tmp)
    except OSError:
        pass
PYEOF

# Phase 74: per-audit session counters (the Phase 53 counter pattern reused
# in the same hook, not a second mechanism). Registry-driven: every audit
# registered in gate-config's `audits` block gets sessions_since_dispatch
# incremented here — future audits auto-count the day they register. The
# manager's dispatch flow resets an entry to 0 at dispatch time. Fail-soft.
[ -d "$TELEM" ] && [ -f "$GATECONF" ] && "$PYBIN" - "$AUDIT_STATE" "$GATECONF" <<'PYEOF' 2>/dev/null
import json, os, sys

state_path, gateconf_path = sys.argv[1], sys.argv[2]
try:
    audits = (json.load(open(gateconf_path, encoding="utf-8")).get("audits") or {})
except Exception:
    sys.exit(0)
if not isinstance(audits, dict) or not audits:
    sys.exit(0)
state = {}
try:
    if os.path.exists(state_path):
        loaded = json.load(open(state_path, encoding="utf-8"))
        if isinstance(loaded, dict):
            state = loaded
except Exception:
    state = {}                       # malformed state: recreate, don't die
for name in audits:
    entry = state.get(name)
    if not isinstance(entry, dict):
        entry = {}
    count = entry.get("sessions_since_dispatch")
    if not (isinstance(count, int) and not isinstance(count, bool) and count >= 0):
        count = 0
    entry["sessions_since_dispatch"] = count + 1
    entry.setdefault("last_dispatched_at", None)
    state[name] = entry
tmp = state_path + f".tmp.{os.getpid()}"
try:
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        json.dump(state, f, indent=2)
        f.write("\n")
    os.replace(tmp, state_path)
except Exception:
    try:
        os.remove(tmp)
    except OSError:
        pass
PYEOF

# Fold staged drafts per family (Phase 48 hardening preserved wholesale).
for family_row in "${FAMILIES[@]}"; do
  read -r family ledger_name ts_field <<<"$family_row"
  LEDGER="$TELEM/$ledger_name"
  [ -f "$LEDGER" ] || continue

  shopt -s nullglob
  drafts=("$TELEM/$family"-*.draft.json)
  shopt -u nullglob
  [ "${#drafts[@]}" -gt 0 ] || continue

  "$PYBIN" - "$LEDGER" "$family" "$ts_field" "${drafts[@]}" <<'PYEOF' 2>/dev/null
import datetime, hashlib, json, os, sys

ledger_path, family, ts_field = sys.argv[1], sys.argv[2], sys.argv[3]
draft_paths = sys.argv[4:]
try:
    ledger = json.load(open(ledger_path, encoding="utf-8"))
    props = ledger.setdefault("proposals", [])
    assert isinstance(props, list)
except Exception:
    sys.exit(0)                     # unreadable ledger: leave drafts staged
seen = {p.get("id") for p in props if isinstance(p, dict) and isinstance(p.get("id"), str)}
now = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

consumed, malformed, added = [], [], 0
for path in draft_paths:
    # one poisoned draft must never wedge the seam: isolate per-draft
    try:
        raw = open(path, "rb").read()
        d = json.loads(raw.decode("utf-8-sig"))
        if not isinstance(d, dict):
            raise ValueError("draft is not an object")
        if not isinstance(d.get("id"), str) or not d["id"]:
            # deterministic id: filename + content hash (no timestamp, so a
            # retry after failed cleanup merges to the SAME id -> no dupes)
            base = os.path.basename(path)[:-len(".draft.json")]
            if base.startswith(family + "-"):
                base = base[len(family) + 1:]
            d["id"] = f"{family}-{base}-{hashlib.sha1(raw).hexdigest()[:8]}"
        if d["id"] in seen:
            consumed.append(path)   # already in the ledger: ledger wins, just clean up
            continue
        # Phase 88: a draft carrying a recorded human disposition — a
        # disposed status PLUS a non-empty review_note, the pair only a
        # review writes (producers never write review_note) — keeps it.
        # Anything else, including a bare non-draft status without the
        # note, fails closed to draft: nothing self-approves through the
        # fold, and the silent-disposition-loss class (bb0a3e9) is closed.
        disposed = d.get("status") in ("approved", "applied", "rejected")
        reviewed = isinstance(d.get("review_note"), str) and d["review_note"].strip()
        if not (disposed and reviewed):
            d["status"] = "draft"   # entries otherwise ENTER as draft
        d.setdefault(ts_field, now)
        props.append(d)
        seen.add(d["id"])
        consumed.append(path)
        added += 1
    except Exception:
        malformed.append(path)

if added:
    tmp = ledger_path + f".tmp.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="utf-8", newline="\n") as f:
            json.dump(ledger, f, indent=2)
            f.write("\n")
        os.replace(tmp, ledger_path)
    except Exception:
        try:
            os.remove(tmp)          # no tmp litter on a failed write
        except OSError:
            pass
        sys.exit(0)                 # ledger not updated: leave drafts staged

# cleanup only after the ledger write landed (or entries were duplicates)
for path in consumed:
    try:
        os.remove(path)
    except OSError:
        pass                        # deterministic ids make a retry safe
for path in malformed:
    try:
        os.replace(path, path + ".malformed")   # visible trace, not retried
    except OSError:
        pass

parts = []
if added:
    parts.append(f"batched {added} {family} draft proposal(s) into {os.path.basename(ledger_path)}")
if malformed:
    parts.append(f"{len(malformed)} unparseable {family} draft(s) kept as *.malformed")
if parts:
    print("[token-cost] " + "; ".join(parts))
PYEOF
done

# ---- cleanup ----
exit 0
