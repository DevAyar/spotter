#!/usr/bin/env bash
# generate-session-telemetry: SessionEnd telemetry collector.
#
# Invoked by sessionend-observe.sh. Parses the current session's JSONL
# transcript at ~/.claude/projects/<encoded-cwd>/<session-id>.jsonl,
# extracts per-turn token usage from message.usage fields, and writes
# three artifacts in one shot:
#
#   1. .claude/telemetry/events/<session_id>.jsonl
#      One line per tool call: timestamp, tool_name, tokens_in,
#      tokens_out, target_resource. tokens_* are turn-level (CC does
#      not expose per-tool breakdown), shared across tools in the same
#      assistant turn. Per-tool granularity is a CC instrumentation
#      gap; turn-level is the only honest signal today.
#
#   2. .claude/telemetry/sessions/<session_id>.md
#      Per-session markdown rollup with YAML frontmatter (totals + the
#      useful_unit metrics) and a human-readable narrative body.
#
#   3. .claude/observations/token-telemetry-<session_id>.json
#      Schema-conformant observation file. pattern_type: token_telemetry,
#      source: session-end-telemetry, privacy_class: safe-to-share,
#      target_resource: session:<session_id>.
#
# Useful unit definition (Phase 45 CORE 12 — usefulness-is-the-floor):
#   useful_units_shipped  = count of git commits with author-date in the
#                           session window
#   useful_units_drafted  = count of files in .claude/captures/ with
#                           mtime in the session window
#   tokens_per_useful_unit = (total_in + total_out) / max(1, shipped + drafted)
#
# Graceful degradation:
#   - No transcript JSONL found → write stub rollup with
#     data_available: false; observation written with null token fields.
#   - no WORKING python/python3 on PATH (a presence-only probe would
#     accept the Windows Store alias stub) → log to stderr, skip
#     telemetry, exit 0.
#   - jq not on PATH → still works (Python writes JSON directly).
#   - usage field absent on a turn → that turn's tokens are null
#     (not omitted from the running totals as 0; they're left out of the
#     average to avoid biasing tokens_per_useful_unit).
#
# Always exits 0 — telemetry MUST NOT block the SessionEnd hook chain.

set -uo pipefail

# ---- constants ----
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
TELEMETRY_DIR="$PROJECT_DIR/.claude/telemetry"
EVENTS_DIR="$TELEMETRY_DIR/events"
SESSIONS_DIR="$TELEMETRY_DIR/sessions"
OBS_DIR="$PROJECT_DIR/.claude/observations"
CAPTURES_DIR="$PROJECT_DIR/.claude/captures"
PROJECTS_DIR="${CLAUDE_PROJECTS_DIR_OVERRIDE:-${HOME}/.claude/projects}"
NOTICE_PREFIX="[generate-session-telemetry]"
# python||python3, validated by EXECUTION not presence: stock macOS and
# Debian/Ubuntu ship python3 only, and the Windows Store publishes a
# python/python3 execution-alias stub that passes `command -v` but exits
# nonzero — either way a presence-only probe silently no-ops this script
# (the Phase 57 silent-inert class; ported from task-watchdog.sh, Phase 63).
PYBIN=""
for _cand in python python3; do
  if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then
    PYBIN="$_cand"
    break
  fi
done

