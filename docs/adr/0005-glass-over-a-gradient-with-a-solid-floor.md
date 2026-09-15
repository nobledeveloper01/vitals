# ADR-0005 — Glass over a gradient, with a solid floor

**Status:** accepted
**Date:** 2026-09-15

## Context

The portfolio's design systems to date are flat and stepped: three surface
tones and a hairline, because depth on a dark screen cannot come from shadow.
Vitals is asked to be the 2027 product — glassmorphism, gradient, motion — and
it is also the product whose floor is a three-year-old 3 GB tablet under one
window and a nurse who is measured against paper.

## Decision

The page is a fixed **gradient mesh**; content sits on it; chrome floats over it
as **glass** in three depths, each meaning one thing. Motion has four tokens and
every animation shows a cause. **And every one of those has a floor:** glass has
a solid twin drawn when the device, the battery or the user says so; every
duration has a zero; the mesh is a cached raster, never live. The app is
complete without any of it. Contrast is asserted in CI for every text colour on
every glass fill composited on every wash, light and dark, glass and solid.

## Consequences

- `Motion.glass` and `Motion.reduced` are read at act time; Settings toggles
  them without a relaunch, and the UI tests audit both states.
- The frame budget on the reference tablet — 16 ms with glass on, measured in
  Phase 4 — decides the default for its device class, not the mock-up.
- Meaning colours stay off regions: a red page would be a triage colour, and
  Vitals does not triage.
