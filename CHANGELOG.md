# Changelog

All notable changes to Vitals. The format follows Keep a Changelog; the project
is pre-release, so everything is under Unreleased until v1.0.

## [Unreleased]

### Added

- **The receiving side of the handover.** A frame is text any camera can
  name (`VITALS/1 …`); *Receive a record* on both faces reads frames from
  the camera, or from a paste field on a device without one, and merges the
  record by union — what arrives is added, nothing is overwritten.

### Fixed

- From a design audit on the phone in both palettes: the QR code sits in a
  rounded frame that matches its shape, with the progress along its edge;
  every sheet clears the home indicator; the dose sheet's helper wraps and
  a single-dose vaccine is not numbered; a given dose shows its day; the
  vitals sheet is two columns with units in the labels; the patient face's
  Settings and lock speak the chosen language, and the clinic face is not
  offered one.
- The routine schedule is a child's: an adult is on no whiteboard, gets no
  reminder and no card. The facility's own record is not a patient in the
  count. The share screen's button enables as the clinic's name is typed.
  One gradient action per screen on the stock screen.

### Added

- **A synthetic demo clinic** behind `--dart-define=VITALS_DEMO=true`, for
  the screenshots and a phone in a hand; never a record.
- **Handing the record over.** A share grant — which kinds, to whom, until
  when — as a fact, enforced where the payload is built; the payload cut
  into checksummed frames and shown as an animated QR with the ring in the
  brand gradient, stepped by hand under less motion. The access log the
  patient sees. A pack checked against a bundled list with three outcomes
  and never a fourth word. The emergency card on the lock face while the
  patient opts in, never on a clinic tablet. The referral letter with the
  sections the nurse chose. The audit export, signed by the tablet's
  Ed25519 key and verified by a Python script with no dependencies.
- **Five languages on the patient face.** English, Naijá, Yorùbá, Hausa and
  Igbo, each a complete table of the same keys held complete by a gate;
  every table but English marked a draft where it is chosen, until a
  speaker has read it. The clinic face stays English.
- **Vitals, antenatal, stock, the fridge.** Readings as integer facts with
  the pulse card, the printed range and the trend behind the number; forms
  drafted on every keystroke and restored after a kill; the pregnancy and
  the visit with its mandatory ten-sign checklist, answers listed and never
  counted; the stock ledger with the count by tapping, the difference shown,
  a unit issued with every dose; the fridge asked twice a day. ADR-0008
  draws the line between printing a range and judging a number, and the
  copy gate and a domain source test hold it.
- **The whiteboard, the card on paper, the reminder.** The clinic home lists
  every child with a dose due, furthest behind first, and counts the ones
  behind; a mother with a phone gets a message draft opened in the phone's
  own messages, never sent by the app. The card prints as an A5 PDF in the
  national layout. The patient face names the next vaccine and its day per
  child the phone holds, and says when a card is complete.
- **The wedge.** The national immunisation schedule as a versioned table,
  doses as facts with batch and expiry, the card with catch-up, an expired
  vial refused before it is written, GS1 parsed as a scanner sends it; the
  patient screen with the card, the dose sheet and the attributed history.
- **The registry.** Registration as a fact; Nigerian-name phonetics; search
  by name, mother or phone; the duplicate assistant that presents and never
  merges; fifty thousand searched under half a second. Phase 2's screens on
  the clinic face, the face and large type remembered across launches.
- **Backup and the mirror.** Every fact into one file under a passphrase
  (PBKDF2, 200k rounds) with every fact checked on restore, from Settings;
  and `Sync`, the replica met over HTTP as another tablet is met over BLE —
  push the delta, pull by cursor, union, remember the meeting — proved
  against a fake replica that keeps the server's contract.
- **The store.** An encrypted append-only log of canonical facts under a
  keychain key, proved encrypted by reading the file, proved to survive a cut
  tail, opened under the splash; `Records` over it feeding the whiteboard and
  the sync-honesty chip. `Exchange` in the domain: deltas and fingerprints.
  ADR-0007.
- **The design, on a screen.** The launch ground in both appearances on both
  platforms, the mark on the icon, four screenshots in the README.
- **The plan.** The roadmap in eight phases with an exit gate each, the release
  ledger with six gates, six ADRs — one codebase two faces, the domain imports
  nothing, facts are immutable and merge by union, the backend is .NET and a
  replica with no authority, glass over a gradient with a solid floor, and the
  thirty things each checked against the rules — the design system, and the
  backlog with three refusals.
