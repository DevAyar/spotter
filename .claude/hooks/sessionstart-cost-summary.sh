#!/usr/bin/env bash
# sessionstart-cost-summary: ambient one-line token-spend summary (Phase 48).
# Reads .claude/telemetry/sessions/*.md frontmatter, prices it with
# .claude/telemetry/model-pricing.json at the assumed_model from
# .claude/gate-config.json, and prints EXACTLY ONE line (latest session +
# trailing-7-day rollup, with an inline over-threshold marker). A printed
# line, not a gate, not a modal - NON-INTERRUPTING / BATCH-AT-SEAMS.
# Fail-soft: any missing input, disabled cost block, or parse problem means
# print nothing; a single bad session file is skipped, never fatal. Always
# exits 0 so the SessionStart hook chain never blocks.

set -uo pipefail

# ---- constants ----
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SESS_DIR="$ROOT/.claude/telemetry/sessions"
PRICING="$ROOT/.claude/telemetry/model-pricing.json"
GATECONF="$ROOT/.claude/gate-config.json"

# ---- helpers ----
# (none - the single python block below does the parsing and arithmetic)

# ---- main ----
PYBIN=$(command -v python || command -v python3) || exit 0
[ -d "$SESS_DIR" ] || exit 0
[ -f "$PRICING" ] || exit 0
[ -f "$GATECONF" ] || exit 0

"$PYBIN" - "$SESS_DIR" "$PRICING" "$GATECONF" <<'PYEOF' 2>/dev/null
import datetime, json, os, sys

sess_dir, pricing_path, gateconf_path = sys.argv[1], sys.argv[2], sys.argv[3]
pricing = json.load(open(pricing_path, encoding="utf-8"))
conf = json.load(open(gateconf_path, encoding="utf-8"))
cost = conf.get("cost") or {}
if cost.get("enabled") is not True:
    sys.exit(0)
model = cost.get("assumed_model", "claude-opus-4-8")
row = (pricing.get("models") or {}).get(model)
if not row:
    sys.exit(0)

def frontmatter(path):
    fm = {}
    # utf-8-sig: tolerate BOM-prefixed files (PowerShell 5.1 rewrites emit one)
    with open(path, encoding="utf-8-sig", errors="replace") as f:
        if f.readline().strip() != "---":
            return None
        for line in f:
            if line.strip() == "---":
                return fm
            if ":" in line:
                k, v = line.split(":", 1)
                fm[k.strip()] = v.strip()
    return None

UTC = datetime.timezone.utc

def parse_ts(s):
    try:
        ts = datetime.datetime.fromisoformat(s.replace("Z", "+00:00"))
    except Exception:
        return None
    # coerce naive timestamps so aware/naive never mix in sort/subtraction
    return ts if ts.tzinfo else ts.replace(tzinfo=UTC)

sessions = []
for fn in os.listdir(sess_dir):
    # one poisoned file must never suppress the whole summary: skip, not die
    try:
        if not fn.endswith(".md"):
            continue
        fm = frontmatter(os.path.join(sess_dir, fn))
        if not fm or fm.get("data_available", "").lower() != "true":
            continue
        ended = parse_ts(fm.get("ended", ""))
        if ended is None:
            continue
        toks = {k: int(float(fm.get(k, "0"))) for k in
                ("total_tokens_in", "total_tokens_out",
                 "total_cache_creation", "total_cache_read")}
        sessions.append((ended, toks))
    except Exception:
        continue
if not sessions:
    sys.exit(0)
sessions.sort(key=lambda s: s[0])

p_in, p_out = row["input_per_mtok"], row["output_per_mtok"]
c_read = pricing.get("cache_read_multiplier", 0.1)
c_write = pricing.get("cache_write_multiplier_5m", 1.25)

def usd(t):
    return (t["total_tokens_in"] * p_in
            + t["total_tokens_out"] * p_out
            + t["total_cache_read"] * p_in * c_read
            + t["total_cache_creation"] * p_in * c_write) / 1e6

def fmt(n):
    return f"{n / 1e6:.1f}M" if n >= 100_000 else f"{n:,}"

last_ended, last = sessions[-1]
last_usd = usd(last)
week = [t for e, t in sessions if (last_ended - e).days < 7]
week_usd = sum(usd(t) for t in week)
cache = last["total_cache_read"] + last["total_cache_creation"]

line = (f"[token-cost] last session ~${last_usd:,.2f} "
        f"(in {fmt(last['total_tokens_in'])} / out {fmt(last['total_tokens_out'])} / "
        f"cache {fmt(cache)} @ {model} rates) | "
        f"7d ~${week_usd:,.2f} across {len(week)} session(s)")

def threshold(v):
    # bool is an int subclass; a stray JSON true must not become a $1 threshold
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None

over = []
ws, w7 = threshold(cost.get("warn_usd_per_session")), threshold(cost.get("warn_usd_per_7d"))
if ws is not None and last_usd > ws:
    over.append(f"session>{ws:g}")
if w7 is not None and week_usd > w7:
    over.append(f"7d>{w7:g}")
if over:
    line += "  !! over threshold (" + ", ".join(over) + ")"
print(line)
PYEOF

# ---- cleanup ----
exit 0
