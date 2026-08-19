#!/usr/bin/env bash
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
body=$(mktemp --suffix=.md)
raw_html=$(mktemp --suffix=.html)
print_html=$(mktemp --suffix=.html)
trap 'rm -f -- "$body" "$raw_html" "$print_html"' EXIT

python3 - "$here" "$(git -C "$here" rev-parse --show-toplevel)" <<'PY'
from pathlib import Path
import re
import subprocess
import sys

here = Path(sys.argv[1])
repo = Path(sys.argv[2])
head = subprocess.check_output(["git", "-C", repo, "rev-parse", "HEAD"], text=True).strip()
sources = re.findall(r"^\| S\d+ \|", (here / "source-ledger.md").read_text(), re.M)
observations = re.findall(r"^\| O\d+ \|", (here / "observation-manifest.md").read_text(), re.M)
claims = set(re.findall(r"^\| ((?:P[012]|POS|D)-\d+) \|", (here / "verified-claims.md").read_text(), re.M))
graph_claims = set(re.findall(r"^\| ((?:P[012]|POS|D)-\d+) \|", (here / "claim-graph.md").read_text(), re.M))
template = (here / "report-template.html").read_text()
expected = (60, 141, 58, "e9f78180748f1feb428ffb20f9d932c5d9918a48")
actual = (len(sources), len(observations), len(claims), head)
if actual != expected or claims != graph_claims:
    raise SystemExit(f"report metadata mismatch: expected={expected} actual={actual} graph_match={claims == graph_claims}")
for marker in ("60 supplied sources", "141 observations", "58 canonical claims", head):
    if marker not in template:
        raise SystemExit(f"report template missing derived marker: {marker}")
PY

tail -n +2 "$here/SYNTHESIS.md" >"$body"

pandoc "$body" \
  --from=gfm \
  --to=html5 \
  --standalone \
  --toc \
  --toc-depth=2 \
  --template="$here/report-template.html" \
  --css="$here/report.css" \
  --embed-resources \
  --metadata=lang:en-CA \
  --metadata='title:Nix configuration portability and immediate-usability review' \
  --metadata='subtitle:An evidence-backed assessment of firmware, drivers, Wi-Fi, installation, desktop behavior, theming, cross-platform support, and operational proof.' \
  --metadata='description:A meticulous portability and immediate-usability audit of a multi-platform Nix configuration.' \
  --output="$raw_html"

python3 "$here/postprocess-report.py" "$raw_html" "$here/REPORT.html"

python3 - "$here/REPORT.html" "$print_html" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text()
text = re.sub(
    r'<a href="(?!https?://|#)[^"]+">(.*?)</a>',
    r'\1',
    text,
    flags=re.S,
)
Path(sys.argv[2]).write_text(text)
PY

node "$here/render-pdf.mjs" "$print_html" "$here/REPORT.pdf" Letter
mkdir -p "$here/pdf-qa"
node "$here/render-pdf.mjs" "$print_html" "$here/pdf-qa/REPORT-A4-proof.pdf" A4

xmllint --html --noout "$here/REPORT.html"
qpdf --check "$here/REPORT.pdf"
qpdf --check "$here/pdf-qa/REPORT-A4-proof.pdf"
