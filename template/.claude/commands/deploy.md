---
description: Run the deploy wrapper. Refuses to deploy a dirty tree; emits a POST-DEPLOY SMOKE TEST REQUIRED banner on success.
allowed-tools: Bash(.claude/scripts/deploy.sh:*)
argument-hint: "[deploy-flags...]"
---

Run `bash .claude/scripts/deploy.sh $ARGUMENTS` and report the output.

If the script rejects the call (path-shape guard or uncommitted-changes check), surface the error and ask the user to clean up first.

After a successful deploy:

1. Surface the `POST-DEPLOY SMOKE TEST REQUIRED` banner verbatim — do not summarize it away.
2. Recommend running `/smoke-test` (or its plugin equivalent if `browser-tester` is installed).
3. Do not declare the deploy "done" until a smoke test confirms the live target.
