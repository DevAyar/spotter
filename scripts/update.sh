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
DELETED_BACKUPS=()  # entries: "<path>|<backup-path>" for orphan deletes

# JSON parsing tool (detected at startup)
JSON_TOOL=""

# SHA-256 command (detected at startup — sha256sum on Linux/Git Bash, shasum -a 256 on macOS)
SHA256_CMD=""

# Marker state (populated by dump_marker) — scalar fields + a parallel-arrays
# emulation of a path→hash map so this script runs on macOS's bash 3.2 (no
# `declare -A`). MARKER_HASH_ENTRIES holds "path<TAB>hash" entries.
MARKER_VERSION=""
MARKER_COMMIT=""
MARKER_INSTALLED_AT=""
MARKER_MODE=""
MARKER_CLAUDE_ONLY=""
MARKER_SOURCE=""
MARKER_UPDATED_AT=""
MARKER_HASH_ENTRIES=()
MARKER_HAS_FILES_OBJECT=false
BACKFILL_MODE=false

# ---- marker_hash_* helpers (bash 3.2-compatible map emulation) ----
marker_hash_get() {
  local key="$1" entry
  for entry in "${MARKER_HASH_ENTRIES[@]:-}"; do
    [ -z "$entry" ] && continue
    if [ "${entry%%	*}" = "$key" ]; then
      printf '%s' "${entry#*	}"
      return 0
    fi
  done
}

