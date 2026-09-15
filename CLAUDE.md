# Vitals

Portable primary health records and drug authenticity verification for Nigeria.
One clinical record with two faces: a **clinic tablet app** that works offline
indefinitely, and a **patient phone app** holding a portable copy. Flutter, one
codebase, both platforms — read `docs/adr/0001-one-codebase-two-faces.md`
before asking why it is not native. Read `docs/00-PRODUCT-STATEMENT.md` for why
this exists, `docs/ROADMAP.md` for what phase the project is in and what its exit
gate is, and `docs/adr/` for the decisions that are already settled. `PHASE`
holds the current phase number.

The one sentence that decides most arguments:

> **The hard problem is not the record. It is merging two records that were both
> edited while neither could see the other.**

Two nurses on two tablets, offline for a week, both updating the same patient.
A conventional last-writer-wins system silently destroys clinical data there —
and here, silent data loss is not a bug, it is a patient harm. Vitals treats
observations as **immutable facts that merge by union, never by overwrite**. That
one modelling decision is the technical core, and it is built first (ADR-0003).

## Design system

Read `DESIGN.md` before making any visual or motion decision. It is the
portfolio's first glass-over-gradient system, and every rule in it has a floor
underneath: **a 10" clinic tablet with 3 GB of RAM that is three years old, and a
patient's 5" 720p phone with 2 GB, both in a room lit by one window.** Glass is
drawn where the device can afford it and replaced by a solid surface where it
cannot, and the app is complete either way (ADR-0005).

## The things that are never traded

1. **Nothing clinical is computed.** Vitals presents records, trends and
   protocol checklists. It never states a diagnosis, a risk score, a triage
   category or a treatment. Crossing that line makes it a regulated medical
   device and takes the decision away from the clinician. `make copy-check`
   fails the build on the words that would.
2. **Facts are immutable and merge by union.** No table has a destructive
   operation for any role. A correction is a new fact that supersedes, never an
   edit. Five merge invariants are property-tested across generated multi-device
   interleavings, and they are the release gate. ADR-0003.
3. **If a nurse needs it to see a patient, it runs on the tablet.** A rural
   clinic may be offline for three weeks. The backend is a replica with no
   authority, and it runs the same merge as the client, in C#, held to the Dart
   by a shared fixture. ADR-0004.
4. **The domain imports nothing.** Not Flutter, not a clock, not randomness. A
   pure Dart package, enforced by `make domain-purity`, proved to fire. ADR-0002.
5. **Every write is attributed and audited.** A staff PIN on every fact; a
   patient can see who opened their record.
6. **A patient's record leaves only in the patient's hand.** Device-to-device
   over BLE or animated QR, with a scope the patient chose. No record is sent to
   a server without a facility's explicit enrolment.
7. **The floor is a real device.** Glass, gradient and motion are the design;
   they are never the reason a three-year-old tablet cannot run the app.

## Working on this repo

- `make ci` is the gate. `make gates` runs the blocking ones alone.
- **Prove a guard fires before trusting it.** Break it on purpose, watch it
  fail, put it back. This has found real defects in every project in this
  portfolio, including gates written the same hour.
- **A gate that passes for a reason unrelated to what it checks is worse than
  one that cannot fail.** Delete the cache and re-run before believing a green
  result. Check the exit status of `make`, not of the pipeline it is in.
- ADRs live in `docs/adr/`. **Write one for any non-obvious decision, before
  the code that depends on it.**
- **`docs/JOURNAL.md` every working session.** What we did, and what surprised us.
- The domain package tests with `dart test` in seconds and needs no device. Run
  it first. The server tests with `dotnet test` and need no database unless
  `TEST_DATABASE_URL` is set.
- **Never commit a record.** A fixture is synthetic; a database from a demo is
  somebody's patient.

## Definition of done

- [ ] Acceptance criteria met and demonstrated on a device
- [ ] **Merge invariants passing** if the domain was touched
- [ ] Works fully offline, indefinitely; interruption-safe by a hard-kill test
- [ ] **No clinical interpretation introduced** — reviewed explicitly, per feature
- [ ] Every write attributed and audited
- [ ] Verified on a physical Android tablet and iPad, phone and iPhone
- [ ] Light and dark authored; every pair contrast-asserted in CI; glass and solid
- [ ] 200% text scaling without truncation; screen-reader labelled
- [ ] Reduce Motion honoured, including the splash
- [ ] Every error path has a forward path
- [ ] ADR written for any non-obvious decision
- [ ] `CHANGELOG.md` updated under `[Unreleased]`
- [ ] `make ci` green
