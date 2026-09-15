// A lab result added as text and listed; an event after a dose recorded
// only when every sign is answered, with the form's serious box kept as an
// answer, listed under the card.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/patient.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'tab-test');
  final born = Gs1.daysOf(2026, 6, 1);
  final today = born + 50;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-lab-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 18));
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
                      givenName: 'Ife',
                      familyName: 'Okafor',
                      sex: 0,
                      bornDays: born,
                      dobEstimated: false)
                  .encode(),
              supersedes: null),
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.immunisation,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload:
                  Given(vaccine: Vaccine.penta, dose: 1, givenDays: today - 1)
                      .encode(),
              supersedes: null),
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

  Widget app(List<int> patient) => MaterialApp(
      home: PatientScreen(
          records: records,
          patient: patient,
          ids: ids,
          author: 'nurse-a',
          today: today));

  testWidgets('a lab result is text, listed with its laboratory', (t) async {
    final semantics = t.ensureSemantics();
    final patient = await child(t);
    await t.pumpWidget(app(patient));
    await t.pumpAndSettle();
    expect(find.text(Strings.noLabResults), findsOneWidget);
    await t.tap(find.byTooltip(Strings.addLabResult));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('labTest')), 'Haemoglobin');
    await t.enterText(find.byKey(const Key('labResult')), '10.2');
    await t.enterText(find.byKey(const Key('labUnit')), 'g/dL');
    await t.enterText(find.byKey(const Key('labName')), 'LUTH');
    await t.pump();
    await io(t, () => t.tap(find.text(Strings.addLabResult).last));
    expect(find.text('10.2 g/dL'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Haemoglobin: 10\.2 g/dL, LUTH, ')),
        findsOneWidget);
    final r = LabResult.of(records.all.values.single.current).single;
    expect((r.test, r.result, r.unit, r.lab),
        ('Haemoglobin', '10.2', 'g/dL', 'LUTH'));
    semantics.dispose();
  });

  testWidgets(
      'an event after a dose needs every sign; the serious box is an answer',
      (t) async {
    // A tall surface: the card's header sits below three cards and above
    // three buttons, and the icon must be inside the list's viewport.
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final patient = await child(t);
    await t.pumpWidget(app(patient));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip(Strings.eventAfterDose));
    await t.pumpAndSettle();
    expect(find.text('9 ${Strings.signsUnanswered}'), findsOneWidget);
    for (final s in AefiSign.values) {
      final key =
          Key('aefi-${s == AefiSign.feverHigh ? 'yes' : 'no'}-${s.name}');
      await t.ensureVisible(find.byKey(key));
      await t.tap(find.byKey(key));
    }
    await t.pump();
    expect(find.byKey(const Key('aefiUnanswered')), findsNothing);
    await t.ensureVisible(find.byKey(const Key('aefiReported')));
    await t.tap(find.byKey(const Key('aefiReported')));
    await t.pump();
    await t.ensureVisible(find.text(Strings.recordEvent));
    await io(t, () => t.tap(find.text(Strings.recordEvent)));
    final e = Aefi.of(records.all.values.single.current).single;
    expect(e.present, [AefiSign.feverHigh]);
    expect((e.vaccine, e.dose, e.seriousAnswered, e.reported),
        (Vaccine.penta.code, 1, false, true));
    expect(
        find.textContaining('Penta 1 · High fever · ${Strings.reportedOnward}'),
        findsOneWidget);
  });
}
