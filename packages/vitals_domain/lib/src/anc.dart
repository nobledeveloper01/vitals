import 'fact.dart';
import 'text.dart';

/// Antenatal care as facts. The registration of a pregnancy carries the
/// first day of the last period and the count of previous pregnancies and
/// births; the expected day of delivery is that day plus 280, which is the
/// convention's arithmetic and nobody's judgement. A visit carries the
/// danger-sign checklist — every sign answered yes or no by the nurse, never
/// summed, never totalled (ADR-0006 refused the total) — and the visit number.
final class Pregnancy {
  const Pregnancy(
      {required this.lmpDays,
      required this.gravida,
      required this.para,
      this.lmpEstimated = false});
  final int lmpDays;
  final int gravida, para;
  final bool lmpEstimated;

  int get eddDays => lmpDays + 280;

  /// The current pregnancy: the latest registered, in the ANC slot with its
  /// own version byte, or none.
  static Pregnancy? of(Iterable<Fact> current) {
    Fact? latest;
    for (final f in current) {
      if (f.kind == FactKind.ancVisit &&
          f.payload.isNotEmpty &&
          f.payload[0] == 2 &&
          (latest == null || f.compareTo(latest) > 0)) {
        latest = f;
      }
    }
    return latest == null ? null : decode(latest.payload);
  }

  /// Completed weeks on a given day, from the last period: arithmetic.
  int weeksOn(int todayDays) => (todayDays - lmpDays) ~/ 7;

  List<int> encode() =>
      [2, ..._i32(lmpDays), gravida, para, lmpEstimated ? 1 : 0];

  static Pregnancy decode(List<int> b) {
    if (b[0] != 2) throw ArgumentError('pregnancy version');
    return Pregnancy(
        lmpDays: _readI32(b, 1),
        gravida: b[5],
        para: b[6],
        lmpEstimated: b[7] == 1);
  }
}

/// The danger signs the national ANC card asks at every visit, as data.
/// Each is a question the nurse answers; the answers are recorded and shown.
enum DangerSign {
  bleeding(0, 'Vaginal bleeding'),
  severeHeadache(1, 'Severe headache'),
  blurredVision(2, 'Blurred vision'),
  convulsions(3, 'Convulsions or fits'),
  swelling(4, 'Swollen face or hands'),
  fever(5, 'Fever'),
  abdominalPain(6, 'Severe abdominal pain'),
  reducedMovement(7, 'Baby moving less'),
  waterBreaking(8, 'Water breaking'),
  breathless(9, 'Difficulty breathing');

  const DangerSign(this.code, this.question);
  final int code;
  final String question;
}

final class AncVisit {
  const AncVisit(
      {required this.visitNumber,
      required this.visitDays,
      required this.answers,
      this.notes = ''});
  final int visitNumber;
  final int visitDays;

  /// Every sign has an answer: the checklist is mandatory, and an unanswered
  /// sign is a visit that is not recorded.
  final Map<DangerSign, bool> answers;
  final String notes;

  bool get complete => DangerSign.values.every(answers.containsKey);

  /// The signs the nurse answered yes to, for the screen to show in `danger`
  /// beside the word the nurse chooses.
  List<DangerSign> get present => [
        for (final s in DangerSign.values)
          if (answers[s] == true) s
      ];

  List<int> encode() {
    if (!complete) throw StateError('every danger sign must be answered');
    final u = utf8Of(notes);
    return [
      1,
      visitNumber,
      ..._i32(visitDays),
      DangerSign.values.length,
      for (final s in DangerSign.values) answers[s]! ? 1 : 0,
      u.length >> 8,
      u.length & 0xff,
      ...u,
    ];
  }

  static AncVisit decode(List<int> b) {
    var i = 0;
    if (b[i++] != 1) throw ArgumentError('visit version');
    final n = b[i++];
    final days = _readI32(b, i);
    i += 4;
    final count = b[i++];
    final answers = <DangerSign, bool>{};
    for (var k = 0; k < count; k++) {
      final v = b[i++];
      if (k < DangerSign.values.length) answers[DangerSign.values[k]] = v == 1;
    }
    final tn = (b[i++] << 8) | b[i++];
    return AncVisit(
        visitNumber: n,
        visitDays: days,
        answers: answers,
        notes: stringOf(b.sublist(i, i + tn)));
  }

  static List<AncVisit> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.ancVisit &&
            f.payload.isNotEmpty &&
            f.payload[0] == 1)
          decode(f.payload)
    ];
    out.sort((a, b) => a.visitDays.compareTo(b.visitDays));
    return out;
  }
}

List<int> _i32(int v) => [for (var s = 24; s >= 0; s -= 8) (v >> s) & 0xff];
int _readI32(List<int> b, int at) {
  var v = 0;
  for (var k = 0; k < 4; k++) {
    v = (v << 8) | b[at + k];
  }
  return v.toSigned(32);
}
