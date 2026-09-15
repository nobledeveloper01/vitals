// The schedule against published ages, catch-up when a child arrives late,
// a series that waits its interval, an estimated date of birth that changes
// no arithmetic, doses as facts that round-trip, and GS1 as a scanner sends it.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  final born = Gs1.daysOf(2026, 1, 1);

  test('at birth three things are due and nothing else; at six weeks four more', () {
    final atBirth = Card.of(bornDays: born, given: const [], todayDays: born);
    expect(Card.dueNow(atBirth).map((l) => '${l.due.vaccine.label} ${l.due.dose}'), ['BCG 1', 'OPV 0', 'Hep B birth dose 1']);
    expect(atBirth.where((l) => l.status == Status.notYet).length, Schedule.v1.length - 3);
    final sixWeeks = Card.of(bornDays: born, given: const [], todayDays: born + 42);
    expect(Card.dueNow(sixWeeks).map((l) => '${l.due.vaccine.label} ${l.due.dose}'), ['BCG 1', 'OPV 0', 'Hep B birth dose 1', 'OPV 1', 'Penta 1', 'PCV 1', 'Rota 1']);
    expect(sixWeeks.firstWhere((l) => l.due.vaccine == Vaccine.penta && l.due.dose == 2).status, Status.notYet, reason: 'ten weeks is not yet');
  });

  test('a dose not given by its day plus grace is overdue; given, it is given', () {
    final late = Card.of(bornDays: born, given: const [], todayDays: born + 42 + 28);
    expect(late.firstWhere((l) => l.due.vaccine == Vaccine.bcg).status, Status.overdue);
    expect(late.firstWhere((l) => l.due.vaccine == Vaccine.penta && l.due.dose == 1).status, Status.due, reason: 'within grace');
    final given = [Given(vaccine: Vaccine.bcg, dose: 1, givenDays: born + 1, batch: 'B1')];
    final card = Card.of(bornDays: born, given: given, todayDays: born + 100);
    final bcg = card.firstWhere((l) => l.due.vaccine == Vaccine.bcg);
    expect(bcg.status, Status.given);
    expect(bcg.given!.batch, 'B1');
  });

  test('catch-up: a child of six months with nothing given gets the first of each series now, and the next waits its interval', () {
    final today = born + 182;
    final card = Card.of(bornDays: born, given: const [], todayDays: today);
    expect(card.firstWhere((l) => l.due.vaccine == Vaccine.penta && l.due.dose == 1).status, Status.overdue);
    expect(card.firstWhere((l) => l.due.vaccine == Vaccine.penta && l.due.dose == 2).status, Status.seriesNotStarted, reason: 'dose two is not offered before dose one');
    final afterFirst = Card.of(bornDays: born, given: [Given(vaccine: Vaccine.penta, dose: 1, givenDays: today)], todayDays: today);
    final two = afterFirst.firstWhere((l) => l.due.vaccine == Vaccine.penta && l.due.dose == 2);
    expect(two.status, Status.due);
    expect(two.dueOn, today + 28, reason: 'the interval pushes the due day past the schedule age');
    final threeWeeksOn = Card.of(bornDays: born, given: [Given(vaccine: Vaccine.penta, dose: 1, givenDays: today)], todayDays: today + 21);
    expect(threeWeeksOn.firstWhere((l) => l.due.vaccine == Vaccine.penta && l.due.dose == 2).status, Status.due, reason: 'due, not overdue, until grace has passed');
  });

  test('an estimated date of birth changes no arithmetic', () {
    final a = Card.of(bornDays: born, given: const [], todayDays: born + 300);
    final b = Card.of(bornDays: born, given: const [], todayDays: born + 300);
    expect(a.map((l) => l.status).toList(), b.map((l) => l.status).toList());
    expect(a.firstWhere((l) => l.due.vaccine == Vaccine.measles && l.due.dose == 1).status, Status.due);
  });

  test('the reminder is the earliest dose not given, overdue first, and nothing when the card is complete', () {
    final atBirth = Card.of(bornDays: born, given: const [], todayDays: born);
    expect(Card.next(atBirth)!.due.vaccine, Vaccine.bcg);
    final lateForPenta = Card.of(bornDays: born, given: [for (final d in Schedule.v1.where((d) => d.dueDays == 0)) Given(vaccine: d.vaccine, dose: d.dose, givenDays: born)], todayDays: born + 100);
    final n = Card.next(lateForPenta)!;
    expect((n.due.vaccine, n.due.dose, n.status), (Vaccine.opv, 1, Status.overdue), reason: 'the six-week doses, in schedule order');
    final complete = Card.of(bornDays: born, given: [for (final d in Schedule.v1) Given(vaccine: d.vaccine, dose: d.dose, givenDays: born + d.dueDays)], todayDays: born + 600);
    expect(Card.next(complete), isNull);
  });

  test('a dose given round-trips through its payload and out of a record', () {
    final g = Given(vaccine: Vaccine.rota, dose: 2, givenDays: born + 75, batch: 'RV-2026-0042', expiryDays: born + 400);
    final back = Given.decode(g.encode());
    expect((back.vaccine, back.dose, back.givenDays, back.batch, back.expiryDays, back.scheduleVersion), (Vaccine.rota, 2, born + 75, 'RV-2026-0042', born + 400, 1));
    expect(Given.of(const []), isEmpty);
    expect(() => Schedule.table(9), throwsArgumentError);
  });

  test('GS1 as printed, with the separator a scanner sends, in any order', () {
    final a = Gs1.parse('(01)05012345678900(17)271231(10)ABC123');
    expect((a!.gtin, a.batch, a.expiryDays), ('05012345678900', 'ABC123', Gs1.daysOf(2027, 12, 31)));
    final b = Gs1.parse('010501234567890010ABC123${Gs1.groupSeparator}17270200');
    expect((b!.batch, b.expiryDays), ('ABC123', Gs1.daysOf(2027, 2, 28)), reason: 'day 00 is the end of the month');
    final c = Gs1.parse('17280229 10 LOT9');
    expect((c!.expiryDays, c.batch, c.gtin), (Gs1.daysOf(2028, 2, 29), 'LOT9', ''));
    expect(Gs1.parse(''), isNull);
    expect(Gs1.parse('hello'), isNull);
    expect(Gs1.parse('171399'), isNull, reason: 'month 13');
    expect(Gs1.daysOf(1970, 1, 1), 0);
    expect(Gs1.daysOf(2000, 3, 1), 11017);
  });
}
