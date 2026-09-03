# case-09

A filing asserts the following about this repository:

> smg_push set the neutral share commit identity only when `git config user.email` resolved nothing — but that resolves the user's GLOBAL config, so on any normally configured machine the fallback never fired and EVERY commit pushed to the share remote carried the user's real name and personal email in its metadata. Invisible to any content grep of the exported event files: the leak rode in commit authorship, not file contents. The audit never named it; found by the Phase 119 census.

Target: `file:.claude/lib/shared-memory-git.sh`

Judge the claim against the repository AS OF COMMIT `c32c0ee6e446`
(use `git show c32c0ee6e446:<path>` to read files at that state; the working
tree may have changed since). Your verdict is one word — `real` when
the factual assertion holds at that commit, `refuted` when it does
not — followed by your evidence: the file and line(s) that decide it,
and the mechanism in two or three sentences. Do not consult
`.claude/observations/` or `experiments/judgment-battery/verdict-key.json`;
the case is only fair blind.
