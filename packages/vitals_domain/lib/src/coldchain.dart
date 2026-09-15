import 'fact.dart';

/// The cold-chain log (ADR-0006 #11): the fridge temperature in tenths of a
/// degree, morning and evening, as a fact on the facility's record. The
/// range is the one printed on the fridge (2 to 8 °C); a reading outside
/// it is marked *attention*, which is a number compared to a range.
final class FridgeReading {
  const FridgeReading(
      {required this.tenths, required this.minutes, this.fridge = 'main'});
  final int tenths;
  final int minutes;
  final String fridge;

  static const int lowTenths = 20, highTenths = 80;
  bool get outside => tenths < lowTenths || tenths > highTenths;

  List<int> encode() {
    final f = fridge.codeUnits;
    return [
      2,
      ...[for (var s = 24; s >= 0; s -= 8) (tenths >> s) & 0xff],
      ...[for (var s = 56; s >= 0; s -= 8) (minutes >> s) & 0xff],
      f.length,
      ...f
    ];
  }

  static FridgeReading decode(List<int> b) {
    var i = 0;
    if (b[i++] != 2) throw ArgumentError('fridge version');
    var t = 0;
    for (var k = 0; k < 4; k++) {
      t = (t << 8) | b[i++];
    }
    var m = 0;
    for (var k = 0; k < 8; k++) {
      m = (m << 8) | b[i++];
    }
    final n = b[i++];
    return FridgeReading(
        tenths: t.toSigned(32),
        minutes: m,
        fridge: String.fromCharCodes(b.sublist(i, i + n)));
  }

  static List<FridgeReading> of(Iterable<Fact> current) {
    // On the facility's own record, in the vitals slot, told apart from a
    // patient's observation by its version byte.
    final out = [
      for (final f in current)
        if (f.kind == FactKind.vitals &&
            f.payload.isNotEmpty &&
            f.payload[0] == 2)
          decode(f.payload)
    ];
    out.sort((a, b) => a.minutes.compareTo(b.minutes));
    return out;
  }

  /// Which of today's two prompts is still unanswered: the morning one
  /// before noon, the evening one after. Minutes since 1970, local.
  static List<String> duePrompts(List<FridgeReading> today,
      {required int nowMinutes}) {
    final dayStart = nowMinutes - nowMinutes % 1440;
    final noon = dayStart + 720;
    final morning = today.any((r) => r.minutes >= dayStart && r.minutes < noon);
    final evening =
        today.any((r) => r.minutes >= noon && r.minutes < dayStart + 1440);
    return [
      if (!morning) 'morning',
      if (nowMinutes >= noon && !evening) 'evening'
    ];
  }
}
