# ADR-0003 — Facts are immutable and merge by union

**Status:** accepted
**Date:** 2026-09-15

## Context

Two nurses on two tablets in one clinic, offline for a week, both updating the
same patient. A patient's phone meeting a facility's tablet after both changed.
Last-writer-wins silently destroys one side. In a clinical record silent loss
is a patient harm, and it is invisible until the harm.

## Decision

A clinical observation is an **immutable fact**: who, when (a hybrid logical
clock and the device's wall time, both kept), on which device, what. A record is
the **set** of its facts. Merge is set union. A correction is a new fact that
*supersedes* another by id; both survive, the record shows the latest, the
history is one tap away. No table has a delete for any role.

Five invariants are the release gate, property-tested across generated
multi-device interleavings:

1. No fact is ever lost.
2. Merge is commutative, associative and idempotent.
3. A correction never hides the original.
4. Two devices that exchanged everything hold identical bytes.
5. Nothing a tablet accepted is rejected elsewhere.

The **canonical encoding** of a record is versioned, big-endian, length-prefixed
and float-free, asserted by a checked-in fixture — the same discipline as Snag's,
for the same reason: invariant 4 is over bytes.

## Consequences

- Storage grows monotonically. A record is compacted only by *snapshotting* —
  a signed digest of the set at a clock — never by deleting facts.
- The merge harness exists before the engine, run against a deliberately broken
  stub that must fail (Phase 0's gate), so the tests are known to bite.
- The server is a replica running this same merge. ADR-0004.
