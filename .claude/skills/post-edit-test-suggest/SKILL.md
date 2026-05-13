---
name: post-edit-test-suggest
description: After editing source files that have an associated test command, surface the test command as a next step. Keeps "what should I run?" present in the manager's view without requiring a post-edit hook.
---

# post-edit-test-suggest

A behavioral skill. After Edit or Write on a watched source path, the manager states the test command and offers to run it.

## Trigger

A successful Edit or Write on any file matching the watched list (below).

## Rule

After the edit, the manager's next message includes:

> **Next:** run `{{TEST_COMMAND}}` to verify.

If the manager has permission to run the command (e.g. it's in the permission allowlist), it may run the command directly. Otherwise it offers and waits for the user. Do not skip the suggestion just because the edit "looks small" — small edits are exactly when broken tests slip through.

`{{TEST_COMMAND}}` is project-specific. `project-tuner-helper` fills this at install time. Common values:

- JS/TS: `npm test` or `npm run test:unit`
- Python: `pytest` or `python -m unittest`
- Go: `go test ./...`
- Rust: `cargo test`

## Files watched

Baseline (every project inherits these):

- Any file under `src/` (source code).
- Any file under `lib/` (library code).
- Any file matching `*.ts`, `*.tsx`, `*.js`, `*.jsx`, `*.py`, `*.go`, `*.rs`, `*.rb` outside of `test/` or `tests/` (those have their own tests-changed path).

<!-- Project-specific watched paths: project-tuner-helper extends below -->

## Notes

Behavioral, not mechanical. A PostToolUse hook would be the mechanical equivalent — and is documented as fragile in `hooks/README.md` because user-level settings can shadow project-level PostToolUse blocks. The skill is the robust path.
