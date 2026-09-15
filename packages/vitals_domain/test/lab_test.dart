// Lab results as the laboratory said them, AEFI as the form asks it: both
// round-trip, both list newest first, an AEFI with a sign unanswered cannot
// be encoded, and the two new kinds have codes the server knows.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  Fact fact(int n, FactKind kind, List<int> payload) => Fact(
      id: List.filled(32, n),
      patient: List.filled(16, 1),
      kind: kind,
      stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
      author: 'nurse',
      payload: payload,
      supersedes: null);

  test('a lab result round-trips as text and lists newest first', () {
    final r = LabResult(
        test: 'Haemoglobin',
        result: '10.2',
        unit: 'g/dL',
        lab: 'LUTH',
        sampledDays: 20_000,
        reportedDays: 20_002);
    final back = LabResult.decode(r.encode());
    expect((
      back.test,
      back.result,
      back.unit,
      back.lab,
      back.sampledDays,
      back.reportedDays
    ), (
      'Haemoglobin',
      '10.2',
      'g/dL',
      'LUTH',
      20_000,
      20_002
    ));
    final older = LabResult(
        test: 'HIV',
        result: 'non-reactive',
        sampledDays: 19_000,
        reportedDays: 19_001);
    final list = LabResult.of([
      fact(1, FactKind.lab, older.encode()),
      fact(2, FactKind.lab, r.encode())
    ]);
    expect(list.map((l) => l.test), ['Haemoglobin', 'HIV']);
  });

  test(
      'an AEFI keeps every answer and the form\'s own serious box; unanswered cannot be encoded',
      () {
    final partial = Aefi(
        vaccine: 3, dose: 1, onsetDays: 20_000, answers: {AefiSign.rash: true});
    expect(() => partial.encode(), throwsStateError);
    final answers = {for (final s in AefiSign.values) s: false}
      ..[AefiSign.feverHigh] = true
      ..[AefiSign.persistentCrying] = true;
    final a = Aefi(
        vaccine: 3,
        dose: 1,
        onsetDays: 20_000,
        answers: answers,
        notes: 'Began the evening after.',
        seriousAnswered: false,
        reported: true);
    final back = Aefi.decode(a.encode());
    expect(back.present, [AefiSign.feverHigh, AefiSign.persistentCrying]);
    expect((
      back.vaccine,
      back.dose,
      back.onsetDays,
      back.notes,
      back.seriousAnswered,
      back.reported
    ), (
      3,
      1,
      20_000,
      'Began the evening after.',
      false,
      true
    ));
    expect(
        Aefi.of([fact(1, FactKind.aefi, a.encode())]).single.complete, isTrue);
  });

  test('the new kinds have the codes the server has', () {
    expect(FactKind.lab.code, 8);
    expect(FactKind.aefi.code, 9);
    expect(FactKind.fromCode(9), FactKind.aefi);
  });
}
