# 6B story doc — outline

Outline-only. 6b is where the prose lands; this file exists so 6b doesn't start cold.

Target total: 1500–3000 words. Audience: me and peers, digestible. Register: calm, matches the `template/CLAUDE_MANAGER.md.template` Slice A tone. No marketing copy.

Locked vocabulary the prose must respect (from Slice A): L0 / L1 / L2 (L3 reserved), three-commit cadence, the 7-source plugin marketplace composition, recursive ownership, ever-evolving framing, "Don't be a directory; be a quality filter."

## 1. What this is — 1 paragraph
One paragraph: claude-skeleton is an orchestration skeleton for Claude Code projects. Current state (v0.9.0 — installable, CI on three platforms, in production on Trainer-View and Echoes-Of-Gill). Who actually uses it.

## 2. Why it exists — 2–3 paragraphs
Origin and motivation. Honest version: the ADHD-driven design rationale. Variable attention forced system-design discipline (explicit handoffs, written rules, persistent state) because the alternative — relying on in-head context — didn't survive a bad attention day. The accidental discovery: that discipline turns out to be generally useful for anyone collaborating with an LLM agent over weeks, not just for managing variable attention. Brief mention of the Trainer-View Phases 1-3 lineage that fed into the skeleton.

## 3. How it works — 3–4 paragraphs
The four layers. One short paragraph each:
- Manager + helpers + skills + scripts (the runtime).
- Approval gates (the autonomy line).
- Recursive ownership L0 / L1 / L2 (the responsibility axis).
- Install / update mechanism (the persistence story — including per-file SHA-256 hashes and the six-way classification).

## 4. How to use it — 2 paragraphs
First paragraph: install flow. `curl … | bash` or local checkout → `install.sh --mode=merge`. `project-tuner-helper` customizes the baseline.
Second paragraph: what a session feels like. Open Claude Code, manager reads STATUS / ROUTING / CLAUDE_MANAGER. Strategic judgment patterns fire when relevant. Three-commit cadence at the end.

## 5. What's distinctive — 3 paragraphs
One paragraph each on the three angles:
- Composition with the ecosystem (not competition). The 7-source list. Verbatim: "Don't be a directory; be a quality filter."
- Recursive ownership as an explicit principle, not an emergent property. Why L0/L1/L2 + L3 reserved.
- Per-file SHA-256 update mechanism. Safe automated updates. Production-validated across two real targets (Trainer-View Flutter + Echoes-Of-Gill Godot).

## 6. What it's not — 1 paragraph
Not a directory of every plugin. Not a multi-LLM framework. Not an autonomous AI agent. Not a portfolio / marketing artefact. Closes with the approval-gated autonomy line: thinking is autonomous, action is approved.

## 7. Where it's going — 1 paragraph
Pointer to [`ROADMAP.md`](ROADMAP.md). Names the three landmarks: v1.1+ capture/reuse loop, v1.2+ `manager-optimizer`, v2.0 plugin recommendation system. One sentence of context per landmark, no detail (that's what ROADMAP is for).

## 8. Peer projects — 1 paragraph + list
One paragraph framing: same problem space, different implementation choices. Then a tight list with a one-line note each:
- `claude-code-templates` — stack-by-stack template projects.
- `claude-agentic-framework` — higher-level multi-agent orchestration patterns.
- `wshobson/agents` — curated subagent collection.
- `claude-skills` — behavioral-skill library.
- `awesome-claude-code-subagents` — community discovery surface.
- `ClaudeFast` — performance-oriented agent patterns.
- `storybloq` — adjacent in problem space; cite for completeness.

Close with one sentence: peer projects are the ecosystem the skeleton composes with, not competitors to displace.

## Target word counts

| Section | Paragraphs | Approx. words |
|---|---|---|
| 1. What this is | 1 | 100–150 |
| 2. Why it exists | 2–3 | 250–400 |
| 3. How it works | 3–4 | 400–600 |
| 4. How to use it | 2 | 200–300 |
| 5. What's distinctive | 3 | 300–450 |
| 6. What it's not | 1 | 100–150 |
| 7. Where it's going | 1 | 100–150 |
| 8. Peer projects | 1 + list | 150–250 |
| **Total** | | **1600–2450** |

Lands mid-range of the 1500–3000 brief.

## Notes

- Do not pre-draft any prose in this file. The outline is the contract; 6b writes the prose against it.
- The "Why it exists" section is the place where the personal angle lands. Keep it honest, brief, and useful — not a confessional, not a sales pitch.
- The "Peer projects" list goes beyond ROADMAP's 7-source plugin marketplace by adding `storybloq` (brief explicitly names it). ROADMAP's marketplace list is the locked v1.0 composition; 6b's peer-projects list is the broader acknowledgment.
- 6b lands as `docs/6B.md` or whatever the canonical name turns out to be. This file does not need to be retained after 6b ships — it's scaffolding.
