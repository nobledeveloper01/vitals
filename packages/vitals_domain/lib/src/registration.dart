import 'fact.dart';

/// What a registration fact says, and its own canonical encoding inside the
/// fact's payload: the patient's names, sex, date of birth (a day, and
/// whether it is known or estimated), the mother's name, a phone, an
/// address line, and the household the patient belongs to. Every field is a
/// string or a small integer; nothing here is interpreted.
final class Registration {
  const Registration({
    required this.givenName,
    required this.familyName,
    this.otherNames = '',
    required this.sex,
    required this.bornDays,
    required this.dobEstimated,
    this.motherName = '',
    this.phone = '',
    this.address = '',
    this.household = const [],
  });

  final String givenName;
  final String familyName;
  final String otherNames;

  /// 0 female, 1 male, 2 not recorded.
  final int sex;

  /// Days since 1970-01-01; a day, not a moment, because a birth certificate
  /// gives a day and most records give less.
  final int bornDays;
  final bool dobEstimated;
  final String motherName;
  final String phone;
  final String address;

  /// 16 bytes, shared by everyone in one household; empty for none yet.
  final List<int> household;

  List<int> encode() {
    final out = <int>[1];
    void str(String s) {
      final u = _utf8(s);
      out.add(u.length >> 8);
      out.add(u.length & 0xff);
      out.addAll(u);
    }

    str(givenName);
    str(familyName);
    str(otherNames);
    out.add(sex);
    for (var s = 24; s >= 0; s -= 8) {
      out.add((bornDays >> s) & 0xff);
    }
    out.add(dobEstimated ? 1 : 0);
    str(motherName);
    str(phone);
    str(address);
    out.add(household.length);
    out.addAll(household);
    return out;
  }

  static Registration decode(List<int> b) {
    var i = 0;
    int u8() => b[i++];
    String str() {
      final n = (u8() << 8) | u8();
      final s = _fromUtf8(b.sublist(i, i + n));
      i += n;
      return s;
    }

    if (u8() != 1) throw ArgumentError('registration version');
    final given = str(), family = str(), other = str();
    final sex = u8();
    var days = 0;
    for (var k = 0; k < 4; k++) {
      days = (days << 8) | u8();
    }
    days = days.toSigned(32);
    final est = u8() == 1;
    final mother = str(), phone = str(), address = str();
    final hn = u8();
    final household = b.sublist(i, i + hn);
    return Registration(
      givenName: given,
      familyName: family,
      otherNames: other,
      sex: sex,
      bornDays: days,
      dobEstimated: est,
      motherName: mother,
      phone: phone,
      address: address,
      household: household,
    );
  }

  /// The registration a record shows: the latest not superseded, or none.
  static Registration? of(Iterable<Fact> current) {
    Fact? latest;
    for (final f in current) {
      if (f.kind == FactKind.registration && (latest == null || f.compareTo(latest) > 0)) latest = f;
    }
    return latest == null ? null : decode(latest.payload);
  }

  String get fullName => [givenName, otherNames, familyName].where((s) => s.isNotEmpty).join(' ');

  static List<int> _utf8(String s) {
    final out = <int>[];
    for (final c in s.runes) {
      if (c < 0x80) {
        out.add(c);
      } else if (c < 0x800) {
        out.addAll([0xc0 | (c >> 6), 0x80 | (c & 0x3f)]);
      } else if (c < 0x10000) {
        out.addAll([0xe0 | (c >> 12), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f)]);
      } else {
        out.addAll([0xf0 | (c >> 18), 0x80 | ((c >> 12) & 0x3f), 0x80 | ((c >> 6) & 0x3f), 0x80 | (c & 0x3f)]);
      }
    }
    return out;
  }

  static String _fromUtf8(List<int> u) {
    final out = <int>[];
    var i = 0;
    while (i < u.length) {
      final b = u[i];
      if (b < 0x80) {
        out.add(b);
        i++;
      } else if (b < 0xe0) {
        out.add(((b & 0x1f) << 6) | (u[i + 1] & 0x3f));
        i += 2;
      } else if (b < 0xf0) {
        out.add(((b & 0x0f) << 12) | ((u[i + 1] & 0x3f) << 6) | (u[i + 2] & 0x3f));
        i += 3;
      } else {
        out.add(((b & 0x07) << 18) | ((u[i + 1] & 0x3f) << 12) | ((u[i + 2] & 0x3f) << 6) | (u[i + 3] & 0x3f));
        i += 4;
      }
    }
    return String.fromCharCodes(out);
  }
}
