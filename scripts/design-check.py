#!/usr/bin/env python3
"""
Fail if DESIGN.md and the palette in code disagree about a colour.

The design document is the contract and the code is what ships; a hex in one
that is not in the other is a decision made by accident. Reads every role
row in DESIGN.md's tables and every Color(0xFF...) in palette.dart.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"


def main() -> int:
    design = ROOT.joinpath("DESIGN.md").read_text()
    code = ROOT.joinpath("app/lib/design/palette.dart").read_text()
    doc_hex = {h.upper() for h in re.findall(r"`#([0-9A-Fa-f]{6})`", design)}
    code_hex = {h.upper() for h in re.findall(r"Color\(0x[0-9A-Fa-f]{2}([0-9A-Fa-f]{6})\)", code)}
    missing_in_code = sorted(doc_hex - code_hex)
    missing_in_doc = sorted(code_hex - doc_hex)
    for h in missing_in_code:
        print(f"{RED}✗{OFF} DESIGN.md names #{h} and palette.dart does not")
    for h in missing_in_doc:
        print(f"{RED}✗{OFF} palette.dart has #{h} and DESIGN.md does not")
    if missing_in_code or missing_in_doc:
        print(f"{RED}design gate failed{OFF}")
        return 1
    # And no raw Color(...) outside the palette and the mark.
    stray = []
    for f in sorted((ROOT / "app/lib").rglob("*.dart")):
        if f.name in ("palette.dart",):
            continue
        for n, line in enumerate(f.read_text().splitlines(), 1):
            if re.search(r"Color\(0x", line) or re.search(r"Colors\.(?!transparent|white\b)", line):
                stray.append(f"{f.relative_to(ROOT)}:{n}")
    for s in stray:
        print(f"{RED}✗{OFF} a colour outside the palette at {s}")
    if stray:
        return 1
    print(f"{GRN}✓{OFF} DESIGN.md and palette.dart agree on {len(doc_hex)} colours, and no screen names one of its own")
    return 0


if __name__ == "__main__":
    sys.exit(main())
