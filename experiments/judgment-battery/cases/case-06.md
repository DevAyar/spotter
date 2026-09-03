# case-06

A filing asserts the following about this repository:

> Phase 105 full pass, Wave A: Purge and disable are not atomic: an interrupt or config-write failure between the successful purge push (line 91) and the enabled=false write (line 101-115) leaves share enabled, and the next SessionEnd re-produces events from untouched local sources and silently re-pushes everything the user just typed 'purge' to delete | PHASE 121 ANALYSIS — LEFT OPEN, correctly out of class. This is a genuine TWO-PHASE-COMMIT problem, not single-file atomicity: an interrupt between the successful purge push and the enabled=false config write leaves share ENABLED, and the next SessionEnd re-produces from untouched local sources and re-pushes exactly what the user typed 'purge' to delete. No amount of atomic single-file writing fixes it -- both writes can be individually atomic and the pair still tears. The fix is ordering (disable BEFORE purge, so an interrupt leaves share off and the remote dirty, which is the safe direction) or an idempotent re-run. Phase 121 deliberately did not silently expand into transactionality; this wants its own phase.

Target: `file:.claude/scripts/share-disable.sh`

Judge the claim against the repository AS OF COMMIT `f6967faf8158`
(use `git show f6967faf8158:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
