/// Drug verification (ADR-0006 #20) with three outcomes and no fourth
/// word. A pack carries a NAFDAC registration number; the phone holds a
/// bundled list it can consult offline. The number is on the list, or it
/// is not, or the list cannot say (no list for that range, or the number
/// was not read). The product never says *genuine*: a number on a list
/// says the number is on the list, and a counterfeiter can print one.
enum Outcome { onTheList, notOnTheList, cannotSay }

final class Verification {
  const Verification(this.outcome, {required this.number, this.product = ''});
  final Outcome outcome;
  final String number;
  final String product;
}

abstract final class Verify {
  /// NAFDAC numbers as printed: a letter or digit pair, a hyphen, four
  /// digits — `A4-1234`, `04-0567` — with the spaces and case a camera
  /// gives. Null when nothing that shape is in the text.
  static String? numberIn(String text) {
    final m = RegExp(r'\b([A-Z0-9]{2})\s*-\s*(\d{4})\b', caseSensitive: false)
        .firstMatch(text.toUpperCase().replaceAll('–', '-'));
    return m == null ? null : '${m[1]}-${m[2]}';
  }

  /// A pack's barcode, as a scanner reads it: a GS1 element string with a
  /// (01) GTIN, or a bare EAN-13 / GTIN-14 of digits. The list may know a
  /// GTIN as well as a number; the number printed inside a code wins.
  static String? gtinIn(String text) {
    final t = text.trim();
    final gs1 = RegExp(r'\(?01\)?(\d{14})').firstMatch(t);
    if (gs1 != null) return gs1[1];
    final bare = RegExp(r'^\d{13,14}$').firstMatch(t);
    return bare == null ? null : bare[0]!.padLeft(14, '0');
  }

  /// The list as data: number to product. A list that covers a prefix is
  /// declared by [covered]; a number whose prefix is not covered is a
  /// question the list cannot answer, not a number that is not on it.
  /// A scanned GTIN the list knows resolves to its number first.
  static Verification check(String? number,
      {required Map<String, String> list,
      required Set<String> covered,
      Map<String, String> gtins = const {},
      String? gtin}) {
    number ??= gtin == null ? null : gtins[gtin];
    if (number == null) {
      return const Verification(Outcome.cannotSay, number: '');
    }
    final prefix = number.substring(0, 2);
    if (!covered.contains(prefix)) {
      return Verification(Outcome.cannotSay, number: number);
    }
    final product = list[number];
    return product == null
        ? Verification(Outcome.notOnTheList, number: number)
        : Verification(Outcome.onTheList, number: number, product: product);
  }
}
