# case-02

A filing asserts the following about this repository:

> [BLOCKER-for-strangers] Phase 105 full pass, Wave A: cleanup_backups/rollback expand empty arrays unguarded; fatal under set -u on bash < 4.4 (macOS 3.2, the script's stated target)

Target: `file:scripts/update.sh`

Judge the claim against the repository AS OF COMMIT `f6967faf8158`
(use `git show f6967faf8158:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
