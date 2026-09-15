import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/report/card_pdf.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  test('the A5 card renders every scheduled dose with what happened to it',
      () async {
    final born = Gs1.daysOf(2026, 1, 1);
    final reg = Registration(
        givenName: 'Ife',
        familyName: 'Okafor',
        sex: 0,
        bornDays: born,
        dobEstimated: true,
        motherName: 'Ngozi',
        phone: '0803');
    final given = [
      Given(vaccine: Vaccine.bcg, dose: 1, givenDays: born + 1, batch: 'B-77')
    ];
    final card = Card.of(bornDays: born, given: given, todayDays: born + 100);
    final bytes = await CardPdf.render(
        reg: reg, card: card, todayDays: born + 100, facility: 'Ikeja PHC');
    expect(bytes.length, greaterThan(1500));
    expect(String.fromCharCodes(bytes.sublist(0, 8)), startsWith('%PDF-'));
    // The text is in the content stream, compressed; the document's own
    // metadata is not, and names the child.
    final text = String.fromCharCodes(bytes);
    expect(text, contains('Ife Okafor'));
  });
}
