// The patient face in a chosen language: the reminder speaks Yorùbá when
// Yorùbá is chosen, the settings say the table is a draft, English says
// nothing of the kind, and every table has every key.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/settings.dart';
import 'package:vitals/screens/shell.dart';
import 'package:vitals/speech/patient_strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/preferences.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'phone-test');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-lang-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 11));
    Preferences.shared.lang = Lang.english;
  });
  tearDown(() async {
    Preferences.shared.lang = Lang.english;
    Preferences.shared.face = Face.unchosen;
    await dir.delete(recursive: true);
  });

  test('every language has every key, and none is English by accident', () {
    for (final e in PatientStrings.tables.entries) {
      expect(e.value.keys.toSet(), PatientStrings.english.keys.toSet(),
          reason: '${e.key.name} is complete');
      if (e.key == Lang.english) continue;
      final same = e.value.entries
          .where((kv) => PatientStrings.english[kv.key] == kv.value)
          .map((kv) => kv.key)
          .toList();
      // Naijá shares words with English; a table that is English with
      // another file name would share nearly all of them.
      expect(same.length, lessThan(PatientStrings.english.length ~/ 4),
          reason: '${e.key.name} repeats English for $same');
    }
  });

  testWidgets('the reminder speaks the chosen language', (t) async {
    final semantics = t.ensureSemantics();
    final patient = ids.patient();
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.registration,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload: Registration(
                      givenName: 'Tolu',
                      familyName: 'Ade',
                      sex: 0,
                      bornDays: today - 10,
                      dobEstimated: false)
                  .encode(),
              supersedes: null)
        ]));
    Preferences.shared.lang = Lang.yoruba;
    await t.pumpWidget(MaterialApp(
        home: Scaffold(body: Reminders(records: records, today: today))));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('Tolu Ade: BCG · ó tó àkókò'), findsOneWidget);
    expect(find.text(PatientStrings.english['reminderNote']!), findsNothing);
    expect(find.text(PatientStrings.t('reminderNote', lang: Lang.yoruba)),
        findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the settings say a language is a draft, and English is not',
      (t) async {
    // The clinic face is not offered a language.
    Preferences.shared.face = Face.clinic;
    await t.pumpWidget(MaterialApp(home: SettingsScreen(records: records)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lang-hausa')), findsNothing);
    Preferences.shared.face = Face.patient;
    await t.pumpWidget(MaterialApp(home: SettingsScreen(records: records)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('draftNote')), findsNothing);
    await t.tap(find.byKey(const Key('lang-hausa')));
    await t.pumpAndSettle();
    expect(Preferences.shared.lang, Lang.hausa);
    expect(find.byKey(const Key('draftNote')), findsOneWidget);
    expect(find.text('Harshe'), findsOneWidget,
        reason: 'the heading changes with the language');
  });
}
