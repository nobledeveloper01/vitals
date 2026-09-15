// Deterministic samples: a patient, six facts across three devices, made
// from a seed the tests own, so the domain never needs randomness.
import 'package:vitals_domain/vitals_domain.dart';

List<int> id(int seed) =>
    List<int>.generate(32, (i) => (seed * 31 + i * 7) & 0xff);
List<int> patientId(int seed) =>
    List<int>.generate(16, (i) => (seed * 13 + i) & 0xff);

Fact fact(int seed,
        {required String device,
        required int wall,
        FactKind kind = FactKind.vitals,
        List<int>? supersedes,
        String author = 'nurse-a'}) =>
    Fact(
      id: id(seed),
      patient: patientId(1),
      kind: kind,
      stamp: Stamp(wallMillis: wall, counter: seed % 3, device: device),
      author: author,
      payload: [seed & 0xff, (seed >> 8) & 0xff, 0x42],
      supersedes: supersedes,
    );

/// A tiny deterministic generator. Not a clock, not randomness: arithmetic.
/// The high bits, never the low: an LCG's low bits cycle so short that
/// `state % 4` never produced a 2 across two hundred worlds, and the
/// correction path went untested while its test stayed green.
final class Gen {
  Gen(this._state);
  int _state;
  int next(int bound) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return (_state >> 16) % bound;
  }
}
