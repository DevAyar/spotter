#!/usr/bin/env bash
# claude-skeleton installer
# See: bash install.sh --help

set -euo pipefail

# ---- Defaults ----
MODE="merge"
SOURCE_PATH=""
TARGET_PATH=""
CLAUDE_ONLY=false
DRY_RUN=false
FORCE=false
SKELETON_REPO_URL="https://github.com/DevAyar/claude-skeleton.git"
TMP_CLONE_DIR=""

# Rollback tracking
ADDED_FILES=()
ADDED_DIRS=()

# Counters
COPIED=0
SKIPPED=0
OVERWRITTEN=0

# ---- Colors (honor NO_COLOR) ----
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  C_RED=$(tput setaf 1 2>/dev/null || true)
  C_GREEN=$(tput setaf 2 2>/dev/null || true)
  C_YELLOW=$(tput setaf 3 2>/dev/null || true)
  C_BLUE=$(tput setaf 4 2>/dev/null || true)
  C_RESET=$(tput sgr0 2>/dev/null || true)
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RESET=""
fi

log()  { printf '%s\n' "$*"; }
info() { printf '%s%s%s\n' "${C_BLUE}" "$*" "${C_RESET}"; }
ok()   { printf '%s%s%s\n' "${C_GREEN}" "$*" "${C_RESET}"; }
warn() { printf '%s%s%s\n' "${C_YELLOW}" "$*" "${C_RESET}" >&2; }
err()  { printf '%s%s%s\n' "${C_RED}"   "$*" "${C_RESET}" >&2; }
die()  { err "error: $*"; exit 1; }

# ---- Cleanup / rollback ----
cleanup() {
  local exit_code=$?
  if [ -n "$TMP_CLONE_DIR" ] && [ -d "$TMP_CLONE_DIR" ]; then
    rm -rf "$TMP_CLONE_DIR"
  fi
  if [ "$exit_code" -ne 0 ] && [ "$DRY_RUN" = false ]; then
    rollback
  fi
  exit "$exit_code"
}

rollback() {
  if [ ${#ADDED_FILES[@]} -eq 0 ] && [ ${#ADDED_DIRS[@]} -eq 0 ]; then
    return 0
  fi
  warn "install failed — rolling back ${#ADDED_FILES[@]} file(s)"
  local f d
  for f in "${ADDED_FILES[@]}"; do
    [ -f "$f" ] && rm -f "$f"
  done
  for d in "${ADDED_DIRS[@]}"; do
    rmdir "$d" 2>/dev/null || true
  done
  ok "rollback complete"
}

trap cleanup EXIT INT TERM

# ---- Help ----
show_help() {
  cat <<'EOF'
claude-skeleton installer

Usage:
  bash install.sh [options]

Modes (--mode=):
  fresh    Refuse unless target's .claude/ is empty (only .gitkeep allowed). Then copy everything.
  merge    DEFAULT. Copy only files that don't exist in target. Never overwrite.
  replace  Overwrite existing files. Requires --force AND interactive confirmation.

Options:
  --source PATH       Path to a claude-skeleton checkout. Default: auto-detect, then clone.
  --target PATH       Target project root. Default: current git repo root.
  --claude-only       Skip top-level *.template files; copy only .claude/ contents.
                      Required for skeleton-on-skeleton self-install (dogfood).
  --dry-run           Print the install plan without making changes.
  --force             Required for --mode=replace.
  --help              Show this help.

Examples:
  # Default merge install into the current git repo
  bash install.sh

  # Fresh install from a local checkout
  bash install.sh --source /path/to/claude-skeleton --mode=fresh

  # Self-install (dogfood / development)
  bash install.sh --claude-only

  # Preview what would happen, no changes
  bash install.sh --dry-run

Notes:
  - Refuses to run if target is not a git repository.
  - Refuses self-install (source == target) UNLESS --claude-only.
  - Writes .claude/.skeleton-version after a successful install.
  - On any error, rolls back every file added by this run.
  - Top-level files (CLAUDE.md, README, .gitignore) are NEVER overwritten,
    even in --mode=replace; only .claude/ obeys the mode rules in v1.
EOF
}

# ---- Arg parsing ----
parse_args() {
  local arg
  while [ $# -gt 0 ]; do
    arg="$1"
    case "$arg" in
      --mode=*)      MODE="${arg#--mode=}" ;;
      --mode)        shift; MODE="${1:-}" ;;
      --source=*)    SOURCE_PATH="${arg#--source=}" ;;
      --source)      shift; SOURCE_PATH="${1:-}" ;;
      --target=*)    TARGET_PATH="${arg#--target=}" ;;
      --target)      shift; TARGET_PATH="${1:-}" ;;
      --claude-only) CLAUDE_ONLY=true ;;
      --dry-run)     DRY_RUN=true ;;
      --force)       FORCE=true ;;
      --help|-h)     show_help; exit 0 ;;
      *)             die "unknown argument: $arg (see --help)" ;;
    esac
    shift
  done

  case "$MODE" in
    fresh|merge|replace) ;;
    *) die "invalid --mode='$MODE' (expected: fresh, merge, replace)" ;;
  esac

  if [ "$MODE" = "replace" ] && [ "$FORCE" = false ]; then
    die "--mode=replace requires --force AND interactive confirmation"
  fi
}

