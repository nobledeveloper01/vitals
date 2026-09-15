// Writes the parity fixture the .NET tests read: for each seed, every fact
// recorded (as canonical single-fact records) and the bytes every settled
// device must hold. Only when asked — VITALS_WRITE_PARITY=<dir> — and it
// refuses to overwrite, because a changed fixture is a changed meaning.
import 'dart:io';

import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

import 'merge_test.dart' show World;

void main() {
  test('write the parity fixture', () {
    final dir = Platform.environment['VITALS_WRITE_PARITY'];
    if (dir == null) {
      markTestSkipped('set VITALS_WRITE_PARITY=<dir> to write the fixture');
      return;
    }
    final out = Directory(dir);
    if (out.existsSync() && out.listSync().isNotEmpty) {
      fail('$dir is not empty; a fixture is replaced deliberately, not by a rerun');
    }
    out.createSync(recursive: true);
    final index = StringBuffer();
    for (var seed = 1; seed <= 200; seed++) {
      final w = World(seed)..run()..settle();
      final facts = w.everRecorded.toSet().toList()..sort();
      final factsBytes = <int>[];
      for (final f in facts) {
        final b = Canonical.bytesOf(Record.of(f.patient, [f]));
        factsBytes.addAll([(b.length >> 24) & 0xff, (b.length >> 16) & 0xff, (b.length >> 8) & 0xff, b.length & 0xff]);
        factsBytes.addAll(b);
      }
      File('$dir/$seed.facts').writeAsBytesSync(factsBytes);
      File('$dir/$seed.merged').writeAsBytesSync(Canonical.bytesOf(w.held.values.first));
      index.writeln('$seed ${facts.length} ${Canonical.bytesOf(w.held.values.first).length}');
    }
    File('$dir/INDEX').writeAsStringSync(index.toString());
  }, tags: ['fixture']);
}
