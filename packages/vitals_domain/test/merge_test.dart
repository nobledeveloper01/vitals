// The five invariants of ADR-0003, as properties over generated multi-device
// interleavings. These exist before the engine is trusted: the harness is
// run against a deliberately broken merge in harness_test.dart and must fail.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'sample.dart';

/// A world: some devices, each holding a record, recording and exchanging
/// in a generated order.
final class World {
  World(this.seed, {this.devices = 3, this.steps = 40}) : gen = Gen(seed);
  final int seed;
  final int devices;
  final int steps;
  final Gen gen;
  final Map<String, Record> held = {};
  final List<Fact> everRecorded = [];
  Record Function(Record, Record) merge = Merge.union;

  void run() {
    for (var d = 0; d < devices; d++) {
      held['d$d'] = Record.empty(patientId(1));
    }
    var wall = 1_700_000_000_000;
    for (var s = 0; s < steps; s++) {
      final d = 'd${gen.next(devices)}';
      switch (gen.next(4)) {
        case 0 || 1: // record a fact
          wall += gen.next(5000);
          final f = fact(seed * 1000 + s,
              device: d, wall: wall, kind: FactKind.values[gen.next(6)]);
          everRecorded.add(f);
          held[d] = merge(held[d]!, Record.of(f.patient, [f]));
        case 2: // correct a fact this device holds
          final current = held[d]!.current;
          if (current.isEmpty) continue;
          final target = current[gen.next(current.length)];
          wall += gen.next(5000);
          final sup = fact(seed * 1000 + s,
              device: d,
              wall: wall,
              kind: FactKind.supersession,
              supersedes: target.id);
          everRecorded.add(sup);
          held[d] = merge(held[d]!, Record.of(sup.patient, [sup]));
        case 3: // exchange with another device, one way or both
          final other = 'd${gen.next(devices)}';
          if (other == d) continue;
          held[d] = merge(held[d]!, held[other]!);
          if (gen.next(2) == 0) held[other] = merge(held[other]!, held[d]!);
      }
    }
  }

  /// Everyone exchanges with everyone until nothing changes.
  void settle() {
    var changed = true;
    while (changed) {
      changed = false;
      for (final a in held.keys) {
        for (final b in held.keys) {
          if (a == b) continue;
          final before = held[a]!.length;
          held[a] = merge(held[a]!, held[b]!);
          if (held[a]!.length != before) changed = true;
        }
      }
    }
  }
}

void main() {
  const seeds = 300;

  test(
      '1. no fact is ever lost: after settling, every device holds everything ever recorded',
      () {
    for (var seed = 1; seed <= seeds; seed++) {
      final w = World(seed)
        ..run()
        ..settle();
      for (final r in w.held.values) {
        expect(r.length, w.everRecorded.toSet().length, reason: 'seed $seed');
        for (final f in w.everRecorded) {
          expect(r.contains(f), isTrue,
              reason: 'seed $seed lost ${f.key.substring(0, 8)}');
        }
      }
    }
  });

  test('2. merge is commutative, associative and idempotent', () {
    for (var seed = 1; seed <= seeds; seed++) {
      final w = World(seed)..run();
      final rs = w.held.values.toList();
      final a = rs[0], b = rs[1], c = rs[2];
      expect(Canonical.bytesOf(Merge.union(a, b)),
          Canonical.bytesOf(Merge.union(b, a)),
          reason: 'commutative, seed $seed');
      expect(Canonical.bytesOf(Merge.union(Merge.union(a, b), c)),
          Canonical.bytesOf(Merge.union(a, Merge.union(b, c))),
          reason: 'associative, seed $seed');
      expect(Canonical.bytesOf(Merge.union(a, a)), Canonical.bytesOf(a),
          reason: 'idempotent, seed $seed');
    }
  });

  test(
      '3. a correction never hides the original: both survive and the history reaches back',
      () {
    var seen = 0;
    for (var seed = 1; seed <= seeds; seed++) {
      final w = World(seed)
        ..run()
        ..settle();
      final r = w.held.values.first;
      final supersessions = r.all.where((f) => f.kind == FactKind.supersession);
      seen += supersessions.length;
      for (final s in supersessions) {
        final original = r.all.firstWhere((f) =>
            f.key == Record.of(f.patient, [f]).all.first.key &&
            _same(f.id, s.supersedes!));
        expect(r.contains(original), isTrue, reason: 'seed $seed');
        expect(r.current.contains(original), isFalse,
            reason: 'a superseded fact is not shown as current, seed $seed');
        expect(r.history(original).map((h) => h.key), contains(s.key),
            reason: 'seed $seed');
      }
    }
    // A generator that never corrects makes this test vacuous; it did once.
    expect(seen, greaterThan(100),
        reason:
            'the worlds must contain corrections for this to test anything');
  });

  test('4. two devices that exchanged everything hold identical bytes', () {
    for (var seed = 1; seed <= seeds; seed++) {
      final w = World(seed)
        ..run()
        ..settle();
      final bytes = w.held.values.map(Canonical.bytesOf).toList();
      for (final b in bytes) {
        expect(b, bytes.first, reason: 'seed $seed');
      }
      // And the bytes round-trip.
      expect(Canonical.bytesOf(Canonical.recordFrom(bytes.first)), bytes.first,
          reason: 'seed $seed');
    }
  });

  test(
      '5. what one device accepted is accepted everywhere: any subset merges into any other without loss',
      () {
    for (var seed = 1; seed <= seeds; seed++) {
      final w = World(seed)..run();
      for (final a in w.held.values) {
        for (final b in w.held.values) {
          final m = Merge.union(a, b);
          for (final f in a.all) {
            expect(m.contains(f), isTrue, reason: 'seed $seed');
          }
          for (final f in b.all) {
            expect(m.contains(f), isTrue, reason: 'seed $seed');
          }
        }
      }
    }
  });

  test('records of two patients refuse to merge', () {
    final a = Record.of(patientId(1), [fact(1, device: 'a', wall: 1)]);
    final b = Record.of(patientId(2), []);
    expect(() => Merge.union(a, b), throwsArgumentError);
  });
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
