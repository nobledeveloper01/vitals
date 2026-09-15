import 'record.dart';

/// Set union. That is the whole merge, and it is the point: union is
/// commutative, associative and idempotent by construction, and it cannot
/// lose a fact because it never chooses between two. The five invariants
/// in ADR-0003 are properties of this function, tested across generated
/// interleavings.
abstract final class Merge {
  static Record union(Record a, Record b) {
    if (!_same(a.patient, b.patient)) {
      throw ArgumentError('records of two patients cannot merge');
    }
    return Record.of(a.patient, [...a.all, ...b.all]);
  }

  static Record all(List<int> patient, Iterable<Record> records) =>
      records.fold(Record.empty(patient), union);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
