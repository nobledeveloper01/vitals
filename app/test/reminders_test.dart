// The mother's phone: a card per child naming the next vaccine and its day —
// overdue in the attention colour, due now, or in so many days — and a
// complete card said so.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/shell.dart';
import 'package:vitals/speech/patient_strings.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'phone-test');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-rem-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 9));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<void> child(
      WidgetTester t, String given, int bornDays, List<Given> doses) async {
    final patient = ids.patient();
    final reg = Registration(
        givenName: given,
        familyName: 'Bello',
        sex: 1,
        bornDays: bornDays,
        dobEstimated: false);
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.registration,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload: reg.encode(),
              supersedes: null),
          for (final g in doses)
            Fact(
                id: ids.fact(),
                patient: patient,
                kind: FactKind.immunisation,
                stamp: ids.stamp(),
                author: 'nurse-a',
                payload: g.encode(),
                supersedes: null),
        ]));
  }

  testWidgets('each child names the next vaccine and its day', (t) async {
    final semantics = t.ensureSemantics();
    final birthDoses = [
      for (final d in Schedule.v1.where((d) => d.dueDays == 0))
        Given(vaccine: d.vaccine, dose: d.dose, givenDays: today - 100)
    ];
    await child(t, 'Musa', today - 100, birthDoses);
    await child(t, 'Amina', today - 10, const []);
    await child(t, 'Sadiq', today - 20, [
      for (final d in Schedule.v1.where((d) => d.dueDays == 0))
        Given(vaccine: d.vaccine, dose: d.dose, givenDays: today - 20)
    ]);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Reminders(records: records, today: today)))));
    await t.pumpAndSettle();
    expect(
        find.bySemanticsLabel('Musa Bello: OPV 1 · 58 ${Strings.daysOverdue}'),
        findsOneWidget,
        reason: 'due at day 42, today is day 100');
    expect(
        find.bySemanticsLabel(
            'Amina Bello: BCG · ${PatientStrings.t('dueNow')}'),
        findsOneWidget);
    expect(
        find.bySemanticsLabel(
            'Sadiq Bello: OPV 1 · ${PatientStrings.t('inDays')} 22 ${Strings.days}'),
        findsOneWidget,
        reason: 'the six-week doses are 42 days from birth');
    semantics.dispose();
  });

  testWidgets('a complete card is said to be complete', (t) async {
    final semantics = t.ensureSemantics();
    await child(t, 'Zara', today - 600, [
      for (final d in Schedule.v1)
        Given(
            vaccine: d.vaccine,
            dose: d.dose,
            givenDays: today - 600 + d.dueDays)
    ]);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: Reminders(records: records, today: today))));
    await t.pumpAndSettle();
    expect(
        find.bySemanticsLabel(
            'Zara Bello: ${PatientStrings.t('cardComplete')}'),
        findsOneWidget);
    semantics.dispose();
  });
}
