"""redact_text — the one text-redaction pattern set (Phase 119).

Canonical on the detect-python precedent (Phase 112): two independent
text-redactors had drifted apart — redact-capture.sh and task-watchdog.sh
disagreed on the base64 threshold (32 vs 33), on whether Windows
drive-letter home paths were handled at all, and on the URL query rule —
and BOTH let the platform's own identity shapes through: backslash
C:\\Users\\<name>, UNC forms, %USERPROFILE% literals, the bare username,
and the encoded C--Users-<name>- session-dir form. This module is the
union of both sets plus those shapes. Consumers import it (sys.path
points at .claude/lib, passed by the calling script); none restate
patterns inline.

Contract:
  redact_text(s) -> str
    - Applies every pattern, in a load-bearing order: secrets first,
      home paths in every shape, env-var literals, the runtime username,
      base64 runs, URL query strings LAST (the query rule eats anything
      after a '?', including what is left of UNC \\?\\ prefixes — that
      over-redaction is the safe direction and is deliberate).
    - Home-path shapes are case-insensitive and match with OR WITHOUT a
      trailing separator (the trailing-separator requirement was itself
      a leak: a bare C:\\Users\\<name> at end-of-string survived).
    - Character classes exclude quotes, so patterns behave inside
      JSON-escaped text (doubled backslashes are matched by the [\\/]+
      runs; replacement tokens contain no quotes or backslash escapes
      that would break JSON validity beyond the matched span).
    - The runtime username set is derived from the environment at import
      (USERNAME, USER, basename of USERPROFILE/HOME) — NEVER hardcoded.
      Names shorter than 3 chars are skipped (boundary-matching a 1-2
      char token would shred ordinary text). Boundary = any non-alnum,
      so the encoded C--Users-<name>-... form is caught too.
    - In-project RELATIVE paths are untouched on purpose: redaction is
      for identity, not for making evidence useless.
  Truncation is the CALLER'S policy, not this module's (task-watchdog
  keeps its 120-char cap locally).

Failure semantics for importers: if this file is missing, the import
raises and the calling writer dies nonzero — which is fail-CLOSED for
the export pipeline (a capture/observation that cannot be redacted is
skipped by the fail-soft walkers, never exported raw).

Mirror note: ships in template/.claude/lib/ byte-identical; keep both in
sync (mirror parity is asserted mechanically at every touching phase).
"""
import os
import re

# ---- secrets (union of both prior sets; KEY/TOKEN take the broader
#      [A-Za-z_]* form, replacements keep the readable label style) ----
_SECRETS = [
    (re.compile(r"[A-Za-z_]*KEY=\S+"), "KEY=<redacted>"),
    (re.compile(r"[A-Za-z_]*TOKEN=\S+"), "TOKEN=<redacted>"),
    (re.compile(r"(?i)\bbearer\s+\S+"), "Bearer <redacted>"),
    (re.compile(r"(?i)\bauthorization:\s*\S+"), "Authorization: <redacted>"),
]

# ---- home paths, every shape this system actually meets ----
# Order within this block: most-specific first (UNC forms carry extra
# structure the drive rule would only partially eat).
_HOMES = [
    # \\host\c$\Users\<name>[\...]  (admin share; leaks hostname too)
    (re.compile(r"(?i)\\{2,}[^\\/\s\"']+\\+[a-z]\$\\+users\\+[^\\/\s\"']+[\\/]?"), r"~\\"),
    # \\?\C:\Users\<name>[\...]  (long-path prefix)
    (re.compile(r"(?i)\\{2,}\?\\+[a-z]:[\\/]+users[\\/]+[^\\/\s\"']+[\\/]?"), r"~\\"),
    # C:\Users\<name>  /  C:/Users/<name>  (drive letter, either slash,
    # trailing separator OPTIONAL — the old requirement was the leak)
    (re.compile(r"(?i)\b[a-z]:[\\/]+users[\\/]+[^\\/\s\"']+[\\/]?"), r"~\\"),
    # /c/Users/<name>  (MSYS / Git Bash)
    (re.compile(r"(?i)(?<![\w])/[a-z]/users/[^/\s\"']+/?"), "~/"),
    # /Users/<name> and /home/<name>  (POSIX; ~-prefixed tolerated)
    (re.compile(r"(?i)~?/(?:users|home)/[^/\s\"']+/?"), "~/"),
]

_ENV_LITERALS = [
    (re.compile(r"(?i)%userprofile%"), "~"),
    (re.compile(r"(?i)\$env:userprofile"), "~"),
]

# ---- the runtime username, derived from the environment, never
#      hardcoded. Boundary = any non-alphanumeric, so path segments,
#      the encoded C--Users-<name>- form, and prose mentions all match.
def _derive_usernames():
    names = set()
    for var in ("USERNAME", "USER"):
        v = os.environ.get(var, "").strip()
        if v:
            names.add(v)
    for var in ("USERPROFILE", "HOME"):
        v = os.environ.get(var, "").strip()
        if v:
            base = os.path.basename(v.rstrip("\\/"))
            if base:
                names.add(base)
    # 1-2 char names would shred ordinary text when boundary-matched.
    return {n for n in names if len(n) >= 3}

_USERNAMES = [
    (re.compile(r"(?<![A-Za-z0-9])" + re.escape(n) + r"(?![A-Za-z0-9])",
                re.IGNORECASE), "<user>")
    for n in sorted(_derive_usernames(), key=len, reverse=True)
]

_TAIL = [
    # base64-ish runs: settled on >=32 (the stricter of the two drifted
    # thresholds). Known cosmetic: also mangles full sha hashes.
    (re.compile(r"[A-Za-z0-9+/]{32,}={0,2}"), "<redacted-b64>"),
    # URL query strings LAST — eats anything after '?', deliberately.
    (re.compile(r"\?[^\s)]+"), "?…"),
]


def redact_text(s):
    if not isinstance(s, str):
        s = str(s)
    for pat, rep in _SECRETS:
        s = pat.sub(rep, s)
    for pat, rep in _HOMES:
        s = pat.sub(lambda _m, r=rep: r.replace("\\\\", "\\"), s)
    for pat, rep in _ENV_LITERALS:
        s = pat.sub(rep, s)
    for pat, rep in _USERNAMES:
        s = pat.sub(rep, s)
    for pat, rep in _TAIL:
        s = pat.sub(rep, s)
    return s
