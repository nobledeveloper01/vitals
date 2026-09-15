# Changelog

All notable changes to Vitals. The format follows Keep a Changelog; the project
is pre-release, so everything is under Unreleased until v1.0.

## [Unreleased]

### Added

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