# ---- Path resolution ----
resolve_skeleton_root() {
  if [ -n "$SOURCE_PATH" ]; then
    [ -d "$SOURCE_PATH/template/.claude" ] || die "--source path missing template/.claude/: $SOURCE_PATH"
    SOURCE_PATH=$(cd "$SOURCE_PATH" && pwd -P)
    return 0
  fi

  local script_dir candidate i
  script_dir=$(cd "$(dirname "$0")" && pwd -P)
  candidate="$script_dir"
  i=0
  while [ "$i" -lt 5 ]; do
    if [ -d "$candidate/template/.claude" ]; then
      SOURCE_PATH="$candidate"
      return 0
    fi
    candidate=$(dirname "$candidate")
    i=$((i+1))
  done

  info "no local claude-skeleton checkout found near $script_dir — cloning"
  command -v git >/dev/null 2>&1 || die "git not on PATH (needed for curl-mode install)"
  TMP_CLONE_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skeleton)
  git clone --depth 1 "$SKELETON_REPO_URL" "$TMP_CLONE_DIR" >/dev/null 2>&1 || die "failed to clone $SKELETON_REPO_URL"
  SOURCE_PATH="$TMP_CLONE_DIR"
}

resolve_target_root() {
  if [ -n "$TARGET_PATH" ]; then
    [ -d "$TARGET_PATH" ] || die "--target path does not exist: $TARGET_PATH"
    TARGET_PATH=$(cd "$TARGET_PATH" && pwd -P)
  else
    TARGET_PATH=$(git rev-parse --show-toplevel 2>/dev/null) || die "not in a git repository (cd to a project root, or pass --target)"
  fi
  command -v git >/dev/null 2>&1 || die "git not on PATH"
  (cd "$TARGET_PATH" && git rev-parse --show-toplevel >/dev/null 2>&1) || die "target is not a git repository: $TARGET_PATH"
}

# ---- Preflight ----
preflight() {
  [ -d "$SOURCE_PATH/template/.claude" ] || die "source missing template/.claude/: $SOURCE_PATH"
  [ -f "$SOURCE_PATH/VERSION" ]          || die "source missing VERSION: $SOURCE_PATH"

  if [ "$SOURCE_PATH" = "$TARGET_PATH" ] && [ "$CLAUDE_ONLY" = false ]; then
    die "source == target ($SOURCE_PATH); use --claude-only for skeleton-on-skeleton self-install"
  fi

  if [ "$MODE" = "fresh" ] && [ -d "$TARGET_PATH/.claude" ]; then
    local found
    found=$(find "$TARGET_PATH/.claude" -type f ! -name '.gitkeep' 2>/dev/null | head -1 || true)
    [ -z "$found" ] || die "--mode=fresh refused: target .claude/ already has content (e.g. $found). Use --mode=merge."
  fi
}

# ---- File processing ----
ensure_dir() {
  local d="$1"
  if [ ! -d "$d" ]; then
    mkdir -p "$d"
    ADDED_DIRS+=("$d")
  fi
}

ensure_exec_if_script() {
  case "$1" in *.sh) chmod +x "$1" ;; esac
}

# process_file <src> <tgt> [<top-level-flag>]
# top-level-flag: "top" means this is a top-level file (CLAUDE.md etc.) — always merge-style (never overwrite)
process_file() {
  local src="$1" tgt="$2" top="${3:-}"
  local action="copy"

  if [ -e "$tgt" ]; then
    if [ "$top" = "top" ]; then
      action="skip"
    else
      case "$MODE" in
        fresh)     die "internal: --mode=fresh hit existing file (preflight should have caught this): $tgt" ;;
        merge)     action="skip" ;;
        replace)   action="overwrite" ;;
      esac
    fi
  fi

  if [ "$DRY_RUN" = true ]; then
    case "$action" in
      copy)      printf '  + %s\n' "$tgt"; COPIED=$((COPIED+1)) ;;
      skip)      printf '  = %s (already present)\n' "$tgt"; SKIPPED=$((SKIPPED+1)) ;;
      overwrite) printf '  ~ %s (overwrite)\n' "$tgt"; OVERWRITTEN=$((OVERWRITTEN+1)) ;;
    esac
    return 0
  fi

  case "$action" in
    skip)
      SKIPPED=$((SKIPPED+1))
      ;;
    overwrite)
      cp -p "$src" "$tgt"
      ensure_exec_if_script "$tgt"
      OVERWRITTEN=$((OVERWRITTEN+1))
      ;;
    copy)
      ensure_dir "$(dirname "$tgt")"
      cp -p "$src" "$tgt"
      ensure_exec_if_script "$tgt"
      ADDED_FILES+=("$tgt")
      COPIED=$((COPIED+1))
      ;;
  esac
}

