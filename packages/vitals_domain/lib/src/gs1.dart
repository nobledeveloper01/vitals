/// A vaccine vial's GS1 barcode, as printed: (01) GTIN, (17) expiry YYMMDD,
/// (10) batch, in any order, with or without the parentheses and with the
/// group separator (ASCII 29) a scanner sends. The batch and the expiry fill
/// the dose form; an expired vial is refused before the dose is recorded —
/// a date compared to a date, which is not interpretation.
final class Gs1 {
  const Gs1({this.gtin = '', this.batch = '', this.expiryDays});
  final String gtin;
  final String batch;

  /// Days since 1970 of the expiry, or null when not printed.
  final int? expiryDays;

  static const String groupSeparator = '\x1d';

  static Gs1? parse(String raw) {
    var s = raw.replaceAll(groupSeparator, '(');
    s = s.replaceAll(RegExp(r'[()\s]'), '');
    if (s.isEmpty) return null;
    var gtin = '', batch = '';
    int? expiry;
    var i = 0;
    var any = false;
    while (i + 2 <= s.length) {
      final ai = s.substring(i, i + 2);
      i += 2;
      switch (ai) {
        case '01':
          if (i + 14 > s.length) {
            return any ? Gs1(gtin: gtin, batch: batch, expiryDays: expiry) : null;
          }
          gtin = s.substring(i, i + 14);
          i += 14;
          any = true;
        case '17':
          if (i + 6 > s.length) {
            return any ? Gs1(gtin: gtin, batch: batch, expiryDays: expiry) : null;
          }
          final y = int.tryParse(s.substring(i, i + 2));
          final m = int.tryParse(s.substring(i + 2, i + 4));
          final d = int.tryParse(s.substring(i + 4, i + 6));
          if (y == null || m == null || d == null || m < 1 || m > 12) return null;
          // Day 00 means the end of the month.
          expiry = daysOf(2000 + y, m, d == 0 ? _daysIn(2000 + y, m) : d);
          i += 6;
          any = true;
        case '10':
          // Variable length: to the next known AI or the end.
          final rest = s.substring(i);
          final stop = RegExp(r'(01\d{14}|17\d{6})').firstMatch(rest);
          batch = stop == null ? rest : rest.substring(0, stop.start);
          i += batch.length;
          any = true;
        default:
          return any ? Gs1(gtin: gtin, batch: batch, expiryDays: expiry) : null;
      }
    }
    return any ? Gs1(gtin: gtin, batch: batch, expiryDays: expiry) : null;
  }

  static int _daysIn(int y, int m) => [
        31,
        (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28,
        31,
        30,
        31,
        30,
        31,
        31,
        30,
        31,
        30,
        31
      ][m - 1];

  /// Days since 1970-01-01 for a civil date, without a calendar library.
  static int daysOf(int y, int m, int d) {
    var days = 0;
    for (var yy = 1970; yy < y; yy++) {
      days += (yy % 4 == 0 && (yy % 100 != 0 || yy % 400 == 0)) ? 366 : 365;
    }
    for (var mm = 1; mm < m; mm++) {
      days += _daysIn(y, mm);
    }
    return days + d - 1;
  }
}
