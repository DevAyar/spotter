# case-07

A filing asserts the following about this repository:

> monitoring-helper reads the WRONG END of the session log. The doc calls it the 'forward-chronological tail' and prescribes offset = total - N, but docs/SESSION_LOG.md's own header says 'Reverse-chronological - newest at top' - so the agent as documented grades the OLDEST sessions. Found during Phase 114 and deliberately NOT fixed: an agent .md is the executable prompt, so correcting the read direction changes runtime behavior, and Phase 114 was scoped docs-only. Frontmatter line 3 ('the recent tail') carries the same error. Needs its own small behavioral phase.

Target: `file:.claude/agents/03_monitoring/monitoring-helper.md`

Judge the claim against the repository AS OF COMMIT `b7744711c43c`
(use `git show b7744711c43c:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
