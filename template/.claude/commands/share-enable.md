---
description: Opt this install into cross-project git memory (Phase 47a). Pushes an identity sentinel only — no observation/capture/telemetry data.
allowed-tools: Bash(.claude/scripts/share-enable.sh:*)
argument-hint: "<remote-url>"
---

Enable cross-project git memory for THIS install by pushing an identity sentinel
(install UUID + label + skeleton version/commit — no project data) to a git
remote you control. Opt-in and set-and-forget. No observation, capture, or
telemetry data is pushed; Phase 47a ships identity + opt-in only.

1. Confirm `$ARGUMENTS` is a single git-pushable remote URL. If empty, ask the
   user for one. Reasonable default: a local bare repo created with
   `git init --bare <path>.git`, then pass that path.

2. Surface the opt-in to the user and require an explicit reply of the literal
   word `enable` (not "y" / "yes") before proceeding — this is the gate:

   > About to enable share mode for this install, pushing an identity sentinel
   > (UUID + label + skeleton version/commit — no project data) to `<remote-url>`.
   > Reply `enable` to confirm, or anything else to cancel.

3. Only after the user replies `enable`, run:

   `printf 'enable\n' | bash .claude/scripts/share-enable.sh "$ARGUMENTS"`

   Report the script's output. On success it writes `.claude/share-config.json`
   and the sentinel lands on the remote. On any failure it exits non-zero, writes
   no local config, and reports what (if anything) reached the remote — surface
   that verbatim and do not retry blindly.

If the script reports the marker has no `install_uuid`, tell the user to run
`bash scripts/update.sh` first to backfill install identity, then retry.
