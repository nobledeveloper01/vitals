#!/usr/bin/env python3
"""Verify a Vitals audit export with nothing but Python.

    python3 scripts/verify-audit.py audit.csv [expected-public-key-hex]

The file ends with two lines: the tablet's Ed25519 public key and the
signature over every byte before the public-key line. Exit 0 when the
signature holds (and the key matches the one you expected, if you gave it),
1 otherwise. Ed25519 below is the reference arithmetic, slow and plain, so
the check depends on no package."""
import hashlib
import re
import sys

q = 2**255 - 19
L = 2**252 + 27742317777372353535851937790883648493


def inv(x):
    return pow(x, q - 2, q)


d = -121665 * inv(121666) % q
I = pow(2, (q - 1) // 4, q)


def xrecover(y):
    xx = (y * y - 1) * inv(d * y * y + 1)
    x = pow(xx, (q + 3) // 8, q)
    if (x * x - xx) % q != 0:
        x = (x * I) % q
    if x % 2 != 0:
        x = q - x
    return x


By = 4 * inv(5) % q
Bx = xrecover(By)
B = (Bx, By)


def edwards(P, Q):
    x1, y1 = P
    x2, y2 = Q
    x3 = (x1 * y2 + x2 * y1) * inv(1 + d * x1 * x2 * y1 * y2)
    y3 = (y1 * y2 + x1 * x2) * inv(1 - d * x1 * x2 * y1 * y2)
    return (x3 % q, y3 % q)


def scalarmult(P, e):
    if e == 0:
        return (0, 1)
    Q = scalarmult(P, e // 2)
    Q = edwards(Q, Q)
    if e & 1:
        Q = edwards(Q, P)
    return Q


def decodepoint(s):
    y = int.from_bytes(s, "little") & ((1 << 255) - 1)
    x = xrecover(y)
    if x & 1 != s[31] >> 7:
        x = q - x
    P = (x, y)
    if (-x * x + y * y - 1 - d * x * x * y * y) % q != 0:
        raise ValueError("not a point")
    return P


def encodepoint(P):
    x, y = P
    return (y | ((x & 1) << 255)).to_bytes(32, "little")


def verify(pk, sig, msg):
    if len(sig) != 64 or len(pk) != 32:
        return False
    R = decodepoint(sig[:32])
    A = decodepoint(pk)
    S = int.from_bytes(sig[32:], "little")
    if S >= L:
        return False
    h = int.from_bytes(hashlib.sha512(sig[:32] + pk + msg).digest(), "little")
    return scalarmult(B, S) == edwards(R, scalarmult(A, h))


def main(path, expected=None):
    data = open(path, "rb").read()
    text = data.decode("utf-8")
    pk = re.search(r"^# public-key ed25519 ([0-9a-f]{64})$", text, re.M)
    sig = re.search(r"^# signature ed25519 ([0-9a-f]{128})$", text, re.M)
    if not pk or not sig:
        print("✗ no signature lines")
        return 1
    if expected and pk[1] != expected.lower():
        print(f"✗ public key {pk[1][:16]}… is not the one expected")
        return 1
    body = text[: pk.start()].encode("utf-8")
    if verify(bytes.fromhex(pk[1]), bytes.fromhex(sig[1]), body):
        rows = body.count(b"\n") - 1
        print(f"✓ signature holds over {rows} rows; key {pk[1][:16]}…")
        return 0
    print("✗ signature does not hold: the file was changed after it was signed")
    return 1


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    sys.exit(main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else None))
