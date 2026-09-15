// The harness must bite. A merge that keeps only the newer fact — last
// writer wins, the thing every conventional system does — is run through the
// same world, and invariant 1 must fail. If this test ever passes with the
// broken merge, the harness is decoration.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'merge_test.dart' show World;

/// Last writer wins: keeps whichever side has the newer latest stamp. Loses
/// facts by design.
Record lastWriterWins(Record a, Record b) {
  if (a.length == 0) return b;
  if (b.length == 0) return a;
  return a.all.last.stamp.compareTo(b.all.last.stamp) >= 0 ? a : b;
}

void main() {
  test('the harness fails a last-writer-wins merge', () {
    var lost = 0;
    for (var seed = 1; seed <= 50; seed++) {
      final w = World(seed)..merge = lastWriterWins;
      w.run();
      w.settle();
      for (final r in w.held.values) {
        if (r.length != w.everRecorded.toSet().length) lost++;
      }
    }
    expect(lost, greaterThan(0),
        reason:
            'a merge that overwrites lost nothing, so the harness cannot see loss');
  });
}
