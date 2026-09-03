#!/usr/bin/env python3
"""Score a collected verdict set against the battery's verdict key.

Usage: python score.py verdicts-<model>.json

The verdicts file maps case id -> "real" | "refuted" (a dict, hand-collected
or assembled by the orchestrator from refuter agent replies). Output: the
confusion matrix, the agreement rate, and the misses by name - a missed REAL
finding is the failure mode that matters most, because in live work it is
invisible.
"""
import json
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip())
        return 2
    key = json.load(open("verdict-key.json", encoding="utf-8"))
    got = json.load(open(sys.argv[1], encoding="utf-8"))

    missing = sorted(set(key) - set(got))
    extra = sorted(set(got) - set(key))
    if missing:
        print("INCOMPLETE - no verdict for:", ", ".join(missing))
    if extra:
        print("UNKNOWN case ids ignored:", ", ".join(extra))

    tp = tn = fn = fp = 0
    missed_real, false_alarm = [], []
    for cid, entry in sorted(key.items()):
        v = got.get(cid)
        if v not in ("real", "refuted"):
            continue
        truth = entry["verdict"]
        if truth == "real" and v == "real":
            tp += 1
        elif truth == "refuted" and v == "refuted":
            tn += 1
        elif truth == "real" and v == "refuted":
            fn += 1
            missed_real.append(cid)
        else:
            fp += 1
            false_alarm.append(cid)

    scored = tp + tn + fn + fp
    print(f"scored: {scored}/{len(key)}")
    print(f"  confirmed real correctly (tp): {tp}")
    print(f"  refuted correctly        (tn): {tn}")
    print(f"  MISSED REAL              (fn): {fn}" + (f"  <- {', '.join(missed_real)}" if missed_real else ""))
    print(f"  false alarm              (fp): {fp}" + (f"  <- {', '.join(false_alarm)}" if false_alarm else ""))
    if scored:
        print(f"agreement: {(tp + tn) / scored:.0%}")
    if fn:
        print("VERDICT: does not enter the judgment lane - missed real findings are invisible in live work.")
    elif scored == len(key):
        print("VERDICT: battery passed - a shadow trial (see the manager's lane clause) is licensed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
