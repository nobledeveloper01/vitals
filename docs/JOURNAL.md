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

## 2026-09-15, before dawn — the store, and what a widget test's clock cannot do

Phase 1's store: an append-only log of canonical single-fact records, each
sealed with ChaCha20-Poly1305 under a key in the keychain and never in the
file (ADR-0007, which sets aside the planned SQLCipher until Phase 2 needs
an index). Four tests: nothing a fact says is in the file; appends union; a
tail cut mid-frame loses that frame and nothing before it; a wrong key reads
nothing and a flipped byte drops only its frame. `Records` over it, opened
under the splash, and the whiteboard and the sync chip read from it. The
domain gained `Exchange`: the delta one device hands another, and a
fingerprint two devices compare first.

### What surprised us

**A widget test's clock does not turn real file IO.** The store opened
under the splash never finished in the flow tests, because `pumpAndSettle`
advances a fake clock and the file read waits on the real event loop. The
tests hand the app a store that is already open; the phone opens its own.

**The launch screen storyboard from the template is from 2017.** Its
`toolsVersion` predates trait collections, so a named colour with a dark
variant cannot be declared in it; Xcode refused to compile the patched file
at all. It was rewritten from nothing, thirty lines, and the launch ground
is now the splash's ground in both appearances — measured by a pixel.

**Two GitHub runs failed on things the Mac did not see.** `dart analyze`
ran before `pub get`, and a page-transition class lives in a different
library on the runner's Flutter than on this machine's. `deps` is now a
target `analyze` depends on, and the transition theme is the platform's own.

**The runner's Flutter was two minors behind this Mac's**, and `path_provider`
wanted the newer SDK. The workflow pins the version this machine has, which
is the honest form of "works on my machine": say which machine.

## 2026-09-15, dawn — the registry

Phases 0 and 1 cleared; Phase 2 built as far as this Mac reaches. A
registration is a fact with its own encoding. Names fold to a phonetic key
tuned to how Nigerians spell one name three ways — the Oluwa- and Chukwu-
prefixes that speech drops, Muhammad's four spellings, the tone marks a
keyboard may or may not have. Search matches every token against the
patient or the mother, or four digits of a phone. A duplicate is a
candidate with reasons, side by side, and a person registers anyway or
opens the one it is; the app never merges.

### What surprised us

**A shared family phone made twins one person.** The first duplicate rule
took "same phone and family name" as a reason, and in Lagos a household
has one phone. Kehinde matched Taiwo. The phone is a reason only with the
given name now, and the twins test is the one that keeps it so.

**A hyphen is a joiner, not a space.** Ade-Ola is one name; the tokeniser
had split it. Its own test said so.

**A widget test's fake clock, again.** A write to the log inside a tap
handler is real file IO; the tests wrap such taps in `runAsync` and wait a
real half-second. And the whiteboard text that never changed turned out to
be a patch that had missed its target after the formatter reflowed the
line — a failing test found a patch that had silently not applied.
