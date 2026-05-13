---
name: token-efficiency-monitor
description: After a dispatched subtask completes, if its token cost exceeded 1.5× the expected envelope for its task type, surface a one-line observation with a likely cause hypothesis. Observational, not enforcing — does not block, retry, or modify.
---

# token-efficiency-monitor

A behavioral skill. The manager honors it after each dispatched subtask
completes. The aim is early visibility into runaway costs so the manager
can adjust dispatch style before the pattern compounds across a session.

## Trigger

A dispatched subtask completes, and its measured token cost exceeds
**1.5× the expected envelope** for its task type.

## Expected envelopes

Starting heuristic — tune per project after watching real usage:

- **Single-file read + edit**: < 10k tokens.
- **Multi-file search / Grep sweep**: < 30k tokens.
- **Plan + design pass** (Plan agent, Plan-mode workflow): < 50k
  tokens.
- **Multi-file refactor** (3+ files modified): < 80k tokens.

If a task doesn't fit any of these envelopes cleanly, the manager picks
the nearest match and adjusts.

## Rule

When the threshold is crossed, surface a **one-line observation** to
the user (not a block, not a retry). Format:

```
[token-efficiency] <task type> used <actual>k vs ~<expected>k. Likely cause: <hypothesis>.
```

Likely-cause hypotheses to consider:

- Duplicate surveys — multiple agents reading the same files.
- Runaway reads — read whole god-files instead of section-routing.
- Unnecessary parallel dispatch — agents that didn't need to run.
- Over-broad Grep / Glob — too many files matched and read.
- Re-reading after every edit — efficiency rule violation.

## Notes

- **Observational, not enforcing.** Alerts feed the manager's
  judgment; they do not block work. If the cost was justified, ignore
  the alert.
- **Threshold is a heuristic.** 1.5× is a starting point. Adjust per
  project after watching the false-positive rate.
- **Envelopes are tunable.** A project that legitimately needs deep
  multi-file analysis can raise the relevant envelope.
- **Does not capture context-window cost.** Skill scope is per-task
  cost, not session-level cost. Long sessions are a separate concern.
