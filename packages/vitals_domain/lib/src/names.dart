/// Nigerian names, the way a registry has to hear them: the same person is
/// Adeola, Adeolá and Ade; Chukwuemeka and Emeka; Muhammad, Mohammed and
/// Muhammed; Oluwaseun and Seun. A phonetic key folds the spellings that
/// are one sound and the prefixes that are one name, so a search for one
/// finds the other and a duplicate check sees them as the same candidate —
/// a candidate, which a person decides. Nothing here decides.
abstract final class Names {
  /// Lower-cased, tone marks and dots stripped, split on space. A hyphen
  /// joins (Ade-Ola is one name); it is dropped, not split on.
  static List<String> tokens(String s) {
    final out = <String>[];
    for (final raw in s.split(RegExp(r'\s+'))) {
      final t = _fold(raw);
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  /// The phonetic key of one token.
  static String key(String token) {
    var t = _fold(token);
    if (t.isEmpty) return '';
    // Yorùbá theophoric prefixes: Oluwa-/Olu- and Ade-/Ola- often dropped in
    // speech (Oluwaseun → Seun, Adeola → Ola is a different name, so only
    // the Oluwa/Olu prefix folds).
    for (final p in ['oluwa', 'olu']) {
      if (t.startsWith(p) && t.length > p.length + 2) {
        t = t.substring(p.length);
        break;
      }
    }
    // Igbo: Chukwu- prefix folds the same way (Chukwuemeka → Emeka).
    if (t.startsWith('chukwu') && t.length > 8) t = t.substring(6);
    // Hausa/Arabic spellings of one name.
    t = t.replaceAll('muhammad', 'mohamed').replaceAll('muhammed', 'mohamed').replaceAll('mohammed', 'mohamed').replaceAll('mohammad', 'mohamed');
    // Sounds that spell two ways.
    t = t
        .replaceAll('ph', 'f')
        .replaceAll('ck', 'k')
        .replaceAll('kw', 'kw')
        .replaceAll('gb', 'gb')
        .replaceAll('sh', 's')
        .replaceAll('ch', 'c')
        .replaceAll('y', 'i')
        .replaceAll('w', 'u');
    // Doubled letters and trailing vowels are spelling, not sound.
    final sb = StringBuffer();
    String? last;
    for (final c in t.split('')) {
      if (c != last) sb.write(c);
      last = c;
    }
    t = sb.toString();
    t = t.replaceAll(RegExp(r'[aeiou]+$'), '');
    // Vowels inside the word are the least stable part of a spelling.
    if (t.length > 3) t = t[0] + t.substring(1).replaceAll(RegExp(r'[aeiou]'), '');
    return t;
  }

  static List<String> keys(String s) => tokens(s).map(key).where((k) => k.isNotEmpty).toList();

  static String _fold(String s) {
    final sb = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final c = _plain[r] ?? r;
      if ((c >= 0x61 && c <= 0x7a)) sb.writeCharCode(c);
    }
    return sb.toString();
  }

  /// Precomposed Yorùbá and Igbo letters to their plain base.
  static const _plain = <int, int>{
    0xe1: 0x61, 0xe0: 0x61, 0xe2: 0x61, 0xe9: 0x65, 0xe8: 0x65, 0xea: 0x65, 0xed: 0x69, 0xec: 0x69,
    0xf3: 0x6f, 0xf2: 0x6f, 0xf4: 0x6f, 0xfa: 0x75, 0xf9: 0x75, 0x1ecd: 0x6f, 0x1eb9: 0x65, 0x1e63: 0x73,
    0x1ecb: 0x69, 0x1ee5: 0x75, 0x1e45: 0x6e, 0x1e44: 0x6e, 0x144: 0x6e, 0x1e5b: 0x72, 0x1e43: 0x6d,
    0x1ecc: 0x6f, 0x1eb8: 0x65, 0x1e62: 0x73, 0x1eca: 0x69, 0x1ee4: 0x75,
  };
}
