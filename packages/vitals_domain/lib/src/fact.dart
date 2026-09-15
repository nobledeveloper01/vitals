import 'clock.dart';

/// What kind of thing a fact records. The number is the encoding's; add at the
/// end, never renumber (ADR-0003: the encoding never changes).
enum FactKind {
  registration(0),
  vitals(1),
  immunisation(2),
  ancVisit(3),
  stockMovement(4),
  note(5),
  supersession(6),
  access(7);

  const FactKind(this.code);
  final int code;

  static FactKind fromCode(int code) =>
      FactKind.values.firstWhere((k) => k.code == code);
}

/// One immutable observation. Who, when, on which device, about whom, what.
/// A fact never changes; a correction is a [FactKind.supersession] fact naming
/// the id it replaces, and both survive.
final class Fact implements Comparable<Fact> {
  const Fact({
    required this.id,
    required this.patient,
    required this.kind,
    required this.stamp,
    required this.author,
    required this.payload,
    this.supersedes,
  });

  /// 32 bytes, chosen by the app from randomness the domain never sees.
  final List<int> id;

  /// The patient's global id, 16 bytes.
  final List<int> patient;
  final FactKind kind;
  final Stamp stamp;

  /// The staff member, by their attribution id. Every write is attributed.
  final String author;

  /// The observation itself, already encoded by its kind's own canonical
  /// encoder. Opaque here; the record does not read it, only keeps it.
  final List<int> payload;

  /// For a supersession: the id of the fact it corrects.
  final List<int>? supersedes;

  String get key => _hex(id);

  @override
  int compareTo(Fact other) {
    final c = stamp.compareTo(other.stamp);
    return c != 0 ? c : _compareBytes(id, other.id);
  }

  @override
  bool operator ==(Object other) => other is Fact && _sameBytes(other.id, id);

  @override
  int get hashCode => Object.hashAll(id);
}

int _compareBytes(List<int> a, List<int> b) {
  final n = a.length < b.length ? a.length : b.length;
  for (var i = 0; i < n; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return a.length.compareTo(b.length);
}

bool _sameBytes(List<int> a, List<int> b) => _compareBytes(a, b) == 0;

String _hex(List<int> bytes) {
  const digits = '0123456789abcdef';
  final out = StringBuffer();
  for (final b in bytes) {
    out.write(digits[b >> 4]);
    out.write(digits[b & 0xf]);
  }
  return out.toString();
}
