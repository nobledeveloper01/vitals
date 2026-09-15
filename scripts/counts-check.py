#!/usr/bin/env python3
"""
Fail if README or RELEASE-GATES quote a figure the repository does not have.

A README that says "six gates" a month after a seventh was added is worse than
one that says nothing. Every figure below is derived, never listed.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"


def blocking_gates() -> int:
    text = ROOT.joinpath("docs/RELEASE-GATES.md").read_text()
    section = text.split("## Blocks v1.0", 1)[1].split("## Cleared", 1)[0]
    return len(re.findall(r"^\| R\d+ \|", section, re.MULTILINE))


def adrs() -> int:
    return len(list((ROOT / "docs/adr").glob("0*.md")))


def thirty() -> int:
    text = ROOT.joinpath("docs/adr/0006-thirty-more-things-each-checked-against-the-rules.md").read_text()
    return len(re.findall(r"^\| \d+ \|", text, re.MULTILINE))


def main() -> int:
    readme = ROOT.joinpath("README.md").read_text()
    checks = [
        (r"(\w+) gates, in \[`docs/RELEASE-GATES.md`", blocking_gates(), "README.md"),
        (r"(\w+) ADRs", adrs(), "README.md"),
        (r"(\w+) more things", thirty(), "README.md"),
    ]
    words = {3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight", 30: "thirty"}
    fails = 0
    for pattern, actual, name in checks:
        m = re.search(pattern, readme)
        if not m:
            print(f"{RED}✗{OFF} {name} does not say /{pattern}/")
            fails += 1
            continue
        said = m.group(1)
        want = words.get(actual, str(actual))
        if said.lower() not in (want.lower(), str(actual)):
            print(f"{RED}✗{OFF} {name} says {said} where the repository has {actual}: /{pattern}/")
            fails += 1
    if fails:
        print(f"{RED}counts gate failed{OFF}")
        return 1
    print(f"{GRN}✓{OFF} the documents count what the repository has: {blocking_gates()} gates, {adrs()} ADRs, {thirty()} things — {len(checks)} figures checked")
    return 0


if __name__ == "__main__":
    sys.exit(main())
