---
description: Run a post-deploy smoke test. Placeholder — real implementation lives in the browser-tester plugin (Tier 3, opt-in).
---

This is a **routing marker**, not a runnable command on its own.

A real smoke-test implementation belongs in the `browser-tester` plugin (Tier 3, opt-in). To install it for this project, see the plugin docs.

If `browser-tester` is not installed:

1. State that the smoke test is manual for now.
2. Recommend the minimum manual check based on what was deployed (one critical-path interaction, the most-trafficked page, etc.).
3. Do **not** skip the smoke test silently. The `deploy.sh` script emits a POST-DEPLOY SMOKE TEST REQUIRED banner for a reason — surface it.
