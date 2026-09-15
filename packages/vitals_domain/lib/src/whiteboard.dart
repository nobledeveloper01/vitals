import 'immunisation.dart';
import 'record.dart';
import 'registration.dart';

/// One child on the whiteboard: who, what is due, and how far behind.
final class DueChild {
  const DueChild(
      {required this.patient,
      required this.registration,
      required this.due,
      required this.mostOverdueDays});
  final List<int> patient;
  final Registration registration;
  final List<CardLine> due;

  /// Days past the most overdue line's due day; zero when nothing is overdue.
  final int mostOverdueDays;
}

/// The ward's whiteboard (ADR-0006 #7) and the defaulter list: every child
/// with a dose due today, ordered so the furthest behind is first, and the
/// defaulters — overdue beyond the grace — as their own list for the day
/// somebody walks the village. Presented; nothing is decided.
abstract final class Whiteboard {
  static List<DueChild> today(Iterable<Record> records,
      {required int todayDays}) {
    final out = <DueChild>[];
    for (final r in records) {
      final reg = Registration.of(r.current);
      if (reg == null) continue;
      if (!Schedule.covers(bornDays: reg.bornDays, todayDays: todayDays)) {
        continue;
      }
      final card = Card.of(
          bornDays: reg.bornDays,
          given: Given.of(r.current),
          todayDays: todayDays);
      final due = Card.dueNow(card);
      if (due.isEmpty) continue;
      var behind = 0;
      for (final l in due) {
        if (l.status == Status.overdue) {
          final b = todayDays - l.dueOn!;
          if (b > behind) behind = b;
        }
      }
      out.add(DueChild(
          patient: r.patient,
          registration: reg,
          due: due,
          mostOverdueDays: behind));
    }
    out.sort((a, b) {
      final c = b.mostOverdueDays.compareTo(a.mostOverdueDays);
      return c != 0
          ? c
          : a.registration.fullName.compareTo(b.registration.fullName);
    });
    return out;
  }

  /// Defaulters: children with at least one dose overdue.
  static List<DueChild> defaulters(Iterable<Record> records,
          {required int todayDays}) =>
      today(records, todayDays: todayDays)
          .where((c) => c.mostOverdueDays > 0)
          .toList();
}
