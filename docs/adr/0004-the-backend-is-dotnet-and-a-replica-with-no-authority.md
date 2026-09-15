# ADR-0004 — The backend is .NET, and a replica with no authority

**Status:** accepted
**Date:** 2026-09-15

## Context

A single facility runs with no server at all, indefinitely. A server arrives
for multi-facility continuity, supervisor aggregates, authoritative drug
verification and device replacement — and must never become the thing a nurse
needs to see a patient. The backend specification was drafted for Node and
Fastify; the portfolio's other server (Backhaul) is C#/.NET 9 with a parity
suite holding it to the domain, and it has been the more reliable of the two
shapes.

## Decision

The server is **C# on .NET 9**, minimal APIs, Postgres through EF Core, in
`server/` with the same three-project shape as Backhaul: `Vitals.Domain` (the
merge and the canonical encoding, translated from the Dart), `Vitals.Api`,
`Vitals.Infrastructure`. It **stores and relays**. It runs the same merge as
every client and performs no validation that could reject a fact a tablet
accepted; it computes nothing clinical.

A **parity fixture** — thousands of generated interleavings with their expected
merged bytes, produced by the Dart tests and checked in — is run by the C#
tests, and CI fails if the two engines disagree on one byte.

## Consequences

- The server can be down for a month and every clinic keeps working; the only
  things that wait are aggregates and cross-facility continuity.
- Tests run in memory by default and against a real Postgres when
  `TEST_DATABASE_URL` is set, as Backhaul's do.
- `docs/07-BACKEND-SPEC.md` is rewritten for this stack; the shape of the API
  in it is unchanged.
