import 'fact.dart';
import 'text.dart';

/// The access log the patient sees (ADR-0006 #15): every open of a record,
/// by whom, when, on which device, as a fact on the record itself — so it
/// travels with the record and a patient's phone can show it. Version byte
/// 2 in the access slot; grants are 1.
final class Access {
  const Access(
      {required this.who,
      required this.minutes,
      required this.device,
      required this.facility});
  final String who;
  final int minutes;
  final String device;
  final String facility;

  List<int> encode() {
    final out = <int>[2];
    void str(String s) {
      final u = utf8Of(s);
      out.addAll([u.length >> 8, u.length & 0xff, ...u]);
    }

    str(who);
    for (var s = 56; s >= 0; s -= 8) {
      out.add((minutes >> s) & 0xff);
    }
    str(device);
    str(facility);
    return out;
  }

  static Access decode(List<int> b) {
    var i = 0;
    if (b[i++] != 2) throw ArgumentError('access version');
    String str() {
      final n = (b[i++] << 8) | b[i++];
      final s = stringOf(b.sublist(i, i + n));
      i += n;
      return s;
    }

    final who = str();
    var m = 0;
    for (var k = 0; k < 8; k++) {
      m = (m << 8) | b[i++];
    }
    final device = str(), facility = str();
    return Access(who: who, minutes: m, device: device, facility: facility);
  }

  /// Newest first: the last person to open the record at the top.
  static List<Access> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.access &&
            f.payload.isNotEmpty &&
            f.payload[0] == 2)
          decode(f.payload)
    ];
    out.sort((a, b) => b.minutes.compareTo(a.minutes));
    return out;
  }
}
