import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'sample.dart';

Record child(int p, String given, int bornDays, List<Given> given_) => Record.of(patientId(p), [
      Fact(id: id(p * 10), patient: patientId(p), kind: FactKind.registration, stamp: Stamp(wallMillis: p, counter: 0, device: 't'), author: 'n', payload: Registration(givenName: given, familyName: 'Okeke', sex: 0, bornDays: bornDays, dobEstimated: false).encode(), supersedes: null),
      for (final (i, g) in given_.indexed)
        Fact(id: id(p * 10 + 1 + i), patient: patientId(p), kind: FactKind.immunisation, stamp: Stamp(wallMillis: p + i + 1, counter: 0, device: 't'), author: 'n', payload: g.encode(), supersedes: null),
    ]);

void main() {
  final today = Gs1.daysOf(2026, 9, 15);

  test('the whiteboard lists every child with something due, furthest behind first; defaulters are the overdue', () {
    final records = [
      child(1, 'Ife', today - 2, const []), // newborn: three due, none overdue
      child(2, 'Tunde', today - 120, const []), // four months, nothing given: badly behind
      child(3, 'Aisha', today - 120, [Given(vaccine: Vaccine.bcg, dose: 1, givenDays: today - 119), Given(vaccine: Vaccine.opv, dose: 0, givenDays: today - 119), Given(vaccine: Vaccine.hepB0, dose: 1, givenDays: today - 119), Given(vaccine: Vaccine.penta, dose: 1, givenDays: today - 78), Given(vaccine: Vaccine.opv, dose: 1, givenDays: today - 78), Given(vaccine: Vaccine.pcv, dose: 1, givenDays: today - 78), Given(vaccine: Vaccine.rota, dose: 1, givenDays: today - 78), Given(vaccine: Vaccine.penta, dose: 2, givenDays: today - 50), Given(vaccine: Vaccine.opv, dose: 2, givenDays: today - 50), Given(vaccine: Vaccine.pcv, dose: 2, givenDays: today - 50), Given(vaccine: Vaccine.rota, dose: 2, givenDays: today - 50)]),
      child(4, 'Bola', today - 5, const []), // newborn, nothing due yet beyond birth doses — all three due
    ];
    final board = Whiteboard.today(records, todayDays: today);
    expect(board.map((c) => c.registration.givenName), ['Tunde', 'Aisha', 'Bola', 'Ife'], reason: 'behind first, then by name');
    expect(board.first.mostOverdueDays, 120, reason: 'BCG due at birth, 120 days ago');
    expect(board.firstWhere((c) => c.registration.givenName == 'Aisha').due.map((l) => '${l.due.vaccine.label} ${l.due.dose}'), ['OPV 3', 'Penta 3', 'PCV 3', 'IPV 1'], reason: 'the fourteen-week doses, due since day 98');
    final defaulters = Whiteboard.defaulters(records, todayDays: today);
    expect(defaulters.map((c) => c.registration.givenName), ['Tunde'], reason: 'Aisha is within grace for her fourteen-week doses');
  });

  test('a child with everything given for their age is not on the board', () {
    final r = child(9, 'Done', today - 3, [Given(vaccine: Vaccine.bcg, dose: 1, givenDays: today - 3), Given(vaccine: Vaccine.opv, dose: 0, givenDays: today - 3), Given(vaccine: Vaccine.hepB0, dose: 1, givenDays: today - 3)]);
    expect(Whiteboard.today([r], todayDays: today), isEmpty);
    expect(Whiteboard.today([Record.empty(patientId(5))], todayDays: today), isEmpty, reason: 'no registration, no card');
  });
}
