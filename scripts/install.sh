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

# Per-file install hashes: one "<relpath><TAB><sha256>" entry per non-top file copied/overwritten.
# Feeds BOTH marker maps, which are byte-identical at install time:
#   - raw_template_baselines : immutable "template version this file was installed from" (Phase 52).
#     update.sh classifies against THIS field.
#   - files                  : DEPRECATED back-compat alias (an old update.sh still reads it).
#                              Mutated by update.sh over time; removal queued for v1.5+.
INSTALLED_HASHES=()

# JSON parsing tool (detected at startup)
JSON_TOOL=""

# SHA-256 command (detected at startup — sha256sum on Linux/Git Bash, shasum -a 256 on macOS)
SHA256_CMD=""

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

# gen_uuid → a UUID v4 on stdout (Python stdlib; no new dependency).
gen_uuid() {
  "$JSON_TOOL" -c 'import uuid; print(uuid.uuid4())'
}

# ---- SHA-256 helpers ----
detect_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CMD="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
  else
    die "sha256sum or shasum required (neither found on PATH)"
  fi
}

# sha256_of <path> → 64-char hex hash on stdout
sha256_of() {
  $SHA256_CMD "$1" 2>/dev/null | awk '{print $1}'
}

# record_installed_hash <absolute-target-path>
# Records "<relpath-from-target><TAB><sha256>" into INSTALLED_HASHES.
record_installed_hash() {
  local tgt="$1"
  local rel hash
  rel="${tgt#$TARGET_PATH/}"
  hash=$(sha256_of "$tgt")
  [ -n "$hash" ] || die "sha256 failed for $tgt"
  INSTALLED_HASHES+=("$rel"$'\t'"$hash")
}

