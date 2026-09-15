# ADR-0002 — The domain imports nothing

**Status:** accepted
**Date:** 2026-09-15

## Context

Every signature, every merge and every schedule in Vitals is computed from the
bytes and rules in the domain. If those depend on Flutter, a platform clock or a
platform random source, two devices can disagree about the same record, and
disagreement here is a lost fact.

## Decision

`packages/vitals_domain` is a Dart package with **no dependencies** — not
Flutter, not `dart:io`, not a clock, not randomness. Time and identifiers enter
as arguments. `make domain-purity` reads every file under it for an `import` of
anything but `dart:core`, `dart:typed_data` and the package's own files, and
fails; the gate is proved to fire by injecting a violation.

## Consequences

- The same package runs the merge on a tablet, a phone and — translated line for
  line — the .NET server, with a shared fixture proving the translation.
- Tests run with `dart test` in seconds and need no device. They run first.
- Anything needing a platform is an interface the app implements.
