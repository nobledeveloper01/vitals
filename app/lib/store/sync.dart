// The replica, met over HTTP the way another tablet is met over BLE: push
// what it lacks, pull what this device lacks, union, and remember the
// meeting. The server has no authority (ADR-0004); a pull is just another
// device's facts. Off until a facility is enrolled.
import 'dart:convert';

import 'package:vitals_domain/vitals_domain.dart';

import 'records.dart';

/// The two calls the mirror needs. HTTP on a phone; a map in the tests.
abstract interface class Transport {
  Future<Map<String, Object?>> postJson(String path, Map<String, Object?> body);
  Future<Map<String, Object?>> getJson(String path);
}

final class SyncOutcome {
  const SyncOutcome({required this.pushed, required this.pulled});
  final int pushed, pulled;
  @override
  bool operator ==(Object other) =>
      other is SyncOutcome && other.pushed == pushed && other.pulled == pulled;
  @override
  int get hashCode => Object.hash(pushed, pulled);
  @override
  String toString() => 'pushed $pushed, pulled $pulled';
}

final class Sync {
  Sync(this.transport, {required this.facility});
  final Transport transport;
  final String facility;

  /// The server's arrival cursor per facility, kept by the caller between
  /// runs so a pull is a delta.
  int cursor = 0;

  Future<SyncOutcome> run(Records records, {required DateTime now}) async {
    // Push everything; the server ignores what it knows and says how many were new.
    final mine = records.all.values.expand((r) => r.all).toList();
    var pushed = 0;
    for (var i = 0; i < mine.length; i += 200) {
      final page =
          mine.sublist(i, i + 200 > mine.length ? mine.length : i + 200);
      final res = await transport.postJson('/sync/push', {
        'facility': facility,
        'facts': page
            .map((f) =>
                base64Encode(Canonical.bytesOf(Record.of(f.patient, [f]))))
            .toList(),
      });
      pushed += (res['added'] as num?)?.toInt() ?? 0;
    }
    // Pull what arrived since the cursor, page by page.
    final pulled = <Fact>[];
    var more = true;
    while (more) {
      final res = await transport
          .getJson('/sync/pull?facility=$facility&after=$cursor&limit=200');
      for (final item in (res['facts'] as List? ?? const [])) {
        final m = item as Map;
        pulled.addAll(
            Canonical.recordFrom(base64Decode(m['bundle'] as String)).all);
      }
      cursor = (res['cursor'] as num?)?.toInt() ?? cursor;
      more = res['more'] == true;
    }
    final kept = await records.met(pulled, at: now);
    return SyncOutcome(pushed: pushed, pulled: kept);
  }
}
