// Phase 5's domain: a grant enforced where the payload is built — a fact
// outside the scope is never in the bytes, an expired grant yields nothing;
// the access log newest first; frames gathered in any order, twice, with a
// damaged one refused; verification with three outcomes and no fourth word.
import 'dart:io';

import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  Fact fact(int n, FactKind kind, List<int> payload) => Fact(
      id: List.filled(32, n),
      patient: List.filled(16, 1),
      kind: kind,
      stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
      author: 'nurse',
      payload: payload,
      supersedes: null);

  group('grants', () {
    final reg = fact(1, FactKind.registration, [1]);
    final imm = fact(2, FactKind.immunisation, [1]);
    final anc = fact(3, FactKind.ancVisit, [1]);
    final vit = fact(4, FactKind.vitals, [1]);

    test('a grant round-trips and lives in the access slot beside the log', () {
      final g = Grant(
          grantee: 'Ikeja PHC',
          kinds: {FactKind.immunisation, FactKind.vitals},
          untilDays: 20_100,
          givenDays: 20_000);
      final back = Grant.decode(g.encode());
      expect((back.grantee, back.untilDays, back.givenDays),
          ('Ikeja PHC', 20_100, 20_000));
      expect(back.kinds, {FactKind.immunisation, FactKind.vitals});
      final access = Access(
          who: 'nurse-a', minutes: 5, device: 'tab', facility: 'Ikeja PHC');
      final facts = [
        fact(5, FactKind.access, g.encode()),
        fact(6, FactKind.access, access.encode())
      ];
      expect(Grant.of(facts).single.grantee, 'Ikeja PHC');
      expect(Access.of(facts).single.who, 'nurse-a');
    });

    test('the payload holds only what the grant allows, plus the registration',
        () {
      final g = Grant(
          grantee: 'Ikeja PHC',
          kinds: {FactKind.immunisation},
          untilDays: 20_100,
          givenDays: 20_000);
      final record = Record.of(List.filled(16, 1),
          [reg, imm, anc, vit, fact(5, FactKind.access, g.encode())]);
      final out =
          Scope.payload(record, grantee: 'Ikeja PHC', todayDays: 20_050);
      expect(out.map((f) => f.kind),
          [FactKind.registration, FactKind.immunisation]);
      expect(out.any((f) => f.kind == FactKind.ancVisit), isFalse,
          reason: 'never in the bytes');
    });

    test('no grant, another grantee, or an expired one is nothing', () {
      final g = Grant(
          grantee: 'Ikeja PHC',
          kinds: {FactKind.immunisation},
          untilDays: 20_100,
          givenDays: 20_000);
      final record = Record.of(
          List.filled(16, 1), [reg, imm, fact(5, FactKind.access, g.encode())]);
      expect(Scope.payload(record, grantee: 'Ikeja PHC', todayDays: 20_101),
          isEmpty,
          reason: 'expired');
      expect(
          Scope.payload(record, grantee: 'Somewhere else', todayDays: 20_050),
          isEmpty);
      expect(
          Scope.payload(Record.of(List.filled(16, 1), [reg, imm]),
              grantee: 'Ikeja PHC', todayDays: 20_050),
          isEmpty);
    });

    test('the later grant to the same grantee is the one that counts', () {
      final wide = Grant(
          grantee: 'Ikeja PHC',
          kinds: {FactKind.immunisation, FactKind.ancVisit},
          untilDays: 20_100,
          givenDays: 20_000);
      final narrow = Grant(
          grantee: 'Ikeja PHC',
          kinds: {FactKind.immunisation},
          untilDays: 20_100,
          givenDays: 20_010);
      final record = Record.of(List.filled(16, 1), [
        reg,
        imm,
        anc,
        fact(5, FactKind.access, wide.encode()),
        fact(6, FactKind.access, narrow.encode())
      ]);
      expect(
          Scope.payload(record, grantee: 'Ikeja PHC', todayDays: 20_050)
              .map((f) => f.kind),
          [FactKind.registration, FactKind.immunisation]);
    });
  });

  group('frames', () {
    test(
        'cut, shuffled, duplicated, and gathered back; a damaged frame refused',
        () {
      final payload = List<int>.generate(1000, (i) => (i * 7) & 0xff);
      final frames = Frame.cut(payload, size: 300);
      expect(frames.length, 4);
      final g = Gather();
      expect(g.add(Frame.decode(frames[2].encode())!), isTrue);
      expect(g.add(Frame.decode(frames[2].encode())!), isFalse,
          reason: 'seen twice');
      expect(g.progress, 0.25);
      expect(g.missing, [0, 1, 3]);
      expect(() => g.payload, throwsStateError);
      final damaged = frames[0].encode()..[Frame.header + 5] ^= 0x01;
      expect(Frame.decode(damaged), isNull);
      expect(Frame.decode([1, 2, 3]), isNull);
      for (final f in [frames[3], frames[0], frames[1]]) {
        g.add(Frame.decode(f.encode())!);
      }
      expect(g.complete, isTrue);
      expect(g.payload, payload);
      expect(Frame.cut(const []), isEmpty);
    });

    test('a frame from another transfer starts the gather over', () {
      final g = Gather();
      g.add(Frame.cut(List.filled(10, 1), size: 5)[0]);
      expect(g.have, 1);
      g.add(Frame.cut(List.filled(30, 2), size: 5)[0]);
      expect((g.have, g.total), (1, 6));
    });
  });

  group('verification', () {
    const list = {
      'A4-1234': 'Paracetamol 500 mg tablets',
      '04-0567': 'Amoxicillin 250 mg capsules'
    };
    const covered = {'A4', '04'};

    test('the number as a camera reads it', () {
      expect(Verify.numberIn('NAFDAC REG. NO. a4 - 1234'), 'A4-1234');
      expect(Verify.numberIn('Reg No: 04–0567 Batch X'), '04-0567');
      expect(Verify.numberIn('no number here'), isNull);
    });

    test('three outcomes: on the list, not on it, cannot say', () {
      expect(Verify.check('A4-1234', list: list, covered: covered).outcome,
          Outcome.onTheList);
      expect(Verify.check('A4-9999', list: list, covered: covered).outcome,
          Outcome.notOnTheList);
      expect(Verify.check('B7-0001', list: list, covered: covered).outcome,
          Outcome.cannotSay,
          reason: 'the list does not cover B7');
      expect(Verify.check(null, list: list, covered: covered).outcome,
          Outcome.cannotSay);
    });

    test('the domain never says genuine', () {
      final banned = RegExp(r'\b(genuine|authentic|fake|counterfeit\w*|real)\b',
          caseSensitive: false);
      final src = File('lib/src/verification.dart')
          .readAsStringSync()
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(banned.allMatches(src).map((m) => m[0]), isEmpty);
    });
  });
}
