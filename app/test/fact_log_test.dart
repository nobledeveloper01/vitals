// The store, as ADR-0007 promises: nothing a fact says appears in the file;
// a log read back is the record; a cut tail loses at most the frame being
// written; a wrong key reads nothing and says nothing.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/store/fact_log.dart';
import 'package:vitals_domain/vitals_domain.dart';

List<int> id(int seed) =>
    List<int>.generate(32, (i) => (seed * 31 + i * 7) & 0xff);
final patient = List<int>.generate(16, (i) => 13 + i);
Fact fact(int seed, String caption) => Fact(
      id: id(seed),
      patient: patient,
      kind: FactKind.note,
      stamp: Stamp(
          wallMillis: 1_700_000_000_000 + seed, counter: 0, device: 'tab-a'),
      author: 'nurse-a',
      payload: caption.codeUnits,
      supersedes: null,
    );

void main() {
  late Directory dir;
  final key = List<int>.generate(32, (i) => i * 3 + 1);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-log-');
  });
  tearDown(() async {
    await dir.delete(recursive: true);
  });

  test('a fact written is a fact read, and nothing it says is in the file',
      () async {
    final log = FactLog(File('${dir.path}/facts.log'), MemoryKey(key));
    await log.append(
        [fact(1, 'BP one twenty over eighty'), fact(2, 'Weight sixty four')]);
    final bytes = await log.file.readAsBytes();
    final text = String.fromCharCodes(bytes);
    expect(text.contains('BP one'), isFalse, reason: 'the file is encrypted');
    expect(text.contains('nurse-a'), isFalse);
    expect(text.contains('tab-a'), isFalse);
    final records = await log.read();
    expect(records.length, 1);
    expect(records.values.single.length, 2);
    expect(String.fromCharCodes(records.values.single.all.first.payload),
        'BP one twenty over eighty');
  });

  test('appending later unions, and the same fact twice is one fact', () async {
    final log = FactLog(File('${dir.path}/facts.log'), MemoryKey(key));
    await log.append([fact(1, 'a')]);
    await log.append([fact(1, 'a'), fact(2, 'b')]);
    final r = (await log.read()).values.single;
    expect(r.length, 2);
  });

  test('a tail cut mid-frame loses that frame and nothing before it', () async {
    final log = FactLog(File('${dir.path}/facts.log'), MemoryKey(key));
    await log.append([fact(1, 'a'), fact(2, 'b'), fact(3, 'c')]);
    final bytes = await log.file.readAsBytes();
    await log.file.writeAsBytes(bytes.sublist(0, bytes.length - 20));
    final r = (await log.read()).values.single;
    expect(r.length, 2, reason: 'the third frame was cut; the first two stand');
  });

  test('a wrong key reads nothing, and a flipped byte drops only its frame',
      () async {
    final log = FactLog(File('${dir.path}/facts.log'), MemoryKey(key));
    await log.append([fact(1, 'a'), fact(2, 'b')]);
    final wrong =
        FactLog(log.file, MemoryKey(List<int>.generate(32, (i) => 7)));
    expect(await wrong.read(), isEmpty);
    final bytes = await log.file.readAsBytes();
    bytes[30] ^= 0x01;
    await log.file.writeAsBytes(bytes);
    final r = (await log.read()).values.single;
    expect(r.length, 1,
        reason: 'the tampered frame fails its tag; the other reads');
  });
}
