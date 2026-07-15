# Getting started — your first 15 minutes after install

You just ran `install.sh` and your project has a new `.claude/` tree and some
unfamiliar session-start output. This walks what happened, what you'll see,
and what to do first. (Install mechanics themselves — modes, flags, updates —
live in [`INSTALLATION.md`](INSTALLATION.md).)

## What just happened to your project

The install copied the skeleton baseline in (a fresh run reports ~82 files):

- **`.claude/agents/`** — 17 helpers in numbered role folders: research,
  audit, monitoring, planning, and a meta tier that watches the system
  itself (drift, artifact fit, cost, the manager's own decisions).
- **`.claude/skills/`** — 6 behavioral conventions the manager follows
  without needing a hook (grep-before-reading-huge-files, bash-safety
  excludes, schema-check-before-config-edits, and so on).
- **`.claude/scripts/`** — 11 mechanical wrappers (commit, deploy, drift
  check, the goals surfacer, shared-memory tooling).
- **`.claude/commands/`** — 10 slash commands, including `/goals` (more on
  that below) and `/commit`.
- **`.claude/hooks/`** — 7 hook scripts wired across four events in
  `settings.json`: session-start checks, pre-compact backup, two
  destructive-command gates on Bash/PowerShell, session-end telemetry.
- **`.claude/.skeleton-version`** — the version marker: a per-file hash
  baseline of everything the template shipped. It's how `update.sh` later
  tells *your* edits apart from template changes, so updates never clobber
  your customizations. Don't hand-edit it; the scripts own it.
- **`.gitignore` entries** (or a note to add them if you already had one) —
  the hooks write runtime data (observations, telemetry, cooldown markers);
  the excludes keep that noise out of your diffs.

The reassurance, with teeth: **nothing in this tree runs anything without
your approval.** Hooks observe and print; agents read and draft; everything
that changes a file or runs a state-changing command waits for you. And every
protection has a stated escape hatch — turn any of it off and the system says
so plainly rather than trapping you (that rule is locked in
[`ROADMAP.md`](ROADMAP.md) § locked principles).

## Your first session start

Transcribed from a real fresh install — you'll see something very close to
this, folded into your session context:

```
{{COMPACT_PROMPT}}

[skeleton-drift] cache empty (no last-known remote version).
  installed: 1.1.4
  refresh:   bash scripts/update.sh --check-remote

[task-watchdog] transcript not resolved for <your project> — check project-dir encoding
```

Line by line:

- **`{{COMPACT_PROMPT}}`** — yes, a literal placeholder. Install copies
  templates as-is; the tuner fills them. Dispatch `project-tuner-helper`
  (the install's closing line told you the same) and this becomes your
  project's durable-rules block. Looks like a bug; isn't.
- **`[skeleton-drift] cache empty`** — the marker has no cached remote
  version yet. Optional: run `bash <skeleton>/scripts/update.sh
  --check-remote` once and this goes silent until a new skeleton release
  actually exists. No urgency.
- **`[task-watchdog] transcript not resolved`** — expected on a first-ever
  session: the watchdog looks for the *prior* session's transcript and there
  isn't one yet. It disappears from your second session onward. (Known
  cosmetic; ignorable.)
- **The plugin auditor ran silently** — it checks installed plugin source on
  a 24h cooldown and only writes observation files; no news is good news.
- **No cost line yet** — it needs a completed session's telemetry. From your
  second session it looks like:

```
[token-cost] last sitting ~$29.23 (in 0.1M / out 45,000 / cache 32.0M @ claude-opus-4-8 rates) | 7d ~$29.23 across 1 lineage(s)
```

  "Last sitting" means exactly that — what the previous sitting cost, not a
  multi-day cumulative (resumed sessions get a `lineage ~$Y since <date>`
  context segment so you see both).

Two more lines exist that you won't see for a while, correctly: the
manager-optimizer nudge (needs draft proposals or a session-count threshold)
and the `[goals]` line (needs an *approved* spec with a due schedule). A
fresh install's first session is mostly quiet. That's not a failure to
launch — the system speaks when it has observed something, and it hasn't
observed anything yet.

## Your first dispatch

Run the whole gate pattern once, on something real:

```
/goals add a --version flag to our build script
```

(Any small, real goal from your project works.) Watch what happens: the
manager researches repo-locally (reads only), asks you at most ONE batched
round of numbered questions — only what the research couldn't answer, and
possibly nothing — then writes a draft spec to `.claude/specs/<slug>.md` and
stops. Open the spec, read the "Open questions" section, and if it's sound,
change `status: draft` to `status: approved` in the frontmatter. That
hand-edit is the approval gate — the same one every artifact in this system
passes through. Nothing built until you flipped it.

Alternative first dispatch: ask for `artifact-fit-analyzer` — a read-only
inventory pass over your `.claude/` that drafts findings without touching
anything.

## The loop you just joined

From your seat it's four steps: **producers observe** (the watchdog files
recurring failures from prior sessions; telemetry records spend) →
**suggestions arrive as drafts** (`workflow-suggester` writes one-page
captures to `.claude/captures/`; specs land in `.claude/specs/`) → **you
approve by editing one frontmatter field** (`draft` → `approved`, or
`rejected` to never see it again) → **approved things get built and the file
records where** (`shipped_to:` / `consumed`). The manager reads, plans, and
drafts on its own; everything that changes your project waits for you. The
skeleton's own repo has run this loop end-to-end — the pattern you're using
is the one it governs itself with.

## Tuning it to your project

- **`.claude/gate-config.json`** — the human-facing knobs: cost warn
  thresholds (compared against per-*sitting* spend), the optimizer's
  cadence. Edit by hand; nothing writes it programmatically.
- **`CLAUDE_MANAGER.md`** — the manager's directive surface, and after
  install it's *yours*: tune it to your project's needs. Local divergence is
  the design, not a violation; only patterns that prove out across many
  installs graduate back into the shared template.
- **`update.sh`** — the safe refresh path when the skeleton ships new
  phases: it classifies every file (unchanged / template-updated /
  locally-modified / new / orphan) and your locally-modified files are never
  overwritten without a per-file prompt.

## Read more

- [`INSTALLATION.md`](INSTALLATION.md) — install and update mechanics.
- [`../README.md`](../README.md) — the pitch and the loop in brief.
- [`../CLAUDE_MANAGER.md`](../CLAUDE_MANAGER.md) — the rules the manager
  itself runs on. Worth a skim so its behavior isn't a black box.