# ---- helpers ----
# encode_cwd <absolute-path>
# Mirrors Claude Code's project-dir encoding: EVERY non-alphanumeric
# character becomes `-` (so C:\Users\x -> C--Users-x, and a dotted dir
# like .claude-mem -> -claude-mem). A Git-Bash form (/c/Users/x) is
# normalized to drive form FIRST — on Windows the hook receives
# CLAUDE_PROJECT_DIR in Git-Bash form, and encoding it raw yields
# `-c-Users-x`, which matches nothing (the Phase 57 diagnosis; this lib
# carried the pre-57 narrow `[:\\/]` class until Phase 63). Known
# ambiguity: a genuine Unix path with a single-letter top dir (/x/proj)
# is misread as a drive; the cwd-match fallback rescues that case.
encode_cwd() {
  local p="$1"
  case "$p" in
    /[A-Za-z]/*)
      local drive="${p:1:1}"
      p="$(printf '%s' "$drive" | tr '[:lower:]' '[:upper:]'):${p:2}"
      ;;
  esac
  printf '%s' "$p" | sed 's/[^A-Za-z0-9]/-/g'
}

# find_current_jsonl: emit the path of the NEWEST JSONL whose `cwd`
# field matches PROJECT_DIR. Differs from task-watchdog's lookup
# (which takes NR==2 / second-newest) because we want the current
# session, not the prior one.
#
# Primary path: encode PROJECT_DIR and look it up directly in
# ~/.claude/projects/<encoded>. Fallback path: scan all project dirs
# and match by JSONL's first event's `cwd` field — handles path-shape
# divergence between hook context and tested env.
find_current_jsonl() {
  # Phase 46b: prefer env-supplied paths over mtime heuristic. The
  # heuristic races with CC's next-session placeholder creation —
  # find sees the just-created empty *.jsonl as newest, returns it,
  # python parses nothing, session_id falls through to "unknown-...".
  # sessionend-observe.sh now exports session_id + transcript_path
  # from CC's stdin payload before invoking us.
  if [ -n "${CLAUDE_HOOK_TRANSCRIPT_PATH:-}" ] && [ -f "$CLAUDE_HOOK_TRANSCRIPT_PATH" ]; then
    printf '%s\n' "$CLAUDE_HOOK_TRANSCRIPT_PATH"
    return
  fi
  local encoded
  encoded=$(encode_cwd "$PROJECT_DIR")
  if [ -n "${CLAUDE_HOOK_SESSION_ID:-}" ]; then
    local path_by_id="$PROJECTS_DIR/$encoded/$CLAUDE_HOOK_SESSION_ID.jsonl"
    if [ -f "$path_by_id" ]; then
      printf '%s\n' "$path_by_id"
      return
    fi
  fi
  local primary_dir="$PROJECTS_DIR/$encoded"
  if [ -d "$primary_dir" ]; then
    # Portable newest-first (find -printf is GNU-only; macOS lacks it).
    # ls -t is line-based: fine for per-file lines, pathological only for
    # filenames containing newlines. Only return on a hit — an existing
    # but empty dir must fall through to the cwd-match fallback (the old
    # unconditional return made the fallback unreachable, Phase 63).
    local newest
    newest=$(ls -1t "$primary_dir"/*.jsonl 2>/dev/null | head -n 1)
    if [ -n "$newest" ]; then
      printf '%s\n' "$newest"
      return
    fi
  fi
  # Fallback: scan all project dirs, pick the newest JSONL whose early
  # events name $PROJECT_DIR. Real transcripts don't carry `cwd` on the
  # FIRST line (Phase 57 diagnosis: first lines are summary/meta events),
  # so scan a bounded number of lines; paths are compared normalized
  # (drive form, forward slashes, case-folded) so Git-Bash and Windows
  # forms match.
  [ -d "$PROJECTS_DIR" ] || return
  [ -n "$PYBIN" ] || return
  "$PYBIN" - "$PROJECTS_DIR" "$PROJECT_DIR" <<'PYFALLBACK'
import json, os, re, sys
projects_dir, target = sys.argv[1], sys.argv[2]

def norm(p):
    if not isinstance(p, str): return ''
    p = p.replace('\\', '/')
    m = re.match(r'^/([A-Za-z])/(.*)$', p)      # /c/Users/x -> C:/Users/x
    if m: p = m.group(1).upper() + ':/' + m.group(2)
    return p.rstrip('/').lower()

target_n = norm(target)
candidates = []
for entry in os.scandir(projects_dir):
    if not entry.is_dir(): continue
    try:
        files = list(os.scandir(entry.path))
    except OSError:
        continue                     # one unreadable project dir must not abort the scan
    for f in files:
        if not f.name.endswith('.jsonl') or not f.is_file(): continue
        try:
            with open(f.path, encoding='utf-8', errors='replace') as fh:
                for i, line in enumerate(fh):
                    if i >= 40: break            # bounded scan for a cwd event
                    line = line.strip()
                    if not line: continue
                    try:
                        ev = json.loads(line)
                    except Exception:
                        continue
                    if 'cwd' in ev:
                        if norm(ev.get('cwd')) == target_n:
                            candidates.append((f.stat().st_mtime, f.path))
                        break                    # first cwd event settles it
        except OSError:
            continue
candidates.sort(reverse=True)
if candidates:
    print(candidates[0][1])
PYFALLBACK
}

# ---- main ----
if [ -z "$PYBIN" ]; then
  printf '%s no working python/python3 on PATH — skipping telemetry\n' "$NOTICE_PREFIX" >&2
  exit 0
fi

mkdir -p "$EVENTS_DIR" "$SESSIONS_DIR" "$OBS_DIR" 2>/dev/null || exit 0

JSONL_PATH=$(find_current_jsonl)
# Fail-soft, but not fail-silent: if transcripts exist yet resolution
# missed, surface ONE line before writing the documented stub — an
# unresolvable transcript dir stayed invisible for eight weeks before
# Phase 57 caught the same class in task-watchdog.
if { [ -z "$JSONL_PATH" ] || [ ! -f "$JSONL_PATH" ]; } \
   && [ -d "$PROJECTS_DIR" ] \
   && find "$PROJECTS_DIR" -maxdepth 2 -name '*.jsonl' -print -quit 2>/dev/null | grep -q .; then
  printf '%s transcript not resolved for %s under %s — writing stub telemetry (check project-dir encoding)\n' \
    "$NOTICE_PREFIX" "$PROJECT_DIR" "$PROJECTS_DIR" >&2
fi

"$PYBIN" - \
  "${JSONL_PATH:-}" \
  "$EVENTS_DIR" \
  "$SESSIONS_DIR" \
  "$OBS_DIR" \
  "$CAPTURES_DIR" \
  "$PROJECT_DIR" \
  "${CLAUDE_HOOK_SESSION_ID:-}" \
  2>/dev/null <<'PYIMPL'
import hashlib, json, os, re, subprocess, sys
from collections import Counter, defaultdict
from datetime import datetime, timezone

jsonl_path = sys.argv[1] or ''
events_dir = sys.argv[2]
sessions_dir = sys.argv[3]
obs_dir = sys.argv[4]
captures_dir = sys.argv[5]
project_dir = sys.argv[6]
# Phase 46b: hook exports CLAUDE_HOOK_SESSION_ID from CC's stdin payload;
# bash passes it through as argv[7]. Prefer it over first-event discovery
# below — the JSONL we're parsing might be empty (race) or, in the legacy
# mtime-heuristic path, the wrong session entirely.
env_session_id = sys.argv[7] if len(sys.argv) > 7 else ''

def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def parse_iso(s):
    if not s:
        return None
    try:
        # Strip Z and parse as UTC
        s2 = s.rstrip('Z')
        return datetime.fromisoformat(s2).replace(tzinfo=timezone.utc)
    except Exception:
        return None

# ---- discover session_id from transcript (or fall back) ----
session_id = env_session_id or None
session_start = None
session_end = now_iso()
turns = []  # list of {timestamp, usage, tool_uses=[{name, input}]}
data_available = False

if jsonl_path and os.path.isfile(jsonl_path):
    try:
        with open(jsonl_path, encoding='utf-8', errors='replace') as f:
            for raw in f:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    ev = json.loads(raw)
                except Exception:
                    continue
                if session_id is None and ev.get('sessionId'):
                    session_id = ev['sessionId']
                if session_start is None and ev.get('timestamp'):
                    session_start = ev['timestamp']
                if ev.get('type') != 'assistant':
                    continue
                if ev.get('isSidechain') is True:
                    # Subagent turns — counted separately, not in main totals.
                    pass  # for now, lump into main; refinement deferred to follow-up
                msg = ev.get('message') or {}
                usage = (msg.get('usage') or {})
                tool_uses = []
                for block in (msg.get('content') or []):
                    if isinstance(block, dict) and block.get('type') == 'tool_use':
                        tool_uses.append({
                            'name': block.get('name', ''),
                            'input': block.get('input') or {},
                        })
                turns.append({
                    'timestamp': ev.get('timestamp', ''),
                    'usage': usage,
                    'tool_uses': tool_uses,
                    'is_sidechain': ev.get('isSidechain') is True,
                })
        data_available = True
    except OSError:
        data_available = False

if session_id is None:
    # Fallback: derive a session_id from current timestamp. Telemetry still
    # gets written, just without transcript-derived data.
    session_id = 'unknown-' + datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
if session_start is None:
    session_start = session_end

# ---- compute target_resource from a tool_use ----
def derive_target_resource(tool_name, tool_input):
    if not isinstance(tool_input, dict):
        return None
    if tool_name in ('Read', 'Edit', 'Write', 'NotebookEdit'):
        fp = tool_input.get('file_path')
        if fp:
            return f'file:{os.path.basename(fp)}'
    if tool_name == 'Bash':
        cmd = tool_input.get('command', '')
        if cmd:
            first = cmd.strip().split(None, 1)[0] if cmd.strip() else ''
            if first.endswith('.sh') or '/' in first:
                return f'script:{os.path.basename(first)}'
            return 'tool:Bash'
    if tool_name == 'Agent':
        st = tool_input.get('subagent_type')
        if st:
            return f'agent:{st}'
    if tool_name == 'Skill':
        sk = tool_input.get('skill')
        if sk:
            return f'skill:{sk}'
    return None

# ---- write per-event JSONL ----
events_path = os.path.join(events_dir, f'{session_id}.jsonl')
total_in = 0
total_out = 0
total_cache_creation = 0
total_cache_read = 0
turns_with_usage = 0
tool_counter = Counter()
top_turns = []  # (total_tokens, timestamp, tool_names)
subagent_dispatches = []  # (timestamp, agent_type, tokens)

try:
    with open(events_path, 'w', encoding='utf-8', newline='\n') as ef:
        for turn in turns:
            ts = turn['timestamp']
            usage = turn['usage'] or {}
            tin = usage.get('input_tokens')
            tout = usage.get('output_tokens')
            tcache_in = usage.get('cache_creation_input_tokens') or 0
            tcache_read = usage.get('cache_read_input_tokens') or 0
            if isinstance(tin, int):
                total_in += tin
                turns_with_usage += 1
            if isinstance(tout, int):
                total_out += tout
            if isinstance(tcache_in, int):
                total_cache_creation += tcache_in
            if isinstance(tcache_read, int):
                total_cache_read += tcache_read

            turn_total = (tin or 0) + (tout or 0)
            tool_names = [t['name'] for t in turn['tool_uses'] if t.get('name')]
            if tool_names:
                top_turns.append((turn_total, ts, tool_names))

            for tu in turn['tool_uses']:
                tool_counter[tu['name']] += 1
                tr = derive_target_resource(tu['name'], tu['input'])
                if tu['name'] == 'Agent' and tr:
                    subagent_dispatches.append((turn_total, ts, tr.replace('agent:', '')))
                entry = {
                    'timestamp': ts,
                    'tool_name': tu['name'],
                    'tokens_in': tin,
                    'tokens_out': tout,
                }
                if tr:
                    entry['target_resource'] = tr
                ef.write(json.dumps(entry, sort_keys=True) + '\n')
except OSError:
    pass

# ---- useful unit metrics ----
def count_commits_in_window(start_iso, end_iso):
    if not start_iso or not end_iso:
        return 0
    try:
        result = subprocess.run(
            ['git', '-C', project_dir, 'log',
             f'--since={start_iso}', f'--until={end_iso}',
             '--pretty=%h'],
            capture_output=True, text=True, timeout=10,
        )
        if result.returncode != 0:
            return 0
        lines = [l for l in result.stdout.splitlines() if l.strip()]
        return len(lines)
    except Exception:
        return 0

def count_captures_in_window(start_iso, end_iso):
    if not os.path.isdir(captures_dir):
        return 0
    start_dt = parse_iso(start_iso)
    end_dt = parse_iso(end_iso)
    if not (start_dt and end_dt):
        return 0
    count = 0
    for entry in os.scandir(captures_dir):
        if not entry.is_file():
            continue
        if not entry.name.endswith('.md'):
            continue
        try:
            mtime = datetime.fromtimestamp(entry.stat().st_mtime, tz=timezone.utc)
        except OSError:
            continue
        if start_dt <= mtime <= end_dt:
            count += 1
    return count

useful_shipped = count_commits_in_window(session_start, session_end)
useful_drafted = count_captures_in_window(session_start, session_end)
useful_total = max(1, useful_shipped + useful_drafted)
# Total tokens processed = raw input + cache (read + creation) + output. All
# four count as model effort even though cache reads are billed cheaply.
# CORE 11 (token-cost-as-design-driver) is about consumption, not billing.
total_processed = total_in + total_cache_read + total_cache_creation + total_out
tokens_per_useful = total_processed / useful_total

# ---- write per-session markdown rollup ----
def fmt_int(n):
    return f'{n:,}' if isinstance(n, int) else str(n)

rollup_path = os.path.join(sessions_dir, f'{session_id}.md')
top_turns.sort(reverse=True)
subagent_dispatches.sort(reverse=True)

try:
    with open(rollup_path, 'w', encoding='utf-8', newline='\n') as rf:
        rf.write('---\n')
        rf.write(f'session_id: {session_id}\n')
        rf.write(f'started: {session_start}\n')
        rf.write(f'ended: {session_end}\n')
        rf.write(f'total_tokens_in: {total_in}\n')
        rf.write(f'total_tokens_out: {total_out}\n')
        rf.write(f'total_cache_creation: {total_cache_creation}\n')
        rf.write(f'total_cache_read: {total_cache_read}\n')
        rf.write(f'turns_with_usage: {turns_with_usage}\n')
        rf.write(f'useful_units_shipped: {useful_shipped}\n')
        rf.write(f'useful_units_drafted: {useful_drafted}\n')
        rf.write(f'tokens_per_useful_unit: {tokens_per_useful:.1f}\n')
        rf.write(f'data_available: {str(data_available).lower()}\n')
        rf.write('---\n\n')
        rf.write(f'# Session {session_id}\n\n')
        if not data_available:
            rf.write('_No transcript data found at SessionEnd — this rollup is a stub. '
                     'See `data_available: false` in frontmatter._\n')
        else:
            rf.write(f'Window: `{session_start}` → `{session_end}`\n\n')
            rf.write(f'**Tokens:** {fmt_int(total_in)} in + {fmt_int(total_out)} out '
                     f'(cache: {fmt_int(total_cache_read)} read, '
                     f'{fmt_int(total_cache_creation)} create)\n\n')
            rf.write(f'**Useful units shipped this session:** {useful_shipped} commits + '
                     f'{useful_drafted} captures drafted → {tokens_per_useful:,.0f} tokens '
                     f'per useful unit.\n\n')
            rf.write('## Tool usage\n\n')
            rf.write('| Tool | Calls |\n|---|---|\n')
            for tool, count in tool_counter.most_common():
                rf.write(f'| `{tool}` | {count} |\n')
            rf.write('\n## Top 5 expensive turns\n\n')
            for tt, ts, names in top_turns[:5]:
                rf.write(f'- `{ts}` — {fmt_int(tt)} tokens — tools: '
                         f'{", ".join(f"`{n}`" for n in names)}\n')
            if subagent_dispatches:
                rf.write('\n## Top 5 subagent dispatches\n\n')
                for tt, ts, agent in subagent_dispatches[:5]:
                    rf.write(f'- `{ts}` — {fmt_int(tt)} tokens — `{agent}`\n')
except OSError:
    pass

# ---- write token-telemetry observation ----
obs_pid = hashlib.sha256(('token_telemetry\n' + session_id).encode('utf-8')).hexdigest()
# Schema rule (session-observer.schema.md :17): the filename IS
# <pattern_id>.json. The old human-readable token-telemetry-<session_id>.json
# prefix violated it (fixed Phase 65); target_resource keeps the session
# identification. pattern_id stays sha256(pattern_type + signature), so
# re-runs against the same session merge (idempotent).
obs_path = os.path.join(obs_dir, f'{obs_pid}.json')

if data_available and turns_with_usage > 0:
    ev_summary = f'session {session_id[:8]}: {total_in} in / {total_out} out across {turns_with_usage} turns'
else:
    ev_summary = 'no transcript data at SessionEnd - stub emission'
out = {
    'pattern_id': obs_pid,
    'source': 'session-end-telemetry',
    'pattern_type': 'token_telemetry',
    'occurrences': 1,
    'first_seen': session_start,
    'last_seen': session_end,
    # Point-in-time, session-bounded producer: emits null and never resolves
    # (schema resolution-lifecycle asymmetry list, registered Phase 65).
    'resolved_at': None,
    'evidence': [{
        'timestamp': session_end,
        'kind': 'session_summary',
        'summary': ev_summary[:120],
    }],
    'confidence': 'high' if (data_available and turns_with_usage > 0) else 'low',
    'privacy_class': 'safe-to-share',
    'target_resource': f'session:{session_id}',
    'total_tokens_in': total_in if turns_with_usage > 0 else None,
    'total_tokens_out': total_out if turns_with_usage > 0 else None,
    'total_cache_creation': total_cache_creation if turns_with_usage > 0 else None,
    'total_cache_read': total_cache_read if turns_with_usage > 0 else None,
    'turns_with_usage': turns_with_usage,
    'useful_units_shipped': useful_shipped,
    'useful_units_drafted': useful_drafted,
    'tokens_per_useful_unit': round(tokens_per_useful, 2),
    'data_available': data_available,
}

try:
    tmp = obs_path + f'.tmp.{os.getpid()}'
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(out, f, indent=2, sort_keys=True)
        f.write('\n')
    os.replace(tmp, obs_path)
except OSError:
    pass

PYIMPL

# ---- cleanup ----
exit 0
