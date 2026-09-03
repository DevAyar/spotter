# case-12

A filing asserts the following about this repository:

> gate-integrity: README.md:36,ROADMAP.md:13,260 attribute a cooldown to drift-check; it fires every session with no cooldown (silent-on-no-drift only)

Target: `file:README.md`

Judge the claim against the repository AS OF COMMIT `bb245f873e97`
(use `git show bb245f873e97:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
