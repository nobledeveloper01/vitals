import 'fact.dart';
import 'record.dart';
import 'text.dart';

/// A share grant (ADR-0006 #16): the patient chose which kinds of fact a
/// facility may hold and until which day. The grant is a fact on the
/// patient's own record, so it travels with the record and is audited like
/// everything else; and it is enforced where the payload is built — a fact
/// outside the scope is never put in the bytes, rather than hidden after.
final class Grant {
  const Grant(
      {required this.grantee,
      required this.kinds,
      required this.untilDays,
      required this.givenDays});

  /// Who may hold the facts: a facility's name as the patient saw it.
  final String grantee;
  final Set<FactKind> kinds;
  final int untilDays;
  final int givenDays;

  bool activeOn(int todayDays) => todayDays <= untilDays;

  List<int> encode() {
    final u = utf8Of(grantee);
    var mask = 0;
    for (final k in kinds) {
      mask |= 1 << k.code;
    }
    return [
      1,
      u.length >> 8,
      u.length & 0xff,
      ...u,
      (mask >> 8) & 0xff,
      mask & 0xff,
      for (var s = 24; s >= 0; s -= 8) (untilDays >> s) & 0xff,
      for (var s = 24; s >= 0; s -= 8) (givenDays >> s) & 0xff,
    ];
  }

  static Grant decode(List<int> b) {
    var i = 0;
    if (b[i++] != 1) throw ArgumentError('grant version');
    final n = (b[i++] << 8) | b[i++];
    final grantee = stringOf(b.sublist(i, i + n));
    i += n;
    final mask = (b[i++] << 8) | b[i++];
    int i32() {
      var v = 0;
      for (var k = 0; k < 4; k++) {
        v = (v << 8) | b[i++];
      }
      return v.toSigned(32);
    }

    final until = i32(), given = i32();
    return Grant(
      grantee: grantee,
      kinds: {
        for (final k in FactKind.values)
          if (mask & (1 << k.code) != 0) k
      },
      untilDays: until,
      givenDays: given,
    );
  }

  /// Grants live in the access slot with their own version byte.
  static List<Grant> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.access &&
            f.payload.isNotEmpty &&
            f.payload[0] == 1)
          decode(f.payload)
    ];
    out.sort((a, b) => a.givenDays.compareTo(b.givenDays));
    return out;
  }
}

abstract final class Scope {
  /// The facts a grantee may be handed today: those of a kind the latest
  /// active grant to them allows. No grant, or an expired one, is nothing —
  /// the empty list, not the whole record with a flag on it. The
  /// registration always goes, because a record without a name is not a
  /// record the grantee can attach to a person; the grant screen says so.
  static List<Fact> payload(Record record,
      {required String grantee, required int todayDays}) {
    Grant? grant;
    for (final g in Grant.of(record.current)) {
      if (g.grantee == grantee && g.activeOn(todayDays)) grant = g;
    }
    if (grant == null) return const [];
    final allowed = {...grant.kinds, FactKind.registration};
    return [
      for (final f in record.all)
        if (allowed.contains(f.kind)) f
    ];
  }
}
