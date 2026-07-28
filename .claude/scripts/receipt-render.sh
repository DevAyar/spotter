#!/usr/bin/env bash
# receipt-render: turn a Phase 92 ship-report receipt block (FIELD: sentence
# lines) into a small self-contained HTML card (Phase 93). Input: a file
# argument, or stdin when no argument is given. Output: writes
# .claude/receipts/latest.html plus a dated copy
# .claude/receipts/YYYY-MM-DD-phase-<N>.html (phase parsed from the VERDICT
# line; "receipt" when absent) so history accrues. The receipt TEXT is the
# canonical record - the HTML is a render of it. Self-contained by
# constraint: inline CSS only, zero JS, zero external references; light/dark
# via prefers-color-scheme; per-section tooltips are static title attributes
# carrying GENERIC field explanations, never per-line custom text. Absent
# fields are omitted honestly, never fabricated. Malformed input (no
# recognized field lines) -> one-line stderr error, exit 1, NO partial file
# (tmp-write + atomic rename). Exits nonzero on failure - this is a
# user-invoked tool, not a hook; it is allowed to fail loudly.

set -uo pipefail

# ---- constants ----
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
OUT_DIR="$ROOT/.claude/receipts"

# ---- helpers ----
# (none - the python block below owns parse + render)

# ---- main ----
# python||python3 validated by EXECUTION, not presence — the Windows Store
# alias stub passes `command -v` but exits nonzero (the Phase 57
# silent-inert class; hardened Phase 63).
PYBIN=""
for _cand in python python3; do
  if command -v "$_cand" >/dev/null 2>&1 && "$_cand" -c 'pass' >/dev/null 2>&1; then
    PYBIN="$_cand"
    break
  fi
done
if [ -z "$PYBIN" ]; then
  echo "receipt-render: no working python found" >&2
  exit 1
fi

# Args: --open launches the default browser on latest.html after a
# successful write (Phase 94); the first non-flag arg is the input file
# (default: stdin). Rendering is byte-identical with or without the flag.
OPEN=0
INPUT="-"
for arg in "$@"; do
  case "$arg" in
    --open) OPEN=1 ;;
    *) INPUT="$arg" ;;
  esac
done
if [ "$INPUT" != "-" ] && [ ! -f "$INPUT" ]; then
  echo "receipt-render: input file not found: $INPUT" >&2
  exit 1
fi

"$PYBIN" - "$INPUT" "$OUT_DIR" <<'PYEOF'
import datetime, html, os, re, sys

input_arg, out_dir = sys.argv[1], sys.argv[2]
text = sys.stdin.read() if input_arg == "-" else open(input_arg, encoding="utf-8-sig").read()

FIELDS = ("VERDICT", "WHAT CHANGED", "SAFETY", "COST", "MODEL",
          "FLAGS", "TO DO LATER", "NEXT UP")
# Generic per-field explanations - what the SECTION means, never the line.
TIPS = {
    "VERDICT": "What shipped, in one sentence, with the commit it landed as.",
    "WHAT CHANGED": "Each line is one before/after change, written in plain language.",
    "SAFETY": "Automated checks written to fail on the old code and pass on the new.",
    "COST": "What this sitting cost, relative to this project's own history; dollar figures appear only when a spending limit trips.",
    "MODEL": "Which AI model wrote the work, read from the commit's signature line.",
    "FLAGS": "Anything surprising or nearly-missed during the work.",
    "TO DO LATER": "Known follow-ups this work leaves open, on purpose.",
    "NEXT UP": "The next planned phase, when one is already decided.",
}

parsed = []   # (field, sentence) in input order
for line in text.splitlines():
    line = line.strip()
    for f in FIELDS:
        if line.startswith(f + ":"):
            parsed.append((f, line[len(f) + 1:].strip()))
            break

if not parsed:
    print("receipt-render: no recognized receipt fields in input", file=sys.stderr)
    sys.exit(1)

by = {}
for f, v in parsed:
    by.setdefault(f, []).append(v)

verdict = by.get("VERDICT", [""])[0]
m = re.search(r"Phase (\d+)", verdict)
slug = f"phase-{m.group(1)}" if m else "receipt"
pushed = "pushed" if "pushed" in verdict.lower() else ("held" if "held" in verdict.lower() else "")

