// The encoding at its edges: every UTF-8 width in a string, negative time,
// truncation, a wrong version, trailing bytes, and a fixture that pins the
// bytes for ever.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'sample.dart';

void main() {
  test('strings of every UTF-8 width round-trip', () {
    for (final s in ['nurse-a', 'Adé', 'Ọlá', '孙', '🩺 ward', '']) {
      final f = Fact(id: id(1), patient: patientId(1), kind: FactKind.note, stamp: Stamp(wallMillis: -5, counter: 0, device: s), author: s, payload: const [], supersedes: null);
      final r = Record.of(patientId(1), [f]);
      final back = Canonical.recordFrom(Canonical.bytesOf(r));
      expect(back.all.single.author, s);
      expect(back.all.single.stamp.device, s);
      expect(back.all.single.stamp.wallMillis, -5, reason: 'a negative wall time survives');
    }
  });

  test('a supersedes id round-trips and a missing one is a zero byte', () {
    final a = fact(1, device: 'a', wall: 10);
    final s = fact(2, device: 'a', wall: 11, kind: FactKind.supersession, supersedes: a.id);
    final r = Record.of(patientId(1), [a, s]);
    final back = Canonical.recordFrom(Canonical.bytesOf(r));
    expect(back.all[1].supersedes, a.id);
    expect(back.all[0].supersedes, isNull);
  });

  test('truncation, a wrong version, trailing bytes and an overlong id are refused', () {
    final bytes = Canonical.bytesOf(Record.of(patientId(1), [fact(1, device: 'a', wall: 1)]));
    for (var n = 0; n < bytes.length; n += 7) {
      expect(() => Canonical.recordFrom(bytes.sublist(0, n)), throwsA(isA<CanonicalError>()), reason: 'cut at $n');
    }
    expect(() => Canonical.recordFrom([2, ...bytes.skip(1)]), throwsA(isA<CanonicalError>()));
    expect(() => Canonical.recordFrom([...bytes, 0]), throwsA(isA<CanonicalError>()));
    final long = Fact(id: List.filled(300, 1), patient: patientId(1), kind: FactKind.note, stamp: const Stamp(wallMillis: 1, counter: 0, device: 'a'), author: 'a', payload: const [], supersedes: null);
    expect(() => Canonical.bytesOf(Record.of(patientId(1), [long])), throwsA(isA<CanonicalError>()));
    expect(const CanonicalError('x').toString(), 'CanonicalError: x');
  });

  test('the fixture: these bytes, for ever', () {
    final r = Record.of(patientId(1), [fact(1, device: 'a', wall: 1_700_000_000_000), fact(2, device: 'b', wall: 1_700_000_000_500, kind: FactKind.immunisation, author: 'nurse-b')]);
    final bytes = Canonical.bytesOf(r);
    expect(bytes.first, 1, reason: 'the version is the first byte');
    expect(bytes.length, 184);
    // The first fact's stamp: version, 1+16 patient, u32 count, 1+32 id, 1+16 patient, kind, then i64 wall.
    final wallAt = 1 + 17 + 4 + 33 + 17 + 1;
    expect(bytes.sublist(wallAt, wallAt + 8), [0, 0, 1, 0x8b, 0xcf, 0xe5, 0x68, 0]);
  });
}
