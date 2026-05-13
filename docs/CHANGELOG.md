# Changelog

All notable changes to claude-skeleton are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows [SemVer](https://semver.org/).

## [0.1.0] - 2026-05-13 — Pre-alpha foundation

- Project initialized.
- Directory structure established (`.claude/`, `template/`, `scripts/`, `docs/`).
- Initial docs scaffolded (`README`, `PHILOSOPHY`, `ARCHITECTURE`, `INSTALLATION` stub, `CHANGELOG`).
- MIT `LICENSE`, `.gitignore`, `VERSION` (`0.1.0`) in place.
- `.claude/settings.json` configured with plan-mode default and durable rules in `compactPrompt`.
- Two-agent install flow documented in `ARCHITECTURE.md` (`integration-installer` for mechanics, `project-tuner-helper` for customization). No implementation yet.
- No features yet — Phase 4a is foundation only. Features land in subsequent phases:
  - **4b**: populate `template/.claude/` with baseline agents/skills/hooks; build `project-tuner-helper`.
  - **4c**: install/update mechanism + `integration-installer`.
  - **4d-e**: validation, test projects.
