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
# Phase 126: the canonical probe (python3-first, execution-validated, 3.7
# floor — .claude/lib/detect-python.sh, Phase 112) replaces the inline
# python-first copy. Still exits 0 — SessionStart must never block a
# session — but says why on stderr instead of vanishing (the cruft-check
# precedent). Exit contract unchanged.
# shellcheck source=../lib/detect-python.sh
. "$(cd "$(dirname "$0")/../lib" 2>/dev/null && pwd)/detect-python.sh"
PYBIN="$DETECTED_PYTHON"
if [ -z "$PYBIN" ]; then
  printf 'sessionstart-cost-summary: skipped — %s\n' "$(python_required_message)" >&2
  exit 0
fi
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
        sessions.append((fm.get("started", "") or ended.isoformat(), ended, toks))
    except Exception:
        continue
if not sessions:
    sys.exit(0)

# Resumed sessions re-report CUMULATIVE lineage totals under new session ids
# (same `started`, later `ended`) — summing raw rollups double-counts. Group
# rollups into lineages keyed by `started`: the latest rollup is the
# lineage's current cumulative state; superseded rollups are checkpoints for
# window deltas. (First optimizer pass caught this: $1,037 naive vs ~$216
# true delta over the same 7 days.)
lineages = {}
for started, ended, toks in sessions:
    lineages.setdefault(started, []).append((ended, toks))
for key in lineages:
    lineages[key].sort(key=lambda r: r[0])

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

newest_key = max(lineages, key=lambda k: lineages[k][-1][0])
newest_rollups = lineages[newest_key]
last_ended, last = newest_rollups[-1]
lineage_usd = usd(last)

# Phase 66: the headline is the PER-SITTING delta — latest rollup minus the
# previous checkpoint in the SAME lineage. A resumed lineage's latest rollup
# is a multi-day CUMULATIVE figure; labeling it "session" created false
# premises and permanently tripped warn_usd_per_session once cumulative
# spend crossed the fixed value. Single-rollup lineages: delta == total.
prev = newest_rollups[-2][1] if len(newest_rollups) > 1 else None
if prev is not None:
    sitting_usd = lineage_usd - usd(prev)
    if sitting_usd < 0:
        # defensive: malformed checkpoint ordering must not print a negative
        # dollar — fall back to the lineage total (and drop the context).
        sitting_usd = lineage_usd
        sit = last
        prev = None
    else:
        sit = {k: max(0, last[k] - prev[k]) for k in last}
else:
    sitting_usd = lineage_usd
    sit = last

# 7d figure = per-lineage window deltas, not a raw-rollup sum.
window_start = last_ended - datetime.timedelta(days=7)
week_usd, week_n = 0.0, 0
for key, rollups in lineages.items():
    latest_ended, latest_toks = rollups[-1]
    if latest_ended < window_start:
        continue                      # lineage finished before the window
    baseline = None
    for e, t in rollups[:-1]:
        if e <= window_start:
            baseline = t              # keep the LATEST pre-window checkpoint
    if baseline is None:
        started_ts = parse_ts(key)
        if started_ts is not None and started_ts < window_start and len(rollups) > 1:
            # lineage predates the window with no pre-window checkpoint:
            # best-effort baseline = earliest checkpoint (overestimates less
            # than counting the whole cumulative lineage)
            baseline = rollups[0][1]
    contrib = usd(latest_toks) - (usd(baseline) if baseline else 0.0)
    if contrib > 0:
        week_usd += contrib
        week_n += 1
cache = sit["total_cache_read"] + sit["total_cache_creation"]

def threshold(v):
    # bool is an int subclass; a stray JSON true must not become a $1 threshold
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None

over = []
ws, w7 = threshold(cost.get("warn_usd_per_session")), threshold(cost.get("warn_usd_per_7d"))
if ws is not None and sitting_usd > ws:
    over.append(f"sitting>{ws:g}")
if w7 is not None and week_usd > w7:
    over.append(f"7d>{w7:g}")

# Phase 91: deviation-first ambient display. The durable receipt is the
# telemetry files + commit bodies — this stanza reads, never writes, and
# nothing about recording or thresholds changed. Norm = MEDIAN of clean
# per-sitting deltas under the Phase 66 semantics across all lineages:
# each lineage contributes its first rollup's own total (spacing =
# ended0 - parsed started; unparseable started drops the sample) plus
# consecutive checkpoint deltas (spacing = ended_i - ended_i-1); clean =
# delta > 0 (drops duplicate-checkpoint zeros) AND spacing <= 2.0 days
# (drops the sparse multi-day class). The headline sitting judges
# AGAINST the norm, never into it. Three display states:
#   tripped   -> full dollar line + !! (dollars carry the API-equiv label)
#   thin-data -> < 3 clean samples: full dollar line (a relative claim
#                with no baseline would be fabrication)
#   normal    -> ONE short relative line, no dollars
norm_samples = []
for key, rollups in lineages.items():
    prev_e = prev_t = None
    for i, (e, t) in enumerate(rollups):
        if i == 0:
            st = parse_ts(key)
            span = (e - st).total_seconds() / 86400 if st is not None else None
            delta = usd(t)
        else:
            span = (e - prev_e).total_seconds() / 86400
            delta = usd(t) - usd(prev_t)
        headline = (key == newest_key and i == len(rollups) - 1)
        if not headline and span is not None and delta > 0 and span <= 2.0:
            norm_samples.append(delta)
        prev_e, prev_t = e, t

if over or len(norm_samples) < 3:
    # Lineage cumulative as context, only when a prior checkpoint exists —
    # on a fresh lineage the delta IS the total and the context is noise.
    lineage_ctx = (f"| lineage ~${lineage_usd:,.2f} since {newest_key[:10]} "
                   if prev is not None else "")
    line = (f"[token-cost] last sitting ~${sitting_usd:,.2f} "
            f"(in {fmt(sit['total_tokens_in'])} / out {fmt(sit['total_tokens_out'])} / "
            f"cache {fmt(cache)} @ {model} rates, API-equiv) "
            f"{lineage_ctx}"
            f"| 7d ~${week_usd:,.2f} across {week_n} lineage(s)")
    if over:
        line += "  !! over threshold (" + ", ".join(over) + ")"
else:
    ns = sorted(norm_samples)
    n = len(ns)
    median = ns[n // 2] if n % 2 else (ns[n // 2 - 1] + ns[n // 2]) / 2
    ratio = (sitting_usd / median) if median > 0 else 0.0
    sit_part = "sitting: typical" if ratio <= 1.5 else f"sitting: {ratio:.1f}x median"
    parts = [sit_part]
    if w7 is not None and w7 > 0:
        parts.append(f"7d: {week_usd / w7 * 100:.0f}% of threshold")
    line = "[token-cost] " + " | ".join(parts)
print(line)
PYEOF
fi

# Phase 97: COST_LINE_ONLY (env - an invocation contract, not a config
# key) ends the hook after stanza 1: no nudge logic, no state write.
# Used by receipt-render's live-strip build so the strip can embed the
# cost line without consuming a due optimizer nudge (the strip renders
# from the rules hook, which runs BEFORE this hook in the chain).
[ -n "${COST_LINE_ONLY:-}" ] && exit 0

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
