import 'clock.dart';
import 'fact.dart';
import 'record.dart';

/// One byte encoding of a record, version 1. Big-endian, length-prefixed, no
/// floats, facts in stamp order — so two devices holding the same set of
/// facts produce identical bytes (invariant 4), whatever order the facts
/// arrived in. A checked-in fixture asserts these bytes; a change to it is a
/// change to what "identical" means for every record in the world.
abstract final class Canonical {
  static const int version = 1;

  static List<int> bytesOf(Record r) {
    final out = <int>[version];
    _bytes(out, r.patient, width: 1);
    final facts = r.all;
    _u32(out, facts.length);
    for (final f in facts) {
      _bytes(out, f.id, width: 1);
      _bytes(out, f.patient, width: 1);
      out.add(f.kind.code);
      _i64(out, f.stamp.wallMillis);
      _u32(out, f.stamp.counter);
      _string(out, f.stamp.device);
      _string(out, f.author);
      _bytes(out, f.payload, width: 4);
      if (f.supersedes == null) {
        out.add(0);
      } else {
        out.add(1);
        _bytes(out, f.supersedes!, width: 1);
      }
    }
    return out;
  }

  static Record recordFrom(List<int> bytes) {
    final r = _Reader(bytes);
    final v = r.u8();
    if (v != version) throw CanonicalError('version $v');
    final patient = r.bytes(width: 1);
    final n = r.u32();
    final facts = <Fact>[];
    for (var i = 0; i < n; i++) {
      final id = r.bytes(width: 1);
      final p = r.bytes(width: 1);
      final kind = FactKind.fromCode(r.u8());
      final wall = r.i64();
      final counter = r.u32();
      final device = r.string();
      final author = r.string();
      final payload = r.bytes(width: 4);
      final hasSup = r.u8();
      final sup = hasSup == 1 ? r.bytes(width: 1) : null;
      facts.add(Fact(
        id: id,
        patient: p,
        kind: kind,
        stamp: Stamp(wallMillis: wall, counter: counter, device: device),
        author: author,
        payload: payload,
        supersedes: sup,
      ));
    }
    if (!r.done) throw CanonicalError('trailing bytes');
    return Record.of(patient, facts);
  }

  static void _u8(List<int> out, int v) => out.add(v & 0xff);
  static void _u32(List<int> out, int v) {
    for (var s = 24; s >= 0; s -= 8) {
      out.add((v >> s) & 0xff);
    }
  }

  static void _i64(List<int> out, int v) {
    for (var s = 56; s >= 0; s -= 8) {
      out.add((v >> s) & 0xff);
    }
  }

  static void _bytes(List<int> out, List<int> b, {required int width}) {
    if (width == 1) {
      if (b.length > 255) throw CanonicalError('too long for one byte');
      _u8(out, b.length);
    } else {
      _u32(out, b.length);
    }
    out.addAll(b);
  }

  static void _string(List<int> out, String s) {
    final units = <int>[];
    for (final c in s.runes) {
      if (c < 0x80) {
        units.add(c);
      } else if (c < 0x800) {
        units.add(0xc0 | (c >> 6));
        units.add(0x80 | (c & 0x3f));
      } else if (c < 0x10000) {
        units.add(0xe0 | (c >> 12));
        units.add(0x80 | ((c >> 6) & 0x3f));
        units.add(0x80 | (c & 0x3f));
      } else {
        units.add(0xf0 | (c >> 18));
        units.add(0x80 | ((c >> 12) & 0x3f));
        units.add(0x80 | ((c >> 6) & 0x3f));
        units.add(0x80 | (c & 0x3f));
      }
    }
    _bytes(out, units, width: 1);
  }
}

final class CanonicalError implements Exception {
  const CanonicalError(this.reason);
  final String reason;
  @override
  String toString() => 'CanonicalError: $reason';
}

final class _Reader {
  _Reader(this._b);
  final List<int> _b;
  var _i = 0;

  bool get done => _i == _b.length;

  int u8() {
    if (_i >= _b.length) throw const CanonicalError('truncated');
    return _b[_i++];
  }

  int u32() {
    var v = 0;
    for (var k = 0; k < 4; k++) {
      v = (v << 8) | u8();
    }
    return v;
  }

  int i64() {
    var v = 0;
    for (var k = 0; k < 8; k++) {
      v = (v << 8) | u8();
    }
    return v.toSigned(64);
  }

  List<int> bytes({required int width}) {
    final n = width == 1 ? u8() : u32();
    if (_i + n > _b.length) throw const CanonicalError('truncated');
    final out = _b.sublist(_i, _i + n);
    _i += n;
    return out;
  }

  String string() {
    final units = bytes(width: 1);
    return String.fromCharCodes(_decodeUtf8(units));
  }

  static List<int> _decodeUtf8(List<int> u) {
    final out = <int>[];
    var i = 0;
    while (i < u.length) {
      final b = u[i];
      if (b < 0x80) {
        out.add(b);
        i += 1;
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
    return out;
  }
}
