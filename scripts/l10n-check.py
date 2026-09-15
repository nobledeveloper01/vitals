#!/usr/bin/env python3
"""Every patient-face language is complete: each translation table has
exactly the keys the English table has, no more, no fewer, none empty.
A missing key would fall back to English silently, which is the kind of
incompleteness the product statement says it will not hide."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEECH = ROOT / "app/lib/speech"
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"
KEY = re.compile(r"^\s*'([\w.]+)':\s*\n?\s*(?:'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\")", re.M)


def keys(path: Path) -> dict:
    text = path.read_text()
    return {m[1]: (m[2] or m[3] or "") for m in KEY.finditer(text)}


def main() -> int:
    english_src = (SPEECH / "patient_strings.dart").read_text()
    block = english_src[english_src.index("english = {"):]
    block = block[: block.index("};")]
    english = {m[1]: (m[2] or m[3] or "") for m in KEY.finditer(block)}
    if not english:
        print(f"{RED}✗{OFF} no English keys found")
        return 1
    bad = 0
    for f in sorted((SPEECH / "translations").glob("*.dart")):
        table = keys(f)
        missing = sorted(set(english) - set(table))
        extra = sorted(set(table) - set(english))
        empty = sorted(k for k, v in table.items() if not v.strip())
        for k in missing:
            print(f"{RED}✗{OFF} {f.name} has no '{k}'")
        for k in extra:
            print(f"{RED}✗{OFF} {f.name} has '{k}', which English does not")
        for k in empty:
            print(f"{RED}✗{OFF} {f.name} leaves '{k}' empty")
        bad += len(missing) + len(extra) + len(empty)
    n = len(list((SPEECH / "translations").glob("*.dart")))
    if bad:
        print(f"{RED}l10n gate failed{OFF}")
        return 1
    print(f"{GRN}✓{OFF} {n} patient-face languages complete — {len(english)} keys each")
    return 0


if __name__ == "__main__":
    sys.exit(main())
