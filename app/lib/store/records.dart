// What the app holds: every patient's record, read once from the log and
// kept in memory, appended to on every write. One place, so the whiteboard,
// the record and the sync chip all read the same set.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'fact_log.dart';
import 'keychain_key.dart';

final class Records extends ChangeNotifier {
  Records(this._log);
  final FactLog _log;
  final Map<String, Record> _records = {};
  DateTime? _lastMet;
  var _ready = false;

  bool get ready => _ready;
  Map<String, Record> get all => Map.unmodifiable(_records);
  int get patients => _records.length;
  int get facts => _records.values.fold(0, (n, r) => n + r.length);

  /// When another device was last met — never "synced" (ADR-0006 #28).
  DateTime? get lastMet => _lastMet;

  static Future<Records> open() async {
    final dir = await getApplicationSupportDirectory();
    final r = Records(FactLog(File('${dir.path}/facts.log'), KeychainKey()));
    await r.load();
    return r;
  }

  /// For tests and fixtures: a log at a path with a key in memory.
  static Future<Records> at(File file, List<int> key) async {
    final r = Records(FactLog(file, MemoryKey(key)));
    await r.load();
    return r;
  }

  Future<void> load() async {
    _records
      ..clear()
      ..addAll(await _log.read());
    _ready = true;
    notifyListeners();
  }

  /// Record new facts: append what is new to the log, union into memory.
  Future<int> record(Iterable<Fact> facts) async {
    final fresh = <Fact>[];
    for (final f in facts) {
      final k = _hex(f.patient);
      final r = _records[k] ?? Record.empty(f.patient);
      if (r.contains(f)) continue;
      _records[k] = Merge.union(r, Record.of(f.patient, [f]));
      fresh.add(f);
    }
    if (fresh.isNotEmpty) {
      await _log.append(fresh);
      notifyListeners();
    }
    return fresh.length;
  }

  /// What arrived from another device: the same as recording, and the
  /// moment is remembered for the chip.
  Future<int> met(Iterable<Fact> facts, {required DateTime at}) async {
    final n = await record(facts);
    _lastMet = at;
    notifyListeners();
    return n;
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
