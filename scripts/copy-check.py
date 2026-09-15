#!/usr/bin/env python3
"""
Fail the build on the words a clinical record must never say.

Vitals presents; it never interprets. A string that says "diagnosis", "risk",
"triage", "recommend" or a dose crosses into a regulated medical device. A
string that says "genuine", "safe", "verified" or "synced" claims what the
product cannot know. This reads every string in the app and the server's
user-facing messages for those words. Rule 1, and honesty about what is known.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = [
    ROOT / "app/lib/speech/strings.dart",
    *sorted((ROOT / "app/lib/speech").glob("translations/*.dart")),
    *sorted((ROOT / "server/src/Vitals.Api").glob("**/Messages.cs")),
]
BANNED = re.compile(
    r"\b(diagnos\w*|risk\w*|triage\w*|recommend\w*|prescri\w*|dosage|\d+\s?(mg|ml|mcg)\b|genuine|safe|unsafe|verified|verify|synced|sync'?d|cured?|treat\w*|abnormal|normal|tachy\w*|brady\w*|hypo\w*|hyper\w*|elevated|critical)\b",
    re.IGNORECASE,
)
RED, GRN, OFF = "\033[0;31m", "\033[0;32m", "\033[0m"


def main() -> int:
    hits, n = [], 0
    for f in FILES:
        if not f.exists():
            continue
        text = re.sub(r"//.*", "", f.read_text())
        for lit in re.findall(r"'((?:[^'\\]|\\.)*)'|\"((?:[^\"\\]|\\.)*)\"", text):
            s = lit[0] or lit[1]
            if not s:
                continue
            n += 1
            for m in BANNED.finditer(s):
                hits.append(f"{f.relative_to(ROOT)}: '{m.group(0)}' in \"{s[:70]}\"")
    for h in hits:
        print(f"{RED}✗{OFF} {h}")
    if hits:
        print(f"{RED}copy gate failed{OFF} — Vitals presents; it never interprets, and never claims what it cannot know")
        return 1
    print(f"{GRN}✓{OFF} nothing the app says interprets or overclaims — {n} strings checked against the word list")
    return 0


if __name__ == "__main__":
    sys.exit(main())
