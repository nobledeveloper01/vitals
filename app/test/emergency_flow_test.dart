// The emergency card: nothing on the lock face until the patient opts in;
// then what they typed, and only that; opted out, it is gone from the face
// and kept in the record; never on a clinic tablet's lock.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/emergency.dart';
import 'package:vitals/screens/lock.dart';
import 'package:vitals/speech/patient_strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/preferences.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'phone-test');

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-emerg-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 14));
    Preferences.shared.face = Face.patient;
  });
  tearDown(() async {
    Preferences.shared.face = Face.unchosen;
    await dir.delete(recursive: true);
  });

  Future<List<int>> me(WidgetTester t) async {
    final patient = ids.patient();
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.registration,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload: Registration(
                      givenName: 'Ada',
                      familyName: 'Eze',
                      sex: 0,
                      bornDays: 10000,
                      dobEstimated: false)
                  .encode(),
              supersedes: null)
        ]));
    return patient;
  }

  Future<void> io(WidgetTester t, Future<void> Function() body) async {
    await t.runAsync(() async {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  testWidgets('opt in, shown on the lock face; opt out, gone and kept',
      (t) async {
    final patient = await me(t);
    await t.pumpWidget(MaterialApp(home: LockScreen(records: records)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emergencyLine-0')), findsNothing);

    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body:
                EmergencySheet(records: records, patient: patient, ids: ids))));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('bloodGroup')), 'O+');
    await t.enterText(find.byKey(const Key('allergies')), 'penicillin');
    await t.tap(find.byKey(const Key('shown')));
    await t.pump();
    await io(t, () => t.tap(find.text(PatientStrings.t('save'))));
    // The sheet popped the test's only route; start a fresh tree.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(MaterialApp(home: LockScreen(records: records)));
    await t.pumpAndSettle();
    expect(find.text('${PatientStrings.t('bloodGroup')}: O+'), findsOneWidget);
    expect(find.text('${PatientStrings.t('allergies')}: penicillin'),
        findsOneWidget);
    expect(find.text(PatientStrings.t('pregnantNow')), findsNothing);

    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body:
                EmergencySheet(records: records, patient: patient, ids: ids))));
    await t.pumpAndSettle();
    expect(find.text('O+'), findsOneWidget,
        reason: 'the sheet shows what is set');
    await t.tap(find.byKey(const Key('shown')));
    await t.pump();
    await io(t, () => t.tap(find.text(PatientStrings.t('save'))));
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(MaterialApp(home: LockScreen(records: records)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emergencyLine-0')), findsNothing);
    final history = records.all.values.single.all
        .where((f) => f.kind == FactKind.note)
        .length;
    expect(history, 2, reason: 'opting out is a fact, not a deletion');
  });

  testWidgets('never on a clinic tablet', (t) async {
    final patient = await me(t);
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.note,
              stamp: ids.stamp(),
              author: 'patient',
              payload: const Emergency(shown: true, bloodGroup: 'AB-').encode(),
              supersedes: null)
        ]));
    Preferences.shared.face = Face.clinic;
    await t.pumpWidget(MaterialApp(home: LockScreen(records: records)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emergencyLine-0')), findsNothing);
  });
}
