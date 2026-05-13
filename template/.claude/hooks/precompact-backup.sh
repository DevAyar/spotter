#!/usr/bin/env bash
# PreCompact hook: back up critical docs before Claude Code auto-compacts
# the conversation. If something gets corrupted across the compaction
# boundary, the backups are the recovery path.
#
# Files backed up (if present):
#   docs/STATUS.md
#   docs/SESSION_LOG.md
#   CLAUDE.md
#
# Backups land at: .claude/agent-memory/precompact-backups/<filename>.<UTC-timestamp>
# The agent-memory/ directory is gitignored — backups stay local.
set -uo pipefail

BACKUP_DIR=".claude/agent-memory/precompact-backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)

backup_if_exists() {
  local src="$1"
  if [ -f "$src" ]; then
    local base
    base=$(basename "$src")
    cp "$src" "$BACKUP_DIR/${base}.${TIMESTAMP}"
  fi
}

backup_if_exists "docs/STATUS.md"
backup_if_exists "docs/SESSION_LOG.md"
backup_if_exists "CLAUDE.md"

exit 0
