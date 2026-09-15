# ADR-0001 — One codebase, two faces: Flutter, not native

**Status:** accepted
**Date:** 2026-09-15

## Context

Vitals is two apps that must agree to the byte: a clinic tablet and a patient
phone, on Android and iOS, phone and tablet, exchanging one clinical record
with no server between them. The portfolio has two native projects (Tender,
Snag) and the case for each was that the platform's own framework *was* the
product — the accessibility layer, the Secure Enclave, ARKit.

## Decision

Vitals is Flutter, from one codebase, and functional parity between the four
faces is a hard requirement gated in CI, not an aspiration.

## Consequences

- The merge engine, the schedule engine and the canonical encoding live in a
  pure Dart package used by every face identically, so parity of the thing that
  matters is structural. ADR-0002.
- The two genuinely native surfaces — BLE and the camera — are behind a
  transport façade with a platform channel each, and the animated QR path is
  the floor that needs neither.
- The glass design system is Flutter's own compositor, not a platform effect,
  and so behaves the same on both — with a solid floor where the GPU cannot
  afford it. ADR-0005.
