#!/usr/bin/env bash
# graduation-review: skeleton-dogfood-only maintainer tool (Phase 47d). Reads the
# cross-project shared-memory event JSON across installs and prints a grouped
# review report for manual graduation pattern-spotting. Read-and-report ONLY —
# drafts nothing, promotes nothing, suggests nothing. NOT shipped to installs
# (no template counterpart, no mirror — like cruft-check.sh).

set -uo pipefail

# ---- constants ----
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
# shellcheck source=../lib/shared-memory-lib.sh
. "$SCRIPT_DIR/../lib/shared-memory-lib.sh"   # sm_share_enabled, SM_TREE, SM_SHARE_CONFIG, SM_PY
# shellcheck source=../lib/shared-memory-git.sh
. "$SCRIPT_DIR/../lib/shared-memory-git.sh"   # smg_ensure_clone, smg_pull_rebase

# ---- helpers ----
remote_url() {
  [ -n "$SM_PY" ] || return 1
  "$SM_PY" - "$SM_SHARE_CONFIG" <<'PY'
import json, sys
try:
    c = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit(1)
if c.get("enabled") is not True:
    sys.exit(1)
sys.stdout.write(c.get("remote_url") or "")
PY
}

# ---- main ----
main() {
  if ! sm_share_enabled; then
    printf 'Share mode is not enabled — nothing to review.\n'
    return 0
  fi
  sm_have_python || { printf 'python not available — cannot review.\n'; return 0; }
  command -v git >/dev/null 2>&1 || { printf 'git not available — cannot review.\n'; return 0; }
  local url
  url="$(remote_url)" || { printf 'Share enabled but no remote_url — nothing to review.\n'; return 0; }
  [ -n "$url" ] || { printf 'Share enabled but no remote_url — nothing to review.\n'; return 0; }
  smg_ensure_clone "$url" "$SM_TREE" || { printf 'Remote unavailable — nothing to review.\n'; return 0; }
  [ -d "$SM_TREE/.git" ] || { printf 'No shared-memory clone — nothing to review.\n'; return 0; }
  smg_pull_rebase "$SM_TREE" || true

  "$SM_PY" - "$SM_TREE" <<'PY'
import json, os, sys
tree = sys.argv[1]
N, PCT = 15, 75                                  # graduation threshold: 15 installs / 75%
PRODUCERS = ["captures", "observations", "version"]   # telemetry excluded from this report
installs, cap_by_type, obs_by_type = {}, {}, {}
for producer in PRODUCERS:
    pdir = os.path.join(tree, producer)
    if not os.path.isdir(pdir):
        continue
    for root, _dirs, files in os.walk(pdir):
        for fn in files:
            if not fn.endswith(".json"):
                continue
            try:
                e = json.load(open(os.path.join(root, fn), encoding="utf-8"))
            except Exception:
                continue
            uuid = e.get("install_uuid") or "unknown"
            inst = installs.setdefault(uuid, {"label": e.get("install_label") or uuid, "counts": {}})
            inst["counts"][producer] = inst["counts"].get(producer, 0) + 1
            p = e.get("payload") or {}
            if producer == "captures" and p.get("status") == "shipped":
                cap_by_type.setdefault(p.get("suggested_artifact_type") or "unclear", set()).add(uuid)
            elif producer == "observations":
                obs_by_type.setdefault(p.get("pattern_type") or "unknown", set()).add(uuid)

total = len(installs)

def overlap(n):
    pct = (100 * n / total) if total else 0
    meets = "MEETS" if (n >= N and pct >= PCT) else "not yet"
    return f"{n} of {total} installs ({pct:.0f}%) — graduation threshold {N} installs / {PCT}%; {meets}"

print("Shared-memory graduation review (read-only, dogfood maintainer tool)")
print(f"Installs seen: {total}\n")
print("== Per-install summary ==")
if not installs:
    print("  (no producer events found)")
for u in sorted(installs):
    c = installs[u]["counts"]
    print(f"  {installs[u]['label']} ({u[:8]}) — " + ", ".join(f"{p}:{c.get(p, 0)}" for p in PRODUCERS))
print("\n== Captures (shipped) by suggested_artifact_type ==")
if not cap_by_type:
    print("  (none)")
for at in sorted(cap_by_type):
    s = cap_by_type[at]
    print(f"  {at}: shipped in {overlap(len(s))}")
    print("      installs: " + ", ".join(sorted(installs[u]["label"] for u in s)))
print("\n== Observations by pattern_type ==")
if not obs_by_type:
    print("  (none)")
for pt in sorted(obs_by_type):
    s = obs_by_type[pt]
    print(f"  {pt}: observed in {overlap(len(s))}")
    print("      installs: " + ", ".join(sorted(installs[u]["label"] for u in s)))
print("\nRead-and-report only — no captures drafted, nothing promoted. The maintainer does the pattern-spotting.")
PY
}

main "$@"

# ---- cleanup ----
exit 0
