#!/usr/bin/env python3
"""Confidence experiment - analysis pass over results_real.json.

THROWAWAY RESEARCH CODE. Reads the capture (results_real.json, gitignored),
never calls the API. Two jobs:

1. Fix-forward re-extraction for the three routing tasks, whose strict
   choice-extractor under-parsed prose answers (<unparsed>). Raw responses
   are printed VERBATIM before re-extraction so the failure mode is visible.
   Genuinely unparseable runs drop from that task's agreement denominator.
2. The pre-committed analysis: per-task agreement table with exact chance
   floors, accuracy summaries, verdict scatter plots, variance report,
   minimum-N curve, and ANALYSIS.md read against MANIFEST_HEADER.md's gate
   language. The script reports; it does not editorialize.
"""
import json
import re
import statistics
import sys
from collections import Counter, defaultdict
from functools import lru_cache
from math import factorial
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

HERE = Path(__file__).resolve().parent
RESULTS = HERE / "results_real.json"
ROUTING_IDS = ("gap_route_01", "gap_route_02", "gap_route_03")
N = 7

rows = json.loads(RESULTS.read_text(encoding="utf-8"))
assert len(rows) == 31, f"expected 31 rows, got {len(rows)}"


# --- tolerant re-extraction (routing fix-forward) -----------------------------
def norm(s):
    """casefold; strip punctuation/backticks/quotes; collapse -/_/whitespace."""
    s = s.casefold()
    s = re.sub(r"[`\"'*.,;:!?()\[\]{}]", " ", s)
    s = re.sub(r"[-_\s]+", " ", s)
    return s.strip()


LABELS = ("suggested artifact type", "artifact type", "routes to", "route to",
          "answer is", "answer")


def tolerant_extract(response, enum_values):
    """Return (answer_or_None, strategy). Ordered, auditable strategies."""
    ntext = norm(response)
    hits = []  # (position, enum_value)
    for v in enum_values:
        for m in re.finditer(rf"\b{re.escape(norm(v))}\b", ntext):
            hits.append((m.start(), v))
    if not hits:
        return None, "UNPARSEABLE"
    distinct = {v for _, v in hits}
    if len(distinct) == 1:
        return hits[0][1], "single-value"
    # several distinct enum values present: prefer a labeled phrasing (last one),
    # else the last-occurring value (models conclude with the answer).
    labeled = []
    for pos, v in hits:
        prefix = ntext[max(0, pos - 40):pos]
        if any(lbl in prefix for lbl in LABELS):
            labeled.append((pos, v))
    if labeled:
        return max(labeled)[1], "labeled"
    return max(hits)[1], "last-occurrence"


print("=" * 78)
print("PART 1 - ROUTING RE-EXTRACTION (fix-forward for the strict choice extractor)")
print("=" * 78)

recovered = {}   # task_id -> list of valid answers (unparseable runs dropped)
flags = {}       # task_id -> notes about drops / disagreements
for r in rows:
    if r["task_id"] not in ROUTING_IDS:
        continue
    enum_values = r["canonical_answers"]
    print(f"\n--- {r['task_id']} (ground_truth: {r['ground_truth']}) ---")
    print("raw_responses, verbatim:")
    for i, resp in enumerate(r["raw_responses"], 1):
        print(f"  run {i}: {resp!r}")
    answers, strategies, dropped = [], [], 0
    for i, resp in enumerate(r["raw_responses"]):
        ans, strat = tolerant_extract(resp, enum_values)
        strict = r["raw_answers"][i]
        if strict != "<unparsed>" and ans is not None and ans != strict:
            print(f"  !! run {i+1}: tolerant ({ans}) disagrees with strict ({strict}) - keeping strict")
            ans, strat = strict, "strict-kept"
        if ans is None:
            dropped += 1
        else:
            answers.append(ans)
        strategies.append(strat)
    recovered[r["task_id"]] = answers
    flags[r["task_id"]] = f"{dropped} run(s) genuinely unparseable, dropped from denominator" if dropped else ""
    print(f"re-extracted: {answers}")
    print(f"strategies:   {strategies}")
    print(f"recovered {len(answers)}/7 runs" + (f"  [FLAG: {flags[r['task_id']]}]" if dropped else ""))


# --- chance floors (exact, uniform multinomial) --------------------------------
@lru_cache(maxsize=None)
def exact_modal_floor(k, n=N):
    """Exact E[max count]/n for n uniform draws over k options."""

    def compositions(total, parts):
        if parts == 1:
            yield (total,)
            return
        for head in range(total + 1):
            for rest in compositions(total - head, parts - 1):
                yield (head,) + rest

    exp_max = 0.0
    for counts in compositions(n, k):
        ways = factorial(n)
        for c in counts:
            ways //= factorial(c)
        exp_max += max(counts) * (ways / (k ** n))
    return exp_max / n