# Badge row - (text, tint) pairs derived from parsed data only.
badges = []
if pushed:
    badges.append((pushed, "good"))
sm = re.search(r"(\d+) automated checks", " ".join(by.get("SAFETY", [])))
if sm:
    badges.append((f"{sm.group(1)} checks pass", "good"))
cost_line = " ".join(by.get("COST", []))
if cost_line:
    if "typical" in cost_line.lower() and "$" not in cost_line:
        badges.append(("spending normal", "info"))
    else:
        badges.append(("spending flagged", "warn"))
mm = re.search(r"Written by ([^,]+)", " ".join(by.get("MODEL", [])))
if mm:
    badges.append((mm.group(1).strip(), "plain"))

# Display-side derivation only (field parsing above is untouched): shas
# for the top-right meta cluster come from the already-parsed verdict.
shas = re.findall(r"\b[0-9a-f]{7,10}\b", verdict)

# Sentence-case labels (the frozen design: no ALL CAPS anywhere).
LABELS = {
    "WHAT CHANGED": "What changed", "SAFETY": "Safety",
    "COST": "Cost so far this sitting", "MODEL": "Who did the work",
    "FLAGS": "Flags", "TO DO LATER": "⏳ To do later", "NEXT UP": "→ Next up",
}

e = html.escape
def section(field, cell=False):
    if field not in by:
        return ""
    cls = "cell" if cell else "row"
    rows = "".join(f'<p class="{cls}">{e(v)}</p>' for v in by[field])
    label = f'<h2>{e(LABELS[field])}</h2>'
    return (f'<div class="sec sec-{field.split()[0].lower()}" '
            f'title="{e(TIPS[field])}">{label}{rows}</div>')

badge_html = "".join(f'<span class="badge b-{k}">{e(t)}</span>' for t, k in badges)
meta = ((f'<code>{e(" ".join(shas))}</code>' if shas else "")
        + (f'<span class="chip">{e(pushed)}</span>' if pushed else ""))
head = (f'<header title="{e(TIPS["VERDICT"])}">'
        f'<div class="headrow">'
        f'<h1>Ship receipt{" - " + e(slug.replace("phase-", "Phase ")) if slug != "receipt" else ""}</h1>'
        f'{f"<div class=meta>{meta}</div>" if meta else ""}'
        f'</div>'
        f'<p class="verdict">{e(verdict)}</p>'
        f'{f"<div class=badges>{badge_html}</div>" if badges else ""}'
        f'</header>')

duo = section("COST") + section("MODEL")
body = (head
        + section("WHAT CHANGED", cell=True)
        + section("SAFETY")
        + (f'<div class="duo">{duo}</div>' if duo else "")
        + section("FLAGS")
        + f'<footer>{section("TO DO LATER")}{section("NEXT UP")}</footer>')

