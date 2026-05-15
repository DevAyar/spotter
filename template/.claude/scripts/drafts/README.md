# scripts/drafts/

Draft bash scripts written by `script-builder` (v1.1+ Phase 3) from approved captures. Each draft is a starting point the user reviews, optionally edits, then promotes by `mv`-ing into `.claude/scripts/` with a descriptive name.

## What lives here

One bash file per drafted script: `<source_pattern_id>.sh.draft`. The filename matches the `pattern_id` of the observation that triggered the capture chain (so observations, captures, and drafts all share an id — idempotency at every layer is direct).

The directory ships empty and populates post-install when `script-builder` is dispatched against approved captures.

## The `.sh.draft` extension

Intentional. Drafts have a shebang but the `.draft` suffix makes them invisible to tools that filter by `.sh`. **They cannot be accidentally executed.** The user explicitly renames to `.sh` on promote, which is also the point at which `chmod +x` is applied (or the script doesn't run).

If you find a draft you want to run *as a test* without committing to promotion, copy it to a tmpdir and rename there. Don't rename in place unless you're promoting.

## Schema

See [`../../agents/05_meta/script-builder.schema.md`](../../agents/05_meta/script-builder.schema.md) for the full draft-script contract: 5-section discipline (shebang+strict-mode / constants / helpers / main / cleanup), path-shape guard patterns, error handling conventions, `bash-safety` integration rules, and a complete realistic example.

## User-promote workflow

After `script-builder` writes a draft here, the manager surfaces this workflow to the user:

1. **Review** the draft. Read it end-to-end — it's compact (30–80 lines) by design.
2. **Optionally edit** in place. Tweak variable names, adjust defaults, add project-specific validation. The draft is a starting point, not a final artifact.
3. **Promote**:
   ```bash
   mv .claude/scripts/drafts/<source_pattern_id>.sh.draft .claude/scripts/<descriptive-name>.sh
   chmod +x .claude/scripts/<descriptive-name>.sh
   ```
   Pick a kebab-case lowercase name describing what the script does. Examples: `count-files-by-ext.sh`, `validate-routing.sh`, `backup-claude-state.sh`.
4. **Flip the capture lifecycle**. Edit the source capture at `.claude/captures/<source_pattern_id>.md`:
   - Change `status: approved` → `status: shipped`.
   - Add `shipped_to: .claude/scripts/<descriptive-name>.sh` (records where the promoted script lives).

The capture file persists forever as the traceability record. Don't delete it.

## Operator notes

- **Safe to delete drafts you don't want.** Deleting a `.sh.draft` here removes the artifact but leaves the capture intact. The next `script-builder` run will see the capture is still `status: approved` AND the draft is missing, and will draft fresh. To prevent re-drafting, change the capture's `status` to `rejected` (or to anything other than `approved`).
- **Don't hand-edit drafts and then leave them here.** If you edit, promote — drafts aren't a long-term home. Stale edited drafts get clobbered if the user accidentally re-dispatches `script-builder` after deleting the file.
- **Safe to inspect.** Files are plain bash; the schema's path-shape guards and `bash-safety` integration mean no surprises. The draft header comment block names the source capture for traceability.

## Idempotency

`script-builder` skips captures whose `<source_pattern_id>.sh.draft` already exists in this directory. To re-draft a pattern after rejecting the first attempt: delete the file, then re-dispatch.

## Producers

- **`script-builder`** — drafts bash scripts from `.claude/captures/*.md` filtered to `status: approved AND suggested_artifact_type: script`. v1.1+ Phase 3.

## Consumers

The user — by promoting drafts into `.claude/scripts/`. No agent consumes from this directory; this is a human review surface.
