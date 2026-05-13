---
description: Run the mechanical commit wrapper. Emits a five-section verbatim report.
allowed-tools: Bash(.claude/scripts/commit.sh:*)
argument-hint: "<commit message>"
---

Run `bash .claude/scripts/commit.sh "$ARGUMENTS"` and report the five-section output verbatim. Do not paraphrase, summarize, or reformat.

If the script errors with a path-shape rejection (exit code 2), the message likely contains a slash or a file extension — ask the user for a rephrased message.

If the commit step fails (non-zero exit on the `git commit` line itself), do not retry blindly. Surface the error and ask the user how to proceed (resolve hook failure, re-stage, etc.).
