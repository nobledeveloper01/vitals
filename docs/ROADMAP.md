# Vitals — roadmap

Phases are gates, not dates. A phase is done when its exit gate is green, and the
next one does not start before. `PHASE` holds the current number; `make phase`
prints it and its gate. The planning documents this was cut from are
`docs/06-ROADMAP.md` and `docs/07-BACKEND-SPEC.md`, kept local.

**The MVP is the immunisation schedule, on a tablet that never needs a network,
with a patient card the mother carries.** The build order follows the product's
own rule: the merge engine first, because every clinical table depends on it and
retrofitting immutability onto a schema that allows updates is a rewrite.

The thirty extra things (ADR-0006) are placed in the phase whose exit gate they
serve, never ahead of it.

## Phase 0 — Foundation · *cleared 2026-09-15*

The app and its two faces, the pure domain package, the design system as code
(mesh, glass with its solid floor, motion tokens, the mark, the splash), the
gates, CI on both platforms, and the .NET server skeleton with its parity
harness — **and the merge test harness before the merge engine exists.**

**Exit gate**. *CI green on both platforms; the domain purity gate, the copy gate
and the contrast gate each proved to fire; the encrypted store proved encrypted
by reading the file; the merge harness running against a deliberately broken
stub and failing.*

From the thirty: #24 auto-lock with the blurred lock screen, #25 the plain-surfaces
and reduce-motion toggles, #26 large-type nurse mode, #23 the attribution chip.

## Phase 1 — The merge engine · *cleared 2026-09-15*

Immutable facts, a hybrid logical clock, union merge, supersession for
corrections, state versioning, the outbox, and the five invariants:

1. **No fact is ever lost** — the union of every device's facts after any
   interleaving equals the set of facts ever recorded.
2. **Merge is commutative, associative and idempotent** — any order, any
   grouping, any repetition gives the same record.
3. **A correction never hides the original** — a superseding fact and the fact it
   supersedes both survive, and the record shows the latest with the history
   one tap away.
4. **Two devices that have exchanged everything hold identical records** — byte
   for byte, in the canonical encoding.
5. **Nothing a tablet accepted is rejected elsewhere** — the server and every
   client run the same merge and the same validation, in Dart and in C#, held to
   one another by a shared fixture of generated interleavings.

**Exit gate**. *All five invariants passing across thousands of generated
multi-device interleavings in Dart, and the same fixture passing in C#. No
clinical feature starts until this is green.*

From the thirty: #22 correction as a superseding fact with visible history, #28
sync honesty ("last met another device"), #29 encrypted backup to a file that
verifies on restore.

## Phase 2 — Registry and search · *cleared 2026-09-15, short of the tablet*

Registration, name tokenisation and phonetics for Nigerian names, FTS plus
trigram search, duplicate detection, households, the patient ID and its QR.

**Exit gate**. *Search under 500 ms across a synthetic 50,000-patient registry on
the reference tablet; duplicate detection validated against realistic
name-variant fixtures; the "same patient?" assistant never merges by itself.*

**Built 2026-09-15, short of the tablet.** Registration as a fact with its own
encoding; Nigerian-name phonetics (Adeola/Adéọlá, Oluwaseun/Seun,
Chukwuemeka/Emeka, Muhammad/Mohammed fold to one key); search by any token,
the mother's name or four digits of a phone; duplicates as candidates with
reasons, twins kept as two, a shared family phone never a reason alone; the
assistant on screen, and a person registering anyway. Fifty thousand
synthetic patients search in under half a second in the test — on this Mac;
the reference tablet is R4.

From the thirty: #13 households with a family view, #14 twins and duplicates by
phonetics + DOB + mother, #21 the merge assistant that presents and never
decides, #6 the paper card photographed at registration.

## Phase 3 — Immunisation, the wedge · **current**

The schedule engine from versioned national tables, dose recording with batch
scanning, validity windows, catch-up, the defaulter list, the digital card, the
patient's reminders, and the stock decrement.

**Exit gate**. *Schedules correct against published fixtures including catch-up
and an imprecise date of birth; reminders fire with the device permanently
offline on both platforms; the printed card matches the national layout.*

**Built 2026-09-15, the core.** The national schedule as a versioned table —
birth, six, ten and fourteen weeks, six, nine and fifteen months; a dose as a
fact with batch and expiry; the card with catch-up (a late first dose pushes
the second by its interval; dose two is never offered before dose one); an
expired vial refused before anything is written; GS1 from the vial's barcode
with the separator a scanner sends. On the screen: the card, the dose sheet,
the history with every fact attributed, registration leading straight to the
card. Then the same night: the ward whiteboard on the clinic home with the
furthest behind first and the defaulters counted; a message draft for a mother
with a phone, opened in the phone's own messages and never sent by the app; the
A5 card as a PDF in the national layout, printed in the palette's own ink; and
the reminder on the mother's phone naming the next vaccine and its day. Still
to build in this phase: the reminders as notifications with the phone offline,
which needs a device in hand (R4). The stock decrement landed with Phase 4.

From the thirty: #4 the A5 card PDF in the national layout, #7 the ward
whiteboard, #8 defaulter SMS drafts, #9 reminders naming the vaccine, #10 GS1
batch scan with expiry, #2 growth curves drawn on the WHO reference.

