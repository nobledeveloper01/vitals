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

## 2026-09-15, morning — the wedge

Phase 3's core: the schedule as data, versioned, so a change is a new table
and the card records which one it was scheduled under; a dose as a fact
with the vial's batch and expiry; the card computed from the date of birth
and what was given, with catch-up — a late first dose pushes the second by
its interval, and the second is never offered before the first; overdue is
due plus twenty-eight days of grace. An expired vial is refused before a
fact exists, which is a date compared to a date and not a judgement. GS1
parsed with the group separator a real scanner sends, including day 00 for
the end of a month.

### What surprised us

**A widget test can hang on a write outside the real loop, before it
starts.** The setup wrote a registration to the log, the fake clock never
turned the file IO, and the test sat for ten minutes. Every write in a
widget test goes through `runAsync` now, and the file says so at the top.

**A patched line that the formatter had reflowed.** Twice tonight a
replacement found nothing to replace and said nothing, and a test failed
for a reason that made no sense until the file was read. Read the file.

**The copy gate refused "Record a dose".** The word list had "dose" for
dosing advice, and a vaccine dose is the record's own word for a thing
given, never advised. The list says *dosage* and any quantity in mg, ml or
mcg now, and was broken on purpose with "Give 5 mg" to see it still bite.

## 2026-09-15, later — the whiteboard, paper, and the mother's phone

### What we did

Phase 3's edges. `Whiteboard.today` over every record: the children with a
dose due today, sorted by how far behind, the defaulters counted; on the
clinic home in the largest type, each row opening the child. A message draft
for a mother with a phone, through the phone's own messages app — the app
composes and never sends, so nothing leaves a facility without a hand on it.
The A5 card as a PDF in the national layout, one row per scheduled dose with
the date given and the batch. `Card.next` in the domain — the earliest dose
not given, overdue first — and the reminder on the patient face naming it,
in the attention colour when overdue, with the day when not.

### What surprised us

**The design gate refused paper.** `PdfColors.grey700` on the printed card
tripped the palette check, and the check was right: the card is the
product's face on paper, and it prints in the light palette's ink now.
The gate did not know about PDFs; it did not need to.

**A test that asserted the wrong number and I believed the test.** A child
born a hundred days ago is fifty-eight days late for a six-week dose, not
thirty; the assertion was written from the grace period, not the schedule.
The widget was right. Work the arithmetic from the table before writing the
expectation.

**The PDF's metadata is a plain string only when it is ASCII.** An em-dash
in the title turned the whole string into UTF-16 hex, and the assertion that
the child's name was in the file found only the header. A colon, then.

## 2026-09-15, before dawn — Phase 4's core

### What we did

ADR-0008 first, because every widget in this phase sits on the line rule 1
draws: a range is printed beside a number and the mark is a comparison; a
checklist is answered by a person and never summed; a convention's
arithmetic is allowed and says where it came from. Then the domain —
observations, notes, the pregnancy and the visit, the stock ledger, the
fridge — and the screens on top: the pulse card, the vitals sheet, the
antenatal screen, stock tiles and the fridge prompt. A draft store that
writes on every keystroke, beside-then-rename, one write at a time per form.

### What surprised us

**The formatter reflowed the domain and the linter found twelve things.**
The package had never been through `dart format` at eighty columns; the
one-line `if` bodies became two-line ones, and the recommended lints want
braces on those. Wrapped them. The analyzer runs with infos fatal, so it
was the gate that found it, which is what it is for.

**The purity gate refused `show`.** `import 'registration.dart' show
utf8Of` is still the package's own file, and the gate's pattern is the
plain form only. The helpers went into `text.dart` and the imports are
plain. The gate did not need to learn a new form; the code needed to use
the one it knows.

**Two draft writes raced for one temporary file.** Every keystroke wrote,
the second rename found the first had taken the file, and the test threw
a path error after it had finished. Writes chain per form now.

**A tap that writes a file has to run through the real loop, even when
the write is a side effect.** The answer chips draft to disk; tapping them
outside `runAsync` left the writes pending in the fake zone, and the
record button then waited on them forever. Same lesson as last night,
one layer further in.

**The search had a `score`.** The guard that greps the domain for the
words a judgement would use found the registry's relevance score, which
is not clinical and was renamed anyway — a guard with an exception list
is a guard with a hole.

### Later: the languages

Four tables, thirteen keys each, a gate that counts them and was broken to
see it count, and a note in Settings that says *a draft, not yet read by a
speaker* under every language but English. The translations are mine and
the note is the honest part; a test also fails a table that repeats English
for more than three keys, so a "translation" that is English with a
different file name cannot pass as one. Naijá shares *days* and *in* with
English, which is Naijá.

## 2026-09-15, dawn — Phase 5 without a camera

### What we did

The half of exchange that needs no hardware: grants, scope enforced where
the bytes are built, frames with checksums, the animated QR, the access
log, verification's three words. The test that matters gathers the frames
off the widget in reverse order and reads the record back: registration,
immunisations, vitals, and no note — because the grant did not include
notes and the note was never in the payload.

### What surprised us

**A periodic `Future.delayed` is a pending timer the test framework will
not forgive.** The QR cycled on a chain of delayed futures; the test
ended with one pending and the framework said so. A `Timer.periodic`
cancelled in `dispose` is the honest shape anyway.

**The design gate refused black.** The QR's modules were `Colors.black`,
which is a colour outside the palette. It is in the palette now — `code`,
`#000000` in both themes, with the note that a camera reads it, not a
person — and the gate did not learn an exception.

**Naijá shares words with English, and the test that catches a fake
translation had to know how many.** Fifteen of forty-four keys were
identical, some rightly (*days*, *of*), some lazily (*Done*, *Next*). The
lazy ones are Naijá now and the threshold is a sixth of the keys; a table
that is English under another name would fail it by a mile.

### Later: the card on the lock face, the letter

The emergency card is a fact in the note slot with its own version byte;
opting out is another fact with *shown* false, so the record keeps that it
was once shown. The lock face reads it only on the patient face — a clinic
tablet's lock never shows a patient's blood group, and a test says so. The
referral letter computes its lines once, as data, so the test reads the
lines and finds the private note absent before the PDF is rendered.

**A sheet that pops the route pops the test's only route.** The emergency
sheet's save ended with `Navigator.pop`, and in a test whose whole tree
was that sheet, the navigator had nothing left and said so on the next
pump. A fresh tree between steps; the widget was right.
