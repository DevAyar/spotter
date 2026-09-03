# case-11

A filing asserts the following about this repository:

> match-rebaseline (Phase 59) is a mechanism that can MANUFACTURE the marker/git divergence state Phase 113 guards: when a user's local edit coincides with the current template, the baseline is advanced to that content, after which the marker believes user content is pristine. Phase 113 added the downstream guard but deliberately did not touch Phase 59 behavior — out of scope for that phase. Worth a dedicated look: should rebaselining refuse when git reports the path dirty?

Target: `file:scripts/update.sh`

Judge the claim against the repository AS OF COMMIT `e72fc478404a`
(use `git show e72fc478404a:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
