#!/usr/bin/env python3
"""Fail if the domain package's line coverage is under 95%. Runs the tests
with coverage itself so the number is never stale."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOMAIN = ROOT / "packages/vitals_domain"
DART = Path.home() / "development/flutter/bin/dart"
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"


def main() -> int:
    dart = str(DART) if DART.exists() else "dart"
    subprocess.run([dart, "pub", "get"], cwd=DOMAIN, check=True, capture_output=True)
    subprocess.run([dart, "test", "--coverage=coverage"], cwd=DOMAIN, check=True, capture_output=True)
    subprocess.run([dart, "run", "coverage:format_coverage", "--lcov", "--in=coverage", "--out=coverage/lcov.info", "--report-on=lib"], cwd=DOMAIN, check=True, capture_output=True)
    text = (DOMAIN / "coverage/lcov.info").read_text()
    found = sum(int(x) for x in re.findall(r"^LF:(\d+)", text, re.MULTILINE))
    hit = sum(int(x) for x in re.findall(r"^LH:(\d+)", text, re.MULTILINE))
    pct = 100.0 * hit / found if found else 0.0
    if pct < 95:
        print(f"{RED}✗{OFF} coverage gate: {pct:.1f}% < 95% of the domain's lines")
        return 1
    print(f"{GRN}✓{OFF} coverage gate passed ({pct:.1f}% ≥ 95%)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
