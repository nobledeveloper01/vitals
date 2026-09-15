// A pack checked: on the list, not on the list, the list cannot say — and
// the screen's words, in every language, never include the fourth one.
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/verify.dart';
import 'package:vitals/speech/patient_strings.dart';

void main() {
  Future<void> check(WidgetTester t, String text) async {
    await t.enterText(find.byKey(const Key('packText')), text);
    await t.tap(find.text(PatientStrings.t('check')));
    await t.pumpAndSettle();
  }

  testWidgets('three outcomes', (t) async {
    await t.pumpWidget(const MaterialApp(home: VerifyScreen()));
    await t.pumpAndSettle();
    await check(t, 'NAFDAC REG NO a4 - 1234');
    expect(find.text(PatientStrings.t('onTheList')), findsOneWidget);
    expect(find.textContaining('Paracetamol'), findsOneWidget);
    await check(t, 'A4-7777');
    expect(find.text(PatientStrings.t('notOnTheList')), findsOneWidget);
    await check(t, 'Z9-0001');
    expect(find.text(PatientStrings.t('cannotSay')), findsOneWidget,
        reason: 'Z9 is not covered by the list');
    await check(t, 'nothing printed');
    expect(find.text(PatientStrings.t('cannotSay')), findsOneWidget);
  });

  test('no language says genuine, authentic, fake or counterfeit', () {
    final banned = RegExp(
        r'\b(genuine|authentic|fake|counterfeit\w*|original|gidi|fake)\b',
        caseSensitive: false);
    for (final e in PatientStrings.tables.entries) {
      for (final kv in e.value.entries) {
        expect(banned.hasMatch(kv.value), isFalse,
            reason: '${e.key.name}.${kv.key} says "${kv.value}"');
      }
    }
  });
}
