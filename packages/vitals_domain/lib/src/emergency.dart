import 'fact.dart';
import 'text.dart';

/// The emergency card (ADR-0006 #17): blood group, allergies and a current
/// pregnancy, on the phone's lock face, only while the patient has opted
/// in. Opting out is a new fact with [shown] false, so the history keeps
/// that it was once shown and when it stopped. Version byte 2 in the note
/// slot. What is on it was typed by the patient or the nurse; nothing is
/// read out of the record for it.
final class Emergency {
  const Emergency(
      {required this.shown,
      this.bloodGroup = '',
      this.allergies = '',
      this.pregnant = false});
  final bool shown;
  final String bloodGroup;
  final String allergies;
  final bool pregnant;

  List<int> encode() {
    final out = <int>[2, shown ? 1 : 0];
    void str(String s) {
      final u = utf8Of(s);
      out.addAll([u.length >> 8, u.length & 0xff, ...u]);
    }

    str(bloodGroup);
    str(allergies);
    out.add(pregnant ? 1 : 0);
    return out;
  }

  static Emergency decode(List<int> b) {
    var i = 0;
    if (b[i++] != 2) throw ArgumentError('emergency version');
    final shown = b[i++] == 1;
    String str() {
      final n = (b[i++] << 8) | b[i++];
      final s = stringOf(b.sublist(i, i + n));
      i += n;
      return s;
    }

    final bg = str(), al = str();
    return Emergency(
        shown: shown, bloodGroup: bg, allergies: al, pregnant: b[i] == 1);
  }

  /// The latest, or null when never set.
  static Emergency? of(Iterable<Fact> current) {
    Fact? latest;
    for (final f in current) {
      if (f.kind == FactKind.note &&
          f.payload.isNotEmpty &&
          f.payload[0] == 2 &&
          (latest == null || f.compareTo(latest) > 0)) {
        latest = f;
      }
    }
    return latest == null ? null : decode(latest.payload);
  }
}
