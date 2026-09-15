// The mirror against a replica in memory that behaves as the .NET server
// does: union on push, arrival order on pull, paging by cursor.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals/store/sync.dart';
import 'package:vitals_domain/vitals_domain.dart';

List<int> id(int seed) =>
    List<int>.generate(32, (i) => (seed * 31 + i * 7) & 0xff);
Fact fact(int seed, String device) => Fact(
      id: id(seed),
      patient: List<int>.generate(16, (i) => 5 + i),
      kind: FactKind.vitals,
      stamp: Stamp(
          wallMillis: 1_700_000_000_000 + seed, counter: 0, device: device),
      author: 'nurse-a',
      payload: [seed],
      supersedes: null,
    );

/// The server's contract, in a map.
final class FakeReplica implements Transport {
  final List<(String facility, String bundle)> rows = [];

  /// Devices a supervisor asked to wipe, and those that confirmed.
  final Set<String> wipeRequested = {};
  final List<String> confirmed = [];
  @override
  Future<Map<String, Object?>> postJson(
      String path, Map<String, Object?> body) async {
    final wiped = RegExp(r'^/devices/([^/]+)/wiped$').firstMatch(path);
    if (wiped != null) {
      wipeRequested.remove(wiped[1]);
      confirmed.add(wiped[1]!);
      return {'wipe': false};
    }
    var added = 0;
    for (final b in body['facts'] as List) {
      if (rows.any((r) => r.$2 == b)) continue;
      rows.add((body['facility'] as String, b as String));
      added++;
    }
    return {'added': added, 'known': (body['facts'] as List).length - added};
  }

  @override
  Future<Map<String, Object?>> getJson(String path) async {
    final dev = RegExp(r'^/devices/([^/?]+)$').firstMatch(path);
    if (dev != null) return {'wipe': wipeRequested.contains(dev[1])};
    final q = Uri.parse(path).queryParameters;
    final after = int.parse(q['after']!), limit = int.parse(q['limit']!);
    final mine = rows.indexed
        .where((r) => r.$2.$1 == q['facility'] && r.$1 + 1 > after)
        .toList();
    final page = mine.take(limit).toList();
    return {
      'facts': page.map((r) => {'seq': r.$1 + 1, 'bundle': r.$2.$2}).toList(),
      'more': mine.length > limit,
      'cursor': page.isEmpty ? after : page.last.$1 + 1,
    };
  }
}

void main() {
  late Directory dir;
  final key = List<int>.generate(32, (i) => i + 2);
  setUp(
      () async => dir = await Directory.systemTemp.createTemp('vitals-sync-'));
  tearDown(() async => dir.delete(recursive: true));

  test('two tablets meet through the replica and hold the same bytes',
      () async {
    final replica = FakeReplica();
    final a = await Records.at(File('${dir.path}/a.log'), key);
    final b = await Records.at(File('${dir.path}/b.log'), key);
    await a.record([fact(1, 'tab-a'), fact(2, 'tab-a')]);
    await b.record([fact(2, 'tab-a'), fact(3, 'tab-b')]);
    final sa = Sync(replica, facility: 'ikeja');
    final sb = Sync(replica, facility: 'ikeja');
    final now = DateTime.utc(2026, 9, 15, 4);
    expect(await sa.run(a, now: now), const SyncOutcome(pushed: 2, pulled: 0),
        reason: 'a pushes two; what it pulls it already has');
    expect(await sb.run(b, now: now), const SyncOutcome(pushed: 1, pulled: 1));
    expect(await sa.run(a, now: now), const SyncOutcome(pushed: 0, pulled: 1));
    expect(Canonical.bytesOf(a.all.values.single),
        Canonical.bytesOf(b.all.values.single));
    expect(a.lastMet, now);
    expect(await sa.run(a, now: now), const SyncOutcome(pushed: 0, pulled: 0),
        reason: 'the cursor makes the next pull a delta');
  });

  test('another facility sees nothing of this one', () async {
    final replica = FakeReplica();
    final a = await Records.at(File('${dir.path}/a.log'), key);
    await a.record([fact(1, 'tab-a')]);
    await Sync(replica, facility: 'ikeja').run(a, now: DateTime.utc(2026));
    final c = await Records.at(File('${dir.path}/c.log'), key);
    expect(
        await Sync(replica, facility: 'surulere')
            .run(c, now: DateTime.utc(2026)),
        const SyncOutcome(pushed: 0, pulled: 0));
    expect(c.facts, 0);
    // The bundle the replica holds is the canonical single-fact record.
    expect(
        Canonical.recordFrom(base64Decode(replica.rows.single.$2))
            .all
            .single
            .stamp
            .device,
        'tab-a');
  });

  test(
      'a device the supervisor asked to wipe erases at its next meeting and pushes nothing',
      () async {
    final replica = FakeReplica();
    final ids = Ids(device: 'tab-lost');
    final file = File('${dir.path}/lost.log');
    final lost = await Records.at(file, key);
    final patient = ids.patient();
    await lost.record([
      Fact(
          id: ids.fact(),
          patient: patient,
          kind: FactKind.registration,
          stamp: ids.stamp(),
          author: 'nurse-a',
          payload: Registration(
                  givenName: 'Ada',
                  familyName: 'Eze',
                  sex: 0,
                  bornDays: 1,
                  dobEstimated: false)
              .encode(),
          supersedes: null)
    ]);
    expect(await file.exists(), isTrue);
    final sync = Sync(replica, facility: 'ikeja', device: 'tab-lost');
    // Nobody asked: a normal meeting.
    expect(await sync.run(lost, now: DateTime.utc(2026, 9, 15)),
        const SyncOutcome(pushed: 1, pulled: 0));
    // The supervisor asked: the next meeting erases first.
    replica.wipeRequested.add('tab-lost');
    final outcome = await sync.run(lost, now: DateTime.utc(2026, 9, 16));
    expect(outcome.wiped, isTrue);
    expect(lost.all, isEmpty);
    expect(await file.exists(), isFalse,
        reason: 'the log is gone from the disk');
    expect(replica.confirmed, ['tab-lost']);
    expect(replica.rows.length, 1,
        reason: 'the replica keeps what it was pushed before');
    // Reopened from the same path: nothing.
    final again = await Records.at(file, key);
    expect(again.all, isEmpty);
    // And a later meeting, from a blank cursor as a blank tablet has, is
    // normal again.
    final fresh = Sync(replica, facility: 'ikeja', device: 'tab-lost');
    expect(await fresh.run(again, now: DateTime.utc(2026, 9, 17)),
        const SyncOutcome(pushed: 0, pulled: 1),
        reason:
            'the record comes back from the replica when this device is trusted again');
  });
}
