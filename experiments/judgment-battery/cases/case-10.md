# case-10

A filing asserts the following about this repository:

> Three cooldown/idempotence markers were written with a bare truncating redirect INSIDE scripts the Phase 105 audit had recorded as atomic: task-watchdog.sh, cruft-check.sh and plugin-quality-check.sh. The per-file verdict was right about each script's observation JSON and wrong about its marker. task-watchdog's is the one that bites: a zero-byte .last-watchdog-session means the prior transcript is treated as unseen, re-processed, and its observations RE-EMITTED. The lesson generalises past this phase -- a per-file atomicity verdict is only as good as its coverage of every write site in that file.

Target: `file:.claude/scripts/task-watchdog.sh`

Judge the claim against the repository AS OF COMMIT `11a270977487`
(use `git show 11a270977487:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
