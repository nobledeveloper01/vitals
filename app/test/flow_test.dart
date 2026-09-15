// Phase 0's flow, widget-tested: the splash sweeps (and cuts under reduced
// motion), the face is chosen, the clinic sees the whiteboard, the patient
// their record, settings toggle glass and motion without a relaunch, and the
// lock asks for the PIN and refuses a wrong one.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/app/app.dart';
import 'package:vitals/design/glass.dart';
import 'package:vitals/design/motion.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/preferences.dart';
import 'package:vitals/store/records.dart';

void main() {
  late Directory dir;
  late Records records;
  // Opened before the widget: real file IO does not complete under a widget
  // test's fake clock, so the store is handed over already open.
  Future<Records> open() async => records;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-flow-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i));
    Preferences.shared
      ..face = Face.unchosen
      ..locked = false
      ..largeType = false;
    Motion.shared
      ..glass = true
      ..reduced = false;
  });

  Future<void> sweep(WidgetTester t) async {
    await t.pumpWidget(VitalsApp(open: open));
    await t.pump(const Duration(milliseconds: 950));
    await t.pumpAndSettle();
  }

  testWidgets('the splash sweeps and the face is asked', (t) async {
    await t.pumpWidget(VitalsApp(open: open));
    expect(find.text(Strings.tagline), findsOneWidget);
    await t.pump(const Duration(milliseconds: 950));
    await t.pumpAndSettle();
    expect(find.text(Strings.chooseFace), findsOneWidget);
  });

  testWidgets('under reduced motion the splash cuts', (t) async {
    Motion.shared.reduced = true;
    await t.pumpWidget(VitalsApp(open: open));
    await t.pump();
    await t.pumpAndSettle();
    expect(find.text(Strings.chooseFace), findsOneWidget);
  });

  testWidgets('the clinic face lands on the whiteboard with sync honesty',
      (t) async {
    await sweep(t);
    await t.tap(find.text(Strings.clinic));
    await t.pumpAndSettle();
    expect(find.text(Strings.whiteboard), findsOneWidget);
    expect(find.text(Strings.registerPatient), findsOneWidget);
    expect(find.textContaining(Strings.lastMet), findsOneWidget);
    expect(find.textContaining('synced'), findsNothing);
  });

  testWidgets('the patient face lands on the record', (t) async {
    await sweep(t);
    await t.tap(find.text(Strings.patient));
    await t.pumpAndSettle();
    expect(find.text(Strings.noRecordYet), findsOneWidget);
    expect(find.text(Strings.receiveRecord), findsOneWidget);
  });

  testWidgets('settings turn glass off and motion down without a relaunch',
      (t) async {
    await sweep(t);
    await t.tap(find.text(Strings.clinic));
    await t.pumpAndSettle();
    expect(find.byType(BackdropFilter), findsWidgets,
        reason: 'glass on: blur is drawn');
    await t.tap(find.byTooltip(Strings.settings));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('plain')));
    await t.pumpAndSettle();
    expect(Motion.shared.glass, isFalse);
    expect(find.byType(BackdropFilter), findsNothing,
        reason: 'glass off: the solid twin, no blur');
    await t.tap(find.byKey(const Key('reduce')));
    await t.pumpAndSettle();
    expect(Motion.shared.reduced, isTrue);
    expect(Motion.shared.of(Motion.move), Duration.zero);
    await t.tap(find.byKey(const Key('largeType')));
    await t.pumpAndSettle();
    expect(Preferences.shared.largeType, isTrue);
    await t.tap(find.text(Strings.done));
    await t.pumpAndSettle();
    expect(find.text(Strings.whiteboard), findsOneWidget);
    expect(find.byType(Glass), findsWidgets);
  });

  testWidgets('the lock refuses a wrong PIN and opens on the right one',
      (t) async {
    Preferences.shared
      ..face = Face.clinic
      ..locked = true;
    await sweep(t);
    expect(find.text(Strings.locked), findsOneWidget);
    await t.enterText(find.byType(TextField), '0000');
    await t.tap(find.text(Strings.unlock));
    await t.pumpAndSettle();
    expect(find.text(Strings.wrongPin), findsOneWidget);
    await t.enterText(find.byType(TextField), '1234');
    await t.tap(find.text(Strings.unlock));
    await t.pumpAndSettle();
    expect(find.text(Strings.whiteboard), findsOneWidget);
  });

  testWidgets('every screen has exactly one primary action', (t) async {
    await sweep(t);
    expect(find.byType(PrimaryButton), findsNothing,
        reason: 'the face picker has two equal choices and no primary');
    await t.tap(find.text(Strings.clinic));
    await t.pumpAndSettle();
    expect(find.byType(PrimaryButton), findsOneWidget);
    await t.tap(find.byTooltip(Strings.settings));
    await t.pumpAndSettle();
    expect(find.byType(PrimaryButton), findsOneWidget);
  });

  testWidgets('at 200% text nothing overflows on the whiteboard or settings',
      (t) async {
    await t.pumpWidget(MediaQuery(
      data: const MediaQueryData(
          textScaler: TextScaler.linear(2.0), size: Size(400, 860)),
      child: VitalsApp(open: open),
    ));
    await t.pump(const Duration(milliseconds: 950));
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.clinic));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await t.tap(find.byTooltip(Strings.settings));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull, reason: 'an overflow throws in tests');
  });
}
