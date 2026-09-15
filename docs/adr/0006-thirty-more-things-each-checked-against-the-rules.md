# ADR-0006 — Thirty more things, each checked against the rules

**Status:** accepted
**Date:** 2026-09-15

## Context

The specification is already large, deliberately: a record that does not
replace the paper card is a second system nobody maintains. The ask was thirty
more things that make the product special. The risk is the one in R5 of the
roadmap: scope creep into clinical decision support, which would make Vitals a
regulated medical device. So each item below was checked against the seven
rules in `CLAUDE.md` before it was accepted, and each names the phase whose exit
gate it serves. An item that would have needed a rule bent is in the backlog
with the reason, not here.

## Decision

Each of the thirty below is accepted, placed in the phase whose exit gate it
serves, and built only when that phase is current. An item that would need a
rule bent is refused and goes to the backlog with the reason.

## The thirty

| # | Thing | Rule it was checked against | Phase |
|---|---|---|---|
| 1 | **The pulse card.** The patient header carries their last vitals as a live glass card with the trend drawn behind the numbers. | Nothing clinical is computed — a line, not a verdict | 4 |
| 2 | **Growth curves on the WHO reference.** A child's weight and height drawn on the reference bands; the band is a reference, the word is the nurse's. | No z-score label, ever | 3 |
| 3 | **The animated QR with a progress ring.** Chunked, error-corrected, with the ring in the brand gradient and a count for reduced motion. | Complete without glass | 5 |
| 4 | **The A5 card in the national layout.** The immunisation card as a PDF that prints onto the paper card's own layout, so a facility with a printer keeps its filing. | The record is the surface | 3 |
| 5 | **Voice notes, kept local.** A nurse records a note on an encounter; the audio is a fact, hashed, never transcribed, never sent. | Every write attributed | 4 |
| 6 | **The paper card, photographed.** At registration the legacy card is photographed and attached, so nothing on paper is lost while the digital record starts. | A patient's record leaves only in their hand | 2 |
| 7 | **The ward whiteboard.** Today's due list on the tablet's home in the largest type, readable from the door. | The floor is a real device | 3 |
| 8 | **Defaulter SMS drafts.** One tap opens the phone's own SMS app with a prefilled message to a mother who missed a dose. No gateway, no server. | If a nurse needs it, it runs on the tablet | 3 |
| 9 | **Reminders that name the vaccine.** The patient's phone says *Penta 2, Thursday, Ikeja PHC*, scheduled at record time, fired offline. | Offline indefinitely | 3 |
| 10 | **GS1 batch scan with the expiry read.** The barcode fills batch and expiry; an expired batch is refused before the dose is recorded. | No interpretation — a date compared to a date | 3 |
| 11 | **The cold-chain log.** Twice a day the tablet asks for the fridge temperature; a reading outside range is marked *attention*, and the log is a fact like any other. | Every write audited | 4 |
| 12 | **Stock count by tapping tiles.** A count sheet where each tile is a product and each tap is one unit, for a nurse counting a shelf with one hand. | 56 dp targets | 4 |
| 13 | **Households.** A family view: a mother and her children on one screen, with each child's next due date. | Registry integrity | 2 |
| 14 | **Twins and duplicates.** Phonetic name, date of birth and mother's name together, tuned to Nigerian naming, so twins are two and one child is one. | Never auto-merges | 2 |
| 15 | **The access log the patient sees.** Every open of their record, by whom, when, on which device, in the patient app. | Every write attributed and audited | 5 |
| 16 | **Share grants with scope and expiry.** The patient chooses which sections a facility may see and for how long; scope is enforced when the payload is built. | Leaves only in the patient's hand | 5 |
| 17 | **The emergency card.** Blood group, allergies, current pregnancy on the phone's lock screen — opt-in, revocable, nothing else. | Opt-in, minimal | 5 |
| 18 | **The offline facility map.** A bundled list of facilities with distances, no network. | Offline indefinitely | 5 |
| 19 | **The referral letter.** A PDF with the record excerpt the nurse chose, for the facility being referred to. | Scope chosen by a person | 5 |
| 20 | **The pack, photographed.** Drug verification by photographing the pack: the NAFDAC number read, the three-state outcome, never *genuine*. | `copy-check` | 5 |
| 21 | **The merge assistant.** Two records that may be one patient, side by side, fact by fact; a person decides, and the decision is itself a fact. | Never auto-merges | 2 |
| 22 | **Correction with visible history.** A wrong reading is superseded, not edited; the record shows the latest and the history is one tap away. | Facts are immutable | 1 |
| 23 | **The attribution chip.** Every fact shows who, when and on which device, in a chip the nurse sees while writing it. | Every write attributed | 0 |
| 24 | **Auto-lock behind glass.** Three minutes, then the record blurs behind `glassHigh` and asks for the PIN; the blur is the lock, not a decoration. | Encryption and access | 0 |
| 25 | **Plain surfaces and less motion.** Two toggles in Settings, read at act time, and the app is complete with both on. | Complete without glass | 0 |
| 26 | **Large-type nurse mode.** One toggle that sets the interface for arm's length and one hand. | The floor | 0 |
| 27 | **Four patient-face languages.** Naijá, Yorùbá, Hausa and Igbo on every patient-facing string, gated for completeness; the clinic face stays English. | Honest about what is known — drafts say so | 4 |
| 28 | **Sync honesty.** *Last met another device: 3 days ago.* Never *synced*. | Honest about what is known | 1 |
| 29 | **Encrypted backup to a file.** Every record to one encrypted file on a USB stick or SD card, and every record verified on restore before it is kept. | Offline indefinitely | 1 |
| 30 | **The signed audit export.** The access and write audit as a signed CSV a supervisor can open anywhere. | Every write audited | 6 |

## Consequences

Nothing in the thirty computes a diagnosis, a risk, a triage category or a
dose. Three ideas were refused for that reason and are in the backlog with
their reasons: a danger-sign *score*, an *anaemia flag* from haemoglobin, and a
*growth faltering* alert. Each is a clinical judgement, and the clinician's
judgement is the point.
