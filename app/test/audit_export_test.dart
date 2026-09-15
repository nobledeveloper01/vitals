// The signed audit export: every write and open as a row, the signature
// holds in Dart and under the Python script with nothing but Python, and a
// changed byte fails both.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/store/audit.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'tab-9');
  final keys = AuditKeys(seed: List<int>.generate(32, (i) => 200 - i));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-audit-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 15));
  });
  tearDown(() async => dir.delete(recursive: true));

  test(
      'rows for writes and opens, signed, verified, and a changed byte refused',
      () async {
    final patient = ids.patient();
    await records.record([
      Fact(
          id: ids.fact(),
          patient: patient,
          kind: FactKind.registration,
          stamp: ids.stamp(now: DateTime.utc(2026, 9, 15, 8)),
          author: 'nurse, "a"',
          payload: Registration(
                  givenName: 'Ada',
                  familyName: 'Eze',
                  sex: 0,
                  bornDays: 10000,
                  dobEstimated: false)
              .encode(),
          supersedes: null),
      Fact(
          id: ids.fact(),
          patient: patient,
          kind: FactKind.access,
          stamp: ids.stamp(now: DateTime.utc(2026, 9, 15, 9)),
          author: 'nurse-b',
          payload: Access(
                  who: 'nurse-b',
                  minutes:
                      DateTime.utc(2026, 9, 15, 7).millisecondsSinceEpoch ~/
                          60000,
                  device: 'tab-9',
                  facility: 'Ikeja PHC')
              .encode(),
          supersedes: null),
    ]);
    final lines = AuditExport.lines(records);
    expect(lines.first, AuditExport.header);
    expect(lines.length, 4, reason: 'two writes and one open');
    expect(lines[1], contains('open,record'),
        reason: 'the open at 07:00 sorts first');
    expect(lines[2], contains('"nurse, ""a"""'), reason: 'CSV-quoted');
    final file = await AuditExport.signed(records, keys);
    expect(await AuditExport.verify(file), isTrue);
    final tampered = List<int>.of(file)..[40] ^= 0x01;
    expect(await AuditExport.verify(tampered), isFalse);

    // The supervisor's check, with nothing but Python.
    final script = File('../scripts/verify-audit.py').absolute.path;
    final good = File('${dir.path}/audit.csv')..writeAsBytesSync(file);
    final bad = File('${dir.path}/audit-bad.csv')..writeAsBytesSync(tampered);
    final ok = await Process.run(
        'python3', [script, good.path, await keys.publicKeyHex()]);
    expect(ok.exitCode, 0, reason: ok.stdout.toString());
    expect(ok.stdout.toString(), contains('signature holds over 3 rows'));
    final no = await Process.run('python3', [script, bad.path]);
    expect(no.exitCode, 1, reason: no.stdout.toString());
    final wrongKey =
        await Process.run('python3', [script, good.path, 'ab' * 32]);
    expect(wrongKey.exitCode, 1);
  });
}
