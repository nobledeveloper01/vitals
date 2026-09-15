#!/usr/bin/env python3
"""
Fail if the domain package imports anything.

Every device and the server compute the same bytes from the same facts. A
domain that reads a clock, a random source or a platform can disagree with
itself across devices, and a disagreement here is a lost fact. So
packages/vitals_domain/lib may import only dart:core (implicit) and its own
files. ADR-0002.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "packages/vitals_domain/lib"
ALLOWED = re.compile(r"^import '(src/[a-z_/]+\.dart|[a-z_]+\.dart)';$")
CLOCKY = re.compile(r"\b(DateTime\.now|Random\(|Stopwatch\(|Platform\.)")
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"


def main() -> int:
    bad = []
    files = sorted(LIB.rglob("*.dart"))
    for f in files:
        for n, line in enumerate(f.read_text().splitlines(), 1):
            s = line.strip()
            if s.startswith("import ") and not ALLOWED.match(s):
                bad.append(f"{f.relative_to(ROOT)}:{n}: {s}")
            if s.startswith("export ") and "package:" in s:
                bad.append(f"{f.relative_to(ROOT)}:{n}: {s}")
            if CLOCKY.search(line):
                bad.append(f"{f.relative_to(ROOT)}:{n}: reads a clock, randomness or the platform")
    for b in bad:
        print(f"{RED}✗{OFF} {b}")
    if bad:
        print(f"{RED}domain purity failed{OFF} — the merge must be the same everywhere; ADR-0002")
        return 1
    print(f"{GRN}✓{OFF} domain layer is pure Dart — {len(files)} files, no imports, no clock, no randomness")
    return 0


if __name__ == "__main__":
    sys.exit(main())
