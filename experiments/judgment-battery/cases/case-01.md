# case-01

A filing asserts the following about this repository:

> [BLOCKER-for-strangers] Phase 105 full pass, Wave A: detect_json_tool prefers `python` over `python3` and never verifies the interpreter actually runs or is Python >= 3.7

Target: `file:scripts/update.sh`

Judge the claim against the repository AS OF COMMIT `f6967faf8158`
(use `git show f6967faf8158:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
