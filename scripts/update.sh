#!/usr/bin/env bash
# claude-skeleton updater
# See: bash update.sh --help

set -euo pipefail

# ---- Defaults ----
SOURCE_PATH=""
TARGET_PATH=""
AUTO_APPLY=false
DRY_RUN=false
SKELETON_REPO_URL="https://github.com/DevAyar/claude-skeleton.git"
TMP_CLONE_DIR=""

# Rollback tracking
ADDED_FILES=()
MODIFIED=()    # entries: "<path>|<backup-path>"
ADDED_DIRS=()

# Findings
UPDATES=()     # paths (relative to .claude/) that differ from template
NEW=()         # paths in template absent from target

# Counters
APPLIED=0
SKIPPED_FILES=0

# ---- Colors ----
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  C_RED=$(tput setaf 1 2>/dev/null || true)
  C_GREEN=$(tput setaf 2 2>/dev/null || true)
  C_YELLOW=$(tput setaf 3 2>/dev/null || true)
  C_BLUE=$(tput setaf 4 2>/dev/null || true)
  C_RESET=$(tput sgr0 2>/dev/null || true)
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RESET=""
fi

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
  if [ ${#ADDED_FILES[@]} -eq 0 ] && [ ${#MODIFIED[@]} -eq 0 ]; then
    return 0
  fi
  warn "update failed — restoring previous state"
  local f entry path backup
  for f in "${ADDED_FILES[@]}"; do
    [ -f "$f" ] && rm -f "$f"
  done
  for entry in "${MODIFIED[@]}"; do
    path="${entry%%|*}"
    backup="${entry##*|}"
    [ -f "$backup" ] && mv -f "$backup" "$path"
  done
  ok "rollback complete"
}

cleanup_backups() {
  local entry backup
  for entry in "${MODIFIED[@]}"; do
    backup="${entry##*|}"
    [ -f "$backup" ] && rm -f "$backup"
  done
}

trap cleanup EXIT INT TERM

# ---- Help ----
show_help() {
  cat <<'EOF'
claude-skeleton updater

Usage:
  bash update.sh [options]

Compares the installed .claude/ in the current git repo against the
current claude-skeleton template. Walks you through which files differ
and which to update.

Options:
  --source PATH    Path to a claude-skeleton checkout. Default: auto-detect or clone.
  --target PATH    Target project root. Default: current git repo root.
  --auto-apply     Apply all template diffs without per-file prompts. New files still
                   ask once; conflicts still require user input.
  --dry-run        Print the update plan without changing anything.
  --help           Show this help.

v1 limitations:
  - "Locally modified" vs "template updated" cannot be distinguished without
    per-file hashes in .skeleton-version. Any diff prompts the user.
  - Top-level files (CLAUDE.md, README, etc.) are not updated by this script.
    Re-run install.sh manually if you want to refresh them.
EOF
}

# ---- Arg parsing ----
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --source=*)   SOURCE_PATH="${1#--source=}" ;;
      --source)     shift; SOURCE_PATH="${1:-}" ;;
      --target=*)   TARGET_PATH="${1#--target=}" ;;
      --target)     shift; TARGET_PATH="${1:-}" ;;
      --auto-apply) AUTO_APPLY=true ;;
      --dry-run)    DRY_RUN=true ;;
      --help|-h)    show_help; exit 0 ;;
      *)            die "unknown argument: $1 (see --help)" ;;
    esac
    shift
  done
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

  info "no local checkout found — cloning $SKELETON_REPO_URL"
  command -v git >/dev/null 2>&1 || die "git not on PATH"
  TMP_CLONE_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t claude-skeleton)
  git clone --depth 1 "$SKELETON_REPO_URL" "$TMP_CLONE_DIR" >/dev/null 2>&1 || die "failed to clone"
  SOURCE_PATH="$TMP_CLONE_DIR"
}

resolve_target_root() {
  if [ -n "$TARGET_PATH" ]; then
    [ -d "$TARGET_PATH" ] || die "--target path does not exist: $TARGET_PATH"
    TARGET_PATH=$(cd "$TARGET_PATH" && pwd -P)
  else
    TARGET_PATH=$(git rev-parse --show-toplevel 2>/dev/null) || die "not in a git repo (cd to a project root, or pass --target)"
  fi
}

preflight() {
  [ -f "$TARGET_PATH/.claude/.skeleton-version" ] || die "target has no .claude/.skeleton-version — not a claude-skeleton install. Run install.sh first."
  [ -d "$SOURCE_PATH/template/.claude" ]          || die "source missing template/.claude/"
  [ -f "$SOURCE_PATH/VERSION" ]                   || die "source missing VERSION"
}

# ---- Scan ----
scan() {
  local skel_claude="$SOURCE_PATH/template/.claude"
  local tgt_claude="$TARGET_PATH/.claude"
  local src rel mapped tgt

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

    if [ ! -e "$tgt" ]; then
      NEW+=("$mapped")
      continue
    fi
    if cmp -s "$src" "$tgt"; then
      continue
    fi
    UPDATES+=("$mapped")
  done < <(find "$skel_claude" -type f 2>/dev/null)
}

print_findings() {
  local installed_version
  installed_version=$(grep -E '^version:' "$TARGET_PATH/.claude/.skeleton-version" 2>/dev/null | awk '{print $2}')
  local current_version
  current_version=$(tr -d '[:space:]' < "$SOURCE_PATH/VERSION")
  echo
  info "installed: ${installed_version:-unknown}    current: ${current_version}"
  printf '  files differing from current template: %d\n' "${#UPDATES[@]}"
  printf '  files new in template (absent locally): %d\n' "${#NEW[@]}"
  echo
}

