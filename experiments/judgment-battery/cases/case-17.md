# case-17

A filing asserts the following about this repository:

> Phase 105 full pass, Wave A: shared-memory-git.sh is sourced without an existence check; if missing, `smg_ensure_clone` becomes command-not-found (127) and the user sees the misleading 'could not clone remote' die instead of 'library missing'

Target: `file:.claude/scripts/share-disable.sh`

Judge the claim against the repository AS OF COMMIT `f6967faf8158`
(use `git show f6967faf8158:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
