# Judgment battery — can a cheaper model hold the judgment lane?

Dogfood maintainer tooling (never ships in `template/`). Phase 135.

The Phase 134 lane clause says judgment lanes inherit the session model
"until someone measures otherwise." This directory is the measuring stick:
17 findings from this repository's own adversarial-verification history —
10 that were confirmed real and fixed, 7 that were refuted on the record —
each with its settled verdict and the commit to judge against. The cases
were chosen so the question is crisply decidable: refuted picks are claims
whose factual assertion was wrong, never true-but-tolerable behavior calls
(those would punish a correct refuter for saying "true").

## Files

- `cases/case-NN.md` — the finding as a refuter receives it: the claim, the
  target, the commit to judge at. **No verdict appears in a case file.**
- `verdict-key.json` — the settled verdicts, the adjudication summary, and
  the source observation id. Kept separate so a dispatched refuter can be
  run blind; the case files say not to read it.
- `score.py` — scores a collected verdict set: confusion matrix, agreement
  rate, and the misses by name.

## Run protocol

1. Dispatch one refuter agent per case on the candidate model, naming the
   model per the manager's per-dispatch lane clause. The prompt is the case
   file's own text; the agent reads the repo at the stated commit
   (`git show <commit>:<path>`).
2. Collect each verdict (`real` / `refuted`) into `verdicts-<model>.json`
   (a flat `{"case-01": "real", ...}` map). Keep the agents' evidence
   paragraphs beside it for the adjudication record.
3. `python score.py verdicts-<model>.json`.

## The bar

A model that misses known-real findings does not enter the judgment lane —
in live work a missed real finding is invisible (the refuter says "fine"
and you believe it). A clean pass licenses a **shadow trial**, not a
demotion: see the manager's shadow-trial clause. Demotion happens only
through the retier draft → owner approval path, argued from the shadow
log's agreement record.

CI validates this directory's integrity (every case has a key entry, no
case leaks its verdict, the scorer works — `judgment-battery-integrity`);
the battery run itself needs an LLM and stays a maintainer action.
