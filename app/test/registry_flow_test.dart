// Phase 2 on the screen: a patient registered, a second who might be the
// first shown side by side and registered anyway by a person, the registry
// searched by another spelling — and fifty thousand searched in under half
// a second, which is the phase's gate.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/app/app.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/preferences.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  Future<Records> open() async => records;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-registry-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i));
    Preferences.shared
      ..face = Face.clinic
      ..locked = false
      ..largeType = false;
  });
  tearDown(() async => dir.delete(recursive: true));

  /// A tap whose handler writes to the log: the write is real file IO,
  /// which only completes when the test lets the real event loop run.
  Future<void> tapAndWrite(WidgetTester t, Finder f) async {
    await t.runAsync(() async {
      await t.tap(f);
      // Long enough for the write on a slow disk; the test does not care how long.
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  Future<void> launch(WidgetTester t) async {
    await t.pumpWidget(VitalsApp(open: open));
    await t.pump(const Duration(milliseconds: 950));
    await t.pumpAndSettle();
  }

  Future<void> fill(WidgetTester t,
      {required String given,
      required String family,
      String mother = '',
      String phone = ''}) async {
    await t.enterText(find.byKey(const Key('given')), given);
    await t.enterText(find.byKey(const Key('family')), family);
    if (mother.isNotEmpty) {
      await t.ensureVisible(find.byKey(const Key('mother')));
      await t.enterText(find.byKey(const Key('mother')), mother);
    }
    if (phone.isNotEmpty) {
      await t.ensureVisible(find.byKey(const Key('phone')));
      await t.enterText(find.byKey(const Key('phone')), phone);
    }
    await t.ensureVisible(find.text(Strings.chooseDate));
    await t.pumpAndSettle();
    await t.tap(find.text(Strings.chooseDate));
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await t.pumpAndSettle();
  }

  testWidgets(
      'a patient is registered and counted, and a look-alike is shown, not merged',
      (t) async {
    await launch(t);
    await t.tap(find.text(Strings.registerPatient));
    await t.pumpAndSettle();
    expect(find.text(Strings.registerPatient), findsOneWidget);
    await fill(t,
        given: 'Adeola',
        family: 'Okafor',
        mother: 'Ngozi Okafor',
        phone: '08031234567');
    await tapAndWrite(t, find.text(Strings.register));
    expect(records.patients, 1);
    expect(
        find.textContaining('1 ${Strings.patientsRegistered}'), findsOneWidget);

    // The same person, another spelling: the assistant, then the person decides.
    await t.tap(find.text(Strings.registerPatient));
    await t.pumpAndSettle();
    await fill(t, given: 'Adéọlá', family: 'Okafor', mother: 'Ngozi Okafor');
    await t.tap(find.text(Strings.register));
    await t.pumpAndSettle();
    // The card sits below the form; a lazy list builds it when scrolled to.
    await t.scrollUntilVisible(find.text(Strings.maybeAlreadyHere), 200,
        scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(find.text(Strings.maybeAlreadyHere), findsOneWidget);
    expect(find.byKey(const Key('candidate')), findsOneWidget);
    expect(find.textContaining('same name and mother'), findsOneWidget);
    expect(records.patients, 1, reason: 'nothing was written yet');
    await tapAndWrite(t, find.text(Strings.registerAnyway));
    expect(records.patients, 2, reason: 'a person chose to register anyway');
    expect(
        find.textContaining('2 ${Strings.patientsRegistered}'), findsOneWidget);
  });

  testWidgets('the registry searches by another spelling and by four digits',
      (t) async {
    await launch(t);
    for (final (g, f, ph) in [
      ('Oluwaseun', 'Bamisaye', '07011112222'),
      ('Emeka', 'Okeke', '')
    ]) {
      await t.tap(find.text(Strings.registerPatient));
      await t.pumpAndSettle();
      await fill(t, given: g, family: f, phone: ph);
      await tapAndWrite(t, find.text(Strings.register));
    }
    await t.tap(find.text(Strings.openRegistry));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('count')), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await t.enterText(find.byKey(const Key('search')), 'seun');
    await t.pumpAndSettle();
    expect(find.text('Oluwaseun Bamisaye'), findsOneWidget);
    expect(find.text('Emeka Okeke'), findsNothing);
    await t.enterText(find.byKey(const Key('search')), '1112');
    await t.pumpAndSettle();
    expect(find.text('Oluwaseun Bamisaye'), findsOneWidget);
    await t.enterText(find.byKey(const Key('search')), 'chukwuemeka');
    await t.pumpAndSettle();
    expect(find.text('Emeka Okeke'), findsOneWidget);
    await t.enterText(find.byKey(const Key('search')), 'zzz');
    await t.pumpAndSettle();
    expect(find.text(Strings.noMatch), findsOneWidget);
  });

  test('fifty thousand patients search in under half a second', () {
    final r = Random(7);
    const givens = [
      'Adeola',
      'Oluwaseun',
      'Emeka',
      'Ngozi',
      'Muhammad',
      'Aisha',
      'Tunde',
      'Chiamaka',
      'Yusuf',
      'Funmilayo',
      'Kehinde',
      'Taiwo'
    ];
    const families = [
      'Okafor',
      'Bamisaye',
      'Okeke',
      'Adeyemi',
      'Bello',
      'Abdullahi',
      'Eze',
      'Olatunji',
      'Ibrahim',
      'Nwosu'
    ];
    final listed = List.generate(50_000, (i) {
      final reg = Registration(
        givenName: givens[r.nextInt(givens.length)],
        familyName: families[r.nextInt(families.length)],
        sex: r.nextInt(2),
        bornDays: 10_000 + r.nextInt(10_000),
        dobEstimated: false,
        motherName:
            '${givens[r.nextInt(givens.length)]} ${families[r.nextInt(families.length)]}',
        phone: '080${r.nextInt(100000000).toString().padLeft(8, '0')}',
        address: '',
      );
      return Listed(List<int>.generate(16, (_) => r.nextInt(256)), reg);
    });
    final sw = Stopwatch()..start();
    final hits = Registry.search(listed, 'adeola okafor');
    final ms = sw.elapsedMilliseconds;
    expect(hits, isNotEmpty);
    expect(ms, lessThan(500), reason: 'search took $ms ms across 50,000');
    sw.reset();
    Registry.duplicates(listed, listed.first);
    expect(sw.elapsedMilliseconds, lessThan(500),
        reason: 'the duplicate check across 50,000');
  });
}
