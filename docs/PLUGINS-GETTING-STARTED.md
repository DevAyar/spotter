# Plugins — the opt-in story

The skeleton composes with the Claude Code plugin ecosystem; it doesn't ship
any of it. This doc covers what the vetted bundle adds, and the discipline
for installing anything — bundle or otherwise — with your eyes open.

## Plugins are opt-in

`install.sh` installed zero plugins. What you choose to add is yours, and the
skeleton's stance is a quality filter, not a catalog ("don't be a directory";
[`../CLAUDE_MANAGER.md`](../CLAUDE_MANAGER.md) § Plugin marketplace
composition). What it *does* do is watch what you install:
`code-quality-auditor`'s mechanical layer runs at session start on a 24h
cooldown against your installed plugin cache — read-only, never auto-fixes,
findings land as observations for normal triage.

## The vetted bundle

Six plugins went through the skeleton's own vetting (the records live in
[`PLUGIN-INSTALLS-v1.1.4.md`](PLUGIN-INSTALLS-v1.1.4.md)):

- **feature-dev** (Anthropic-official) — guided feature development: codebase
  exploration, architecture design, review agents.
- **code-review** (Anthropic-official) — pull-request review workflow.
- **commit-commands** (Anthropic-official) — commit/push/PR slash commands.
- **security-guidance** (Anthropic-official) — a PreToolUse advisory hook on
  Edit/Write; at vetting it was disjoint from the skeleton's own Bash/
  PowerShell gates, so the two compose rather than collide.
- **superpowers** (community — `obra/superpowers-marketplace`) — a large
  behavioral-skill library (TDD, debugging, planning disciplines) plus one
  additive SessionStart hook.
- **claude-mem** (community — `thedotmack/claude-mem`) — persistent
  cross-session memory. The interesting one; see the worked example below.

Honest externality note: these descriptions were true at vetting time. The
plugins are external code updating on their own schedules — the skeleton
re-audits what's in your cache on its cooldown, but a description here is
vetting rationale, not a live guarantee.

## The eyes-open install pattern

The discipline, in order: **audit first** (read the plugin's actual source —
manifest, hooks, scripts — before installing; for Anthropic-official plugins
this is defense-in-depth, for community plugins it's mandatory), then
**install with explicit awareness of side effects** — concerns documented in
writing before the install, not discovered after.

The worked example is claude-mem. Vetting found four concerns that exceeded
the halt bar, and the install was deferred until they could be accepted
knowingly: its advertised `npx` install path auto-installs Bun and uv
globally; it runs a background worker process; an opt-in network-egress code
path (Telegram/Discord/Slack) exists in the codebase whether or not you
configure it; and — the punchline worth internalizing — two of those live
*outside* `~/.claude/`, where the skeleton's audit triad has no visibility
by design. The install happened anyway, later and deliberately, with all
four concerns recorded verbatim as the input contract. That's the pattern:
not "no concerns," but "no concerns you haven't read and accepted in
writing."

After install, the eight plugin-discipline rules apply (CLAUDE_MANAGER
§ Plugin discipline): no silent hook additions, no network at hook time,
conflicts with native helpers fail closed to the native helper, and
promotion from opt-in to always-on is a deliberate human decision.

## Trust tiers, in one paragraph

Two tiers exist, defined operationally: **tier-1** is Anthropic-official
(shipped through `claude-plugins-official`) — still audited, on the
principle that curated isn't automatically clean; **tier-2** is everything
community-curated, and it's what triggers the mandatory eyes-open pattern
above. That's the whole codification today — there is no tier-3, no scoring,
no automated trust inference. A `--candidate` audit mode for
pre-install vetting is planned (v1.5-B), and plugin *recommendations* are a
later tier still.

## What the auditor checks

`plugin-quality-check.sh`, three heuristics, plain terms:

- **(i) Manifest honesty** — the plugin's manifest declares a component path
  that doesn't exist or is empty.
- **(ii) Hook schema** — a `hooks/` directory exists but `hooks.json` is
  malformed or schema-violating (a hook that can't load is a hook that fails
  silently).
- **(iii) Destructive patterns** — plugin shell scripts contain destructive
  commands against unguarded paths, checked against the same shared pattern
  libraries the skeleton's own PreToolUse gates use.

A finding is an observation file in `.claude/observations/` — it enters the
same triage flow as everything else the system observes. Nothing is blocked
or uninstalled automatically.

## Read more

- [`GETTING-STARTED.md`](GETTING-STARTED.md) — your first 15 minutes.
- [`../CLAUDE_MANAGER.md`](../CLAUDE_MANAGER.md) § Plugin marketplace
  composition — the ecosystem sources and the install rule.
- Plugin recommendations *with reasons* — "you have no test discipline;
  superpowers ships one" — are a future tier (v1.5/v2.0 per
  [`ROADMAP.md`](ROADMAP.md)). This doc is the manual-era discipline that
  tier will automate.
