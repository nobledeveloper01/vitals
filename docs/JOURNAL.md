# Journal

What happened, and what surprised us. Newest last. Every working session adds an entry.

## 2026-09-15, night — the plan, and the design floor

Vitals was specified to depth and deliberately built last but one. Tonight it
starts: the ask was thirty more things, a 2027 design — glass, gradient,
motion — a mark and a splash, and a .NET backend. The documents came first, as
they do in this portfolio: the sentence that decides arguments is the merge,
not the record, so the merge engine is Phase 1 and nothing clinical starts
before its five invariants are green.

### What surprised us

**Thirty things and three refusals.** Each candidate was checked against the
seven rules before it was accepted; three failed the first one — a danger-sign
score, an anaemia flag, a growth alert — because each is a clinical judgement
wearing a feature's clothes. They are in the backlog with the reason, which is
the honest place for them.

**The 2027 design has a 2022 floor.** Glass over a gradient mesh is the ask; the
reference tablet is three years old and has 3 GB. The design system was written
with a solid twin for every glass depth and a zero for every duration, and the
rule that the app is complete without any of it. The contrast gate measures
text on glass composited over the darkest wash, which is the only honest way to
measure it.

**The backend spec said Node.** The portfolio's one running server is C#/.NET
and has been the steadier shape; ADR-0004 moves Vitals to it and keeps the
spec's API. The merge engine will exist twice, Dart and C#, held to one another
by a fixture the Dart tests generate — the same discipline as Snag's two
verifiers.

## 2026-09-15, small hours — the engine twice, and the test that was green for nothing

The domain package: a hybrid logical clock, immutable facts, a record that is
a set, union as the whole merge, supersession as correction, and one byte
encoding. Five invariants over three hundred generated worlds of three
devices recording, correcting and exchanging in generated orders; a harness
test that runs a last-writer-wins merge through the same worlds and must see
loss. Then the same engine in C#, held to the Dart by a fixture of two
hundred worlds — every fact and the settled bytes — merged forward, reversed,
shuffled and halved, to the byte.

### What surprised us

**Invariant 3 passed with nothing to test.** The C# side asserted that the
worlds contained corrections at all, and they did not: the generator's `state
% 4` never produced a 2. An LCG's low bits cycle in a handful of steps — a
thing every textbook says and every hand forgets. The Dart test had been
green over a set of zero supersessions. The generator takes its high bits
now, the Dart test asserts the count, and the fixture was regenerated. The
second verifier found the first's blind spot on its first run, which is the
reason there are two.

**Two devices can correct the same fact while apart.** Union keeps both
corrections; the original is hidden as superseded; and which correction is
"latest" is a question the merge must not answer. `history` returns both and
the record shows neither as lost. Who was right is the nurse's call.