CSS = """
:root{color-scheme:light dark;
--fg:#1c1c1e;--fg2:#4a4a52;--muted:#71717a;--page:#ececf0;--card:#fff;--line:#e0e0e6;--well:#f4f4f7;
--good-bg:#e3f2e5;--good-fg:#1d5c28;--info-bg:#e2edf9;--info-fg:#1e4d7d;--warn-bg:#fbeed6;--warn-fg:#7a5210;
--plain-bg:#eeeef2;--plain-fg:#44444c;--amber:#d99a1f}
@media(prefers-color-scheme:dark){:root{
--fg:#ececf0;--fg2:#b8b8c2;--muted:#8b8b95;--page:#0e0e10;--card:#1a1a1e;--line:#2c2c33;--well:#232329;
--good-bg:#1e3322;--good-fg:#8fd49a;--info-bg:#1c2c40;--info-fg:#8ab8ec;--warn-bg:#3a2e14;--warn-fg:#e5b566;
--plain-bg:#28282e;--plain-fg:#c2c2cc;--amber:#c98f22}}
body{font:15px/1.5 system-ui,sans-serif;color:var(--fg);background:var(--page);margin:0;padding:2rem 1rem}
.card{max-width:640px;margin:0 auto;background:var(--card);border:1px solid var(--line);border-radius:12px;padding:1.4rem 1.5rem}
.headrow{display:flex;justify-content:space-between;align-items:baseline;gap:.8rem}
h1{font-size:1.15rem;margin:0}
.meta{white-space:nowrap}
.meta code{font:.72rem/1 ui-monospace,Consolas,monospace;color:var(--muted);margin-right:.5em}
h2{font-size:.8rem;font-weight:600;color:var(--muted);margin:0 0 .4rem}
.verdict{margin:.35rem 0 .6rem;font-size:1rem;color:var(--fg2)}
.sec{border-top:1px solid var(--line);padding:.8rem 0;margin:0}
.row{margin:.25rem 0}
.cell{background:var(--well);border-radius:8px;padding:.5rem .7rem;margin:.35rem 0}
.duo{display:grid;grid-template-columns:1fr 1fr;gap:0 1.2rem}
.duo .sec{min-width:0}
@media(max-width:520px){.duo{grid-template-columns:1fr}}
.sec-flags{border-left:3px solid var(--amber);padding-left:.8rem}
.chip{font-size:.7rem;background:var(--good-bg);color:var(--good-fg);border-radius:.6em;padding:.15em .6em;vertical-align:middle}
.badge{display:inline-block;font-size:.72rem;border-radius:.5em;padding:.18em .6em;margin-right:.35em}
.b-good{background:var(--good-bg);color:var(--good-fg)}
.b-info{background:var(--info-bg);color:var(--info-fg)}
.b-warn{background:var(--warn-bg);color:var(--warn-fg)}
.b-plain{background:var(--plain-bg);color:var(--plain-fg)}
.badges{margin:.45rem 0 .3rem}
footer{border-top:1px solid var(--line);margin-top:.2rem}
footer .sec{border-top:0;padding:.55rem 0}
footer .sec h2{margin-bottom:.15rem}
"""

page = (f"<!DOCTYPE html><html><head><meta charset='utf-8'>"
        f"<meta name='viewport' content='width=device-width,initial-scale=1'>"
        f"<title>Ship receipt</title><style>{CSS}</style></head>"
        f"<body><main class='card'>{body}</main></body></html>")

os.makedirs(out_dir, exist_ok=True)
today = datetime.date.today().isoformat()
for name in ("latest.html", f"{today}-{slug}.html"):
    dest = os.path.join(out_dir, name)
    tmp = dest + f".tmp.{os.getpid()}"
    try:
        with open(tmp, "w", encoding="utf-8", newline="\n") as f:
            f.write(page)
        os.replace(tmp, dest)
    except Exception as exc:
        try:
            os.remove(tmp)
        except OSError:
            pass
        print(f"receipt-render: write failed for {name}: {exc}", file=sys.stderr)
        sys.exit(1)
print(os.path.join(out_dir, "latest.html"))
PYEOF

RENDER_RC=$?
[ "$RENDER_RC" -eq 0 ] || exit "$RENDER_RC"

# Phase 94: --open hands latest.html to the platform's default browser.
# A process launch on a LOCAL file - not a network call; the card itself
# still references nothing external (the guard's zero-http grep proves
# it). Best-effort: a launch failure never fails the render. Suppressed
# when CI is set (GitHub Actions exports CI=true on every runner), and
# each branch is command-existence-gated so headless boxes skip silently.
if [ "$OPEN" -eq 1 ] && [ -z "${CI:-}" ]; then
  CARD="$OUT_DIR/latest.html"
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
      # //c dodges MSYS path-mangling; cygpath -w gives the Windows form.
      if command -v cmd.exe >/dev/null 2>&1 && command -v cygpath >/dev/null 2>&1; then
        cmd.exe //c start "" "$(cygpath -w "$CARD")" >/dev/null 2>&1 || true
      fi
      ;;
    Darwin)
      command -v open >/dev/null 2>&1 && { open "$CARD" >/dev/null 2>&1 || true; }
      ;;
    *)
      command -v xdg-open >/dev/null 2>&1 && { xdg-open "$CARD" >/dev/null 2>&1 & } || true
      ;;
  esac
fi

# ---- cleanup ----
# (exit status: the python render's - loud failure is correct here)
exit "$RENDER_RC"
