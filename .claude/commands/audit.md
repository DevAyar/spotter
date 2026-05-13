---
description: Dispatch audit-helper to check drift between a doc section and current code reality. Appends the report to docs/SESSION_LOG.md.
argument-hint: "<doc>:<section>"
---

Dispatch the `audit-helper` subagent with the user's scope argument (e.g. `STATUS.md:"In progress"` or `ROUTING.md:"Helper roster"`).

After the helper returns:

1. Surface the findings to the user verbatim (severity + suggested fix per row).
2. Append a `### Audit — <scope> — <today's date>` subheader under today's session entry in `docs/SESSION_LOG.md`, with the report body below.
3. If the audit is clean, log a single line: `Audit clean: <scope>, <date>`.

Do **not** edit any doc the helper flagged. Surface findings first; let the user direct any follow-up edits.
