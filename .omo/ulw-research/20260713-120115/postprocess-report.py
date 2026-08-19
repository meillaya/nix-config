from __future__ import annotations

import os
from pathlib import Path
import re
import sys
import tempfile


CAPTIONS = (
    "Readiness evidence for all six exported configurations",
    "Truthful hardware support classes and current evidence boundaries",
    "Prioritized P0 remediation actions and required closure evidence",
    "Rejected, narrowed, or obsolete claims from the source corpus",
)


def add_column_scope(match: re.Match[str]) -> str:
    tag = match.group(0)
    return tag if "scope=" in tag else tag[:-1] + ' scope="col">'


def transform_table(match: re.Match[str], index: int) -> str:
    inner = match.group(1)
    head = re.search(r"<thead>(.*?)</thead>", inner, flags=re.S)
    if head is None:
        raise ValueError(f"table {index + 1} lacks thead")
    scoped_head = re.sub(r"<th(?:\s[^>]*)?>", add_column_scope, head.group(0))
    inner = inner.replace(head.group(0), scoped_head)

    body = re.search(r"<tbody>(.*?)</tbody>", inner, flags=re.S)
    if body is None:
        raise ValueError(f"table {index + 1} lacks tbody")
    scoped_rows = re.sub(
        r"(<tr>\s*)<td(\s[^>]*)?>(.*?)</td>",
        lambda item: (
            f'{item.group(1)}<th scope="row"{item.group(2) or ""}>'
            f"{item.group(3)}</th>"
        ),
        body.group(0),
        flags=re.S,
    )
    inner = inner.replace(body.group(0), scoped_rows)
    caption_id = f"table-caption-{index + 1}"
    hint_id = f"table-hint-{index + 1}"
    return (
        '<div class="table-region" role="region" tabindex="0" '
        f'aria-labelledby="{caption_id}" aria-describedby="{hint_id}">'
        f'<p class="table-hint" id="{hint_id}">'
        "Scroll horizontally to read the complete table.</p>"
        f'<table><caption id="{caption_id}">{CAPTIONS[index]}</caption>'
        f"{inner}</table></div>"
    )


def process(text: str) -> str:
    text = text.replace("</input>", "")
    region_count = text.count('class="table-region"')
    if region_count:
        if region_count != len(CAPTIONS):
            raise ValueError(
                f"refusing partially postprocessed HTML: {region_count} regions"
            )
        for caption in CAPTIONS:
            if text.count(caption) != 1:
                raise ValueError(f"missing or duplicate caption: {caption}")
        return text

    tables = list(re.finditer(r"<table>(.*?)</table>", text, flags=re.S))
    if len(tables) != len(CAPTIONS):
        raise ValueError(f"expected {len(CAPTIONS)} tables, found {len(tables)}")

    index = 0

    def replace_table(match: re.Match[str]) -> str:
        nonlocal index
        rendered = transform_table(match, index)
        index += 1
        return rendered

    return re.sub(r"<table>(.*?)</table>", replace_table, text, flags=re.S)


def atomic_write(destination: Path, text: str) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    handle, temporary = tempfile.mkstemp(
        prefix=f".{destination.name}.", dir=destination.parent
    )
    try:
        with os.fdopen(handle, "w") as stream:
            stream.write(text)
        os.replace(temporary, destination)
    except BaseException:
        Path(temporary).unlink(missing_ok=True)
        raise


def main() -> None:
    if len(sys.argv) not in (1, 3):
        raise SystemExit("usage: postprocess-report.py [INPUT OUTPUT]")
    if len(sys.argv) == 1:
        source = destination = Path(__file__).with_name("REPORT.html")
    else:
        source, destination = map(Path, sys.argv[1:])
    atomic_write(destination, process(source.read_text()))


if __name__ == "__main__":
    main()