marker_hash_set() {
  local key="$1" val="$2" i
  for ((i=0; i<${#MARKER_HASH_ENTRIES[@]}; i++)); do
    if [ "${MARKER_HASH_ENTRIES[$i]%%	*}" = "$key" ]; then
      MARKER_HASH_ENTRIES[$i]="$key"$'\t'"$val"
      return 0
    fi
  done
  MARKER_HASH_ENTRIES+=("$key"$'\t'"$val")
}

marker_hash_unset() {
  local key="$1" entry new=()
  for entry in "${MARKER_HASH_ENTRIES[@]:-}"; do
    [ -z "$entry" ] && continue
    if [ "${entry%%	*}" != "$key" ]; then
      new+=("$entry")
    fi
  done
  MARKER_HASH_ENTRIES=("${new[@]:-}")
  # Re-empty the trailing placeholder, if any.
  if [ ${#MARKER_HASH_ENTRIES[@]} -eq 1 ] && [ -z "${MARKER_HASH_ENTRIES[0]}" ]; then
    MARKER_HASH_ENTRIES=()
  fi
}

# Findings buckets (populated by classify)
UNCHANGED_FILES=()
TEMPLATE_UPDATED_FILES=()
LOCALLY_MODIFIED_FILES=()
LOCAL_MATCHES_TEMPLATE_FILES=()
NEW_FILES=()
ORPHAN_FILES=()

# Counters
APPLIED=0
SKIPPED_FILES=0

# ---- Colors ----
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ] && command -v tput >/dev/null 2>&1; then
  C_RED=$(tput setaf 1 2>/dev/null || true)
  C_GREEN=$(tput setaf 2 2>/dev/null || true)
  C_YELLOW=$(tput setaf 3 2>/dev/null || true)
  C_BLUE=$(tput setaf 4 2>/dev/null || true)
  C_BOLD=$(tput bold 2>/dev/null || true)
  C_RESET=$(tput sgr0 2>/dev/null || true)
else
  C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""; C_RESET=""
fi

info() { printf '%s%s%s\n' "${C_BLUE}" "$*" "${C_RESET}"; }
ok()   { printf '%s%s%s\n' "${C_GREEN}" "$*" "${C_RESET}"; }
warn() { printf '%s%s%s\n' "${C_YELLOW}" "$*" "${C_RESET}" >&2; }
err()  { printf '%s%s%s\n' "${C_RED}"   "$*" "${C_RESET}" >&2; }
die()  { err "error: $*"; exit 1; }

# ---- JSON helpers ----
detect_json_tool() {
  if command -v python >/dev/null 2>&1; then
    JSON_TOOL="python"
  elif command -v python3 >/dev/null 2>&1; then
    JSON_TOOL="python3"
  else
    die "JSON parsing requires python on PATH (not found)"
  fi
}

# dump_marker: read .skeleton-version (JSON or legacy shell format) and
# populate MARKER_* scalars, MARKER_HASH_ENTRIES, and MARKER_HAS_FILES_OBJECT.
dump_marker() {
  local marker="$TARGET_PATH/.claude/.skeleton-version"
  local dump tag key val
  dump=$("$JSON_TOOL" -c '
import json, sys
sys.stdout.reconfigure(newline="\n")
with open(sys.argv[1]) as f:
    text = f.read()
stripped = text.lstrip()
if stripped.startswith("{"):
    d = json.loads(text)
    for k in ("version","commit","installed_at","mode","claude_only","source","updated_at"):
        if k in d:
            v = d[k]
            if isinstance(v, bool):
                v = "true" if v else "false"
            print(f"FIELD\t{k}\t{v}")
    if "files" in d and isinstance(d["files"], dict):
        print("HAS_FILES\ttrue\t")
        for p, h in d["files"].items():
            print(f"HASH\t{p}\t{h}")
    else:
        print("HAS_FILES\tfalse\t")
else:
    for line in text.split("\n"):
        line = line.strip()
        if not line or ":" not in line:
            continue
        k, _, v = line.partition(":")
        print(f"FIELD\t{k.strip()}\t{v.strip()}")
    print("HAS_FILES\tfalse\t")
' "$marker") || die "failed to parse $marker"
  # Defensive: strip CR in case Python on Windows still emitted CRLF
  dump="${dump//$'\r'/}"
  while IFS=$'\t' read -r tag key val; do
    case "$tag" in
      FIELD)
        case "$key" in
          version)      MARKER_VERSION="$val" ;;
          commit)       MARKER_COMMIT="$val" ;;
          installed_at) MARKER_INSTALLED_AT="$val" ;;
          mode)         MARKER_MODE="$val" ;;
          claude_only)  MARKER_CLAUDE_ONLY="$val" ;;
          source)       MARKER_SOURCE="$val" ;;
          updated_at)   MARKER_UPDATED_AT="$val" ;;
        esac
        ;;
      HAS_FILES) if [ "$key" = "true" ]; then MARKER_HAS_FILES_OBJECT=true; fi ;;
      HASH)      MARKER_HASH_ENTRIES+=("$key"$'\t'"$val") ;;
    esac
  done <<< "$dump"
  return 0
}

