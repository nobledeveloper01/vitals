import 'fact.dart';
import 'text.dart';

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
      if (f.kind == FactKind.registration &&
          (latest == null || f.compareTo(latest) > 0)) {
        latest = f;
      }
    }
    return latest == null ? null : decode(latest.payload);
  }

  String get fullName =>
      [givenName, otherNames, familyName].where((s) => s.isNotEmpty).join(' ');

  static List<int> _utf8(String s) => utf8Of(s);
  static String _fromUtf8(List<int> u) => stringOf(u);
}
