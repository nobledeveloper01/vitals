// The referral letter holds the sections the nurse chose and not the
// others; the reason is the nurse's words; the bytes are a PDF.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/report/referral_pdf.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  final today = Gs1.daysOf(2026, 9, 15);
  Fact fact(int n, FactKind kind, List<int> payload) => Fact(
      id: List.filled(32, n),
      patient: List.filled(16, 1),
      kind: kind,
      stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
      author: 'nurse-a',
      payload: payload,
      supersedes: null);

  test('chosen sections in, unchosen out', () async {
    final reg = Registration(
        givenName: 'Ada',
        familyName: 'Eze',
        sex: 0,
        bornDays: today - 100,
        dobEstimated: false);
    final current = [
      fact(1, FactKind.registration, reg.encode()),
      fact(
          2,
          FactKind.immunisation,
          Given(
                  vaccine: Vaccine.bcg,
                  dose: 1,
                  givenDays: today - 99,
                  batch: 'B1')
              .encode()),
      fact(
          3,
          FactKind.vitals,
          Observation(
                  measure: Measure.weight,
                  value: 5200,
                  takenMinutes: today * 1440)
              .encode()),
      fact(4, FactKind.note, const Note(text: 'a private note').encode()),
    ];
    final lines = ReferralPdf.lines(
        current: current,
        chosen: {Section.card, Section.vitals},
        todayDays: today);
    expect(lines.keys.toSet(), {Section.card, Section.vitals});
    expect(lines[Section.card]!.first, 'BCG: given 08/06/2026 batch B1');
    expect(lines[Section.vitals]!.single, contains('Weight 5.2 kg'));
    expect(lines.values.expand((l) => l).join(), isNot(contains('private')));
    final bytes = await ReferralPdf.render(
        reg: reg,
        sections: lines,
        to: 'General Hospital Ikeja',
        from: 'Ikeja PHC',
        reason:
            'Weight not rising since the last visit; mother asks for a second opinion.',
        author: 'nurse-a',
        todayDays: today);
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    expect(String.fromCharCodes(bytes), contains('Referral: Ada Eze'));
  });
}
