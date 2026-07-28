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

INPUT="${1:--}"
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

# Badge row - derived from parsed data only.
badges = []
if pushed:
    badges.append(pushed)
sm = re.search(r"(\d+) automated checks", " ".join(by.get("SAFETY", [])))
if sm:
    badges.append(f"{sm.group(1)} checks pass")
cost_line = " ".join(by.get("COST", []))
if cost_line:
    badges.append("spending normal" if "typical" in cost_line.lower() and "$" not in cost_line
                  else "spending flagged" if cost_line else "")
mm = re.search(r"Written by ([^,]+)", " ".join(by.get("MODEL", [])))
if mm:
    badges.append(mm.group(1).strip())
badges = [b for b in badges if b]

e = html.escape
def section(field, tag="div"):
    if field not in by:
        return ""
    rows = "".join(f'<p class="row">{e(v)}</p>' for v in by[field])
    label = "" if field == "VERDICT" else f'<h2>{e(field.title())}</h2>'
    return (f'<{tag} class="sec sec-{field.split()[0].lower()}" '
            f'title="{e(TIPS[field])}">{label}{rows}</{tag}>')

badge_html = "".join(f'<span class="badge">{e(b)}</span>' for b in badges)
head = (f'<header title="{e(TIPS["VERDICT"])}">'
        f'<h1>Ship receipt{" - " + e(slug.replace("phase-", "Phase ")) if slug != "receipt" else ""}'
        f'{f" <span class=chip>{e(pushed)}</span>" if pushed else ""}</h1>'
        f'<p class="verdict">{e(verdict)}</p>'
        f'{f"<div class=badges>{badge_html}</div>" if badges else ""}'
        f'</header>')

body = (head
        + section("WHAT CHANGED")
        + section("SAFETY")
        + section("COST")
        + section("MODEL")
        + section("FLAGS")
        + f'<footer>{section("TO DO LATER")}{section("NEXT UP")}</footer>')

CSS = """
:root{color-scheme:light dark;--fg:#1a1a1a;--bg:#fff;--muted:#555;--line:#ddd;--chip:#e8f0e8;--badge:#f0f0f4}
@media(prefers-color-scheme:dark){:root{--fg:#e8e8e8;--bg:#161618;--muted:#aaa;--line:#333;--chip:#243024;--badge:#26262c}}
body{font:15px/1.5 system-ui,sans-serif;color:var(--fg);background:var(--bg);max-width:640px;margin:2rem auto;padding:0 1rem}
h1{font-size:1.15rem;margin:0 0 .3rem}h2{font-size:.75rem;text-transform:uppercase;letter-spacing:.06em;color:var(--muted);margin:0 0 .3rem}
.verdict{margin:.2rem 0 .6rem;font-size:1rem}
.sec{border-top:1px solid var(--line);padding:.7rem 0;margin:0}
.row{margin:.25rem 0}
.chip{font-size:.7rem;background:var(--chip);border-radius:.6em;padding:.15em .6em;vertical-align:middle}
.badge{display:inline-block;font-size:.72rem;background:var(--badge);border-radius:.5em;padding:.15em .55em;margin-right:.35em}
.badges{margin:.4rem 0 .2rem}
footer .sec{border-top:1px dashed var(--line)}
"""

page = (f"<!DOCTYPE html><html><head><meta charset='utf-8'>"
        f"<meta name='viewport' content='width=device-width,initial-scale=1'>"
        f"<title>Ship receipt</title><style>{CSS}</style></head>"
        f"<body>{body}</body></html>")

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

# ---- cleanup ----
# (exit status is the python block's - loud failure is correct here)
