#!/usr/bin/env bash
# sessionstart-cost-summary: ambient one-line token-spend summary (Phase 48)
# plus the cooldown-gated manager-optimizer nudge (Phase 53).
# Stanza 1 reads .claude/telemetry/sessions/*.md frontmatter, prices it with
# .claude/telemetry/model-pricing.json at the assumed_model from
# .claude/gate-config.json, and prints EXACTLY ONE line (latest session +
# trailing-7-day rollup, with an inline over-threshold marker).
# Stanza 2 prints AT MOST ONE additional ambient line - only when
# gate-config optimizer.enabled and either draft optimizer proposals await
# review or the sessions-since-last-run counter crossed run_every_sessions,
# and the nudge cooldown is satisfied. Printed lines, not gates, not modals
# - NON-INTERRUPTING / BATCH-AT-SEAMS; <=2 lines total from this hook
# (Phase 48's one + Phase 53's at-most-one).
# Fail-soft: any missing input, disabled block, or parse problem means
# print nothing for that stanza; a single bad session file is skipped,
# never fatal. Always exits 0 so the SessionStart hook chain never blocks.

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
[ -f "$GATECONF" ] || exit 0        # both stanzas need gate-config

# Stanza 1 (Phase 48 cost line). Its inputs gate ONLY this stanza - a
# missing pricing file or sessions dir must not suppress the nudge below.
if [ -d "$SESS_DIR" ] && [ -f "$PRICING" ]; then
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
fi

# ---- Phase 53: optimizer nudge (at most ONE additional ambient line) ----
OPT_LEDGER="$ROOT/.claude/telemetry/optimizer-proposals.json"
OPT_STATE="$ROOT/.claude/telemetry/optimizer-state.json"
if [ -f "$OPT_LEDGER" ]; then
  "$PYBIN" - "$OPT_LEDGER" "$OPT_STATE" "$GATECONF" <<'PYEOF' 2>/dev/null
import json, os, sys

ledger_path, state_path, gateconf_path = sys.argv[1], sys.argv[2], sys.argv[3]

def usable_int(v):
    return isinstance(v, int) and not isinstance(v, bool)

try:
    conf = json.load(open(gateconf_path, encoding="utf-8"))
except Exception:
    sys.exit(0)
opt = conf.get("optimizer") or {}
if opt.get("enabled") is not True:
    sys.exit(0)
run_every = opt.get("run_every_sessions")
run_every = run_every if usable_int(run_every) and run_every > 0 else 12
cooldown = opt.get("nudge_cooldown_sessions")
cooldown = cooldown if usable_int(cooldown) and cooldown > 0 else 4

try:
    led = json.load(open(ledger_path, encoding="utf-8"))
    pending = sum(1 for p in (led.get("proposals") or [])
                  if isinstance(p, dict) and p.get("status") == "draft")
except Exception:
    sys.exit(0)

state = {}
try:
    if os.path.exists(state_path):
        loaded = json.load(open(state_path, encoding="utf-8"))
        if isinstance(loaded, dict):
            state = loaded
except Exception:
    state = {}
count = state.get("sessions_since_last_run")
count = count if usable_int(count) and count >= 0 else 0
last_nudge = state.get("last_nudge_count")
last_nudge = last_nudge if usable_int(last_nudge) else None

if not pending and count < run_every:
    sys.exit(0)                      # nothing to nudge about
if last_nudge is not None and (count - last_nudge) < cooldown:
    sys.exit(0)                      # cooldown: don't nag every session

if pending:
    print(f"[manager-optimizer] {pending} draft proposal(s) awaiting review in "
          f".claude/telemetry/optimizer-proposals.json - dispatch manager-optimizer or review by hand")
else:
    print(f"[manager-optimizer] {count} session(s) since last optimizer run "
          f"(threshold {run_every}) - consider dispatching manager-optimizer")

state["last_nudge_count"] = count
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
fi

# ---- cleanup ----
exit 0
