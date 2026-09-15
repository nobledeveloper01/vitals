# Release gates

What stops v1.0, and what would clear it. The count in the README is checked
against this table by `make counts-check`.

## Blocks v1.0

| # | Gate | Waiting on | Expected to clear in |
|---|---|---|---|
| R1 | **The merge invariants against real interleavings.** Generated interleavings are the proof; two tablets that were actually offline for a week in one clinic are the evidence. The engine is Phase 1; the clinic is Phase 6. | Two tablets in a clinic | Phase 6 |
| R2 | **Encounter time against the paper baseline.** A nurse who finds the app slower than paper abandons it, and no simulator measures a nurse. | A supervised pilot | Phase 4 |
| R3 | **Mixed Android↔iOS transfer on real hardware.** BLE between an Android tablet and an iPhone, and the animated QR between any two devices, have to be watched. | Two handsets of each platform | Phase 5 |
| R4 | **The reference tablet.** A three-year-old 3 GB tablet under one window: search under 500 ms, glass or its solid floor, the crash rate. | The tablet | Phase 2 onward |
| R5 | **A clinician reads every screen for interpretation.** The gate on words catches the vocabulary; only a nurse or a doctor catches a chart that implies a diagnosis by its colour. | An hour of a clinician | Phase 4 |
| R6 | **A programme partner for the pilot.** The institutional sales cycle is the product's largest risk and it starts before Phase 6, not after. | A partner | Phase 6 |

## Cleared

| # | Gate | Cleared on | By |
|---|---|---|---|
