# Claude Code hook schema reference

Canonical source: <https://docs.claude.com/en/docs/claude-code/hooks>

This doc summarizes the structure `cruft-check.sh` heuristic viii validates. It does not reinvent or rephrase the canonical spec; consult the Anthropic docs for any authoritative behavior question. The intent here is a quick local reference for the fields heuristic viii enforces.

## Structure

`settings.json` (or `settings.json.template`) carries a top-level `hooks` object:

```
hooks: {
  <EventName>: [
    {
      matcher?: string,
      hooks: [
        { type: "command", command: string, timeout?: number }
      ]
    }
  ]
}
```

EventName values include `PreCompact`, `SessionStart`, `SessionEnd`, `PreToolUse`, `PostToolUse`, `Notification`, `Stop`, `SubagentStop`, `UserPromptSubmit`. See the canonical docs for the complete current list.

## Required fields on each inner hook object

- `type` — must be the literal string `"command"`. v1.0 → Phase 14c-diag silently dropped hook entries missing this field (CC's schema validator rejected the entry but accepted the surrounding permissions block).
- `command` — non-empty string. The shell invocation to run. By convention in claude-skeleton: `bash "$CLAUDE_PROJECT_DIR/.claude/hooks/<name>.sh"`.

## Optional fields

- `matcher` — string pattern applied to event payload (e.g. tool name for `PreToolUse`, `"auto"` for `PreCompact`). Required for some events, optional for others — see canonical docs.
- `timeout` — number of seconds before the hook is killed. Default per CC.

## What heuristic viii validates

For each `hooks.<EventName>[entry].hooks[idx]` inner object:

1. `type` field equals `"command"`.
2. `command` field is present and non-empty.

That's the entire validation surface. Output-schema concerns (the `hookSpecificOutput` wrapper Phase 14e fixed in `sessionstart-rules.sh`) are runtime-stdout-shape questions, not static config-schema questions — out of scope for this heuristic.

## Files validated

- `.claude/settings.json` (dogfood)
- `template/.claude/settings.json.template` (ships to target projects)

Both honor the same schema; both get validated on every cruft-check pass.
