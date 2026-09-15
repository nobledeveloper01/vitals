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

  /// The list as data: number to product. A list that covers a prefix is
  /// declared by [covered]; a number whose prefix is not covered is a
  /// question the list cannot answer, not a number that is not on it.
  static Verification check(String? number,
      {required Map<String, String> list, required Set<String> covered}) {
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