# write_marker_json — atomic write of new-format marker.
# Args: <file> <version> <commit> <installed_at> <mode> <claude_only> <source> <updated_at_or_empty>
# Reads "<relpath>\t<hash>" lines from stdin.
write_marker_json() {
  local file="$1" version="$2" commit="$3" installed_at="$4" mode="$5" claude_only="$6" source="$7" updated_at="$8"
  local tmp="${file}.tmp.$$"
  "$JSON_TOOL" -c '
import json, sys
files = {}
for line in sys.stdin:
    line = line.rstrip("\r\n")
    if not line: continue
    parts = line.split("\t", 1)
    if len(parts) != 2: continue
    files[parts[0]] = parts[1]
out = {
  "version": sys.argv[1],
  "commit": sys.argv[2],
  "installed_at": sys.argv[3],
  "mode": sys.argv[4],
  "claude_only": (sys.argv[5] == "true"),
  "source": sys.argv[6],
}
if sys.argv[7]:
    out["updated_at"] = sys.argv[7]
out["files"] = files
with open(sys.argv[8], "w", newline="\n") as f:
    json.dump(out, f, indent=2, sort_keys=True)
    f.write("\n")
' "$version" "$commit" "$installed_at" "$mode" "$claude_only" "$source" "$updated_at" "$tmp" || { rm -f "$tmp"; return 1; }
  mv -f "$tmp" "$file"
}

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
  if [ ${#ADDED_FILES[@]} -eq 0 ] && [ ${#MODIFIED[@]} -eq 0 ] && [ ${#DELETED_BACKUPS[@]} -eq 0 ]; then
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
  for entry in "${DELETED_BACKUPS[@]}"; do
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
  for entry in "${DELETED_BACKUPS[@]}"; do
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
current claude-skeleton template using per-file SHA-256 hashes
recorded in .claude/.skeleton-version. Classifies each file:

  - TEMPLATE_UPDATED   — template moved on; you didn't touch it.
                         Safe to apply.
  - LOCALLY_MODIFIED   — you modified it; template also moved on.
                         Warned; never auto-updated.
  - UNCHANGED          — file matches template and recorded hash.
  - NEW                — template has it; you don't.
  - ORPHAN             — you have it (in marker); template no longer
                         ships it.

Options:
  --source PATH    Path to a claude-skeleton checkout. Default: auto-detect or clone.
  --target PATH    Target project root. Default: current git repo root.
  --auto-apply     Apply all template diffs without per-file prompts. New files still
                   ask once; LOCALLY_MODIFIED and ORPHAN files still require explicit
                   user input.  DISABLED during the first run after a 0.7.x→0.8.0
                   schema migration (backfill mode).
  --dry-run        Print the update plan without changing anything.
  --help           Show this help.

Backfill (one-time):
  Markers created before 0.8.0 lack per-file hashes. On first run with
  an old marker, the script enters BACKFILL MODE: it cannot detect
  pre-existing local modifications, so it forces interactive review
  and prints a prominent warning. After this run, the marker is
  upgraded to JSON with per-file hashes; subsequent runs use precise
  classification.
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

# ---- Classification ----
detect_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CMD="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
  else
    die "sha256sum or shasum required (neither found on PATH)"
  fi
}

hash_file() {
  $SHA256_CMD "$1" 2>/dev/null | awk '{print $1}'
}

src_for_rel() {
  # Resolve a relative path (e.g. "agents/01/foo.md") back to source.
  # Accepts paths with or without leading ".claude/".
  local rel="$1"
  rel="${rel#.claude/}"
  local cand="$SOURCE_PATH/template/.claude/$rel"
  if [ -f "$cand" ]; then
    printf '%s' "$cand"
  else
    printf '%s' "$cand.template"
  fi
}

classify() {
  local skel_claude="$SOURCE_PATH/template/.claude"
  local tgt_claude="$TARGET_PATH/.claude"
  local src rel mapped tgt full_rel
  local hash_recorded hash_current hash_template
  local in_template=()

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
    full_rel=".claude/$mapped"
    in_template+=("$full_rel")

    if [ ! -e "$tgt" ]; then
      NEW_FILES+=("$full_rel")
      continue
    fi

    hash_template=$(hash_file "$src")
    hash_current=$(hash_file "$tgt")
    hash_recorded=$(marker_hash_get "$full_rel")

    if [ -z "$hash_recorded" ]; then
      # No recorded hash → per-file backfill.
      BACKFILL_MODE=true
      marker_hash_set "$full_rel" "$hash_current"
      hash_recorded="$hash_current"
    fi

    if [ "$hash_recorded" = "$hash_current" ] && [ "$hash_recorded" = "$hash_template" ]; then
      UNCHANGED_FILES+=("$full_rel")
    elif [ "$hash_recorded" = "$hash_current" ] && [ "$hash_recorded" != "$hash_template" ]; then
      TEMPLATE_UPDATED_FILES+=("$full_rel")
    elif [ "$hash_recorded" != "$hash_current" ] && [ "$hash_current" != "$hash_template" ]; then
      LOCALLY_MODIFIED_FILES+=("$full_rel")
    else
      # recorded != current AND current == template
      LOCAL_MATCHES_TEMPLATE_FILES+=("$full_rel")
    fi
  done < <(find "$skel_claude" -type f 2>/dev/null)

  # Orphan detection: any marker entry not seen in template.
  local entry rec_path found p
  for entry in "${MARKER_HASH_ENTRIES[@]:-}"; do
    [ -z "$entry" ] && continue
    rec_path="${entry%%	*}"
    found=false
    for p in "${in_template[@]:-}"; do
      if [ "$p" = "$rec_path" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = false ]; then
      ORPHAN_FILES+=("$rec_path")
    fi
  done
}

# ---- Backfill warning ----
maybe_announce_backfill() {
  if [ "$MARKER_HAS_FILES_OBJECT" = false ]; then
    BACKFILL_MODE=true
  fi
  if [ "$BACKFILL_MODE" = false ]; then
    return 0
  fi
  echo
  warn "${C_BOLD}════════════════════ BACKFILL MODE ════════════════════${C_RESET}"
  warn "${C_BOLD}This marker was created before per-file hashes existed."
  warn "${C_BOLD}Cannot detect local modifications made before this migration."
  warn "${C_BOLD}Files differing from the template are classified as TEMPLATE_UPDATED."
  warn "${C_BOLD}If you have known local modifications, REVIEW INDIVIDUALLY."
  warn "${C_BOLD}═══════════════════════════════════════════════════════${C_RESET}"
  if [ "$AUTO_APPLY" = true ]; then
    warn "--auto-apply disabled during backfill; forcing interactive review."
    AUTO_APPLY=false
  fi
  echo
}

# ---- Print findings ----
print_findings() {
  local installed_version current_version
  installed_version="${MARKER_VERSION:-unknown}"
  current_version=$(tr -d '[:space:]' < "$SOURCE_PATH/VERSION")
  echo
  info "installed: ${installed_version}    current: ${current_version}"
  printf '  template updates available:   %d\n' "${#TEMPLATE_UPDATED_FILES[@]}"
  printf '  locally modified files:       %d  (will not auto-update)\n' "${#LOCALLY_MODIFIED_FILES[@]}"
  printf '  new files in template:        %d\n' "${#NEW_FILES[@]}"
  printf '  orphans (gone from template): %d\n' "${#ORPHAN_FILES[@]}"
  if [ ${#LOCAL_MATCHES_TEMPLATE_FILES[@]} -gt 0 ]; then
    printf '  locally edited to match:      %d  (apply is a no-op)\n' "${#LOCAL_MATCHES_TEMPLATE_FILES[@]}"
  fi
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

backup_then_overwrite() {
  local src="$1" tgt="$2"
  local backup="$tgt.bak.$$"
  cp -p "$tgt" "$backup"
  cp -p "$src" "$tgt"
  ensure_exec_if_script "$tgt"
  MODIFIED+=("$tgt|$backup")
}

backup_then_delete() {
  local tgt="$1"
  local backup="$tgt.bak.$$"
  cp -p "$tgt" "$backup"
  rm -f "$tgt"
  DELETED_BACKUPS+=("$tgt|$backup")
}

# ---- Apply: NEW files ----
apply_new() {
  [ ${#NEW_FILES[@]} -eq 0 ] && return 0
  info "new files in template:"
  local rel
  for rel in "${NEW_FILES[@]}"; do
    printf '  + %s\n' "$rel"
  done
  local reply
  if [ "$AUTO_APPLY" = true ]; then
    reply="y"
  else
    printf 'Copy all? [Y/n] '
    read -r reply || reply="y"
  fi
  case "$reply" in
    n|N|no|NO) info "skipped new files"; SKIPPED_FILES=$((SKIPPED_FILES + ${#NEW_FILES[@]})); return 0 ;;
  esac
  [ "$DRY_RUN" = true ] && { APPLIED=$((APPLIED + ${#NEW_FILES[@]})); return 0; }
  local src tgt h
  for rel in "${NEW_FILES[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/$rel"
    ensure_dir "$(dirname "$tgt")"
    cp -p "$src" "$tgt"
    ensure_exec_if_script "$tgt"
    ADDED_FILES+=("$tgt")
    h=$(hash_file "$tgt")
    marker_hash_set "$rel" "$h"
    APPLIED=$((APPLIED+1))
  done
  ok "applied ${#NEW_FILES[@]} new file(s)"
}

# ---- Apply: TEMPLATE_UPDATED files ----
apply_template_updates() {
  [ ${#TEMPLATE_UPDATED_FILES[@]} -eq 0 ] && return 0
  echo
  info "template updates available (you haven't modified these):"
  local rel
  for rel in "${TEMPLATE_UPDATED_FILES[@]}"; do
    printf '  ~ %s\n' "$rel"
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
    A|a|apply) apply_all_template_updates ;;
    R|r|review) review_template_updates ;;
    *) info "skipped all template updates"; SKIPPED_FILES=$((SKIPPED_FILES + ${#TEMPLATE_UPDATED_FILES[@]})) ;;
  esac
}

apply_all_template_updates() {
  local rel src tgt h
  for rel in "${TEMPLATE_UPDATED_FILES[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/$rel"
    if [ "$DRY_RUN" = false ]; then
      backup_then_overwrite "$src" "$tgt"
      h=$(hash_file "$tgt")
      marker_hash_set "$rel" "$h"
    fi
    APPLIED=$((APPLIED+1))
  done
  ok "applied ${#TEMPLATE_UPDATED_FILES[@]} template update(s)"
}

review_template_updates() {
  local rel src tgt reply h
  for rel in "${TEMPLATE_UPDATED_FILES[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/$rel"
    echo
    info "$rel"
    while :; do
      printf '  [u]pdate  [k]eep  [d]iff  : '
      read -r reply || reply="k"
      case "$reply" in
        u|U)
          if [ "$DRY_RUN" = false ]; then
            backup_then_overwrite "$src" "$tgt"
            h=$(hash_file "$tgt")
            marker_hash_set "$rel" "$h"
          fi
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

# ---- Apply: LOCALLY_MODIFIED files ----
apply_local_modifications() {
  [ ${#LOCALLY_MODIFIED_FILES[@]} -eq 0 ] && return 0
  echo
  warn "${C_BOLD}LOCALLY MODIFIED files (changed since install) — review required:${C_RESET}"
  local rel
  for rel in "${LOCALLY_MODIFIED_FILES[@]}"; do
    printf '  ! %s\n' "$rel"
  done
  echo
  warn "These will NOT be auto-overwritten. Per-file decision:"
  if [ "$AUTO_APPLY" = true ]; then
    warn "  (--auto-apply does not apply to LOCALLY_MODIFIED files)"
  fi

  local src tgt reply h
  for rel in "${LOCALLY_MODIFIED_FILES[@]}"; do
    src=$(src_for_rel "$rel")
    tgt="$TARGET_PATH/$rel"
    echo
    warn "$rel"
    while :; do
      printf '  [K]eep your version (default)  [o]verwrite with template  [d]iff  : '
      read -r reply || reply="k"
      case "$reply" in
        ""|k|K|keep)
          SKIPPED_FILES=$((SKIPPED_FILES+1))
          break
          ;;
        o|O|overwrite)
          if [ "$DRY_RUN" = false ]; then
            backup_then_overwrite "$src" "$tgt"
            h=$(hash_file "$tgt")
            marker_hash_set "$rel" "$h"
          fi
          APPLIED=$((APPLIED+1))
          break
          ;;
        d|D|diff)
          diff -u "$tgt" "$src" || true
          ;;
      esac
    done
  done
}

# ---- Apply: ORPHANS ----
apply_orphans() {
  [ ${#ORPHAN_FILES[@]} -eq 0 ] && return 0
  echo
  info "files in marker but no longer in template:"
  local rel
  for rel in "${ORPHAN_FILES[@]}"; do
    printf '  - %s\n' "$rel"
  done
  echo
  local reply
  if [ "$AUTO_APPLY" = true ]; then
    warn "  (--auto-apply does not delete orphans)"
    reply="n"
  else
    printf 'Delete these files? [y/N] '
    read -r reply || reply="n"
  fi
  case "$reply" in
    y|Y|yes|YES)
      [ "$DRY_RUN" = true ] && return 0
      local tgt
      for rel in "${ORPHAN_FILES[@]}"; do
        tgt="$TARGET_PATH/$rel"
        [ -f "$tgt" ] && backup_then_delete "$tgt"
        marker_hash_unset "$rel"
        APPLIED=$((APPLIED+1))
      done
      ok "deleted ${#ORPHAN_FILES[@]} orphan(s)"
      ;;
    *)
      info "kept orphan files (marker entries retained)"
      SKIPPED_FILES=$((SKIPPED_FILES + ${#ORPHAN_FILES[@]}))
      ;;
  esac
}

# ---- Version marker ----
write_version_marker() {
  [ "$DRY_RUN" = true ] && return 0
  # Write if anything was applied OR if backfill happened (schema migration).
  if [ "$APPLIED" -eq 0 ] && [ "$BACKFILL_MODE" = false ]; then
    return 0
  fi
  local marker="$TARGET_PATH/.claude/.skeleton-version"
  local version commit ts
  version=$(tr -d '[:space:]' < "$SOURCE_PATH/VERSION")
  commit=$(git -C "$SOURCE_PATH" rev-parse HEAD 2>/dev/null || echo "unknown")
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local installed_at="${MARKER_INSTALLED_AT:-unknown}"
  local prev_mode="${MARKER_MODE:-merge}"
  local prev_claude_only="${MARKER_CLAUDE_ONLY:-false}"
  {
    local entry
    for entry in "${MARKER_HASH_ENTRIES[@]:-}"; do
      [ -z "$entry" ] && continue
      printf '%s\n' "$entry"
    done
  } | write_marker_json "$marker" "$version" "$commit" "$installed_at" "$prev_mode" "$prev_claude_only" "$SOURCE_PATH" "$ts"
}

summary() {
  echo
  if [ "$DRY_RUN" = true ]; then
    info "DRY RUN — no files written."
    printf '  would apply:  %d\n' "$APPLIED"
    printf '  would skip:   %d\n' "$SKIPPED_FILES"
    return 0
  fi
  ok "update complete"
  printf '  applied: %d\n' "$APPLIED"
  printf '  skipped: %d\n' "$SKIPPED_FILES"
  if [ "$BACKFILL_MODE" = true ]; then
    ok "marker migrated to per-file-hash schema (0.8.0)"
  fi
}

# ---- Main ----
parse_args "$@"
detect_json_tool
detect_sha256
resolve_skeleton_root
resolve_target_root
preflight
dump_marker
maybe_announce_backfill
classify
print_findings
if [ ${#NEW_FILES[@]} -eq 0 ] \
   && [ ${#TEMPLATE_UPDATED_FILES[@]} -eq 0 ] \
   && [ ${#LOCALLY_MODIFIED_FILES[@]} -eq 0 ] \
   && [ ${#ORPHAN_FILES[@]} -eq 0 ]; then
  ok "everything up to date"
  if [ "$BACKFILL_MODE" = true ] && [ "$DRY_RUN" = false ]; then
    write_version_marker
    ok "marker migrated to per-file-hash schema (0.8.0)"
  fi
  exit 0
fi
apply_new
apply_template_updates
apply_local_modifications
apply_orphans
write_version_marker
cleanup_backups
summary
