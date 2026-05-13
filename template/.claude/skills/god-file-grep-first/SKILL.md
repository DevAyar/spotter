---
name: god-file-grep-first
description: Before Reading a file larger than the threshold (default 1000 lines), Grep for the exact target first, then Read with offset and limit. Prevents wasting context on full reads of long files when you only need a small section.
---

# god-file-grep-first

A behavioral skill. The manager and helpers honor it whenever a Read would land on a large file.

## Trigger

About to call Read on a file that is either:

- Larger than the threshold (default **1000 lines**), OR
- On the explicit god-file list below.

## Rule

**Do not Read the file end-to-end.** Instead:

1. **Grep first.** Search for the specific symbol, section header, or string you need. Use `output_mode: content` with `-n` to get line numbers.
2. **Read narrowly.** Call Read with `offset` and `limit` set to the surrounding window (e.g. `offset = match_line - 5, limit = 30`).
3. **Iterate if needed.** If the first slice doesn't have the full answer, expand the window or Grep for a related symbol.

This is the core context-discipline rule. A 5000-line file Read end-to-end burns tokens that could have fueled three useful operations.

## Threshold

Default: **1000 lines**.

To adjust per-project, set in your CLAUDE_MANAGER.md or as a comment in this file:

> Threshold override: <N> lines for this project.

## God-file list

Explicit god-files (always Grep-first regardless of size):

<!-- Project-specific god-files: project-tuner-helper extends below -->

(Empty by default. `project-tuner-helper` populates this at install time based on the project's actual large files — common candidates: long migrations, generated schemas, large fixture JSON, multi-thousand-line legacy modules.)

## Notes

Behavioral, not mechanical. There is no hook that blocks a full Read — the rule lives in the manager's discipline. If a manager violates this skill 2+ times in a row, that's a flag for the next monitoring-helper session to surface.
