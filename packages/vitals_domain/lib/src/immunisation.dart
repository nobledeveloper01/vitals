import 'fact.dart';

/// The vaccines the national routine schedule names. The code is the
/// encoding's; add at the end, never renumber.
enum Vaccine {
  bcg(0, 'BCG'),
  hepB0(1, 'Hep B birth dose'),
  opv(2, 'OPV'),
  penta(3, 'Penta'),
  pcv(4, 'PCV'),
  rota(5, 'Rota'),
  ipv(6, 'IPV'),
  measles(7, 'Measles'),
  yellowFever(8, 'Yellow fever'),
  menA(9, 'Men A'),
  vitaminA(10, 'Vitamin A');

  const Vaccine(this.code, this.label);
  final int code;
  final String label;
  static Vaccine fromCode(int c) => Vaccine.values.firstWhere((v) => v.code == c);
}

/// One dose on the schedule: the vaccine, which dose in its series, the age
/// it is due (days), and the earliest age it may be given. The national
/// schedule as data, versioned, so a change is a new table and the version
/// a patient was scheduled under is recorded on their card.
final class Due {
  const Due(this.vaccine, this.dose, this.dueDays, {required this.earliestDays, this.intervalDays = 28});
  final Vaccine vaccine;
  final int dose;
  final int dueDays;
  final int earliestDays;

  /// Minimum days after the previous dose of the same series.
  final int intervalDays;
}

abstract final class Schedule {
  /// Nigeria's routine immunisation schedule, version 1 (NPHCDA, as
  /// published): birth, 6, 10 and 14 weeks, 6, 9 and 15 months.
  static const int version = 1;

  static const List<Due> v1 = [
    Due(Vaccine.bcg, 1, 0, earliestDays: 0),
    Due(Vaccine.opv, 0, 0, earliestDays: 0),
    Due(Vaccine.hepB0, 1, 0, earliestDays: 0),
    Due(Vaccine.opv, 1, 42, earliestDays: 42),
    Due(Vaccine.penta, 1, 42, earliestDays: 42),
    Due(Vaccine.pcv, 1, 42, earliestDays: 42),
    Due(Vaccine.rota, 1, 42, earliestDays: 42),
    Due(Vaccine.opv, 2, 70, earliestDays: 70),
    Due(Vaccine.penta, 2, 70, earliestDays: 70),
    Due(Vaccine.pcv, 2, 70, earliestDays: 70),
    Due(Vaccine.rota, 2, 70, earliestDays: 70),
    Due(Vaccine.opv, 3, 98, earliestDays: 98),
    Due(Vaccine.penta, 3, 98, earliestDays: 98),
    Due(Vaccine.pcv, 3, 98, earliestDays: 98),
    Due(Vaccine.ipv, 1, 98, earliestDays: 98),
    Due(Vaccine.vitaminA, 1, 182, earliestDays: 182, intervalDays: 182),
    Due(Vaccine.measles, 1, 274, earliestDays: 274),
    Due(Vaccine.yellowFever, 1, 274, earliestDays: 274),
    Due(Vaccine.menA, 1, 274, earliestDays: 274),
    Due(Vaccine.vitaminA, 2, 365, earliestDays: 365, intervalDays: 182),
    Due(Vaccine.measles, 2, 456, earliestDays: 456),
  ];

  static List<Due> table(int version) => switch (version) { 1 => v1, _ => throw ArgumentError('schedule version $version') };
}

/// A dose given, as a fact's payload: vaccine, dose number, the day it was
/// given, the batch and its expiry, and the schedule version in force.
final class Given {
  const Given({required this.vaccine, required this.dose, required this.givenDays, this.batch = '', this.expiryDays = 0, this.scheduleVersion = Schedule.version});
  final Vaccine vaccine;
  final int dose;
  final int givenDays;
  final String batch;
  final int expiryDays;
  final int scheduleVersion;

  List<int> encode() {
    final b = <int>[1, vaccine.code, dose];
    void i32(int v) {
      for (var s = 24; s >= 0; s -= 8) {
        b.add((v >> s) & 0xff);
      }
    }

    i32(givenDays);
    final batchUnits = batch.codeUnits;
    b.add(batchUnits.length);
    b.addAll(batchUnits);
    i32(expiryDays);
    b.add(scheduleVersion);
    return b;
  }

  static Given decode(List<int> b) {
    var i = 0;
    int u8() => b[i++];
    int i32() {
      var v = 0;
      for (var k = 0; k < 4; k++) {
        v = (v << 8) | u8();
      }
      return v.toSigned(32);
    }

    if (u8() != 1) throw ArgumentError('given version');
    final vaccine = Vaccine.fromCode(u8());
    final dose = u8();
    final given = i32();
    final n = u8();
    final batch = String.fromCharCodes(b.sublist(i, i + n));
    i += n;
    final expiry = i32();
    final sv = u8();
    return Given(vaccine: vaccine, dose: dose, givenDays: given, batch: batch, expiryDays: expiry, scheduleVersion: sv);
  }

  static List<Given> of(Iterable<Fact> current) =>
      [for (final f in current) if (f.kind == FactKind.immunisation) decode(f.payload)];
}

/// One line of the card: a scheduled dose and what happened to it.
enum Status { given, due, overdue, notYet, seriesNotStarted }

final class CardLine {
  const CardLine(this.due, this.status, {this.given, this.dueOn});
  final Due due;
  final Status status;
  final Given? given;

  /// The day this dose is due for this child — the schedule's age, or later
  /// when a catch-up interval pushes it.
  final int? dueOn;
}

abstract final class Card {
  /// The child's card as of [todayDays]: every scheduled dose, given or not,
  /// with catch-up — a dose not given by its day stays due, and the next in
  /// its series waits the minimum interval after the last one actually
  /// given. Overdue is due plus a grace of 28 days. An estimated date of
  /// birth changes nothing here; the card says it is estimated.
  static List<CardLine> of({required int bornDays, required List<Given> given, required int todayDays, int version = Schedule.version, int graceDays = 28}) {
    final table = Schedule.table(version);
    final lines = <CardLine>[];
    for (final d in table) {
      final match = given.where((g) => g.vaccine == d.vaccine && g.dose == d.dose).toList()..sort((a, b) => a.givenDays.compareTo(b.givenDays));
      if (match.isNotEmpty) {
        lines.add(CardLine(d, Status.given, given: match.first, dueOn: bornDays + d.dueDays));
        continue;
      }
      var dueOn = bornDays + d.dueDays;
      // Catch-up: after the previous dose in the series, if that was late.
      final previous = given.where((g) => g.vaccine == d.vaccine && g.dose == d.dose - 1).toList()..sort((a, b) => a.givenDays.compareTo(b.givenDays));
      if (previous.isNotEmpty) {
        final earliestAfter = previous.first.givenDays + d.intervalDays;
        if (earliestAfter > dueOn) dueOn = earliestAfter;
      }
      final earliest = bornDays + d.earliestDays;
      final Status status;
      if (todayDays < earliest) {
        status = Status.notYet;
      } else if (d.dose > 1 && previous.isEmpty) {
        status = Status.seriesNotStarted; // the first dose comes first
      } else if (todayDays > dueOn + graceDays) {
        status = Status.overdue;
      } else {
        status = Status.due;
      }
      lines.add(CardLine(d, status, dueOn: dueOn));
    }
    return lines;
  }

  /// What is due now, in schedule order: the next thing to give.
  static List<CardLine> dueNow(List<CardLine> card) => card.where((l) => l.status == Status.due || l.status == Status.overdue).toList();
}
