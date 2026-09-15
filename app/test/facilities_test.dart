// The facility list by distance: from a position, nearest first with the
// kilometres; without one, an area's centre and the words that say so.
import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/data/facilities.dart';
import 'package:vitals/screens/facilities.dart';
import 'package:vitals/speech/patient_strings.dart';

void main() {
  test('kilometres on the sphere, and nearest first', () {
    expect(Facilities.km(6.5, 3.35, 6.5, 3.35), 0);
    // One degree of latitude is about 111 km.
    expect(Facilities.km(6.0, 3.35, 7.0, 3.35), closeTo(111.2, 0.5));
    final near = Facilities.near(6.60, 3.35);
    expect(near.first.$1.name, 'Ikeja Primary Health Centre');
    expect(near.first.$2, lessThan(0.5));
    expect(near.last.$1.name, 'Onikan Health Centre');
  });

  testWidgets('with a position: from where you are', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(MaterialApp(
        home: FacilitiesScreen(locate: () async => (6.518, 3.354))));
    await t.pumpAndSettle();
    expect(find.text(PatientStrings.t('fromWhereYouAre')), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp(
            r'^Lagos University Teaching Hospital, Teaching hospital, Mushin, 0\.0 km$')),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('without one: pick an area, distances from its centre',
      (t) async {
    await t.pumpWidget(
        MaterialApp(home: FacilitiesScreen(locate: () async => null)));
    await t.pumpAndSettle();
    expect(find.text(PatientStrings.t('noPosition')), findsOneWidget);
    expect(find.byKey(const Key('fromNote')), findsNothing);
    await t.tap(find.byKey(const Key('area-Ikorodu')));
    await t.pumpAndSettle();
    expect(find.text('${PatientStrings.t('fromTheCentreOf')} Ikorodu'),
        findsOneWidget);
    final names = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .where((s) => s.contains('Hospital') || s.contains('Centre'))
        .toList();
    expect(names.first, 'Ikorodu General Hospital');
  });
}
