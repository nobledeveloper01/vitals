// Vitals on the screen: readings become facts and the pulse card shows the
// last of each with its range; a reading outside the range is marked and
// nothing more; a sheet killed mid-entry comes back with what was typed;
// an empty sheet writes nothing.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/patient.dart';
import 'package:vitals/screens/vitals.dart';
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
  final born = Gs1.daysOf(1990, 5, 1);
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-vit-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 6));
    drafts = Drafts(Directory('${dir.path}/drafts'));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<List<int>> adult(WidgetTester t) async {
    final patient = ids.patient();
    final reg = Registration(
        givenName: 'Ngozi',
        familyName: 'Okafor',
        sex: 0,
        bornDays: born,
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

  Widget app(List<int> patient) => MaterialApp(
      home: PatientScreen(
          records: records,
          patient: patient,
          ids: ids,
          author: 'nurse-a',
          today: today,
          drafts: drafts,
          nowMinutes: today * 1440 + 600));

  /// Anything that touches the drafts file or the log runs through the
  /// real event loop; the fake clock never turns file IO.
  Future<void> io(WidgetTester t, Future<void> Function() body) async {
    await t.runAsync(() async {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  testWidgets('readings become facts; the card shows them with the range',
      (t) async {
    final semantics = t.ensureSemantics();
    final patient = await adult(t);
    await t.pumpWidget(app(patient));
    await t.pumpAndSettle();
    expect(find.text(Strings.noVitalsYet), findsOneWidget);
    expect(find.byKey(const Key('noCard')), findsOneWidget,
        reason: 'an adult has no immunisation card');
    expect(find.text(Strings.immunisationCard), findsNothing);
    await io(t, () => t.tap(find.text(Strings.recordVitals)));
    await io(t, () async {
      await t.enterText(find.byKey(const Key('field-pulse')), '88');
      await t.enterText(find.byKey(const Key('field-temperature')), '37.2');
      await t.enterText(find.byKey(const Key('field-weight')), '62.5');
    });
    await io(t, () => t.tap(find.text(Strings.recordVitals).last));
    expect(find.byKey(const Key('value-pulse')), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text('37.2'), findsOneWidget);
    expect(find.text('62.5'), findsOneWidget);
    expect(find.bySemanticsLabel('Pulse, 88 /min, ${Strings.range} 60–100'),
        findsOneWidget,
        reason: 'the range is printed beside the number');
    expect(find.text(Strings.outsideRange), findsNothing);
    final obs = Observation.of(records.all.values.single.current);
    expect(obs.length, 3);
    expect(obs.firstWhere((o) => o.measure == Measure.weight).value, 62500);
    expect(records.all.values.single.all.last.author, 'nurse-a');
    Map<String, String>? left;
    await io(
        t, () async => left = await drafts.read('vitals-${_hex(patient)}'));
    expect(left, isEmpty,
        reason: 'the draft is cleared once the facts are written');
    semantics.dispose();
  });

  testWidgets('outside the range is marked, and that is the only word',
      (t) async {
    final semantics = t.ensureSemantics();
    final patient = await adult(t);
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: patient,
              kind: FactKind.vitals,
              stamp: ids.stamp(),
              author: 'nurse-a',
              payload: Observation(
                      measure: Measure.pulse,
                      value: 112,
                      takenMinutes: today * 1440)
                  .encode(),
              supersedes: null)
        ]));
    await t.pumpWidget(app(patient));
    await t.pumpAndSettle();
    expect(
        find.bySemanticsLabel(
            'Pulse, 112 /min, ${Strings.range} 60–100, ${Strings.outsideRange}'),
        findsOneWidget);
    expect(find.text(Strings.outsideRange), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a sheet killed mid-entry comes back with what was typed',
      (t) async {
    final patient = await adult(t);
    Widget sheet() => MaterialApp(
        home: Scaffold(
            body: VitalsSheet(
                records: records,
                patient: patient,
                ids: ids,
                author: 'nurse-a',
                drafts: drafts,
                nowMinutes: 1)));
    await io(t, () => t.pumpWidget(sheet()));
    await io(
        t, () => t.enterText(find.byKey(const Key('field-systolic')), '13'));
    await io(
        t, () => t.enterText(find.byKey(const Key('field-systolic')), '130'));
    // The kill: the tree is thrown away and built again from nothing.
    await t.pumpWidget(const SizedBox());
    await io(t, () => t.pumpWidget(sheet()));
    expect(find.byKey(const Key('draftRestored')), findsOneWidget);
    expect(find.text('130'), findsOneWidget);
    expect(Observation.of(records.all.values.single.current), isEmpty,
        reason: 'a draft is not a fact');
  });

  testWidgets('an empty sheet writes nothing', (t) async {
    final patient = await adult(t);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: VitalsSheet(
                records: records,
                patient: patient,
                ids: ids,
                author: 'nurse-a',
                drafts: drafts,
                nowMinutes: 1))));
    await t.pumpAndSettle();
    await io(t, () => t.tap(find.text(Strings.recordVitals).last));
    expect(records.all.values.single.all.length, 1,
        reason: 'the registration alone');
  });
}

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