## Phase 4 — Vitals, ANC and stock

Vitals with trends and reference ranges, the flag rail, consultation records,
ANC registration and visits, the mandatory danger-sign checklist, the stock
ledger and alerts, interruption-safe forms.

**Exit gate**. *Encounter recording time at or below the paper baseline in a
supervised pilot; every form provably restores after a hard kill mid-entry; no
clinical interpretation anywhere, reviewed line by line.*

From the thirty: #1 the pulse card on the patient header, #5 voice notes kept
local, #11 the cold-chain log with its twice-daily prompt, #12 stock count by
tapping tiles, #27 the four patient-face languages.

**Built 2026-09-15, the core.** Vital signs as facts — integers in fixed
units — with the pulse card showing the last of each measure, the published
range printed beside it, the trend drawn behind the number and *outside range*
the only mark (ADR-0008); the vitals sheet drafted on every keystroke and
proved to come back after the tree is thrown away. Antenatal: the pregnancy
with its expected day labelled *from the last period + 280 days*; the visit
that cannot be recorded until all ten danger signs are answered, the yeses
shown one by one in the danger colour and never counted; a source test that
fails on the words *score*, *risk*, *triage*, *diagnos-* or *severity* in the
domain. Stock: every movement a fact on the facility's record, the count by
tapping tiles with the difference from the ledger shown and never absorbed,
low stock and expiring batches marked, a unit issued with every dose in the
same write. The fridge: morning and evening prompts, a reading outside the
printed range marked. Then the four patient-face languages (#27): Naijá,
Yorùbá, Hausa and Igbo as complete tables of the same keys, `l10n-check`
failing on one missing and proved to, each marked a draft in Settings until a
speaker has read it; the clinic face stays English. Still to do in this
phase: voice notes (#5), and the exit gate's supervised timing (R2).

## Phase 5 — Exchange and verification

The peer transport façade: BLE as the guaranteed path, animated chunked QR as
the floor between any two devices with a screen and a camera; the handshake,
encryption, scope enforcement at payload construction; patient share grants and
the access log; drug verification with the three-state outcome and reporting.

**Exit gate**. *Mixed Android↔iOS transfer verified on real hardware; a full ANC
history transfers in under fifteen seconds; scope enforcement proved at payload
construction; a verification never says "genuine".*

From the thirty: #3 the animated QR with its progress ring, #15 the access log
the patient sees, #16 share grants with scope and expiry, #17 the emergency card
the patient opts into, #18 the offline facility map, #19 the referral letter,
#20 the pack photographed for verification.

**Built 2026-09-15, the core, short of a camera.** The share grant as a fact
on the patient's record — which kinds, to whom, until when — and the payload
built from the grant and nothing else: a test gathers the frames off the
screen the way a camera would and reads a record back that holds the
registration and the granted kinds, and the note that was never in the bytes.
Frames with index, total and a checksum, gathered in any order, twice, with a
damaged one refused; the animated QR with the ring in the brand gradient,
stepping by hand with a count under less motion. The access log: a clinic
opening a record writes an attributed fact to it, and the patient's phone
lists every open newest first. Verification with three outcomes — *on the
list*, *not on the list*, *the list cannot say* — and a test over every
language for the fourth word. Then the emergency card (#17) on the lock face
while the patient says so and never on a clinic tablet, opting out a fact and
not a deletion; and the referral letter (#19) with the sections the nurse
chose and the unchosen ones never in the bytes. Then the receiving side: a
frame is text — `VITALS/1 ` and base64 — so any camera knows what it saw,
and a *Receive a record* screen on both faces gathers frames from the camera,
or from a paste field where there is no camera, and merges the record by
union; a test pastes a real transfer's frames in reverse, one twice, one junk,
and reads the record back on the other device, then again for nothing added.
Still to build: BLE (R3, hardware), a mixed Android↔iOS QR transfer watched
on real handsets (R3), the facility map (#18), the pack photographed (#20's
camera half).

## Phase 6 — Pilot hardening → **v1.0**

Two facilities. Lab results, referrals, AEFI, remote wipe, the audit export,
performance and crash rate to the 99.7% bar. **v1.0 ships.**

**Exit gate**. *Crash-free above 99.7% across the pilot; a nurse who has never
seen the app records an immunisation visit unassisted; the two facilities'
records merge with no fact lost, checked by the invariants against the pilot
data.*

From the thirty: #30 the signed audit export.

**Built ahead, 2026-09-15.** The audit export: every write and every open as
a CSV row, signed with the tablet's own Ed25519 key kept in the keychain, the
public key in the file and in Settings; `scripts/verify-audit.py` checks a
file with nothing but Python, and the test runs it on a good file, a changed
byte, and the wrong key. The rest of this phase is the pilot itself.

## Phase 7 — Scale · *v1.1*

The supervisor dashboard served by the .NET server, FHIR export, multi-facility
deployment tooling, LGA aggregate reporting, the outbreak signal from clustered
counterfeit reports.

**Exit gate**. *A supervisor sees two facilities' aggregates without any patient
identifiable; a FHIR bundle exported from Vitals imports into a reference
server unchanged.*
