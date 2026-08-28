# Spotter in 60 seconds

Spotter is a governance layer for Claude Code: it watches your project for
scope drift while you work and files what it finds as drafts you review.
Nothing changes your project until you say yes.

## The three commands

```bash
git clone https://github.com/DevAyar/spotter.git
cd <your-project> && bash <path-to>/spotter/scripts/install.sh
claude
```

No prompts. The install ends with a block telling you what landed and what
to do first.

## What you'll see in your first session

```
[claude-skeleton] First session in this project — welcome.
  ... nothing changes your project without your approval.
[skeleton-drift] remote never checked — run: bash ~/path/to/spotter/scripts/update.sh --check-remote
[task-watchdog] transcript not resolved for <your project> — check project-dir encoding
```

The welcome shows once. The drift line prints that command with your own
checkout path filled in; run it whenever you like. The watchdog line is a
known first-session wart and disappears from your second session on. After
that, a quiet first hour is correct: the system speaks when it has observed
something, and it has not observed anything yet.

## The first thing to do

Type `/goals <a real small goal>` in your session. Spotter researches your
repo, asks at most one round of questions, writes a draft spec to
`.claude/specs/`, and stops. Nothing is built until you yourself change the
spec's `status: draft` to `approved`.

## Leaving

Uninstall is a short list of removals in
[INSTALLATION.md](INSTALLATION.md#uninstall). Run it in a normal terminal,
not inside a Claude session: the safety hooks treat bulk deletion as
exactly what it is.

This is the 60-second page. The 15-minute tour, which explains what landed
and why, is [GETTING-STARTED.md](GETTING-STARTED.md).
