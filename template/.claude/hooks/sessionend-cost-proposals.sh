#!/usr/bin/env bash
# sessionend-cost-proposals: the BATCH-AT-SEAMS seam for re-tier drafts
# (Phase 48). Folds any .claude/telemetry/retier-*.draft.json files staged
# by token-cost-monitor during the session into the draft ledger
# .claude/telemetry/retier-proposals.json (entries always enter as status
# "draft"). Consumed drafts are removed only AFTER the ledger write lands;
# unparseable drafts are renamed *.malformed (kept for human review, never
# silently deleted, never retried). DRAFT-ONLY: this seam writes the ledger
# and nothing else - it never touches a model pin, settings, or any live
# component. No-op when nothing is staged. Idempotent by entry id (ids for
# id-less drafts derive from filename + content hash, so retries after a
# failed cleanup cannot duplicate). Fail-soft: always exits 0 so the
# SessionEnd hook chain never blocks.

set -uo pipefail

# ---- constants ----
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
TELEM="$ROOT/.claude/telemetry"
LEDGER="$TELEM/retier-proposals.json"

# ---- helpers ----
# (none - the python block below owns the whole merge + file lifecycle)

# ---- main ----
PYBIN=$(command -v python || command -v python3) || exit 0
[ -f "$LEDGER" ] || exit 0

shopt -s nullglob
drafts=("$TELEM"/retier-*.draft.json)
shopt -u nullglob
[ "${#drafts[@]}" -gt 0 ] || exit 0

"$PYBIN" - "$LEDGER" "${drafts[@]}" <<'PYEOF' 2>/dev/null
import datetime, hashlib, json, os, sys

ledger_path, draft_paths = sys.argv[1], sys.argv[2:]
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
            if base.startswith("retier-"):
                base = base[len("retier-"):]
            d["id"] = f"retier-{base}-{hashlib.sha1(raw).hexdigest()[:8]}"
        if d["id"] in seen:
            consumed.append(path)   # already in the ledger: just clean up
            continue
        d["status"] = "draft"       # entries always ENTER as draft
        d.setdefault("created_at", now)
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
    parts.append(f"batched {added} re-tier draft proposal(s) into retier-proposals.json")
if malformed:
    parts.append(f"{len(malformed)} unparseable draft(s) kept as *.malformed")
if parts:
    print("[token-cost] " + "; ".join(parts))
PYEOF

# ---- cleanup ----
exit 0
