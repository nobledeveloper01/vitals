import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'merge_test.dart' show World;

void main() {
  test('a delta each way makes two devices agree, and the fingerprint says so', () {
    for (var seed = 1; seed <= 100; seed++) {
      final w = World(seed)..run();
      final rs = w.held.values.toList();
      var a = rs[0], b = rs[1];
      final toB = Exchange.delta(from: a, to: b);
      final toA = Exchange.delta(from: b, to: a);
      expect(toB.every((f) => !b.contains(f)), isTrue);
      a = Merge.union(a, Record.of(a.patient, toA));
      b = Merge.union(b, Record.of(b.patient, toB));
      expect(Canonical.bytesOf(a), Canonical.bytesOf(b), reason: 'seed $seed');
      expect(Exchange.fingerprint(a), Exchange.fingerprint(b));
      expect(Exchange.delta(from: a, to: b), isEmpty);
    }
  });

  test('the outbox is the delta against nothing', () {
    final w = World(3)..run();
    final r = w.held.values.first;
    expect(Exchange.delta(from: r, to: Record.empty(r.patient)).length, r.length);
  });
}
