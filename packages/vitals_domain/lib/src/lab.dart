import 'fact.dart';
import 'text.dart';

/// A laboratory result as the laboratory reported it (Phase 6): the test's
/// name, the result as printed — a number with its unit, or a word like
/// *reactive* — the laboratory, the day the sample was taken and the day
/// the result came. Text, not a number the app compares to anything: a
/// laboratory's reference range is printed on the laboratory's own report,
/// and the word for what a result means is the clinician's (ADR-0008).
final class LabResult {
  const LabResult(
      {required this.test,
      required this.result,
      this.unit = '',
      this.lab = '',
      required this.sampledDays,
      required this.reportedDays});
  final String test;
  final String result;
  final String unit;
  final String lab;
  final int sampledDays;
  final int reportedDays;

  List<int> encode() {
    final out = <int>[1];
    void str(String s) {
      final u = utf8Of(s);
      out.addAll([u.length >> 8, u.length & 0xff, ...u]);
    }

    str(test);
    str(result);
    str(unit);
    str(lab);
    for (final v in [sampledDays, reportedDays]) {
      for (var s = 24; s >= 0; s -= 8) {
        out.add((v >> s) & 0xff);
      }
    }
    return out;
  }

  static LabResult decode(List<int> b) {
    var i = 0;
    if (b[i++] != 1) throw ArgumentError('lab version');
    String str() {
      final n = (b[i++] << 8) | b[i++];
      final s = stringOf(b.sublist(i, i + n));
      i += n;
      return s;
    }

    int i32() {
      var v = 0;
      for (var k = 0; k < 4; k++) {
        v = (v << 8) | b[i++];
      }
      return v.toSigned(32);
    }

    final test = str(), result = str(), unit = str(), lab = str();
    return LabResult(
        test: test,
        result: result,
        unit: unit,
        lab: lab,
        sampledDays: i32(),
        reportedDays: i32());
  }

  /// Newest report first.
  static List<LabResult> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.lab) decode(f.payload)
    ];
    out.sort((a, b) => b.reportedDays.compareTo(a.reportedDays));
    return out;
  }
}

/// An adverse event following immunisation (Phase 6): which dose, the day
/// it began, what was observed — a checklist of the signs the national
/// AEFI form asks about, each yes or no — the nurse's words, and whether
/// it was reported onward. No grading: the form's *serious* box is a
/// question the nurse answers, kept as an answer.
enum AefiSign {
  feverHigh(0, 'High fever'),
  swellingAtSite(1, 'Swelling or abscess at the site'),
  rash(2, 'Rash'),
  convulsion(3, 'Convulsion'),
  persistentCrying(4, 'Persistent crying over three hours'),
  collapse(5, 'Collapse or shock-like episode'),
  breathing(6, 'Difficulty breathing'),
  admitted(7, 'Admitted to hospital'),
  died(8, 'Died');

  const AefiSign(this.code, this.question);
  final int code;
  final String question;
}

final class Aefi {
  const Aefi(
      {required this.vaccine,
      required this.dose,
      required this.onsetDays,
      required this.answers,
      this.notes = '',
      this.seriousAnswered = false,
      this.reported = false});
  final int vaccine;
  final int dose;
  final int onsetDays;
  final Map<AefiSign, bool> answers;
  final String notes;

  /// The form's own *serious* box, as the nurse answered it.
  final bool seriousAnswered;
  final bool reported;

  bool get complete => AefiSign.values.every(answers.containsKey);
  List<AefiSign> get present => [
        for (final s in AefiSign.values)
          if (answers[s] == true) s
      ];

  List<int> encode() {
    if (!complete) throw StateError('every sign must be answered');
    final u = utf8Of(notes);
    return [
      1,
      vaccine,
      dose,
      for (var s = 24; s >= 0; s -= 8) (onsetDays >> s) & 0xff,
      AefiSign.values.length,
      for (final s in AefiSign.values) answers[s]! ? 1 : 0,
      seriousAnswered ? 1 : 0,
      reported ? 1 : 0,
      u.length >> 8,
      u.length & 0xff,
      ...u,
    ];
  }

  static Aefi decode(List<int> b) {
    var i = 0;
    if (b[i++] != 1) throw ArgumentError('aefi version');
    final vaccine = b[i++], dose = b[i++];
    var onset = 0;
    for (var k = 0; k < 4; k++) {
      onset = (onset << 8) | b[i++];
    }
    final n = b[i++];
    final answers = <AefiSign, bool>{};
    for (var k = 0; k < n; k++) {
      final v = b[i++];
      if (k < AefiSign.values.length) answers[AefiSign.values[k]] = v == 1;
    }
    final serious = b[i++] == 1, reported = b[i++] == 1;
    final tn = (b[i++] << 8) | b[i++];
    return Aefi(
        vaccine: vaccine,
        dose: dose,
        onsetDays: onset.toSigned(32),
        answers: answers,
        notes: stringOf(b.sublist(i, i + tn)),
        seriousAnswered: serious,
        reported: reported);
  }

  static List<Aefi> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.aefi) decode(f.payload)
    ];
    out.sort((a, b) => b.onsetDays.compareTo(a.onsetDays));
    return out;
  }
}
