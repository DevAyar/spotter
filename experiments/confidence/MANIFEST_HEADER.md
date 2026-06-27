# Confidence experiment — manifest header (gate language)

**Write/read this FIRST.** It governs how the results of this experiment may — and may not — be used. Throwaway research code; not a skeleton feature.

## The question

Does **resampling-agreement** — running the same task N times against identical frozen input and measuring how much the structured answers converge — correlate with **correctness** on structured-answer tasks?

That is the only thing under test. This is a research bet that may not pan out (see `docs/ROADMAP.md` § Gated on telemetry maturity → the confidence-and-fidelity engine). The point of the experiment is to find out, not to assume.

## Pre-commit gate (verbatim, load-bearing)

> A clean structured result means: the signal CAN exist — proceed to a prose stress-test. It does NOT mean: build the engine. The prose stress-test is the next gate, not an optional follow-up.

## API-direct caveat (verbatim, load-bearing)

> This experiment is API-direct (raw model + constitution context, no Claude Code orchestration). A green result means the signal is real IN PRINCIPLE — not that it is real inside CC specifically. That jump is untested here; do not over-generalize a green result to CC-in-the-loop behavior.

## Scope boundaries

This experiment covers **confidence (resampling-agreement) only**. Explicitly out of scope:

- **NO fidelity** — no faithful-to-source / nuance-flattening measurement.
- **NO gate integration** — nothing here routes or influences any approval gate.
- **NO calibration** — no mapping from agreement to a calibrated probability.
- **NO prose scoring** — structured-answer tasks only; prose is a later, separate gate.

Step 1 (this commit) is narrower still: it builds the harness skeleton and proves one thing — **N identical replays against frozen input with zero state carry-over between runs**. No agreement scoring, no analysis, no ground-truth logic. Capture only.
