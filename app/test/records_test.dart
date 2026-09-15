// Records over the log: what is recorded is read back after a relaunch, a
// device met is remembered, and the counts the whiteboard shows are right.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

List<int> id(int seed) =>
    List<int>.generate(32, (i) => (seed * 31 + i * 7) & 0xff);
List<int> patient(int n) => List<int>.generate(16, (i) => n + i);
Fact fact(int seed, int p, {String device = 'tab-a'}) => Fact(
      id: id(seed),
      patient: patient(p),
      kind: FactKind.vitals,
      stamp: Stamp(
          wallMillis: 1_700_000_000_000 + seed, counter: 0, device: device),
      author: 'nurse-a',
      payload: [seed],
      supersedes: null,
    );

void main() {
  late Directory dir;
  final key = List<int>.generate(32, (i) => i + 9);
  setUp(() async =>
      dir = await Directory.systemTemp.createTemp('vitals-records-'));
  tearDown(() async => dir.delete(recursive: true));

  test('what is recorded survives a relaunch, per patient', () async {
    final file = File('${dir.path}/facts.log');
    final a = await Records.at(file, key);
    expect(a.ready, isTrue);
    expect(await a.record([fact(1, 1), fact(2, 1), fact(3, 2)]), 3);
    expect(await a.record([fact(2, 1)]), 0, reason: 'known already');
    expect((a.patients, a.facts), (2, 3));
    final b = await Records.at(file, key);
    expect((b.patients, b.facts), (2, 3));
    expect(b.all.values.map((r) => r.length).toList()..sort(), [1, 2]);
  });

  test('meeting a device is remembered, and its facts are unioned', () async {
    final r = await Records.at(File('${dir.path}/facts.log'), key);
    await r.record([fact(1, 1)]);
    expect(r.lastMet, isNull);
    final when = DateTime.utc(2026, 9, 15, 3);
    expect(await r.met([fact(1, 1), fact(9, 1, device: 'tab-b')], at: when), 1);
    expect(r.lastMet, when);
    expect(r.facts, 2);
  });
}
