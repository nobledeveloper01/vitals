// The hybrid logical clock: physical time only moves it forward, a device
// whose clock went back keeps counting from what it saw, and a stamp
// received from another device is always after it.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  test('next: forward time resets the counter; stalled or backward time counts',
      () {
    final a = Stamp.next(last: null, nowMillis: 1000, device: 'a');
    expect((a.wallMillis, a.counter), (1000, 0));
    final b = Stamp.next(last: a, nowMillis: 1000, device: 'a');
    expect((b.wallMillis, b.counter), (1000, 1));
    final c = Stamp.next(last: b, nowMillis: 900, device: 'a');
    expect((c.wallMillis, c.counter), (1000, 2),
        reason: 'a clock that went back does not move the stamp back');
    final d = Stamp.next(last: c, nowMillis: 1001, device: 'a');
    expect((d.wallMillis, d.counter), (1001, 0));
    expect(
        a.compareTo(b) < 0 && b.compareTo(c) < 0 && c.compareTo(d) < 0, isTrue);
  });

  test('receive: the next stamp is after both what was seen and what was held',
      () {
    final seen = const Stamp(wallMillis: 5000, counter: 3, device: 'b');
    final r1 =
        Stamp.receive(last: null, seen: seen, nowMillis: 1000, device: 'a');
    expect(r1.compareTo(seen) > 0, isTrue);
    expect((r1.wallMillis, r1.counter), (5000, 4),
        reason: 'the seen wall wins and its counter advances');
    final r2 =
        Stamp.receive(last: r1, seen: seen, nowMillis: 1000, device: 'a');
    expect((r2.wallMillis, r2.counter), (5000, 5),
        reason: 'both at the seen wall: the larger counter advances');
    final r3 = Stamp.receive(
        last: r2,
        seen: const Stamp(wallMillis: 4000, counter: 9, device: 'b'),
        nowMillis: 1000,
        device: 'a');
    expect((r3.wallMillis, r3.counter), (5000, 6),
        reason: 'the held wall wins and its counter advances');
    final r4 =
        Stamp.receive(last: r3, seen: seen, nowMillis: 9000, device: 'a');
    expect((r4.wallMillis, r4.counter), (9000, 0),
        reason: 'physical time ahead of both: fresh');
  });

  test('order is total and the device breaks the last tie', () {
    const a = Stamp(wallMillis: 1, counter: 0, device: 'a');
    const b = Stamp(wallMillis: 1, counter: 0, device: 'b');
    expect(a.compareTo(b) < 0, isTrue);
    expect(a == const Stamp(wallMillis: 1, counter: 0, device: 'a'), isTrue);
    expect(a.hashCode,
        const Stamp(wallMillis: 1, counter: 0, device: 'a').hashCode);
    expect(a.toString(), '1.0@a');
  });
}
