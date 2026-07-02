#!/usr/bin/env python3
"""Confidence experiment - step 1: replay-mechanism harness skeleton.

THROWAWAY RESEARCH CODE. Not a skeleton feature; ships nothing, propagates
nowhere. See MANIFEST_HEADER.md for the gate language that governs how these
results may be read.

What this proves (and ONLY this): N identical replays of a frozen task against
a frozen input, with zero state carry-over between runs. No agreement scoring,
no analysis, no ground-truth logic - capture only. Analysis is a separate later
script that operates on the saved results.json.

The Anthropic API key is read from the ANTHROPIC_API_KEY environment variable
only. It is never written to a file, hardcoded, or passed as an argument.
"""

import argparse
import json
import os
import sys
from pathlib import Path

import anthropic

# --- config -----------------------------------------------------------------
N_RUNS = 7
MODEL = "claude-sonnet-4-6"      # cheap enough for high-N research; the question
                                 # is the agreement signal, not frontier quality.
MAX_TOKENS = 64                  # dummy tasks emit one-word structured answers.

HERE = Path(__file__).resolve().parent
DEFAULT_MANIFEST = HERE / "real_manifest.json"


# --- manifest / output wiring -------------------------------------------------
def load_tasks(manifest_path):
    """Accept both manifest shapes: the {_meta, tasks} object (real_manifest.json)
    or a bare task list."""
    data = json.loads(manifest_path.read_text(encoding="utf-8"))
    return data["tasks"] if isinstance(data, dict) else data


def results_path_for(manifest_path, model=None):
    """Derive the output file from the manifest name: real_manifest.json ->
    results_real.json. An explicit --model adds a suffix
    (results_real_sonnet-4-6.json) so per-model runs never clobber each other."""
    name = manifest_path.name
    stem = name[:-len("_manifest.json")] if name.endswith("_manifest.json") else manifest_path.stem
    if model:
        tag = model[len("claude-"):] if model.startswith("claude-") else model
        return manifest_path.parent / f"results_{stem}_{tag}.json"
    return manifest_path.parent / f"results_{stem}.json"


# --- answer extractors ------------------------------------------------------
def extract_answer(rule, text):
    """Pull the STRUCTURED answer from a raw response per the manifest rule.

    kinds:
      exact  -> the trimmed response verbatim (e.g. "GREEN")
      yes_no -> "yes" / "no" if present, else "<unparsed>"
      choice -> the first rule["options"] value that appears, else "<unparsed>"
    """
    kind = rule.get("kind")
    stripped = text.strip()
    if kind == "exact":
        return stripped
    if kind == "yes_no":
        low = stripped.lower()
        for token in ("yes", "no"):
            if token in low:
                return token
        return "<unparsed>"
    if kind == "choice":
        up = stripped.upper()
        for option in rule.get("options", []):
            if option.upper() in up:
                return option
        return "<unparsed>"
    return "<unknown-extractor>"


# --- one task: N frozen, independent replays --------------------------------
def run_task(client, task):
    """Call the API N_RUNS times against IDENTICAL input.

    The request is built ONCE and reused read-only across every run. Nothing
    from run k carries into run k+1 - no conversation accumulation, no shared
    mutable state. This frozen-input-identical-replay is the entire point of
    step 1.
    """
    frozen_request = {
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "system": task["context"],                                   # frozen input context
        "messages": [{"role": "user", "content": task["prompt"]}],   # frozen task prompt
    }

    raw_answers = []
    raw_responses = []
    for _ in range(N_RUNS):
        try:
            resp = client.messages.create(**frozen_request)
            text = "".join(b.text for b in resp.content if b.type == "text")
        except Exception as exc:                 # capture, don't abort the run
            text = f"<ERROR: {type(exc).__name__}: {exc}>"
        raw_responses.append(text)
        raw_answers.append(extract_answer(task["extractor"], text))

    return {
        "task_id": task["task_id"],
        "task_type": task["task_type"],
        "task_class": task.get("task_class"),
        "source": task.get("source"),
        "framing": task.get("framing"),
        "difficulty": task.get("difficulty"),
        "cheap_check_settles": task["cheap_check_settles"],
        "cheap_check_result": task.get("cheap_check_result"),
        "canonical_answers": task.get("canonical_answers"),
        "ground_truth": task.get("ground_truth"),   # manifest value; null where absent
        "notes": task.get("notes"),
        "model": MODEL,                             # the model actually used this run
        "n_runs": N_RUNS,
        "raw_answers": raw_answers,
        "raw_responses": raw_responses,
    }


# --- main -------------------------------------------------------------------
def main():
    global MODEL

    parser = argparse.ArgumentParser(
        description="Confidence-experiment replay harness (capture only)."
    )
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST),
                        help="Task manifest path ({_meta, tasks} object or bare list).")
    parser.add_argument("--model", default=None,
                        help=f"Model override (default: {MODEL}). When passed "
                             "explicitly, the output filename gains a model suffix.")
    args = parser.parse_args()
    if args.model:
        MODEL = args.model                       # run_task reads the module global
    manifest_path = Path(args.manifest)
    results_path = results_path_for(manifest_path, args.model)

    if not os.environ.get("ANTHROPIC_API_KEY"):
        sys.exit(
            "ANTHROPIC_API_KEY is not set in the environment. Set it and re-run; "
            "this harness reads the key from the environment only."
        )

    tasks = load_tasks(manifest_path)
    client = anthropic.Anthropic()               # reads ANTHROPIC_API_KEY from env

    results = [run_task(client, task) for task in tasks]
    results_path.write_text(json.dumps(results, indent=2), encoding="utf-8")

    print(f"Wrote {len(results)} task object(s) to {results_path}")
    for r in results:
        distinct = sorted(set(r["raw_answers"]))
        verdict = "IDENTICAL" if len(distinct) == 1 else f"{len(distinct)} distinct"
        print(f"  {r['task_id']}: {r['raw_answers']}  [{verdict}]")


if __name__ == "__main__":
    main()