# --- per-task records -----------------------------------------------------------
records = []
for r in rows:
    tid = r["task_id"]
    if tid in ROUTING_IDS:
        valid = recovered[tid]
    else:
        assert "<unparsed>" not in r["raw_answers"], f"unexpected unparsed outside routing: {tid}"
        valid = list(r["raw_answers"])
    counts = Counter(valid)
    top = counts.most_common()
    scored = len(valid) > 0
    if scored:
        tie = len(top) > 1 and top[0][1] == top[1][1]
        modal, modal_n = top[0]
    else:
        tie, modal, modal_n = False, None, 0   # zero valid runs -> UNSCOREABLE
    rec = {
        "task_id": tid,
        "task_class": r["task_class"],
        "difficulty": r.get("difficulty") or "-",
        "source": r["source"],
        "framing": r.get("framing") or r["task_type"],
        "n_valid": len(valid),
        "scored": scored,
        "modal": (modal + ("*TIE*" if tie else "")) if scored else "-",
        "agreement": (modal_n / len(valid)) if scored else None,
        "ground_truth": r["ground_truth"],
        "correct": scored and (modal == r["ground_truth"]) and not tie,
        "chance_floor": exact_modal_floor(len(r["canonical_answers"])),
        "valid_answers": valid,
        "flag": flags.get(tid, "") if scored else "UNSCOREABLE - zero valid runs; excluded from scoring",
    }
    records.append(rec)

scored_recs = [rec for rec in records if rec["scored"]]
unscoreable = [rec for rec in records if not rec["scored"]]

print("\n" + "=" * 78)
print("PART 2 - PER-TASK TABLE (31 tasks)")
print("=" * 78)
hdr = f"{'task_id':34}{'class':9}{'diff':11}{'src':11}{'nv':3} {'modal':20}{'agree':7}{'truth':20}{'ok':3} {'floor':6}"
print(hdr)
print("-" * len(hdr))
for rec in records:
    agree_s = f"{rec['agreement']:<7.3f}" if rec["scored"] else f"{'-':7}"
    ok_s = ("Y" if rec["correct"] else "N") if rec["scored"] else "-"
    print(f"{rec['task_id']:34}{rec['task_class']:9}{rec['difficulty']:11}{rec['source']:11}"
          f"{rec['n_valid']:<3}{rec['modal']:20}{agree_s}{str(rec['ground_truth']):20}"
          f"{ok_s:3}{rec['chance_floor']:<6.3f}"
          + (f"  {rec['flag']}" if rec['flag'] else ""))
print(f"\nscored: {len(scored_recs)}/31" + (f" | unscoreable: {[u['task_id'] for u in unscoreable]}" if unscoreable else ""))

# --- accuracy summaries -----------------------------------------------------------
def acc(subset):
    return (sum(1 for x in subset if x["correct"]), len(subset))


def summarize(key):
    groups = defaultdict(list)
    for rec in scored_recs:
        groups[rec[key]].append(rec)
    return {g: acc(v) for g, v in sorted(groups.items())}


print("\n" + "=" * 78)
print("PART 3 - ACCURACY SUMMARY (scored tasks only)")
print("=" * 78)
c, t = acc(scored_recs)
print(f"overall: {c}/{t} ({c/t:.1%})")
summaries = {}
for key in ("task_class", "difficulty", "source", "framing"):
    summaries[key] = summarize(key)
    parts = ", ".join(f"{g}: {cc}/{tt}" for g, (cc, tt) in summaries[key].items())
    print(f"by {key}: {parts}")

# --- verdict plots ------------------------------------------------------------------
import random
random.seed(31)  # deterministic jitter


def scatter(subset, path, title):
    fig, ax = plt.subplots(figsize=(8, 4.5))
    for rec in subset:
        x = rec["agreement"] + random.uniform(-0.012, 0.012)
        y = (1 if rec["correct"] else 0) + random.uniform(-0.06, 0.06)
        ax.scatter(x, y, s=46, alpha=0.75,
                   color="#2a7f4f" if rec["correct"] else "#b03030",
                   edgecolor="black", linewidth=0.4)
        if not rec["correct"]:
            ax.annotate(rec["task_id"].replace("gap_", "").replace("stress_", "s:"),
                        (x, y), fontsize=7, xytext=(4, 4), textcoords="offset points")
    ax.set_xlabel("resampling agreement (modal / valid runs)")
    ax.set_ylabel("modal answer correct")
    ax.set_yticks([0, 1]); ax.set_yticklabels(["wrong", "right"])
    ax.set_xlim(0.3, 1.1); ax.set_ylim(-0.35, 1.35)
    ax.set_title(title)
    ax.grid(True, alpha=0.25)
    fig.tight_layout()
    fig.savefig(path, dpi=140)
    plt.close(fig)


