// The ward whiteboard on the clinic home: children with a dose due, the
// furthest behind first, a triangle and a count for the ones behind, a row
// that opens the child, and the message draft for a mother with a phone.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/shell.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'tab-test');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-board-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 5));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<void> child(WidgetTester t, String given, int bornDays,
      {String phone = ''}) async {
    final patient = ids.patient();
    final reg = Registration(
        givenName: given,
        familyName: 'Okeke',
        sex: 0,
        bornDays: bornDays,
        dobEstimated: false,
        phone: phone);
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
  }

  testWidgets('the whiteboard lists the due, behind first, and opens a child',
      (t) async {
    final semantics = t.ensureSemantics();
    await child(t, 'Ife', today - 2);
    await child(t, 'Tunde', today - 120, phone: '08031234567');
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: WhiteboardList(records: records, today: today)))));
    await t.pumpAndSettle();
    expect(find.text('2 ${Strings.dueToday}'), findsOneWidget);
    expect(find.bySemanticsLabel('1 ${Strings.defaulters}'), findsOneWidget);
    final names = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .where((s) => s.endsWith('Okeke'))
        .toList();
    expect(names, ['Tunde Okeke', 'Ife Okeke'], reason: 'behind first');
    expect(
        find.bySemanticsLabel(
            RegExp('Tunde Okeke: .* 120 ${Strings.daysOverdue}')),
        findsOneWidget);
    expect(find.byTooltip(Strings.draftSms), findsOneWidget,
        reason: 'only the mother with a phone gets a draft');
    await t.tap(find.text('Ife Okeke'));
    await t.pumpAndSettle();
    expect(find.text(Strings.immunisationCard), findsOneWidget,
        reason: 'the row opens the child');
    semantics.dispose();
  });

  testWidgets('nothing due, nothing shown', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: WhiteboardList(records: records, today: today))));
    await t.pumpAndSettle();
    expect(find.textContaining(Strings.dueToday), findsNothing);
  });
}