# Marker `source` provenance, recorded in PORTABLE form so tracked dogfood
# markers never embed a machine path (pre-publication hygiene):
# self-install -> "<self>", under-HOME -> "~/...", already-portable values
# pass through, else as-is. One consumer exists: update.sh's one-time
# raw-baseline migration uses it as a repo fallback and expands the
# portable forms back before use.
portable_source_path() {
  local src="$1" tgt="$2"
  case "$src" in
    '<self>'|'~'*) printf '%s' "$src"; return ;;
  esac
  # Canonicalize when the dir exists so Windows-form (C:/...) and MSYS-form
  # (/c/...) spellings of the same path compare equal.
  local csrc
  csrc=$(cd "$src" 2>/dev/null && pwd -P) || csrc="$src"
  if [ -n "$tgt" ] && [ "$csrc" = "$tgt" ]; then
    printf '<self>'; return
  fi
  case "$csrc" in
    "$HOME"/*) printf '~%s' "${csrc#"$HOME"}"; return ;;
  esac
  printf '%s' "$src"
}

# write_marker_json <file> <version> <commit> <installed_at> <mode> <claude_only> <source> <updated_at_or_empty> <cached_skeleton_head_or_empty> <cached_skeleton_head_fetched_at_or_empty>
# Reads TAB-separated lines from stdin, tagged by destination map:
#   "F<TAB><relpath><TAB><hash>"  -> files (DEPRECATED back-compat)
#   "R<TAB><relpath><TAB><hash>"  -> raw_template_baselines (Phase 52, classification source)
# A 2-field "<relpath><TAB><hash>" line (no tag) is treated as files for safety.
# Atomic: writes to <file>.tmp.$$ then mv.
write_marker_json() {
  local file="$1" version="$2" commit="$3" installed_at="$4" mode="$5" claude_only="$6" source="$7" updated_at="$8"
  local cached_head="${9:-}" cached_fetched_at="${10:-}"
  local install_uuid="${11:-}" install_label="${12:-}" install_created="${13:-}"
  local tmp="${file}.tmp.$$"
  "$JSON_TOOL" -c '
import json, sys
files = {}
raw = {}
for line in sys.stdin:
    line = line.rstrip("\r\n")
    if not line: continue
    parts = line.split("\t")
    if len(parts) == 3:
        tag, p, h = parts
        (raw if tag == "R" else files)[p] = h
    elif len(parts) == 2:
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
out["cached_skeleton_head"] = sys.argv[8] if sys.argv[8] else None
out["cached_skeleton_head_fetched_at"] = sys.argv[9] if sys.argv[9] else None
if sys.argv[10]:
    out["install_uuid"] = sys.argv[10]
if sys.argv[11]:
    out["install_label"] = sys.argv[11]
if sys.argv[12]:
    out["install_created"] = sys.argv[12]
out["files"] = files
out["raw_template_baselines"] = raw
with open(sys.argv[13], "w", newline="\n") as f:
    json.dump(out, f, indent=2, sort_keys=True)
    f.write("\n")
' "$version" "$commit" "$installed_at" "$mode" "$claude_only" "$source" "$updated_at" "$cached_head" "$cached_fetched_at" "$install_uuid" "$install_label" "$install_created" "$tmp" || { rm -f "$tmp"; return 1; }
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

  # Phase 62: install.sh is first-install only. A marker means an existing
  # install; re-running would mint a new install identity (uuid) and reset
  # per-file baselines to only the files copied this run — silently breaking
  # update.sh classification and orphaning shared-memory history.
  if [ -f "$TARGET_PATH/.claude/.skeleton-version" ]; then
    die "target already has a claude-skeleton install (.claude/.skeleton-version present).
install.sh is for first-time installs only — re-running it would mint a new install identity and reset per-file baselines.
To update this install, run:  bash scripts/update.sh --target $TARGET_PATH
If a from-scratch reinstall is genuinely intended: delete .claude/.skeleton-version first and re-run — be aware this mints a new install identity, resets baselines, and orphans any shared-memory history keyed to the old uuid."
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
      [ "$top" != "top" ] && record_installed_hash "$tgt"
      OVERWRITTEN=$((OVERWRITTEN+1))
      ;;
    copy)
      ensure_dir "$(dirname "$tgt")"
      cp -p "$src" "$tgt"
      ensure_exec_if_script "$tgt"
      ADDED_FILES+=("$tgt")
      [ "$top" != "top" ] && record_installed_hash "$tgt"
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
  # Install identity (Phase 47a): generated once at fresh install, immutable
  # thereafter. install_label defaults to the target dir basename (user-editable
  # later); install_created stamps the first write. update.sh backfills these for
  # pre-47a markers and never regenerates them.
  local install_uuid install_label install_created
  install_uuid=$(gen_uuid)
  install_label=$(basename "$TARGET_PATH")
  install_created="$ts"
  ensure_dir "$TARGET_PATH/.claude"
  local marker_existed=false
  [ -f "$marker" ] && marker_existed=true
  # Emit each install hash to BOTH maps: F (files, deprecated) and R (raw_template_baselines).
  # They are identical at install time — raw template content as just copied.
  {
    local entry
    for entry in "${INSTALLED_HASHES[@]:-}"; do
      [ -z "$entry" ] && continue
      printf 'F\t%s\n' "$entry"
      printf 'R\t%s\n' "$entry"
    done
  } | write_marker_json "$marker" "$version" "$commit" "$ts" "$MODE" "$CLAUDE_ONLY" "$(portable_source_path "$SOURCE_PATH" "$TARGET_PATH")" "" "" "" "$install_uuid" "$install_label" "$install_created"
  if [ "$marker_existed" = false ]; then
    ADDED_FILES+=("$marker")
  fi
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
  # Phase 72: the post-install moment is when the user is most oriented —
  # real counts, one place to read, one first move, one honest reassurance.
  local n_agents n_skills n_scripts n_commands n_hooks
  n_agents=$(find "$TARGET_PATH/.claude/agents" -name '*.md' ! -name '*.schema.md' 2>/dev/null | wc -l | tr -d ' ')
  n_skills=$(find "$TARGET_PATH/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  n_scripts=$(find "$TARGET_PATH/.claude/scripts" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
  n_commands=$(find "$TARGET_PATH/.claude/commands" -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
  n_hooks=$(find "$TARGET_PATH/.claude/hooks" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
  printf 'What landed: %s agents, %s skills, %s scripts, %s slash commands, %s hooks.\n' \
    "$n_agents" "$n_skills" "$n_scripts" "$n_commands" "$n_hooks"
  printf 'Nothing here runs anything without your approval; every protection has a stated off-switch.\n'
  echo
  printf 'Read next:  %s/docs/GETTING-STARTED.md\n' "$SOURCE_PATH"
  printf '            (or https://github.com/DevAyar/claude-skeleton/blob/main/docs/GETTING-STARTED.md)\n'
  printf 'First move: /goals <a real small goal>  - research, one round of questions, then a\n'
  printf '            draft spec in .claude/specs/ that waits for YOUR approval.\n'
  printf 'Plugins:    ask for the plugin manifest - plugin-discovery drafts it with evidence, you review, /plugin installs by hand.\n'
  if [ "$CLAUDE_ONLY" = false ]; then
    printf 'Then:       dispatch project-tuner-helper to fill placeholders and tune to this project.\n'
  fi
  printf 'Mechanics:  docs/INSTALLATION.md (update / uninstall).\n'
}

# ---- Main ----
parse_args "$@"
detect_json_tool
detect_sha256
resolve_skeleton_root
resolve_target_root
preflight
confirm_replace
[ "$DRY_RUN" = true ] && info "DRY RUN — planned operations:"
plan_and_execute
write_version_marker
# Phase 73: drop the gitignored first-run flag — the SessionStart rules
# chain consumes it exactly once to print the welcome. update.sh never
# creates it, so existing installs never see the welcome. Runtime state
# outside the template inventory: cannot perturb classification.
if [ "$DRY_RUN" = false ]; then
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$TARGET_PATH/.claude/.first-run" 2>/dev/null || true
fi
summary
