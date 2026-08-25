# Vitals

**Portable primary health records and drug authenticity verification for Nigeria.**

Two failures, both fatal, both caused by missing information at the point of care.

Nigerian primary healthcare runs on paper, so there is no continuity: a pregnant woman attends
antenatal care at one clinic, travels to deliver, and arrives somewhere that knows nothing about
her rising blood pressure — pre-eclampsia is detectable from a trend and invisible from a single
reading. Separately, falsified and substandard medicines circulate at a rate that makes them a
genuine cause of death, concentrated in exactly the categories where failure kills fastest.

Vitals is one clinical record with two faces: a **clinic tablet app** that works offline
indefinitely, and a **patient phone app** holding a portable copy they carry between facilities.

See [`docs/00-PRODUCT-STATEMENT.md`](docs/00-PRODUCT-STATEMENT.md) for the full analysis.

---

## Status

Specified, not yet built. Deliberately **last but one** in the build order — it is bound to a long
institutional sales cycle, so it should not be built before the products that can validate
themselves faster.

## The insight

**The hard problem is not the record. It is merging two records that were both edited while
neither could see the other.**

Two nurses on two tablets in one clinic, offline for a week, both updating the same patient. Or a
patient's phone meeting a facility's tablet after both changed. A conventional last-writer-wins
system silently destroys clinical data in this situation — and here, silent data loss is not a
bug, it is a patient harm.

Vitals treats clinical observations as **immutable facts that merge by union, never by
overwrite**. A blood pressure taken on Tuesday and one taken on Wednesday are both true. They do
not conflict. They both survive.

That single modelling decision is what makes a genuinely offline clinical record safe, and it is
the technical core of the product.

## Does it need a backend?

**Yes, but later and thinner than you would expect.** A single-facility deployment runs
**entirely serverless** — every clinical workflow is on-device, and records move between devices
peer-to-peer over BLE or a QR handshake with no network and no server at all.

A backend arrives for multi-facility continuity and supervisor oversight. Even then it is a
replica with **no special authority**: it runs the same merge semantics as the client, and it
performs no server-side validation that could reject a record a tablet accepted.

The design rule is absolute: **if a nurse needs it to see a patient, it runs on the tablet.** A
rural clinic may be offline for three weeks. A system that degrades when offline is a system that
does not work.

## What it will not do

Vitals presents records, trends and protocol checklists. It **does not** compute a diagnosis, a
risk score, a triage category, or a treatment recommendation. Crossing that line turns the
product into a regulated medical device — and the clinician's judgement is the point.

## Platforms

Android 8+ and iOS 14+, phone and tablet, from one codebase. The genuinely hard cross-platform
problem is **device-to-device transfer between mixed Android↔iOS pairs**, where BLE is the
guaranteed path and chunked animated QR is the floor that works between any two devices with a
screen and a camera.