plan_and_execute() {
  local skel_claude="$SOURCE_PATH/template/.claude"
  local tgt_claude="$TARGET_PATH/.claude"
  local src rel mapped tgt

  # Walk template/.claude/**
  while IFS= read -r src; do
    [ -f "$src" ] || continue
    case "$src" in
      */.gitkeep) continue ;;
    esac
    rel="${src#$skel_claude/}"
    mapped="$rel"
    case "$mapped" in
      *.template) mapped="${mapped%.template}" ;;
    esac
    tgt="$tgt_claude/$mapped"
    process_file "$src" "$tgt"
  done < <(find "$skel_claude" -type f 2>/dev/null)

  if [ "$CLAUDE_ONLY" = true ]; then
    return 0
  fi

  # Top-level *.template files in template/
  if [ -d "$SOURCE_PATH/template" ]; then
    for src in "$SOURCE_PATH/template"/*.template; do
      [ -f "$src" ] || continue
      mapped=$(basename "$src" .template)
      tgt="$TARGET_PATH/$mapped"
      process_file "$src" "$tgt" "top"
    done
  fi

  # template/docs/*.template
  if [ -d "$SOURCE_PATH/template/docs" ]; then
    for src in "$SOURCE_PATH/template/docs"/*.template; do
      [ -f "$src" ] || continue
      mapped=$(basename "$src" .template)
      tgt="$TARGET_PATH/docs/$mapped"
      process_file "$src" "$tgt" "top"
    done
  fi
}

# ---- Confirmation for --mode=replace ----
confirm_replace() {
  [ "$MODE" = "replace" ] || return 0
  [ "$DRY_RUN" = true ] && return 0
  warn "--mode=replace will overwrite existing files in $TARGET_PATH/.claude/."
  printf 'Type YES to continue: '
  local reply
  read -r reply
  [ "$reply" = "YES" ] || die "replace not confirmed"
}

# ---- Version marker ----
write_version_marker() {
  [ "$DRY_RUN" = true ] && return 0
  local marker="$TARGET_PATH/.claude/.skeleton-version"
  local version commit ts
  version=$(tr -d '[:space:]' < "$SOURCE_PATH/VERSION")
  commit=$(git -C "$SOURCE_PATH" rev-parse HEAD 2>/dev/null || echo "unknown")
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  ensure_dir "$TARGET_PATH/.claude"
  printf 'version: %s\ncommit: %s\ninstalled_at: %s\nmode: %s\nclaude_only: %s\nsource: %s\n' \
    "$version" "$commit" "$ts" "$MODE" "$CLAUDE_ONLY" "$SOURCE_PATH" > "$marker"
  ADDED_FILES+=("$marker")
}

# ---- Summary ----
summary() {
  echo
  if [ "$DRY_RUN" = true ]; then
    info "DRY RUN — no files written."
    printf '  would copy:      %d\n' "$COPIED"
    printf '  would skip:      %d\n' "$SKIPPED"
    [ "$OVERWRITTEN" -gt 0 ] && printf '  would overwrite: %d\n' "$OVERWRITTEN"
    return 0
  fi
  ok "claude-skeleton install complete"
  printf '  source:   %s\n' "$SOURCE_PATH"
  printf '  target:   %s\n' "$TARGET_PATH"
  if [ "$CLAUDE_ONLY" = true ]; then
    printf '  mode:     %s (--claude-only)\n' "$MODE"
  else
    printf '  mode:     %s\n' "$MODE"
  fi
  printf '  copied:   %d\n' "$COPIED"
  printf '  skipped:  %d\n' "$SKIPPED"
  [ "$OVERWRITTEN" -gt 0 ] && printf '  overwrote: %d\n' "$OVERWRITTEN"
  printf '  marker:   %s\n' "$TARGET_PATH/.claude/.skeleton-version"
  echo
  if [ "$CLAUDE_ONLY" = false ]; then
    printf 'Next: dispatch project-tuner-helper to fill placeholders and tune to this project.\n'
  fi
  printf 'See: docs/INSTALLATION.md for update / uninstall.\n'
}

# ---- Main ----
parse_args "$@"
resolve_skeleton_root
resolve_target_root
preflight
confirm_replace
[ "$DRY_RUN" = true ] && info "DRY RUN — planned operations:"
plan_and_execute
write_version_marker
summary
