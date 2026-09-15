// The patient hands over their record: the grant is a fact, the frames on
// the screen decode to a record holding only the registration and what the
// grant allows — the scope enforced where the bytes are built — and with
// less motion the code steps by hand with a count.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/design/glass.dart';
import 'package:vitals/design/motion.dart';
import 'package:vitals/screens/share.dart';
import 'package:vitals/speech/patient_strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'phone-test');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-share-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 12));
    Motion.shared.reduced = false;
  });
  tearDown(() async {
    Motion.shared.reduced = false;
    await dir.delete(recursive: true);
  });

  Future<List<int>> child(WidgetTester t) async {
    final patient = ids.patient();
    Fact f(FactKind k, List<int> payload) => Fact(
        id: ids.fact(),
        patient: patient,
        kind: k,
        stamp: ids.stamp(),
        author: 'nurse-a',
        payload: payload,
        supersedes: null);
    await t.runAsync(() => records.record([
          f(
              FactKind.registration,
              Registration(
                      givenName: 'Ada',
                      familyName: 'Eze',
                      sex: 0,
                      bornDays: today - 400,
                      dobEstimated: false)
                  .encode()),
          f(
              FactKind.immunisation,
              Given(vaccine: Vaccine.bcg, dose: 1, givenDays: today - 399)
                  .encode()),
          f(
              FactKind.vitals,
              Observation(
                      measure: Measure.weight,
                      value: 9000,
                      takenMinutes: today * 1440)
                  .encode()),
          f(FactKind.note, const Note(text: 'private').encode()),
        ]));
    return patient;
  }

  Future<void> io(WidgetTester t, Future<void> Function() body) async {
    await t.runAsync(() async {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
  }

  testWidgets('the frames hold only the registration and the granted kinds',
      (t) async {
    Motion.shared.reduced = true;
    final patient = await child(t);
    await t.pumpWidget(MaterialApp(
        home: ShareScreen(
            records: records, patient: patient, ids: ids, today: today)));
    await t.pumpAndSettle();
    expect(
        t.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed, isNull,
        reason: 'no grantee, no code');
    await t.enterText(find.byKey(const Key('grantee')), 'Ikeja PHC');
    await t.pump();
    expect(t.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNotNull);
    // Immunisations are on by default; add vitals, leave notes off.
    await t.tap(find.byKey(const Key('kind-vitals')));
    await t.tap(find.byKey(const Key('days-30')));
    await t.pump();
    await io(t, () => t.tap(find.text(PatientStrings.t('showCode'))));
    expect(find.byKey(const Key('qr')), findsOneWidget);
    final state = t.state<State<AnimatedQr>>(find.byKey(const Key('qr')));
    final frames = state.widget.frames;
    // Gather the frames the way a camera would and read the record back.
    final g = Gather();
    for (final f in frames.reversed) {
      g.add(Frame.decode(f.encode())!);
    }
    expect(g.complete, isTrue);
    final received = Canonical.recordFrom(g.payload);
    expect(received.all.map((f) => f.kind).toSet(),
        {FactKind.registration, FactKind.immunisation, FactKind.vitals});
    expect(received.all.any((f) => f.kind == FactKind.note), isFalse,
        reason: 'the note was never in the bytes');
    expect(received.all.any((f) => f.kind == FactKind.access), isFalse,
        reason: 'the grant itself stays with the patient');
    final grant = Grant.of(records.all.values.single.current).single;
    expect((grant.grantee, grant.untilDays), ('Ikeja PHC', today + 30));
    expect(grant.kinds, {FactKind.immunisation, FactKind.vitals});
    expect(find.text('1 / ${frames.length}'), findsOneWidget);
  });

  testWidgets('with less motion the code steps by hand', (t) async {
    Motion.shared.reduced = true;
    final frames =
        Frame.cut(List<int>.generate(900, (i) => i & 0xff), size: 300);
    await t.pumpWidget(MaterialApp(
        home:
            Scaffold(body: AnimatedQr(frames: frames, key: const Key('qr')))));
    await t.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('1 / 3'), findsOneWidget,
        reason: 'nothing moves by itself');
    await t.tap(find.byTooltip(PatientStrings.t('next')));
    await t.pump();
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byKey(const Key('frame-1')), findsOneWidget);
  });

  testWidgets('with motion the frames go by themselves', (t) async {
    final frames =
        Frame.cut(List<int>.generate(900, (i) => i & 0xff), size: 300);
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AnimatedQr(
                frames: frames,
                perFrame: const Duration(milliseconds: 100),
                key: const Key('qr')))));
    await t.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 250));
    expect(find.text('3 / 3'), findsOneWidget);
    await t.pumpWidget(const SizedBox());
  });
}
