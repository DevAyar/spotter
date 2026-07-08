#!/usr/bin/env bash
# task-watchdog: retrospective observer of the prior Claude Code
# session. Reads the prior session's JSONL transcript at
# ~/.claude/projects/<encoded-cwd>/<session-id>.jsonl, detects
# long-running bash calls and recurring failures, and writes
# observation files to .claude/observations/ using session-observer's
# schema. Invoked by sessionstart-rules.sh after drift-check.sh; also
# manually dispatchable. Retrospective only — NEVER polls live,
# NEVER hits the network, NEVER writes outside .claude/observations/.
# Idempotent via .last-watchdog-session marker. Always exits 0 so the
# SessionStart hook chain never blocks.

set -uo pipefail

# ---- constants ----
DURATION_THRESHOLD_MS=300000        # 5 minutes — bash calls exceeding this are flagged.
FAILURE_OCCURRENCE_THRESHOLD=3      # same error signature this many times → emit observation.
EVIDENCE_CAP=20                     # schema rule — keep most recent N evidence entries.

OBS_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/observations"
LAST_SESSION_MARKER="$OBS_DIR/.last-watchdog-session"
# CLAUDE_PROJECTS_DIR_OVERRIDE lets tests point at a fixture tree.
PROJECTS_DIR="${CLAUDE_PROJECTS_DIR_OVERRIDE:-${HOME}/.claude/projects}"
NOTICE_PREFIX="[task-watchdog]"
# python||python3, validated by EXECUTION not presence: stock macOS and
# Debian/Ubuntu ship python3 only, and the Windows Store publishes a
# python/python3 execution-alias stub that passes `command -v` but exits
# nonzero — either way a presence-only probe silently no-ops this script
# (the Phase 57 silent-inert class).
PYBIN=""
for _cand in python python3; do
  if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then
    PYBIN="$_cand"
    break
  fi
done

# ---- helpers ----
emit() { printf '%s\n' "$*"; }

# encode_cwd <absolute-path>
# Mirrors Claude Code's project-dir encoding: EVERY non-alphanumeric
# character becomes `-` (so C:\Users\x -> C--Users-x, and a dotted dir
# like .claude-mem -> -claude-mem). A Git-Bash form (/c/Users/x) is
# normalized to drive form FIRST — on Windows the hook receives
# CLAUDE_PROJECT_DIR in Git-Bash form, and encoding it raw yields
# `-c-Users-x`, which matches nothing. That mismatch kept this script
# silently inert on Windows installs (Phase 57 diagnosis). Known
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

read_last_session_id() {
  [ -f "$LAST_SESSION_MARKER" ] && cat "$LAST_SESSION_MARKER" 2>/dev/null
}

write_last_session_id() {
  printf '%s\n' "$1" > "$LAST_SESSION_MARKER"
}

