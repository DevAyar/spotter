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
#   - python not on PATH → log to stderr, skip telemetry, exit 0.
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

# ---- helpers ----
encode_cwd() {
  # CC encodes project dirs by replacing each of ':', '\', '/' with '-'.
  # Use sed (clearer than tr's backslash-quoting gotchas in the shell).
  # Examples:
  #   C:\Users\darre\Dev\Claude-Skeleton → C--Users-darre-Dev-Claude-Skeleton
  #   /home/u/proj                       → -home-u-proj
  printf '%s' "$1" | sed 's/[:\\/]/-/g'
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
  local encoded
  encoded=$(encode_cwd "$PROJECT_DIR")
  local primary_dir="$PROJECTS_DIR/$encoded"
  if [ -d "$primary_dir" ]; then
    find "$primary_dir" -maxdepth 1 -type f -name '*.jsonl' -printf '%T@\t%p\n' 2>/dev/null \
      | sort -rn \
      | awk 'NR==1 {print $2}'
    return
  fi
  # Fallback: scan all project dirs, pick newest JSONL whose first
  # event names $PROJECT_DIR. Bounded by maxdepth + early-break on
  # first-event match.
  [ -d "$PROJECTS_DIR" ] || return
  command -v python >/dev/null 2>&1 || return
  python - "$PROJECTS_DIR" "$PROJECT_DIR" <<'PYFALLBACK'
import json, os, sys
projects_dir, target = sys.argv[1], sys.argv[2]
candidates = []
for entry in os.scandir(projects_dir):
    if not entry.is_dir():
        continue
    for f in os.scandir(entry.path):
        if not f.name.endswith('.jsonl') or not f.is_file():
            continue
        try:
            with open(f.path, encoding='utf-8', errors='replace') as fh:
                for line in fh:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        ev = json.loads(line)
                    except Exception:
                        continue
                    if ev.get('cwd') == target:
                        candidates.append((f.stat().st_mtime, f.path))
                    break
        except OSError:
            continue
candidates.sort(reverse=True)
if candidates:
    print(candidates[0][1])
PYFALLBACK
}

# ---- main ----
if ! command -v python >/dev/null 2>&1; then
  printf '%s python not on PATH — skipping telemetry\n' "$NOTICE_PREFIX" >&2
  exit 0
fi

mkdir -p "$EVENTS_DIR" "$SESSIONS_DIR" "$OBS_DIR" 2>/dev/null || exit 0

JSONL_PATH=$(find_current_jsonl)

python - \
  "${JSONL_PATH:-}" \
  "$EVENTS_DIR" \
  "$SESSIONS_DIR" \
  "$OBS_DIR" \
  "$CAPTURES_DIR" \
  "$PROJECT_DIR" \
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
session_id = None
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
obs_path = os.path.join(obs_dir, f'token-telemetry-{session_id}.json')

# Use a fixed observation pattern_id derived from session_id so re-runs against
# the same session merge (idempotent). filename prefix is human-readable.
out = {
    'pattern_id': obs_pid,
    'source': 'session-end-telemetry',
    'pattern_type': 'token_telemetry',
    'occurrences': 1,
    'first_seen': session_start,
    'last_seen': session_end,
    'resolved_at': session_end,  # telemetry observations are point-in-time, not active patterns
    'evidence': [{
        'timestamp': session_end,
        'kind': 'session_summary',
    }],
    'confidence': 'high',
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
