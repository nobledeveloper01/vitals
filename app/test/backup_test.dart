// Backup and restore: one file, a passphrase, every fact back, a wrong
// passphrase refused, a tampered frame counted and not kept.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/store/backup.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

List<int> id(int seed) =>
    List<int>.generate(32, (i) => (seed * 31 + i * 7) & 0xff);
Fact fact(int seed) => Fact(
      id: id(seed),
      patient: List<int>.generate(16, (i) => (seed % 3) + i),
      kind: FactKind.vitals,
      stamp: Stamp(
          wallMillis: 1_700_000_000_000 + seed, counter: 0, device: 'tab-a'),
      author: 'nurse-a',
      payload: [seed],
      supersedes: null,
    );

void main() {
  late Directory dir;
  final key = List<int>.generate(32, (i) => i + 1);
  final salt = List<int>.generate(16, (i) => 99 - i);
  setUp(() async =>
      dir = await Directory.systemTemp.createTemp('vitals-backup-'));
  tearDown(() async => dir.delete(recursive: true));

  test(
      'every fact comes back through a passphrase, and a wrong one brings nothing',
      () async {
    final a = await Records.at(File('${dir.path}/a.log'), key);
    await a.record(List.generate(9, fact));
    final file = File('${dir.path}/vitals.backup');
    await Backup.write(a, file, passphrase: 'ikeja-phc-2026', salt: salt);
    expect(String.fromCharCodes(await file.readAsBytes()).contains('nurse-a'),
        isFalse,
        reason: 'the backup is encrypted');

    final b = await Records.at(File('${dir.path}/b.log'), key);
    final wrong = await Backup.restore(b, file, passphrase: 'wrong');
    expect(wrong, (kept: 0, refused: 9),
        reason: 'every frame refused under the wrong key');
    expect(b.facts, 0);

    final right = await Backup.restore(b, file, passphrase: 'ikeja-phc-2026');
    expect(right, (kept: 9, refused: 0));
    expect(b.facts, 9);
    expect(b.patients, 3);
    final again = await Backup.restore(b, file, passphrase: 'ikeja-phc-2026');
    expect(again.kept, 0, reason: 'nothing new the second time');
  });

  test('a tampered frame is refused and the rest are kept', () async {
    final a = await Records.at(File('${dir.path}/a.log'), key);
    await a.record(List.generate(4, fact));
    final file = File('${dir.path}/vitals.backup');
    await Backup.write(a, file, passphrase: 'p', salt: salt);
    final bytes = await file.readAsBytes();
    bytes[60] ^= 0x01;
    await file.writeAsBytes(bytes);
    final b = await Records.at(File('${dir.path}/b.log'), key);
    final r = await Backup.restore(b, file, passphrase: 'p');
    expect(r, (kept: 3, refused: 1));
  });

  test('a file that is not a backup is one refusal', () async {
    final b = await Records.at(File('${dir.path}/b.log'), key);
    final file = File('${dir.path}/not.backup')..writeAsBytesSync([1, 2, 3]);
    expect(
        await Backup.restore(b, file, passphrase: 'p'), (kept: 0, refused: 1));
  });
}