# find_prior_jsonl: emit the path of the second-newest JSONL whose
# `cwd` field matches $CLAUDE_PROJECT_DIR. Falls back to scanning all
# project dirs and matching by cwd if the encoded-path lookup misses.
# Empty output if no candidate exists.
find_prior_jsonl() {
  local target_cwd="${CLAUDE_PROJECT_DIR:-$PWD}"
  local encoded
  encoded=$(encode_cwd "$target_cwd")
  local primary_dir="$PROJECTS_DIR/$encoded"
  if [ -d "$primary_dir" ]; then
    # Take the SECOND most recently modified .jsonl (newest is the
    # current session, which is just starting and has no completed
    # tool calls yet).
    # Portable second-newest (find -printf is GNU-only; macOS lacks it).
    # ls -t is line-based: fine for per-file lines, pathological only for
    # filenames containing newlines.
    ls -1t "$primary_dir"/*.jsonl 2>/dev/null | sed -n '2p'
    return
  fi
  # Fallback: scan all project dirs, pick the second-newest JSONL whose
  # early events name $target_cwd. Real transcripts don't carry `cwd` on
  # the FIRST line (Phase 57 diagnosis: first lines are summary/meta
  # events), so scan a bounded number of lines; paths are compared
  # normalized (drive form, forward slashes, case-folded) so Git-Bash and
  # Windows forms match.
  [ -d "$PROJECTS_DIR" ] || return
  [ -n "$PYBIN" ] || return
  "$PYBIN" - "$PROJECTS_DIR" "$target_cwd" <<'PYFALLBACK'
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
if len(candidates) >= 2:
    print(candidates[1][1])
PYFALLBACK
}

# ---- main ----
if [ -z "${CLAUDE_PROJECT_DIR:-}" ] && [ ! -d "$PWD/.claude" ]; then
  exit 0
fi

mkdir -p "$OBS_DIR" 2>/dev/null || exit 0

JSONL_PATH=$(find_prior_jsonl)
if [ -z "$JSONL_PATH" ] || [ ! -f "$JSONL_PATH" ]; then
  # Fail-soft, but not fail-silent: if the projects dir exists and holds
  # transcripts yet resolution missed, surface one line — an unresolvable
  # transcript dir stayed invisible for eight weeks before Phase 57.
  if [ -d "$PROJECTS_DIR" ] && find "$PROJECTS_DIR" -maxdepth 2 -name '*.jsonl' -print -quit 2>/dev/null | grep -q .; then
    emit "$NOTICE_PREFIX transcript not resolved for ${CLAUDE_PROJECT_DIR:-$PWD} under $PROJECTS_DIR — check project-dir encoding"
  fi
  exit 0
fi

if [ -z "$PYBIN" ]; then
  # No python/python3 → no clean way to walk JSONL. Silent no-op.
  exit 0
fi

# Cheap sessionId peek so we can short-circuit on already-processed
# sessions without parsing the full file.
PRIOR_SESSION_ID=$("$PYBIN" - "$JSONL_PATH" <<'PYPEEK'
import json, sys
try:
    with open(sys.argv[1], encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try:
                ev = json.loads(line)
            except Exception:
                continue
            if 'sessionId' in ev:
                print(ev['sessionId'])
                break
except OSError:
    pass
PYPEEK
)

[ -n "$PRIOR_SESSION_ID" ] || exit 0

if [ "$(read_last_session_id)" = "$PRIOR_SESSION_ID" ]; then
  exit 0
fi

# Process the JSONL. Python helper writes observation files in place.
"$PYBIN" - "$JSONL_PATH" "$OBS_DIR" "$DURATION_THRESHOLD_MS" "$FAILURE_OCCURRENCE_THRESHOLD" "$EVIDENCE_CAP" 2>/dev/null <<'PYIMPL'
import hashlib, json, os, re, sys
from collections import defaultdict
from datetime import datetime, timezone

jsonl_path, obs_dir = sys.argv[1], sys.argv[2]
duration_threshold_ms = int(sys.argv[3])
failure_threshold = int(sys.argv[4])
evidence_cap = int(sys.argv[5])

# ---- redaction (mirrors session-observer.schema.md rules) ----
SECRET_PATTERNS = [
    re.compile(r'[A-Z_]*KEY=\S+'),
    re.compile(r'[A-Z_]*TOKEN=\S+'),
    re.compile(r'Bearer\s+\S+', re.IGNORECASE),
    re.compile(r'Authorization:\s*\S+', re.IGNORECASE),
    re.compile(r'~?/(?:Users|home)/[^/\s]+'),
    re.compile(r'[A-Za-z0-9+/]{33,}={0,2}'),
]

def redact(s):
    if not isinstance(s, str): s = str(s)
    for p in SECRET_PATTERNS:
        s = p.sub('<redacted>', s)
    if len(s) > 120:
        s = s[:119] + '…'
    return s

# ---- signature normalization ----
def normalize_command(cmd):
    if not isinstance(cmd, str): return ''
    s = cmd.strip()
    s = re.sub(r'/\S+', '<path>', s)
    s = re.sub(r'\d+', 'N', s)
    return s[:120]

def normalize_error_signature(content):
    if not isinstance(content, str):
        try: content = json.dumps(content)
        except Exception: content = str(content)
    first_line = content.strip().splitlines()[0] if content.strip() else ''
    first_line = first_line.lower()
    first_line = re.sub(r'/\S+', '<path>', first_line)
    first_line = re.sub(r'\d+', 'N', first_line)
    return first_line[:80]

def pattern_id(ptype, signature):
    h = hashlib.sha256()
    h.update(ptype.encode('utf-8'))
    h.update(b'\n')
    h.update(signature.encode('utf-8'))
    return h.hexdigest()

# ---- walk JSONL: pair tool_use ↔ tool_result ----
tool_uses = {}
durations = defaultdict(list)
errors = defaultdict(list)

try:
    fh = open(jsonl_path, encoding='utf-8', errors='replace')
except OSError:
    sys.exit(0)

with fh:
    for raw in fh:
        raw = raw.strip()
        if not raw: continue
        try:
            ev = json.loads(raw)
        except Exception:
            continue
        if ev.get('isSidechain') is True:
            continue
        msg = ev.get('message') or {}
        if ev.get('type') == 'assistant':
            for block in (msg.get('content') or []):
                if isinstance(block, dict) and block.get('type') == 'tool_use':
                    tool_uses[block.get('id')] = {
                        'name': block.get('name', ''),
                        'input': block.get('input') or {},
                        'timestamp': ev.get('timestamp', ''),
                    }
        elif ev.get('type') == 'user':
            for block in (msg.get('content') or []):
                if not (isinstance(block, dict) and block.get('type') == 'tool_result'):
                    continue
                use_id = block.get('tool_use_id')
                tu = tool_uses.get(use_id)
                if not tu: continue
                result = ev.get('toolUseResult') or {}
                duration_ms = 0
                if isinstance(result, dict):
                    duration_ms = int(result.get('durationMs') or 0)
                content = block.get('content')
                is_error = bool(block.get('is_error'))
                exit_code = result.get('exitCode') if isinstance(result, dict) else None

                # Duration check (Bash only — other tools rarely report meaningful durationMs).
                if tu['name'] == 'Bash' and duration_ms >= duration_threshold_ms:
                    cmd = tu['input'].get('command', '') if isinstance(tu['input'], dict) else ''
                    sig = normalize_command(cmd)
                    if sig:
                        durations[sig].append({
                            'command': cmd,
                            'duration_ms': duration_ms,
                            'timestamp': tu['timestamp'],
                            'tool_name': tu['name'],
                        })

                # Failure check.
                content_str = content if isinstance(content, str) else ''
                if not content_str and isinstance(content, list):
                    parts = [b.get('text','') for b in content if isinstance(b, dict) and b.get('type')=='text']
                    content_str = '\n'.join(parts)
                failed = is_error or (
                    exit_code is not None and exit_code != 0
                ) or content_str.startswith('<tool_use_error>')
                if failed:
                    sig = normalize_error_signature(content_str)
                    if sig:
                        errors[sig].append({
                            'tool_name': tu['name'],
                            'content': content_str,
                            'timestamp': ev.get('timestamp', ''),
                            'command': tu['input'].get('command', '') if isinstance(tu['input'], dict) and tu['name']=='Bash' else '',
                        })

# ---- emit observations ----
def now_iso():
    return datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

def write_observation(pid, ptype, signature, events, notes=None):
    path = os.path.join(obs_dir, f'{pid}.json')
    existing = None
    if os.path.exists(path):
        try:
            with open(path, encoding='utf-8') as f:
                existing = json.load(f)
        except Exception:
            existing = None

    new_evidence = []
    for ev in events:
        ts = ev.get('timestamp') or now_iso()
        if ptype == 'recurring_failure':
            summary = redact(ev.get('content', '').splitlines()[0] if ev.get('content') else 'tool error')
            entry = {
                'timestamp': ts,
                'kind': 'error',
                'summary': summary,
                'tool_name': ev.get('tool_name', ''),
            }
            if ev.get('command'):
                entry['args_redacted'] = redact(ev['command'])
        else:
            entry = {
                'timestamp': ts,
                'kind': 'tool_call',
                'tool_name': ev.get('tool_name', 'Bash'),
                'args_redacted': redact(ev.get('command', '')),
                'summary': redact(f"long-running bash call ({ev.get('duration_ms',0)//1000}s)"),
            }
        new_evidence.append(entry)

    if existing:
        occurrences = int(existing.get('occurrences', 0)) + len(events)
        first_seen = existing.get('first_seen') or new_evidence[0]['timestamp']
        last_seen = new_evidence[-1]['timestamp']
        prior_evidence = existing.get('evidence') or []
        combined = (prior_evidence + new_evidence)[-evidence_cap:]
        source = existing.get('source', 'task-watchdog')
    else:
        occurrences = len(events)
        first_seen = new_evidence[0]['timestamp']
        last_seen = new_evidence[-1]['timestamp']
        combined = new_evidence[-evidence_cap:]
        source = 'task-watchdog'

    # task-watchdog's `other`-typed long-running observations are
    # anomaly-style: a single 5min+ bash call IS the signal. We emit
    # at occurrences=1 and let cross-session accumulation bump the
    # count. recurring_failure already enforces its own ≥3 threshold
    # upstream of this call.

    if occurrences >= 5:
        confidence = 'high'
    elif occurrences >= 3:
        confidence = 'med'
    else:
        confidence = 'low'

    # Phase 46 privacy_class mapping for task-watchdog:
    #   - recurring_failure → share-with-redaction (error signature shareable,
    #     command args redact via the safe-to-share field allowlist).
    #   - other (long-running bash) → share-with-redaction (duration + tool
    #     shareable; command args redact).
    privacy_class = 'share-with-redaction'

    # target_resource: opportunistic. For recurring_failure, attribute to the
    # failing tool (Bash | Read | Edit | ...). For long-running bash, attribute
    # to "script:<first-bash-token>" when the command is a script invocation,
    # else just "tool:Bash". Producers MAY omit when no identifiable resource.
    target_resource = None
    if events:
        first = events[0]
        if ptype == 'recurring_failure':
            tn = first.get('tool_name', '')
            if tn:
                target_resource = f'tool:{tn}'
        else:
            cmd = first.get('command', '')
            if cmd:
                first_token = cmd.strip().split(None, 1)[0] if cmd.strip() else ''
                if first_token.endswith('.sh') or '/' in first_token:
                    target_resource = f'script:{os.path.basename(first_token)}'
                else:
                    target_resource = 'tool:Bash'

    out = {
        'pattern_id': pid,
        'source': source,
        'pattern_type': ptype,
        'occurrences': occurrences,
        'first_seen': first_seen,
        'last_seen': last_seen,
        'resolved_at': None,
        'evidence': combined,
        'confidence': confidence,
        'privacy_class': privacy_class,
    }
    if notes:
        out['notes'] = notes
    if target_resource:
        out['target_resource'] = target_resource

    tmp = path + f'.tmp.{os.getpid()}'
    with open(tmp, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(out, f, indent=2, sort_keys=True)
        f.write('\n')
    os.replace(tmp, path)

# Long-running bash: emit even for a single occurrence ≥ threshold (schema requires ≥2 occurrences total, so single-occurrence patterns wait for the next session to bump count — or merge with an existing observation).
duration_minutes = duration_threshold_ms // 60000
for sig, events in durations.items():
    pid = pattern_id('other', sig)
    notes = f"long-running bash call (>{duration_minutes}m)"
    write_observation(pid, 'other', sig, events, notes=notes)

# Recurring failures: only emit if same signature ≥ failure_threshold this session.
for sig, events in errors.items():
    if len(events) < failure_threshold:
        continue
    pid = pattern_id('recurring_failure', sig)
    write_observation(pid, 'recurring_failure', sig, events)
PYIMPL
PYIMPL_RC=$?

if [ "$PYIMPL_RC" -ne 0 ]; then
  emit "$NOTICE_PREFIX prior-session scan failed — observations may be stale"
  exit 0
fi

write_last_session_id "$PRIOR_SESSION_ID"
exit 0
