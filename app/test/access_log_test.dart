// The access log: a clinic opening a record writes an attributed fact to
// it; the patient's phone lists every open, newest first; the phone's own
// open writes nothing.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/patient.dart';
import 'package:vitals/screens/shell.dart';
import 'package:vitals/speech/patient_strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'tab-7');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-access-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 13));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<List<int>> child(WidgetTester t) async {
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
                      bornDays: today - 400,
                      dobEstimated: false)
                  .encode(),
              supersedes: null)
        ]));
    return patient;
  }

  testWidgets('a clinic open is written, attributed; the phone own open is not',
      (t) async {
    final patient = await child(t);
    await t.runAsync(() async {
      await t.pumpWidget(MaterialApp(
          home: PatientScreen(
              records: records,
              patient: patient,
              ids: ids,
              author: 'nurse-b',
              today: today,
              nowMinutes: today * 1440 + 500,
              openedAt: 'Ikeja PHC')));
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    final opens = Access.of(records.all.values.single.current);
    expect(opens.length, 1);
    expect((opens.single.who, opens.single.device, opens.single.facility),
        ('nurse-b', 'tab-7', 'Ikeja PHC'));
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() async {
      await t.pumpWidget(MaterialApp(
          home: PatientScreen(
              records: records,
              patient: patient,
              ids: ids,
              author: 'patient',
              today: today)));
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    expect(Access.of(records.all.values.single.current).length, 1,
        reason: 'the phone opening its own record is not an access');
  });

  testWidgets('the phone lists every open, newest first', (t) async {
    final patient = await child(t);
    Fact open(String who, int minutes) => Fact(
        id: ids.fact(),
        patient: patient,
        kind: FactKind.access,
        stamp: ids.stamp(),
        author: who,
        payload: Access(
                who: who,
                minutes: minutes,
                device: 'tab-7',
                facility: 'Ikeja PHC')
            .encode(),
        supersedes: null);
    await t.runAsync(() => records.record([
          open('nurse-a', today * 1440 - 3000),
          open('nurse-b', today * 1440 - 60),
        ]));
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AccessLogList(
                records: records,
                now:
                    DateTime.utc(1970).add(Duration(minutes: today * 1440))))));
    await t.pumpAndSettle();
    expect(find.text(PatientStrings.t('nobodyYet')), findsNothing);
    final chips = find.byType(AttributionChip);
    expect(chips, findsNWidgets(2));
    expect((t.widget(chips.first) as AttributionChip).author, 'nurse-b',
        reason: 'newest first');
    expect((t.widget(chips.first) as AttributionChip).kind, 'Ikeja PHC');
  });
}
