/// UTF-8 by hand, so the domain imports nothing (ADR-0002).
List<int> utf8Of(String s) {
  final out = <int>[];
  for (final c in s.runes) {
    if (c < 0x80) {
      out.add(c);
    } else if (c < 0x800) {
      out.addAll([0xc0 | (c >> 6), 0x80 | (c & 0x3f)]);
    } else if (c < 0x10000) {
      out.addAll(
          [0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f)]);
    } else {
      out.addAll([
        0xf0 | (c >> 18),
        0x80 | ((c >> 12) & 0x3f),
        0x80 | ((c >> 6) & 0x3f),
        0x80 | (c & 0x3f)
      ]);
    }
  }
  return out;
}

String stringOf(List<int> u) {
  final out = <int>[];
  var i = 0;
  while (i < u.length) {
    final b = u[i];
    if (b < 0x80) {
      out.add(b);
      i++;
    } else if (b < 0xe0) {
      out.add(((b & 0x1f) << 6) | (u[i + 1] & 0x3f));
      i += 2;
    } else if (b < 0xf0) {
      out.add(
          ((b & 0x0f) << 12) | ((u[i + 1] & 0x3f) << 6) | (u[i + 2] & 0x3f));
      i += 3;
    } else {
      out.add(((b & 0x07) << 18) |
          ((u[i + 1] & 0x3f) << 12) |
          ((u[i + 2] & 0x3f) << 6) |
          (u[i + 3] & 0x3f));
      i += 4;
    }
  }
  return String.fromCharCodes(out);
}
