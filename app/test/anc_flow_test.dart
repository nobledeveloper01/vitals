// Antenatal on the screen: a pregnancy registered with its expected day
// labelled as arithmetic; a visit that cannot be recorded until every sign
// is answered; the signs answered yes shown one by one and never counted
// into anything; a bad date refused.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/anc.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/drafts.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  late Drafts drafts;
  final ids = Ids(device: 'tab-test');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-anc-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 8));
    drafts = Drafts(Directory('${dir.path}/drafts'));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<List<int>> mother(WidgetTester t) async {
    final patient = ids.patient();
    final reg = Registration(
        givenName: 'Hauwa',
        familyName: 'Sani',
        sex: 0,
        bornDays: Gs1.daysOf(1998, 2, 2),
        dobEstimated: false);
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

  Future<void> io(WidgetTester t, Future<void> Function() body) async {
    await t.runAsync(() async {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  Widget app(List<int> patient) => MaterialApp(
      home: AncScreen(
          records: records,
          patient: patient,
          ids: ids,
          author: 'nurse-a',
          drafts: drafts,
          today: today));

  testWidgets(
      'a pregnancy is registered; the expected day says where it comes from',
      (t) async {
    final patient = await mother(t);
    await t.pumpWidget(app(patient));
    await t.pumpAndSettle();
    expect(find.text(Strings.noPregnancyYet), findsOneWidget);
    await t.tap(find.text(Strings.registerPregnancy));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('lmp')), '2026-13-01');
    await t.tap(find.text(Strings.registerPregnancy).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('refusal')), findsOneWidget);
    await t.enterText(find.byKey(const Key('lmp')), '2026-06-15');
    await t.enterText(find.byKey(const Key('gravida')), '2');
    await t.enterText(find.byKey(const Key('para')), '1');
    await io(t, () => t.tap(find.text(Strings.registerPregnancy).last));
    expect(find.text('13 ${Strings.weeks}'), findsOneWidget,
        reason: '92 days over seven');
    expect(find.textContaining('2027-03-22'), findsOneWidget,
        reason: 'June 15 plus 280 days');
    expect(find.textContaining(Strings.fromLastPeriod), findsOneWidget);
    expect(Pregnancy.of(records.all.values.single.current)!.gravida, 2);
  });

  testWidgets(
      'a visit needs every sign answered; the yeses are listed, not counted',
      (t) async {
    final semantics = t.ensureSemantics();
    final patient = await mother(t);
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.ancVisit,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload:
                  Pregnancy(lmpDays: today - 100, gravida: 1, para: 0).encode(),
              supersedes: null)
        ]));
    await t.pumpWidget(app(patient));
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.recordVisit));
    await t.pumpAndSettle();
    expect(find.text('10 ${Strings.signsUnanswered}'), findsOneWidget);
    // Every answer drafts to a file, so the taps run through the real loop.
    await io(t, () async {
      for (final s in DangerSign.values) {
        if (s == DangerSign.bleeding || s == DangerSign.fever) continue;
        await t.ensureVisible(find.byKey(Key('no-${s.name}')));
        await t.tap(find.byKey(Key('no-${s.name}')));
      }
    });
    expect(find.text('2 ${Strings.signsUnanswered}'), findsOneWidget);
    await t.ensureVisible(find.text(Strings.recordVisit).last);
    await io(t, () => t.tap(find.text(Strings.recordVisit).last));
    expect(AncVisit.of(records.all.values.single.current), isEmpty,
        reason: 'the button is disabled with two unanswered');
    await io(t, () async {
      await t.ensureVisible(find.byKey(const Key('yes-bleeding')));
      await t.tap(find.byKey(const Key('yes-bleeding')));
      await t.ensureVisible(find.byKey(const Key('yes-fever')));
      await t.tap(find.byKey(const Key('yes-fever')));
    });
    expect(find.byKey(const Key('unanswered')), findsNothing);
    await t.ensureVisible(find.text(Strings.recordVisit).last);
    await io(t, () => t.tap(find.text(Strings.recordVisit).last));
    final visit = AncVisit.of(records.all.values.single.current).single;
    expect(visit.present, [DangerSign.bleeding, DangerSign.fever]);
    expect(
        find.bySemanticsLabel(
            '${Strings.visit} 1, 2026-09-15, ${Strings.answeredYesTo} Vaginal bleeding, Fever'),
        findsOneWidget);
    expect(find.text('Vaginal bleeding'), findsOneWidget);
    expect(find.textContaining('2 '), findsNothing,
        reason: 'no count of the signs anywhere on the screen');
    semantics.dispose();
  });
}
