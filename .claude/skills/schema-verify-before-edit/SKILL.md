---
name: schema-verify-before-edit
description: Before editing a structured config file (settings.json, package.json, tsconfig.json, GitHub workflow YAML), read the file's current shape and the schema/spec it conforms to. Prevents accidental breakage from "fix-by-feel" edits to load-bearing config.
---

# schema-verify-before-edit

A behavioral skill. The manager and helpers honor it whenever an Edit or Write would land on a watched file.

## Trigger

About to Edit or Write a file matching the watched list.

## Rule

**Do not edit the file until you have:**

1. Read the file in full (or the relevant section if the file is large).
2. Either read the schema/spec the file conforms to (e.g. JSON Schema, the tool's docs), OR — if no schema is available — verified that the change matches the existing structure by example.
3. If the file is JSON or YAML, mentally parse the change to confirm it doesn't break the parse.

A small wrong edit to settings.json or package.json can silently break every future session or build. The cost of reading first is seconds; the cost of repairing a broken config is minutes-to-hours.

## Files watched

Baseline (every project inherits these):

- `.claude/settings.json` — Claude Code config. Hook registrations, permissions, statusLine.
- `package.json` — Node project manifest. Scripts, dependencies, engines.
- `tsconfig.json` — TypeScript compiler config.
- `.github/workflows/*.yml` — GitHub Actions workflow definitions.

<!-- Project-specific watched files: project-tuner-helper extends below -->

## Notes

This skill is intentionally **behavioral, not mechanical** — there is no pre-Edit hook that blocks the write. The rule lives in the manager's discipline. If a project wants a mechanical gate, add a PreToolUse hook that runs a schema-check script before Edit/Write fires on a watched path.
