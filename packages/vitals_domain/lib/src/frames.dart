/// The animated QR (ADR-0006 #3), as bytes: a payload cut into frames, each
/// carrying its index, the total, and a checksum of its part, so a camera
/// that sees frames in any order, twice, or with gaps knows what it has and
/// what it still needs. The QR's own error correction handles the pixels;
/// this handles the sequence. Nothing here draws.
final class Frame {
  const Frame({required this.index, required this.total, required this.part});
  final int index;
  final int total;
  final List<int> part;

  static const int header = 8;

  List<int> encode() {
    final crc = crc32(part);
    return [
      (index >> 8) & 0xff,
      index & 0xff,
      (total >> 8) & 0xff,
      total & 0xff,
      (crc >> 24) & 0xff,
      (crc >> 16) & 0xff,
      (crc >> 8) & 0xff,
      crc & 0xff,
      ...part,
    ];
  }

  /// Null for bytes that are not a frame or whose part is damaged.
  static Frame? decode(List<int> b) {
    if (b.length < header) return null;
    final index = (b[0] << 8) | b[1];
    final total = (b[2] << 8) | b[3];
    final crc = (b[4] << 24) | (b[5] << 16) | (b[6] << 8) | b[7];
    final part = b.sublist(header);
    if (total == 0 || index >= total || crc32(part) != crc) return null;
    return Frame(index: index, total: total, part: part);
  }

  /// The frame as the text a QR carries: a name any camera can read, a
  /// version, and the bytes in base64. A phone that is not Vitals sees
  /// `VITALS/1 …` and knows what it is looking at; a Vitals device parses it.
  static const String prefix = 'VITALS/1 ';
  String get text => prefix + _base64(encode());

  /// Null for text that is not a frame.
  static Frame? fromText(String text) {
    final t = text.trim();
    if (!t.startsWith(prefix)) return null;
    final bytes = _unbase64(t.substring(prefix.length));
    return bytes == null ? null : decode(bytes);
  }

  /// Cut a payload into frames of at most [size] bytes of part each.
  static List<Frame> cut(List<int> payload, {int size = 400}) {
    if (payload.isEmpty) return const [];
    final total = (payload.length + size - 1) ~/ size;
    return [
      for (var i = 0; i < total; i++)
        Frame(
            index: i,
            total: total,
            part: payload.sublist(
                i * size,
                (i + 1) * size > payload.length
                    ? payload.length
                    : (i + 1) * size)),
    ];
  }

  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  static String _base64(List<int> b) {
    final out = StringBuffer();
    for (var i = 0; i < b.length; i += 3) {
      final n = (b[i] << 16) |
          ((i + 1 < b.length ? b[i + 1] : 0) << 8) |
          (i + 2 < b.length ? b[i + 2] : 0);
      out.write(_alphabet[(n >> 18) & 63]);
      out.write(_alphabet[(n >> 12) & 63]);
      out.write(i + 1 < b.length ? _alphabet[(n >> 6) & 63] : '=');
      out.write(i + 2 < b.length ? _alphabet[n & 63] : '=');
    }
    return out.toString();
  }

  static List<int>? _unbase64(String s) {
    final clean = s.replaceAll(RegExp(r'\s'), '');
    if (clean.length % 4 != 0) return null;
    final out = <int>[];
    for (var i = 0; i < clean.length; i += 4) {
      var n = 0;
      var pad = 0;
      for (var k = 0; k < 4; k++) {
        final c = clean[i + k];
        if (c == '=') {
          pad++;
          n <<= 6;
          continue;
        }
        final v = _alphabet.indexOf(c);
        if (v < 0 || pad > 0) return null;
        n = (n << 6) | v;
      }
      out.add((n >> 16) & 0xff);
      if (pad < 2) out.add((n >> 8) & 0xff);
      if (pad < 1) out.add(n & 0xff);
    }
    return out;
  }

  static int crc32(List<int> bytes) {
    var crc = 0xffffffff;
    for (final b in bytes) {
      crc ^= b;
      for (var k = 0; k < 8; k++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

/// What a camera has gathered so far.
final class Gather {
  final Map<int, List<int>> _parts = {};
  int? _total;

  int get total => _total ?? 0;
  int get have => _parts.length;
  bool get complete => _total != null && _parts.length == _total;

  /// The fraction gathered, for the ring.
  double get progress => _total == null ? 0 : _parts.length / _total!;

  /// Feed one scan; true when it added something new. A frame from a
  /// different transfer (another total) starts over.
  bool add(Frame f) {
    if (_total != f.total) {
      _parts.clear();
      _total = f.total;
    }
    if (_parts.containsKey(f.index)) return false;
    _parts[f.index] = f.part;
    return true;
  }

  /// The indexes still needed, so the sender can be told or the screen
  /// can say "3 more".
  List<int> get missing => [
        for (var i = 0; i < total; i++)
          if (!_parts.containsKey(i)) i
      ];

  List<int> get payload {
    if (!complete) throw StateError('${missing.length} frames missing');
    return [for (var i = 0; i < total; i++) ..._parts[i]!];
  }
}
