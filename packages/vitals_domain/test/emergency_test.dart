// The emergency card as a fact: round-trips, the latest wins, opting out
// is a fact and not a deletion, and a note is still a note.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  Fact fact(int n, FactKind kind, List<int> payload) => Fact(
      id: List.filled(32, n),
      patient: List.filled(16, 1),
      kind: kind,
      stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
      author: 'patient',
      payload: payload,
      supersedes: null);

  test('round-trip, latest wins, opting out keeps the history', () {
    final on = Emergency(
        shown: true, bloodGroup: 'O+', allergies: 'penicillin', pregnant: true);
    final back = Emergency.decode(on.encode());
    expect((back.shown, back.bloodGroup, back.allergies, back.pregnant),
        (true, 'O+', 'penicillin', true));
    final facts = [
      fact(1, FactKind.note, on.encode()),
      fact(2, FactKind.note, const Note(text: 'a note').encode())
    ];
    expect(Emergency.of(facts)!.shown, isTrue);
    expect(Note.of(facts).single.text, 'a note',
        reason: 'told apart by the version byte');
    final off = [
      ...facts,
      fact(3, FactKind.note, const Emergency(shown: false).encode())
    ];
    expect(Emergency.of(off)!.shown, isFalse);
    expect(off.length, 3, reason: 'nothing was deleted');
    expect(Emergency.of(const []), isNull);
  });
}
