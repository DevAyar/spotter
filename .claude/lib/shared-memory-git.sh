#!/usr/bin/env bash
# shared-memory-git: sourced git helpers for the Phase 47c-1 cross-project
# memory push layer. Turns a directory into a working clone of the share remote
# and provides a fail-soft commit+push with a bounded pull-rebase race net.
#
# SOURCED, never executed — no main, no top-level exit. The caller owns strict
# mode (set -uo pipefail). No model invocation; network only via git against the
# configured remote.
#
# Helpers:
#   smg_ensure_clone <remote_url> <dir>  — make <dir> a working clone (idempotent)
#   smg_pull_rebase  <dir>               — pull --rebase; skips an empty remote
#   smg_push         <dir> <message>     — stage+commit-if-changed+push, retry x3
#
# The pull-rebase-retry is a thin safety net for the push-vs-push race against a
# shared remote, NOT a merge-conflict resolver — each install writes only its own
# <uuid> paths, so rebases never hit content conflicts.

# ---- constants ----
SMG_PUSH_RETRIES=3
SMG_NOTICE="[shared-memory-git]"

# ---- helpers ----
smg_log() { printf '%s %s\n' "$SMG_NOTICE" "$*" >&2; }

# smg_url_ok <url> → 0 if the remote URL is a shape this layer will hand to
# git. (Phase 117.) The url is CONFIG-SUPPLIED — it comes back out of
# share-config.json on every later push — and git's transport layer treats
# some shapes as code: an `ext::` URL EXECUTES an arbitrary command, every
# other `scheme::` form invokes a transport helper, and a leading dash
# parses as an option. Allowlist, not blocklist:
#   https://…            (hosted remotes)
#   ssh://…              (explicit ssh)
#   user@host:path       (SCP form)
#   file://… , /abs/path , C:/drive/path  (local + network-drive remotes;
#                         no command execution — and the share test suite's
#                         own remotes are bare absolute paths)
# Everything else is rejected, including plain http:// (credentials and
# capture payloads in the clear). Callers print the reason; this returns.
smg_url_ok() {
  local u="$1"
  case "$u" in
    -*)                       return 1 ;;  # option injection
    *::*)                     return 1 ;;  # ext:: and every transport helper
    https://*|ssh://*)        return 0 ;;
    file://*)                 return 0 ;;
    /*)                       return 0 ;;  # absolute path (POSIX)
    [A-Za-z]:/*|[A-Za-z]:\\*) return 0 ;;  # absolute path (Windows drive)
    *://*)                    return 1 ;;  # any other scheme (http, git, ftp…)
    *@*:*)                    return 0 ;;  # SCP form user@host:path
    *)                        return 1 ;;
  esac
}

# smg_is_clone <dir> → 0 if <dir> is itself a clone root (owns a .git dir).
# Deliberately checks <dir>/.git rather than `rev-parse --is-inside-work-tree`:
# the latter returns true for a plain/empty <dir> nested inside a PARENT repo
# (e.g. the project itself), which would make ensure_clone skip cloning and let
# later git ops fall through to the parent repo — catastrophic.
smg_is_clone() { [ -d "$1/.git" ]; }

# smg_remote_has_commits <dir> → 0 if origin has at least one branch (non-empty).
smg_remote_has_commits() { git -C "$1" ls-remote --heads origin 2>/dev/null | grep -q .; }

# smg_ensure_clone <remote_url> <dir>: idempotent. (a) already a clone → no-op;
# (b) absent/empty dir → plain clone; (c) populated dir → clone to a temp dir,
# graft its .git into <dir>, then reset --mixed so the pre-existing files show as
# uncommitted changes ("fold in any files already present"). Fail-soft: returns
# non-zero on failure, never raises.
smg_ensure_clone() {
  local url="$1" dir="$2" tmp
  command -v git >/dev/null 2>&1 || { smg_log "git not on PATH"; return 1; }
  [ -n "$url" ] || { smg_log "no remote url"; return 1; }
  smg_url_ok "$url" || { smg_log "remote url rejected (allowed: https://, ssh://, user@host:path, file://, absolute path): $url"; return 1; }
  smg_is_clone "$dir" && return 0
  if [ ! -e "$dir" ] || [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
    mkdir -p "$dir" 2>/dev/null || return 1
    git clone --quiet -- "$url" "$dir" 2>/dev/null && return 0
    smg_log "clone into empty dir failed: $url"; return 1
  fi
  tmp="$(mktemp -d 2>/dev/null)" || return 1
  if ! git clone --quiet -- "$url" "$tmp" 2>/dev/null; then
    smg_log "clone to temp failed: $url"; rm -rf "$tmp"; return 1
  fi
  mv "$tmp/.git" "$dir/.git" 2>/dev/null || { rm -rf "$tmp"; return 1; }
  rm -rf "$tmp"
  if git -C "$dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    git -C "$dir" reset --mixed --quiet HEAD 2>/dev/null || true
  fi
  return 0
}

# smg_pull_rebase <dir>: pull --rebase from origin when the remote has commits;
# skip silently on an empty remote (no upstream yet). Fail-soft.
smg_pull_rebase() {
  smg_is_clone "$1" || return 1
  smg_remote_has_commits "$1" || return 0
  git -C "$1" pull --rebase --quiet origin HEAD 2>/dev/null \
    || { smg_log "pull --rebase failed (fail-soft)"; return 1; }
}

# smg_push <dir> <commit_message>: stage everything, commit if there are staged
# changes, then push. On a non-fast-forward rejection, pull --rebase and retry,
# bounded at SMG_PUSH_RETRIES. Fail-soft: log + return non-zero on final failure,
# never raise. Thin race net, NOT a merge resolver.
smg_push() {
  local d="$1" msg="$2" attempt=1
  smg_is_clone "$d" || { smg_log "not a clone: $d"; return 1; }
  # Ensure a commit identity exists in the clone (CI runners have none global).
  git -C "$d" config user.email >/dev/null 2>&1 || git -C "$d" config user.email "share@claude-skeleton.local"
  git -C "$d" config user.name  >/dev/null 2>&1 || git -C "$d" config user.name  "claude-skeleton share"
  git -C "$d" add -A 2>/dev/null || return 1
  if ! git -C "$d" diff --cached --quiet 2>/dev/null; then
    git -C "$d" commit --quiet -m "$msg" 2>/dev/null || { smg_log "commit failed"; return 1; }
  fi
  while [ "$attempt" -le "$SMG_PUSH_RETRIES" ]; do
    git -C "$d" push --quiet origin HEAD 2>/dev/null && return 0
    smg_log "push rejected ($attempt/$SMG_PUSH_RETRIES) — pull --rebase + retry"
    smg_remote_has_commits "$d" && git -C "$d" pull --rebase --quiet origin HEAD 2>/dev/null || true
    attempt=$((attempt + 1))
  done
  smg_log "push failed after $SMG_PUSH_RETRIES attempts (fail-soft)"
  return 1
}