scatter(scored_recs, HERE / "scatter_agreement_all.png",
        f"Agreement vs correctness - all {len(scored_recs)} scored tasks (jittered)")
gap_only = [rec for rec in scored_recs if rec["task_class"] == "gap"]
scatter(gap_only, HERE / "scatter_agreement_gap.png",
        "Agreement vs correctness - GAP POOL (the verdict plot, jittered)")
print("\nplots written: scatter_agreement_all.png, scatter_agreement_gap.png")

# --- variance report ----------------------------------------------------------------
print("\n" + "=" * 78)
print("PART 4 - VARIANCE REPORT")
print("=" * 78)
agreements = [rec["agreement"] for rec in scored_recs]
dist = Counter(f"{a:.3f}" for a in agreements)
stdev = statistics.pstdev(agreements)
print("agreement distribution:", dict(sorted(dist.items(), reverse=True)))
print(f"mean {statistics.mean(agreements):.3f} | pstdev {stdev:.3f}")
conf_wrong = [rec for rec in scored_recs if rec["agreement"] >= 6 / 7 - 1e-9 and not rec["correct"]]
low_wrong = [rec for rec in scored_recs if rec["agreement"] < 6 / 7 - 1e-9 and not rec["correct"]]
NO_VARIANCE = stdev < 0.05
if NO_VARIANCE:
    print("\nPLAIN STATEMENT: agreement is ~constant across this distribution - the")
    print("signal has NO VARIANCE here and therefore cannot discriminate correctness.")
print(f"\nconfidently-wrong (agreement >= 6/7 AND modal wrong): {len(conf_wrong)}")
for rec in conf_wrong:
    print(f"  {rec['task_id']:34} agreement {rec['agreement']:.3f}  modal {rec['modal']}  truth {rec['ground_truth']}")
if low_wrong:
    print(f"low-agreement wrong: {[rec['task_id'] for rec in low_wrong]}")

# --- minimum-N curve ----------------------------------------------------------------
print("\n" + "=" * 78)
print("PART 5 - MINIMUM-N CURVE (first 3 / first 5 / all valid runs)")
print("=" * 78)
flips = []
for rec in scored_recs:
    verdicts = {}
    for n in (3, 5, 7):
        sub = rec["valid_answers"][:n]
        if not sub:
            continue
        m, mc = Counter(sub).most_common(1)[0]
        verdicts[n] = (m, mc / len(sub), m == rec["ground_truth"])
    if len({v[2] for v in verdicts.values()}) > 1:
        flips.append((rec["task_id"], verdicts))
print(f"tasks whose correct/incorrect verdict differs at lower N: {len(flips)}")
for tid, v in flips:
    print(f"  {tid}: N3={v[3]}  N5={v[5]}  N7={v[7]}")
if not flips:
    print("  (none - every task's verdict is already settled at N=3)")

# --- mechanical branch determination ------------------------------------------------
mean_c = statistics.mean([r["agreement"] for r in scored_recs if r["correct"]] or [0])
wrong = [r for r in scored_recs if not r["correct"]]
mean_w = statistics.mean([r["agreement"] for r in wrong] or [0])
if NO_VARIANCE:
    branch, reason = "RED", (f"agreement is ~constant (pstdev {stdev:.3f}) - no variance to discriminate with; "
                             f"{len(conf_wrong)} task(s) are confidently wrong at >=6/7 agreement")
elif conf_wrong and (mean_c - mean_w) <= 0.10:
    branch, reason = "RED", (f"wrong answers do NOT sit at lower agreement (mean correct {mean_c:.3f} vs "
                             f"mean wrong {mean_w:.3f}); {len(conf_wrong)} confidently-wrong task(s)")
else:
    branch, reason = "GREEN", (f"agreement varies (pstdev {stdev:.3f}) and wrong answers sit at lower agreement "
                               f"(mean correct {mean_c:.3f} vs mean wrong {mean_w:.3f})")
print("\n" + "=" * 78)
print(f"MECHANICAL BRANCH: {branch} - {reason}")
print("=" * 78)

# --- ANALYSIS.md ---------------------------------------------------------------------
md = []
md.append("# Confidence experiment — analysis (results_real.json)\n")
md.append(f"Capture: 31 tasks x {N} runs, model `{rows[0]['model']}`. Analysis is API-free; "
          "results_real.json stays gitignored. Read this against the gate language in "
          "[`MANIFEST_HEADER.md`](MANIFEST_HEADER.md).\n")
