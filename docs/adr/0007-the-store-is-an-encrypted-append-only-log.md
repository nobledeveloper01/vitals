# ADR-0007 — The store is an encrypted append-only log, until the registry needs an index

**Status:** accepted
**Date:** 2026-09-15

## Context

The planning documents chose SQLCipher-backed Drift for the tablet's store. It
is the right shape for Phase 2's registry — fifty thousand patients searched in
under half a second need an index. It is the wrong first move: it pulls in a
native SQLCipher build on both platforms and an ORM before a single fact is
stored, and the Phase 0 exit gate — *the encrypted store proved encrypted by
reading the file* — is a gate about bytes on disk, not about queries.

## Decision

Phase 1's store is an **append-only log of canonical single-fact records**, each
sealed with ChaCha20-Poly1305 under a key that lives in the platform keychain
and never in the file. Nothing in the log is ever rewritten; a merge appends
what was missing and a correction appends a supersession — the same shape as
the record itself. Reading the store is decrypting and unioning the log. A test
opens the file and asserts no fact's bytes appear in it.

Phase 2 adds the index it needs — SQLCipher through Drift, as planned — beside
the log, never instead of it: the log stays the record and the index is
derived, rebuildable from it.

## Consequences

- The Phase 0 gate is provable now, in a widget test, on any machine.
- Backup (ADR-0006 #29) is the log copied under a second key; restore is
  decrypt, verify each fact decodes, union.
- A corrupt tail — a write cut by a dead battery — loses at most the fact
  being written, and the test cuts a file mid-record to prove it.
