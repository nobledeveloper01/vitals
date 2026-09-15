// Antenatal facts: the expected day is the last period plus 280, weeks are
// arithmetic, the danger-sign checklist is mandatory and every answer is
// kept — and there is no sum, no score, no word for the visit as a whole.
import 'dart:io';

import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  test('the expected day and the weeks are arithmetic from the last period',
      () {
    final p =
        Pregnancy(lmpDays: 20_000, gravida: 2, para: 1, lmpEstimated: true);
    expect(p.eddDays, 20_280);
    expect(p.weeksOn(20_000 + 7 * 12 + 3), 12);
    final back = Pregnancy.decode(p.encode());
    expect((back.lmpDays, back.gravida, back.para, back.lmpEstimated),
        (20_000, 2, 1, true));
    Fact fact(int n, List<int> payload) => Fact(
        id: List.filled(16, n),
        patient: List.filled(16, 1),
        kind: FactKind.ancVisit,
        stamp: Stamp(wallMillis: n * 1000, counter: 0, device: 'a'),
        author: 'nurse',
        payload: payload,
        supersedes: null);
    final visit = AncVisit(
        visitNumber: 1,
        visitDays: 20_050,
        answers: {for (final s in DangerSign.values) s: false});
    final facts = [fact(1, p.encode()), fact(2, visit.encode())];
    expect(Pregnancy.of(facts)!.lmpDays, 20_000);
    expect(AncVisit.of(facts).single.visitNumber, 1,
        reason: 'the pregnancy and the visit share a slot and are told apart');
  });

  test(
      'a visit with a sign unanswered cannot be encoded; a complete one keeps every answer',
      () {
    final partial = AncVisit(
        visitNumber: 1, visitDays: 20_100, answers: {DangerSign.fever: false});
    expect(partial.complete, isFalse);
    expect(() => partial.encode(), throwsStateError);
    final answers = {for (final s in DangerSign.values) s: false}
      ..[DangerSign.bleeding] = true
      ..[DangerSign.severeHeadache] = true;
    final v = AncVisit(
        visitNumber: 2, visitDays: 20_130, answers: answers, notes: 'BP taken');
    final back = AncVisit.decode(v.encode());
    expect(back.complete, isTrue);
    expect(back.present, [DangerSign.bleeding, DangerSign.severeHeadache]);
    expect(back.answers[DangerSign.fever], isFalse);
    expect((back.visitNumber, back.visitDays, back.notes),
        (2, 20_130, 'BP taken'));
  });

  test('the domain has no score, risk or triage: a guard on the source itself',
      () {
    // ADR-0006 refused the danger-sign total. A future getter that sums the
    // answers is a failing test before it is a regulated device.
    final banned = RegExp(
        r'\b(score\w*|risk\w*|triage\w*|diagnos\w*|severity)\b',
        caseSensitive: false);
    for (final f in Directory('lib/src').listSync().whereType<File>()) {
      final hits = banned.allMatches(f.readAsStringSync()).map((m) => m[0]);
      expect(hits, isEmpty, reason: '${f.path} says ${hits.join(', ')}');
    }
  });
}
