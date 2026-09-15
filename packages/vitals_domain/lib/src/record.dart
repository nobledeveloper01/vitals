import 'fact.dart';

/// A patient's record: the set of its facts, ordered by stamp. Nothing here
/// deletes. What a reader sees is [current]: every fact that has not been
/// superseded, with the superseded ones one step away in [history].
final class Record {
  Record._(this.patient, Map<String, Fact> facts) : _facts = facts;

  factory Record.empty(List<int> patient) => Record._(patient, {});

  factory Record.of(List<int> patient, Iterable<Fact> facts) {
    final r = Record.empty(patient);
    for (final f in facts) {
      r._facts[f.key] = f;
    }
    return r;
  }

  final List<int> patient;
  final Map<String, Fact> _facts;

  /// Every fact ever recorded, in stamp order.
  List<Fact> get all => _facts.values.toList()..sort();

  int get length => _facts.length;

  bool contains(Fact f) => _facts.containsKey(f.key);

  /// The facts a reader is shown: not superseded, and not themselves
  /// supersessions.
  List<Fact> get current {
    final superseded = <String>{
      for (final f in _facts.values)
        if (f.kind == FactKind.supersession && f.supersedes != null)
          _key(f.supersedes!),
    };
    return all
        .where((f) =>
            f.kind != FactKind.supersession && !superseded.contains(f.key))
        .toList();
  }

  /// Everything that corrected a fact, and everything that corrected those,
  /// in stamp order. Two devices may correct the same fact while apart —
  /// both corrections survive, and both are here; the record shows neither
  /// as hidden and the reader decides, which is the nurse's call, not the
  /// merge's.
  List<Fact> history(Fact f) {
    final out = <Fact>[];
    var frontier = <String>{f.key};
    while (frontier.isNotEmpty) {
      final next = <String>{};
      for (final s in all) {
        if (s.kind == FactKind.supersession &&
            s.supersedes != null &&
            frontier.contains(_key(s.supersedes!))) {
          out.add(s);
          next.add(s.key);
        }
      }
      frontier = next;
    }
    return out;
  }

  static String _key(List<int> id) {
    const digits = '0123456789abcdef';
    final out = StringBuffer();
    for (final b in id) {
      out.write(digits[b >> 4]);
      out.write(digits[b & 0xf]);
    }
    return out.toString();
  }
}
