# confidence experiment — replay harness (step 1)

Throwaway research code (not a skeleton feature; ships nothing, propagates nowhere). `harness.py` reads a tiny task manifest (`dummy_manifest.json`) and, for each task, calls the Anthropic API `N=7` times against **identical frozen input** with no state carried between runs, then writes the extracted structured answer plus the full raw response for every run to `results.json`. Step 1 proves only that the frozen-input identical-replay mechanism works — there is no agreement scoring or analysis here (that is a later script operating over the saved JSON).

## Run

Requires `ANTHROPIC_API_KEY` in the environment and the `anthropic` package (`python -m pip install anthropic`). The key is read from the environment only — never written to a file or passed as an argument.

```
python harness.py
```

Expect 3 task objects in `results.json`, each with 7 `raw_answers` and 7 `raw_responses`; the `dummy_green_deterministic` task should be 7/7 identical (stable replay — the core thing step 1 proves).

See [`MANIFEST_HEADER.md`](MANIFEST_HEADER.md) for the gate language that governs how a clean result may — and may not — be read.