# ---- Helpers ----
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

src_for_rel() {
  # Resolve a relative path back to source — may be .template'd
  local rel="$1"
  local cand="$SOURCE_PATH/template/.claude/$rel"
  if [ -f "$cand" ]; then
    printf '%s' "$cand"
  else
    printf '%s' "$cand.template"
  fi
}

backup_then_overwrite() {
  local src="$1" tgt="$2"
  local backup="$tgt.bak.$$"
  cp -p "$tgt" "$backup"
  cp -p "$src" "$tgt"
  ensure_exec_if_script "$tgt"
  MODIFIED+=("$tgt|$backup")
}

# ---- New files ----
apply_new() {
  [ ${#NEW[@]} -eq 0 ] && return 0
  info "new files in template:"
  local rel
  for rel in "${NEW[@]}"; do
    printf '  + .claude/%s\n' "$rel"
  done
  local reply
  if [ "$AUTO_APPLY" = true ]; then
    reply="y"
  else
    printf 'Copy all? [Y/n] '
    read -r reply || reply="y"
  fi
  case "$reply" in
    n|N|no|NO) info "skipped new files"; SKIPPED_FILES=$((SKIPPED_FILES + ${#NEW[@]})); return 0 ;;
  esac
  [ "$DRY_RUN" = true ] && return 0
  local src tgt
  for rel in "${NEW[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/.claude/$rel"
    ensure_dir "$(dirname "$tgt")"
    cp -p "$src" "$tgt"
    ensure_exec_if_script "$tgt"
    ADDED_FILES+=("$tgt")
    APPLIED=$((APPLIED+1))
  done
  ok "applied ${#NEW[@]} new file(s)"
}

# ---- Updates ----
apply_updates() {
  [ ${#UPDATES[@]} -eq 0 ] && return 0
  echo
  info "files that differ between target and current template:"
  local rel
  for rel in "${UPDATES[@]}"; do
    printf '  ~ .claude/%s\n' "$rel"
  done

  local action
  if [ "$AUTO_APPLY" = true ]; then
    action="A"
  else
    echo
    printf 'Action: [A]pply all  [R]eview individually  [S]kip all  : '
    read -r action || action="S"
  fi

  case "$action" in
    A|a|apply) apply_all_updates ;;
    R|r|review) review_updates ;;
    *) info "skipped all updates"; SKIPPED_FILES=$((SKIPPED_FILES + ${#UPDATES[@]})) ;;
  esac
}

apply_all_updates() {
  local rel src tgt
  for rel in "${UPDATES[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/.claude/$rel"
    [ "$DRY_RUN" = false ] && backup_then_overwrite "$src" "$tgt"
    APPLIED=$((APPLIED+1))
  done
  ok "applied ${#UPDATES[@]} update(s)"
}

review_updates() {
  local rel src tgt reply
  for rel in "${UPDATES[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/.claude/$rel"
    echo
    info ".claude/$rel"
    while :; do
      printf '  [u]pdate  [k]eep  [d]iff  : '
      read -r reply || reply="k"
      case "$reply" in
        u|U)
          [ "$DRY_RUN" = false ] && backup_then_overwrite "$src" "$tgt"
          APPLIED=$((APPLIED+1))
          break
          ;;
        k|K)
          SKIPPED_FILES=$((SKIPPED_FILES+1))
          break
          ;;
        d|D)
          diff -u "$tgt" "$src" || true
          ;;
      esac
    done
  done
}

# ---- Version marker ----
write_version_marker() {
  [ "$DRY_RUN" = true ] && return 0
  [ "$APPLIED" -eq 0 ]   && return 0
  local marker="$TARGET_PATH/.claude/.skeleton-version"
  local version commit ts installed_at prev_mode prev_claude_only
  version=$(tr -d '[:space:]' < "$SOURCE_PATH/VERSION")
  commit=$(git -C "$SOURCE_PATH" rev-parse HEAD 2>/dev/null || echo "unknown")
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  installed_at=$(grep -E '^installed_at:' "$marker" 2>/dev/null | head -1 | awk '{print $2}')
  prev_mode=$(grep -E '^mode:' "$marker" 2>/dev/null | head -1 | awk '{print $2}')
  prev_claude_only=$(grep -E '^claude_only:' "$marker" 2>/dev/null | head -1 | awk '{print $2}')
  printf 'version: %s\ncommit: %s\ninstalled_at: %s\nmode: %s\nclaude_only: %s\nsource: %s\nupdated_at: %s\n' \
    "$version" "$commit" "${installed_at:-unknown}" "${prev_mode:-merge}" "${prev_claude_only:-false}" "$SOURCE_PATH" "$ts" > "$marker"
}

summary() {
  echo
  if [ "$DRY_RUN" = true ]; then
    info "DRY RUN — no files written."
    return 0
  fi
  ok "update complete"
  printf '  applied: %d\n' "$APPLIED"
  printf '  skipped: %d\n' "$SKIPPED_FILES"
}

# ---- Main ----
parse_args "$@"
resolve_skeleton_root
resolve_target_root
preflight
scan
print_findings
if [ ${#NEW[@]} -eq 0 ] && [ ${#UPDATES[@]} -eq 0 ]; then
  ok "everything up to date"
  exit 0
fi
apply_new
apply_updates
write_version_marker
cleanup_backups
summary
