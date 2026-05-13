---
name: plugin-roster-search
description: When the manager needs to find a handler for a capability and doesn't already know one from `ROUTING.md`, grep across agent / skill / command descriptions in `.claude/` plus active plugin directories. Returns top 3 candidates ranked by description fit.
---

# plugin-roster-search

A behavioral skill. The manager honors it when looking for a capability
provider that isn't already covered by a `ROUTING.md` row.

## Trigger

The manager needs to find a handler for capability X, and:

- `ROUTING.md` has no matching row.
- The manager doesn't already remember a relevant agent / skill /
  command from session context.

## Rule

Grep across description fields in:

- `.claude/agents/**` — the `description:` frontmatter field.
- `.claude/skills/**` — the `description:` frontmatter field.
- `.claude/commands/**` — top-line heading or description.
- Plugin directories declared in `.claude/settings.json`.

Rank matches by description fit (count of matched terms, weighted
toward whole-phrase matches). Return the top 3 candidates with file
paths and one-line summaries.

## Output format

```
1. agents/02_audit/audit-helper.md — Drift detection between docs and code reality.
2. ...
3. ...
```

If no match scores above a useful floor, return nothing and fall back
to general planning rather than inventing a new helper.

## Notes

- Cheap and fast. Grep over descriptions, not whole files.
- If a candidate looks like a partial fit, the manager dispatches it
  and refines from the response — don't over-think the ranking.
- Does not replace `system-memory-helper`. That agent answers "what
  do I have." This skill answers "what handles X."
