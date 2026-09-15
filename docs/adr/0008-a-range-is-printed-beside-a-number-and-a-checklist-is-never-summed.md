# ADR-0008 — A range is printed beside a number, and a checklist is never summed

**Status:** accepted
**Date:** 2026-09-15

## Context

Phase 4 puts vital signs, antenatal visits and a danger-sign checklist on the
screen. Every one of them is a place where a product drifts, one helpful
feature at a time, into stating what a number means: a pulse turns red, a
visit gets a score, three ticks become a category. Each step is small and each
is a clinical judgement made by software, which rule 1 forbids and ADR-0006
already refused once (the danger-sign score, the anaemia flag, the growth
alert).

The line between *presenting* and *interpreting* has to be drawn precisely
enough that a reviewer can apply it to a widget without a meeting.

## Decision

Three rules, each testable.

1. **A number is shown with the published reference range printed beside it,
   and the mark for *outside the range* is a comparison of that number to
   that range and nothing else.** The range is data (`Reference.table`),
   named by source, chosen by age band, and the screen prints it — *60–100* —
   next to the value so a nurse sees what the mark compares against. The
   mark is the `attention` colour and the word *outside range*; never *high*,
   *low*, *abnormal*, *tachycardia*, or a colour for danger. A trend is a
   line through the readings, drawn behind the number, with no slope named.

2. **A checklist is answered by a person, every answer is kept, and nothing
   sums them.** The antenatal danger signs are ten questions the national
   card asks. The nurse answers each; a visit with one unanswered cannot be
   recorded. The screen shows the signs answered *yes* in the `danger`
   colour, one by one, under the words *the nurse answered yes to*, and the
   next step is the nurse's. The domain has no getter that counts, weights
   or categorises the answers, and a test greps the domain's source for
   `score`, `risk`, `triage`, `diagnos*` and `severity` so a future one is a
   failing test before it is a regulated device.

3. **Arithmetic that a convention defines is allowed and is labelled as
   arithmetic.** An expected day of delivery is the last period plus 280
   days; completed weeks are days over seven; a dose's due day is birth plus
   the schedule's age. These are printed with their derivation visible
   (*from the last period*) so nobody mistakes them for a finding.

## Consequences

- The reference table is versioned data like the schedule; a change is a new
  table, reviewed against its source, never a code edit.
- `copy-check` gains the words rule 1 forbids on a reading: *high*, *low*,
  *abnormal*, *normal*, *tachy\**, *brady\**, *hypo\**, *hyper\**.
- A partner who wants a score gets a conversation about who is responsible
  when it is wrong, not a feature flag.
- The growth curve (#2) is a reference band drawn behind a child's points,
  by the same rule as the trend line: the band is printed, the word is the
  nurse's.
