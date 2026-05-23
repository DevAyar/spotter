---
description: Push this install's shared-memory events to the remote now (Phase 47c-1) — the on-demand fallback for the automatic SessionEnd push.
allowed-tools: Bash(.claude/scripts/shared-memory-push.sh:*)
---

Push THIS install's cross-project shared-memory events to the configured remote
right now, instead of waiting for the automatic SessionEnd push. Same on-change
gate, same fail-soft behavior — it only changes WHEN the push runs. Run:

`bash .claude/scripts/shared-memory-push.sh --manual`

Report the output verbatim. It refreshes the local events, then pushes only if
something changed since the last push:

- `Pushed: …` — new events reached the remote.
- `Nothing to push …` — the tree is unchanged since the last push (exit 0).
- `Share mode is not enabled …` — run /share-enable first.
- `Remote unavailable …` / `Push failed …` — the remote was unreachable; the
  next SessionEnd (or another /share-push) retries. It never blocks.

Under the hood it ensures `.claude/shared-memory/` is a working clone of the
remote, pulls --rebase, runs the producer, and pushes. No project data beyond
the redacted shared-memory envelopes is sent.
