// Phase 3 on the screen: a newborn's card with three doses due at birth;
// BCG recorded from a scanned vial and shown as given with its batch; an
// expired vial refused before anything is written; every dose attributed.
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
  final born = Gs1.daysOf(2026, 9, 1);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-imm-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 4));
  });
  tearDown(() async => dir.delete(recursive: true));

  /// Written through the real event loop: the log is real file IO, which a
  /// widget test's fake clock never turns.
  Future<List<int>> newborn(WidgetTester t) async {
    final patient = ids.patient();
    final reg = Registration(
        givenName: 'Ife',
        familyName: 'Okafor',
        sex: 0,
        bornDays: born,
        dobEstimated: false,
        motherName: 'Ngozi');
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.registration,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload: reg.encode(),
              supersedes: null)
        ]));
    return patient;
  }

  Widget app(List<int> patient, int today) => MaterialApp(
      home: PatientScreen(
          records: records,
          patient: patient,
          ids: ids,
          author: 'nurse-a',
          today: today));

  Future<void> tapAndWrite(WidgetTester t, Finder f) async {
    await t.runAsync(() async {
      await t.tap(f);
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  testWidgets(
      'a newborn has three doses due; BCG from a scanned vial is given with its batch',
      (t) async {
    final semantics = t.ensureSemantics();
    final patient = await newborn(t);
    await t.pumpWidget(app(patient, born + 2));
    await t.pumpAndSettle();
    expect(find.text('Ife Okafor'), findsOneWidget);
    expect(find.text('3 ${Strings.dueNow}'), findsOneWidget);
    expect(find.bySemanticsLabel('BCG: ${Strings.due}'), findsOneWidget);
    expect(find.bySemanticsLabel('Penta 1: ${Strings.notYet}'), findsOneWidget);

    await t.tap(find.text(Strings.recordDose));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dose-bcg-1')), findsOneWidget);
    await t.enterText(find.byKey(const Key('scan')),
        '(01)05012345678900(17)271231(10)BCG-7A');
    await t.pumpAndSettle();
    expect(find.text('BCG-7A'), findsOneWidget,
        reason: 'the batch filled itself from the scan');
    expect(find.textContaining('2027-12-31'), findsOneWidget);
    await tapAndWrite(t, find.text(Strings.recordDose).last);
    expect(find.text('2 ${Strings.dueNow}'), findsOneWidget);
    expect(find.bySemanticsLabel('BCG: ${Strings.given}'), findsOneWidget);
    final given = Given.of(records.all.values.single.current);
    expect(given.single.batch, 'BCG-7A');
    expect(given.single.expiryDays, Gs1.daysOf(2027, 12, 31));
    expect(records.all.values.single.all.last.author, 'nurse-a',
        reason: 'attributed');
    semantics.dispose();
  });

  testWidgets('the print button hands over an A5 PDF named for the child',
      (t) async {
    final patient = await newborn(t);
    List<int>? bytes;
    String? name;
    await t.pumpWidget(MaterialApp(
        home: PatientScreen(
            records: records,
            patient: patient,
            ids: ids,
            author: 'nurse-a',
            today: born + 2,
            facility: 'Ikeja PHC',
            share: (pdf, n) async {
              bytes = pdf;
              name = n;
            })));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.tap(find.byTooltip(Strings.printCard));
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump();
    expect(name, 'card-ife-okafor.pdf');
    expect(String.fromCharCodes(bytes!.sublist(0, 5)), '%PDF-');
  });

  testWidgets('an expired vial is refused and nothing is written', (t) async {
    final patient = await newborn(t);
    await t.pumpWidget(app(patient, born + 2));
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.recordDose));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('scan')), '(17)250101(10)OLD');
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.recordDose).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('refusal')), findsOneWidget);
    expect(find.text(Strings.expiredVial), findsOneWidget);
    expect(Given.of(records.all.values.single.current), isEmpty);
  });

  testWidgets(
      'a six-month-old with nothing given is overdue for the first of each series, and dose two waits',
      (t) async {
    final semantics = t.ensureSemantics();
    final patient = await newborn(t);
    await t.pumpWidget(app(patient, born + 182));
    await t.pumpAndSettle();
    expect(
        find.bySemanticsLabel('Penta 1: ${Strings.overdue}'), findsOneWidget);
    expect(find.bySemanticsLabel('Penta 2: ${Strings.afterTheFirst}'),
        findsOneWidget);
    expect(
        find.bySemanticsLabel('Measles 1: ${Strings.notYet}'), findsOneWidget);
    await t.tap(find.text(Strings.recordDose));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dose-penta-1')));
    await t.pumpAndSettle();
    await tapAndWrite(t, find.text(Strings.recordDose).last);
    expect(find.bySemanticsLabel('Penta 1: ${Strings.given}'), findsOneWidget);
    expect(find.bySemanticsLabel('Penta 2: ${Strings.due}'), findsOneWidget,
        reason:
            'the series has started; the next waits its interval and is due');
    semantics.dispose();
  });
}
