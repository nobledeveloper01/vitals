// The other side of the handover, with the code pasted the way a device
// with no camera would: the frames a share screen shows, fed in reverse
// with one repeated and one that is not a frame, gather into the record
// and merge in; the same record again adds nothing; junk is refused.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/receive.dart';
import 'package:vitals/speech/patient_strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records phone, tablet;
  final ids = Ids(device: 'phone-test');
  final today = Gs1.daysOf(2026, 9, 15);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-recv-');
    phone = await Records.at(
        File('${dir.path}/phone.log'), List<int>.generate(32, (i) => i + 16));
    tablet = await Records.at(
        File('${dir.path}/tablet.log'), List<int>.generate(32, (i) => i + 17));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<void> io(WidgetTester t, Future<void> Function() body) async {
    await t.runAsync(() async {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  testWidgets(
      'frames pasted in any order become the record on the other device',
      (t) async {
    // The phone's record: a child with a dose, big enough for several frames.
    final patient = ids.patient();
    Fact f(FactKind k, List<int> payload) => Fact(
        id: ids.fact(),
        patient: patient,
        kind: k,
        stamp: ids.stamp(),
        author: 'nurse-a',
        payload: payload,
        supersedes: null);
    await t.runAsync(() => phone.record([
          f(
              FactKind.registration,
              Registration(
                      givenName: 'Ada',
                      familyName: 'Eze',
                      sex: 0,
                      bornDays: today - 100,
                      dobEstimated: false,
                      address: 'No. 4, a long street name in Ikeja, Lagos')
                  .encode()),
          for (var i = 0; i < 6; i++)
            f(
                FactKind.immunisation,
                Given(
                        vaccine: Vaccine.values[i],
                        dose: 1,
                        givenDays: today - 99 + i,
                        batch: 'B-$i')
                    .encode()),
        ]));
    final bytes = Canonical.bytesOf(phone.all.values.single);
    final frames = Frame.cut(bytes, size: 200);
    expect(frames.length, greaterThan(2),
        reason: 'a real multi-frame transfer');

    await t.pumpWidget(MaterialApp(
        home: ReceiveScreen(
            records: tablet,
            camera: false,
            now: DateTime.utc(2026, 9, 15, 9))));
    await t.pumpAndSettle();
    expect(find.text(PatientStrings.shared('waitingForCode')), findsOneWidget);

    Future<void> paste(String text) async {
      await t.enterText(find.byKey(const Key('pasteField')), text);
      await io(t, () => t.tap(find.text(PatientStrings.shared('addCode'))));
    }

    await paste('https://example.com/not-a-code');
    expect(find.byKey(const Key('refusal')), findsOneWidget);
    await paste(frames.last.text);
    expect(find.byKey(const Key('refusal')), findsNothing);
    expect(find.textContaining('1 / ${frames.length}'), findsOneWidget);
    await paste(frames.last.text);
    expect(find.textContaining('1 / ${frames.length}'), findsOneWidget,
        reason: 'the same frame twice counts once');
    for (final fr in frames.reversed.skip(1)) {
      await paste(fr.text);
    }
    expect(find.text('Ada Eze'), findsOneWidget);
    expect(
        find.text(
            '7 ${PatientStrings.shared('factsReceived')} · 7 ${PatientStrings.shared('factsNew')}'),
        findsOneWidget);
    final got = tablet.all.values.single;
    expect(got.length, 7);
    expect(Given.of(got.current).length, 6);
    expect(tablet.lastMet, DateTime.utc(2026, 9, 15, 9),
        reason: 'the tablet met another device');

    // Again: union, nothing added.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(
        MaterialApp(home: ReceiveScreen(records: tablet, camera: false)));
    await t.pumpAndSettle();
    for (final fr in frames) {
      await paste(fr.text);
    }
    expect(
        find.text(
            '7 ${PatientStrings.shared('factsReceived')} · 0 ${PatientStrings.shared('factsNew')}'),
        findsOneWidget);
    expect(tablet.all.values.single.length, 7);
  });
}
