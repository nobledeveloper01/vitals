// The fridge log: a reading in tenths that round-trips, outside the printed
// range as a comparison, and the two daily prompts.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  test('a reading round-trips and is told apart from an observation', () {
    final r = FridgeReading(tenths: 95, minutes: 30_000_000, fridge: 'vaccine');
    final back = FridgeReading.decode(r.encode());
    expect((back.tenths, back.minutes, back.fridge, back.outside),
        (95, 30_000_000, 'vaccine', true));
    expect(FridgeReading(tenths: 20, minutes: 0).outside, isFalse);
    expect(FridgeReading(tenths: -5, minutes: 0).outside, isTrue);
    expect(() => Observation.decode(r.encode()), throwsArgumentError);
  });

  test('the morning prompt until it is answered, the evening one after noon',
      () {
    const day = 29_000_000 - 29_000_000 % 1440;
    expect(
        FridgeReading.duePrompts(const [], nowMinutes: day + 60), ['morning']);
    expect(
        FridgeReading.duePrompts([FridgeReading(tenths: 40, minutes: day + 60)],
            nowMinutes: day + 100),
        isEmpty);
    expect(
        FridgeReading.duePrompts([FridgeReading(tenths: 40, minutes: day + 60)],
            nowMinutes: day + 800),
        ['evening']);
    expect(FridgeReading.duePrompts(const [], nowMinutes: day + 800),
        ['morning', 'evening']);
  });
}
