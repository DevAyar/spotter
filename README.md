# claude-skeleton

[![CI](https://github.com/DevAyar/claude-skeleton/actions/workflows/ci.yml/badge.svg)](https://github.com/DevAyar/claude-skeleton/actions/workflows/ci.yml)

claude-skeleton is a **structural immune system** for Claude Code projects — a
governance layer that watches a project for scope decay, drift, and the silent
erosion of the principles it was built on. It sits on top of the Claude Code
ecosystem and orchestrates the moving parts (agents, skills, scripts, slash
commands, hooks) so the project stays coherent as it grows.

## The 30-second version

**The problem.** Projects decay structurally over time. The original logic of
why each piece exists fades — and AI-assisted coding makes the decay faster,
because it's easy to generate volume and hard to keep that volume coherent. What
lands is *slop*: code that compiles and passes tests but doesn't fit the
project's shape. Linters check syntax; nothing checks "does this still belong
here?"

**Who it's for.** Solo developers and small teams shipping projects worth
maintaining longer than three months — games, frameworks, mobile apps, deployed
services. The overhead pays back the moment you return to a project six months
later. Not for throwaway scripts or single-session experiments.

**What makes it different.** Three things. *Per-project governance* — each
install evolves its own discipline from a shared seed; pinball governs pinball,
Trainer-View governs TV. *Approval-gated autonomy* — thinking is automated (read,
plan, observe, audit, draft), but anything that changes the project waits for
you. *Scope actively governed, not passively hoped for* — a watchdog triad fires
on a cadence to catch drift while it's still a five-minute fix, not a six-month
rewrite.

## Where it is now

- **Version:** v1.1.4. The substrate has shipped — observation layer,
  capture/reuse loop, audit triad, vetted plugin bundle, and hook infrastructure
  all live and stable.
- **Latest:** the closed-loop tuner-baseline fix landed at `789d2cd` —
  per-project tuner customizations now survive `update.sh` byte-identical.
- **In production:** Trainer-View (Flutter + Firebase), Echoes-Of-Gill (Godot),
  Pinball (starting up), plus the skeleton's own dogfood install.
- **Forward direction:** compose with the ecosystem, don't compete with it. See
  [`docs/ROADMAP.md`](docs/ROADMAP.md) for the readiness-gated sequence.

## Install

Non-destructive install into any project — missing files are added, existing
files are left alone, versions tracked per-project so updates stay safe. See
[`docs/INSTALLATION.md`](docs/INSTALLATION.md) for install + update mechanics.

## Read more

- [`docs/STORY.md`](docs/STORY.md) — the full pitch: mission, the core
  principles, how the loop prevents scope decay.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — versioning and readiness-gated
  sequencing.
- [`CLAUDE_MANAGER.md`](CLAUDE_MANAGER.md) — the manager directive surface
  installed projects inherit.
- [`docs/INSTALLATION.md`](docs/INSTALLATION.md) — install + update mechanics.

## License

MIT — see [LICENSE](LICENSE).

---

*Written for peers and informed devs familiar with Claude Code's plugin
marketplace, agents, hooks, and slash commands. Not a portfolio piece — useful
first, philosophy second.*
