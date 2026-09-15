// Vitals as facts: integers in fixed units that round-trip, the last of each
// measure for the pulse card, the trend oldest first, reference ranges by
// age, and a note with an audio hash. Nothing here names what a number means.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  Fact fact(int n, FactKind kind, List<int> payload) => Fact(
      id: List.filled(16, n),
      patient: List.filled(16, 1),
      kind: kind,
      stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
      author: 'nurse',
      payload: payload,
      supersedes: null);

  test('an observation round-trips, including a negative and the encounter',
      () {
    final o = Observation(
        measure: Measure.temperature,
        value: 375,
        takenMinutes: 29_000_000,
        encounter: List.filled(16, 7));
    final back = Observation.decode(o.encode());
    expect((back.measure, back.value, back.takenMinutes),
        (Measure.temperature, 375, 29_000_000));
    expect(back.encounter, List.filled(16, 7));
    expect(back.display, '37.5');
    expect(
        Observation(measure: Measure.weight, value: 3250, takenMinutes: 0)
            .display,
        '3.2');
    expect(
        Observation(measure: Measure.pulse, value: 88, takenMinutes: 0).display,
        '88');
    expect(
        Observation.decode(Observation(
                    measure: Measure.systolic, value: -1, takenMinutes: 1)
                .encode())
            .value,
        -1);
    expect(() => Measure.byCode(99), throwsArgumentError);
  });

  test(
      'the pulse card shows the last of each measure and the trend is oldest first',
      () {
    final facts = [
      fact(
          1,
          FactKind.vitals,
          Observation(measure: Measure.pulse, value: 80, takenMinutes: 100)
              .encode()),
      fact(
          2,
          FactKind.vitals,
          Observation(measure: Measure.pulse, value: 96, takenMinutes: 300)
              .encode()),
      fact(
          3,
          FactKind.vitals,
          Observation(measure: Measure.pulse, value: 90, takenMinutes: 200)
              .encode()),
      fact(
          4,
          FactKind.vitals,
          Observation(measure: Measure.systolic, value: 120, takenMinutes: 200)
              .encode()),
      fact(
          5, FactKind.vitals, FridgeReading(tenths: 50, minutes: 200).encode()),
      fact(6, FactKind.note, const Note(text: 'x').encode()),
    ];
    final all = Observation.of(facts);
    expect(all.length, 4, reason: 'the fridge reading is not an observation');
    expect(Observation.trend(all, Measure.pulse).map((o) => o.value),
        [80, 90, 96]);
    final latest = Observation.latest(all);
    expect(latest[Measure.pulse]!.value, 96);
    expect(latest[Measure.systolic]!.value, 120);
    expect(latest[Measure.weight], isNull);
  });

  test('reference ranges are by age, and outside is a comparison', () {
    final adult = Reference.forAge(Measure.pulse, 365 * 30)!;
    expect((adult.low, adult.high), (60, 100));
    final infant = Reference.forAge(Measure.pulse, 100)!;
    expect((infant.low, infant.high), (100, 160));
    expect(adult.outside(101), isTrue);
    expect(adult.outside(100), isFalse);
    expect(Reference.forAge(Measure.weight, 100), isNull,
        reason:
            'weight has no single range; the growth curve is the reference');
  });

  test('a note round-trips with its audio hash and encounter', () {
    final n = Note(
        text: 'Mother says feeding well — Ọmọ',
        audioSha256: List.filled(32, 9),
        encounter: List.filled(16, 3));
    final back = Note.decode(n.encode());
    expect((back.text, back.audioSha256.length), (n.text, 32));
    expect(back.encounter, List.filled(16, 3));
    expect(Note.of([fact(1, FactKind.note, n.encode())]).single.text, n.text);
  });
}
