# confidence experiment — replay harness

Throwaway research code (not a skeleton feature; ships nothing, propagates nowhere). `harness.py` reads a task manifest (`real_manifest.json` by default; `--manifest` overrides the path, `--model` overrides the model and suffixes the output name) and, for each task, calls the Anthropic API `N=7` times against **identical frozen input** with no state carried between runs, writing the extracted structured answers, the full raw responses, and the manifest's metadata + ground truth to `results_<name>.json` (gitignored). Capture only — analysis lives in `analysis.py`, and the experiment's result record is [`ANALYSIS.md`](ANALYSIS.md): the resampling-agreement leg resolved **RED** on structured tasks (zero agreement variance; resampling drops per the pre-committed gate).

## Run

Requires `ANTHROPIC_API_KEY` in the environment and the `anthropic` package (`python -m pip install anthropic`). The key is read from the environment only — never written to a file or passed as an argument.

```
python harness.py
```

See [`MANIFEST_HEADER.md`](MANIFEST_HEADER.md) for the gate language that governs how results may — and may not — be read.
