// The handover protocol over a link: a scoped record's bytes cross an
// in-memory pair and come back the same; a lossy link is made whole by a
// repeat, and Gather counts the repeats once; a link that closes early
// yields nothing, never a partial record.
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/transport/link.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  Record sample() {
    final patient = List<int>.generate(16, (i) => i + 3);
    var n = 0;
    Fact f(FactKind k, List<int> payload) => Fact(
        id: List.filled(32, ++n),
        patient: patient,
        kind: k,
        stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
        author: 'nurse',
        payload: payload,
        supersedes: null);
    return Record.of(patient, [
      f(
          FactKind.registration,
          Registration(
                  givenName: 'Ada',
                  familyName: 'Eze',
                  sex: 0,
                  bornDays: 20_000,
                  dobEstimated: false,
                  address:
                      'A long address line to make the record span several frames of one hundred and sixty bytes')
              .encode()),
      for (var i = 0; i < 8; i++)
        f(
            FactKind.immunisation,
            Given(
                    vaccine: Vaccine.values[i],
                    dose: 1,
                    givenDays: 20_000 + i,
                    batch: 'B-$i')
                .encode()),
    ]);
  }

  test('the bytes cross the link and come back the same', () async {
    final bytes = Canonical.bytesOf(sample());
    final (a, b) = MemoryLink.pair();
    final progress = <double>[];
    final received = Handover.receive(b, onProgress: progress.add);
    await Handover.send(a, bytes);
    expect(await received, bytes);
    expect(progress.first, lessThan(1));
    expect(progress.last, 1);
    expect(Frame.cut(bytes, size: 160).length, greaterThan(3),
        reason: 'several frames');
    await a.close();
  });

  test('a lossy link is made whole by a repeat, counted once', () async {
    final bytes = Canonical.bytesOf(sample());
    final (a, b) = MemoryLink.pair(dropFromA: {1});
    final received = Handover.receive(b);
    // One pass loses frame 1 on this link forever; the receiver waits.
    await Handover.send(a, bytes);
    var done = false;
    received.then((_) => done = true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(done, isFalse, reason: 'a frame is missing');
    // A second link end without the loss (the sender moved closer) completes it.
    final (a2, b2) = MemoryLink.pair();
    final gather2 = Handover.receive(b2);
    await Handover.send(a2, bytes, repeats: 2);
    expect(await gather2, bytes);
    await a.close();
    await a2.close();
  });

  test('a link that closes early yields nothing', () async {
    final bytes = Canonical.bytesOf(sample());
    final (a, b) = MemoryLink.pair();
    final received = Handover.receive(b);
    final frames = Frame.cut(bytes, size: 160);
    await a.send(frames.first);
    await a.close();
    expect(await received, isNull);
  });
}
