#!/usr/bin/env python3
"""Throwaway diagnostic - does an OMITTED temperature get served as ~0?

Separate from harness.py (its committed logic is untouched; not imported here).
Two conditions, identical model / max_tokens / system / prompt - the ONLY
variable is the temperature handling:

  C1: temperature=1.0 set EXPLICITLY in the request.
  C2: temperature OMITTED - byte-for-byte the shape harness.py sends today.

Read:
  C1 spreads + C2 identical -> B: the omitted default is served as ~0
      (independent calls all collapsing to argmax). Fix = set temperature.
  both spread               -> A: apparatus fine; the integer probe was flawed.
  both identical            -> deeper suppressor; reopen.

resp.id per call separates B from a hidden cache layer:
  7 DISTINCT ids + identical text  -> independent calls hitting argmax (B).
  7 IDENTICAL ids + identical text -> a caching/replay suppressor, not temp.

The API key is read from ANTHROPIC_API_KEY only - never written, hardcoded, or
passed as an argument. Prints to stdout; writes no file.
"""

import os
import sys

import anthropic

N = 7
MODEL = "claude-sonnet-4-6"      # mirrors harness.py (hardcoded, not imported)
MAX_TOKENS = 64                  # mirrors harness.py
SYSTEM = "Output only what is asked, with no extra words or punctuation."
PROMPT = "Output exactly 8 random lowercase letters and nothing else."


def one_call(client, explicit_temperature):
    """Single API call. explicit_temperature=None omits the field entirely."""
    request = {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "system": SYSTEM,
        "messages": [{"role": "user", "content": PROMPT}],
    }
    if explicit_temperature is not None:
        request["temperature"] = explicit_temperature      # C1 only; C2 omits it
    resp = client.messages.create(**request)
    text = "".join(b.text for b in resp.content if b.type == "text")
    return text, resp.id


def run_condition(client, explicit_temperature):
    texts, ids = [], []
    for _ in range(N):
        try:
            text, rid = one_call(client, explicit_temperature)
        except Exception as exc:                 # capture, don't abort the run
            text, rid = f"<ERROR: {type(exc).__name__}: {exc}>", None
        texts.append(text)
        ids.append(rid)
    return texts, ids


def report(label, temp_note, texts, ids):
    print(f"=== {label}  ({temp_note}) ===")
    for i, text in enumerate(texts, 1):
        print(f"  run {i}: {text!r}")
    print(f"  distinct texts: {len(set(texts))}/{N}")
    print(f"  distinct ids:   {len(set(ids))}/{N}")
    print(f"  ids: {ids}")
    print()


def main():
    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit("ANTHROPIC_API_KEY is not set; this diagnostic reads the key from the env only.")

    client = anthropic.Anthropic()              # reads ANTHROPIC_API_KEY from env

    c1_texts, c1_ids = run_condition(client, 1.0)     # explicit temperature=1.0
    c2_texts, c2_ids = run_condition(client, None)    # omitted (current harness behavior)

    print()
    report("CONDITION 1", "temperature=1.0 explicit", c1_texts, c1_ids)
    report("CONDITION 2", "temperature OMITTED (current harness behavior)", c2_texts, c2_ids)

    print("=== read ===")
    print("  C1 spreads + C2 identical -> B: omitted default served as ~0; fix = explicit temperature=1.0")
    print("  both spread               -> A: apparatus fine; integer probe was flawed (adopt this letters probe)")
    print("  both identical            -> deeper suppressor; reopen")
    print("  (per condition: 7 distinct ids confirm independent calls; 7 identical ids would mean caching)")


if __name__ == "__main__":
    main()