md.append("## Routing re-extraction (fix-forward)\n")
md.append("The verbatim raw responses settle the failure mode: it is **token-budget truncation, not "
          "extraction tolerance**. On the routing tasks the model ignored the one-word instruction, "
          "opened with analysis prose, and was cut off by `MAX_TOKENS = 64` before ever stating a "
          "value — those runs genuinely contain no enum value, so they drop from the agreement "
          "denominator rather than being guessed. One further run (gap_route_02 run 1) was a transient "
          "API 529 Overloaded error, captured by the harness's fail-soft error handling and likewise "
          "dropped. **Limitations for any future capture:** (a) one-word-answer prompts need a larger "
          "token budget or stricter format forcing for tasks that invite reasoning; (b) tolerant "
          "extraction (normalization + labeled-phrase detection) belongs in the harness. The proven "
          "harness was not edited; this is fixed forward here.\n")
for tid in ROUTING_IDS:
    rec = next(x for x in records if x["task_id"] == tid)
    md.append(f"- `{tid}`: recovered {rec['n_valid']}/7 runs -> {rec['valid_answers']}"
              + (f" — {rec['flag']}" if rec["flag"] else ""))
if unscoreable:
    md.append(f"\n**Unscoreable ({len(unscoreable)}):** "
              + ", ".join(f"`{u['task_id']}`" for u in unscoreable)
              + " — zero valid runs; excluded from all scoring below "
              f"(scored set = {len(scored_recs)}/31).")
md.append("\n## Per-task table\n")
md.append("| task_id | class | difficulty | source | n_valid | modal | agreement | truth | correct | chance floor |")
md.append("|---|---|---|---|---|---|---|---|---|---|")
for rec in records:
    agree_s = f"{rec['agreement']:.3f}" if rec["scored"] else "-"
    ok_s = ("Y" if rec["correct"] else "N") if rec["scored"] else "-"
    md.append(f"| {rec['task_id']} | {rec['task_class']} | {rec['difficulty']} | {rec['source']} "
              f"| {rec['n_valid']} | {rec['modal']} | {agree_s} | {rec['ground_truth']} "
              f"| {ok_s} | {rec['chance_floor']:.3f} |")
md.append("\nChance floor = exact E[modal count]/N for uniform answers at N=7 "
          "(k=2: 0.651, k=3: 0.527, k=5: 0.423, k=9: 0.345). Agreement at or below the floor carries no signal.\n")
md.append("## Accuracy\n")
md.append(f"Overall: **{c}/{t} ({c/t:.1%})**\n")
for key in ("task_class", "difficulty", "source", "framing"):
    parts = " · ".join(f"{g} {cc}/{tt}" for g, (cc, tt) in summaries[key].items())
    md.append(f"- by {key}: {parts}")
md.append("\n## Variance\n")
md.append(f"Agreement distribution: {dict(sorted(dist.items(), reverse=True))} — mean "
          f"{statistics.mean(agreements):.3f}, pstdev {stdev:.3f}.\n")
if NO_VARIANCE:
    md.append("**The signal has no variance on this distribution and therefore cannot discriminate "
              "correctness here.**\n")
md.append(f"Confidently-wrong list (agreement >= 6/7, modal wrong) — the decisive evidence ({len(conf_wrong)}):\n")
for rec in conf_wrong:
    md.append(f"- `{rec['task_id']}` — agreement {rec['agreement']:.3f}, modal `{rec['modal']}`, "
              f"truth `{rec['ground_truth']}` ({rec['difficulty']}, {rec['framing']})")
if low_wrong:
    md.append(f"\nLow-agreement wrong: {', '.join('`'+rec['task_id']+'`' for rec in low_wrong)}")
md.append("\n## Minimum-N\n")
if flips:
    for tid, v in flips:
        md.append(f"- `{tid}` flips: N3 {v[3]} / N5 {v[5]} / N7 {v[7]}")
else:
    md.append("No task's correct/incorrect verdict differs at N=3 or N=5 vs N=7 — the verdicts are "
              "settled by the third run everywhere.")
md.append("\n## Plots\n")
md.append("![all tasks](scatter_agreement_all.png)\n")
md.append("![gap pool — the verdict plot](scatter_agreement_gap.png)\n")
md.append("## Verdict (against the pre-committed gate)\n")
md.append(f"> {json.loads((HERE / 'real_manifest.json').read_text(encoding='utf-8'))['_meta']['gate_language']}\n")
md.append(f"**Branch supported by the data: {branch}.** {reason.capitalize()}.\n")
(HERE / "ANALYSIS.md").write_text("\n".join(md) + "\n", encoding="utf-8")
print("\nANALYSIS.md written.")
