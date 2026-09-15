import 'fact.dart';
import 'text.dart';

/// A vital sign as a nurse wrote it: which measure, an integer in the
/// measure's own fixed unit (no floating point crosses a device boundary),
/// the day and minute it was taken, and the encounter it belongs to. The
/// reference range printed beside it on the screen is the published one for
/// the measure; comparing a number to a printed range is arithmetic, and the
/// word for what the number means is the nurse's (ADR-0008).
enum Measure {
  systolic(0, 'Systolic', 'mmHg', 1),
  diastolic(1, 'Diastolic', 'mmHg', 1),
  pulse(2, 'Pulse', '/min', 1),
  temperature(3, 'Temperature', '°C', 10),
  respiratory(4, 'Breaths', '/min', 1),
  spo2(5, 'SpO₂', '%', 1),
  weight(6, 'Weight', 'kg', 1000),
  height(7, 'Height', 'cm', 10),
  muac(8, 'MUAC', 'cm', 10),
  fundalHeight(9, 'Fundal height', 'cm', 1),
  fetalHeart(10, 'Fetal heart', '/min', 1);

  const Measure(this.code, this.label, this.unit, this.perUnit);
  final int code;
  final String label;
  final String unit;

  /// Stored integers per displayed unit: temperature in tenths, weight in
  /// grams, height in millimetres.
  final int perUnit;

  static Measure byCode(int c) => values.firstWhere((m) => m.code == c,
      orElse: () => throw ArgumentError('measure $c'));
}

/// A published reference range, as data. Adult ranges from the WHO/NPHCDA
/// standing orders; the child's from the same, by age band. A range is
/// something the screen prints next to a number; nothing here decides.
final class Reference {
  const Reference(this.measure, this.low, this.high,
      {this.fromDays = 0, this.toDays = 1 << 30});
  final Measure measure;
  final int low, high;
  final int fromDays, toDays;

  static const List<Reference> table = [
    Reference(Measure.systolic, 90, 140, fromDays: 365 * 12),
    Reference(Measure.diastolic, 60, 90, fromDays: 365 * 12),
    Reference(Measure.pulse, 60, 100, fromDays: 365 * 12),
    Reference(Measure.pulse, 70, 120, fromDays: 365 * 2, toDays: 365 * 12),
    Reference(Measure.pulse, 100, 160, toDays: 365 * 2),
    Reference(Measure.temperature, 360, 375),
    Reference(Measure.respiratory, 12, 20, fromDays: 365 * 12),
    Reference(Measure.respiratory, 20, 30, fromDays: 365 * 2, toDays: 365 * 12),
    Reference(Measure.respiratory, 30, 50, toDays: 365 * 2),
    Reference(Measure.spo2, 94, 100),
    Reference(Measure.fetalHeart, 110, 160),
  ];

  static Reference? forAge(Measure m, int ageDays) {
    for (final r in table) {
      if (r.measure == m && ageDays >= r.fromDays && ageDays < r.toDays) {
        return r;
      }
    }
    return null;
  }

  /// Outside the printed range: a comparison, marked *attention* on the screen.
  bool outside(int value) => value < low || value > high;
}

final class Observation implements Comparable<Observation> {
  const Observation(
      {required this.measure,
      required this.value,
      required this.takenMinutes,
      this.encounter = const []});
  final Measure measure;
  final int value;

  /// Minutes since 1970 — a moment, because two readings an hour apart are a trend.
  final int takenMinutes;

  /// 16 bytes naming the encounter, or empty.
  final List<int> encounter;

  List<int> encode() {
    final out = <int>[1, measure.code];
    for (var s = 24; s >= 0; s -= 8) {
      out.add((value >> s) & 0xff);
    }
    for (var s = 56; s >= 0; s -= 8) {
      out.add((takenMinutes >> s) & 0xff);
    }
    out.add(encounter.length);
    out.addAll(encounter);
    return out;
  }

  static Observation decode(List<int> b) {
    var i = 0;
    if (b[i++] != 1) throw ArgumentError('observation version');
    final m = Measure.byCode(b[i++]);
    var v = 0;
    for (var k = 0; k < 4; k++) {
      v = (v << 8) | b[i++];
    }
    var t = 0;
    for (var k = 0; k < 8; k++) {
      t = (t << 8) | b[i++];
    }
    final n = b[i++];
    return Observation(
        measure: m,
        value: v.toSigned(32),
        takenMinutes: t,
        encounter: b.sublist(i, i + n));
  }

  /// Every current vital, oldest first.
  static List<Observation> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.vitals &&
            f.payload.isNotEmpty &&
            f.payload[0] == 1)
          decode(f.payload)
    ];
    out.sort();
    return out;
  }

  /// The last of each measure: the pulse card's numbers.
  static Map<Measure, Observation> latest(List<Observation> all) {
    final out = <Measure, Observation>{};
    for (final o in all) {
      final have = out[o.measure];
      if (have == null || o.takenMinutes >= have.takenMinutes) {
        out[o.measure] = o;
      }
    }
    return out;
  }

  /// The trend drawn behind a number: that measure's readings, oldest first.
  static List<Observation> trend(List<Observation> all, Measure m) =>
      all.where((o) => o.measure == m).toList();

  String get display {
    if (measure.perUnit == 1) return '$value';
    final whole = value ~/ measure.perUnit;
    final frac = value % measure.perUnit;
    final digits = measure.perUnit == 10
        ? 1
        : measure.perUnit == 1000
            ? 1
            : 2;
    final f = (frac * 10 ~/ measure.perUnit).toString().padLeft(digits, '0');
    return '$whole.$f';
  }

  @override
  int compareTo(Observation o) => takenMinutes != o.takenMinutes
      ? takenMinutes.compareTo(o.takenMinutes)
      : measure.code.compareTo(o.measure.code);
}

/// A consultation note (ADR-0006 #5's text half): free text and an optional
/// audio hash, never transcribed, never interpreted.
final class Note {
  const Note(
      {required this.text,
      this.audioSha256 = const [],
      this.encounter = const []});
  final String text;
  final List<int> audioSha256;
  final List<int> encounter;

  List<int> encode() {
    final u = utf8Of(text);
    return [
      1,
      u.length >> 8,
      u.length & 0xff,
      ...u,
      audioSha256.length,
      ...audioSha256,
      encounter.length,
      ...encounter
    ];
  }

  static Note decode(List<int> b) {
    var i = 0;
    if (b[i++] != 1) throw ArgumentError('note version');
    final n = (b[i++] << 8) | b[i++];
    final text = stringOf(b.sublist(i, i + n));
    i += n;
    final hn = b[i++];
    final hash = b.sublist(i, i + hn);
    i += hn;
    final en = b[i++];
    return Note(text: text, audioSha256: hash, encounter: b.sublist(i, i + en));
  }

  static List<Note> of(Iterable<Fact> current) => [
        for (final f in current)
          if (f.kind == FactKind.note &&
              f.payload.isNotEmpty &&
              f.payload[0] == 1)
            decode(f.payload)
      ];
}
