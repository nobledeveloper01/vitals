# Vitals — Product Statement

**Portable primary health records and drug authenticity verification for Nigeria.**

---

## The Problem

Two failures, both fatal, both caused by missing information at the point of care.

### 1. There is no continuity of care

Nigerian primary healthcare runs on paper. A patient's record lives in a card kept at the
facility — or, very often, kept by the patient in a folder that gets lost, soaked, or left at
home.

The consequences compound:

- A pregnant woman attends antenatal care at one PHC, travels for delivery, and arrives at a
  facility that knows nothing about her blood pressure trend, her haemoglobin, or the fact
  that her last two readings were rising. Pre-eclampsia is detectable from a trend and
  invisible from a single reading.
- A child's immunisation card is lost, so the schedule restarts, is abandoned, or is guessed.
- A patient with a chronic condition sees four different clinicians in a year and each one
  starts from nothing.
- Facility-level stock-outs are invisible until someone arrives and the drug is not there.

There is no shortage of clinical skill. There is a shortage of the previous page.

### 2. Counterfeit and substandard medicine

Falsified and substandard medicines circulate at a rate that makes them a genuine cause of
mortality, concentrated in exactly the categories where failure kills fastest: antimalarials,
antibiotics, and maternal-health drugs. A patient has no way to distinguish a real pack from a
convincing fake, and neither, in many cases, does the person selling it.

Verification schemes exist. Adoption is patchy, the codes are easy to miss, and there is no
feedback loop — a person who discovers a fake has nowhere useful to report it, so the
information dies with them.

---

## Why Existing Solutions Do Not Work

**Hospital information systems** are built for tertiary hospitals with IT departments, stable
power, and internet. They are priced and architected for institutions that look nothing like a
rural PHC with one nurse, a solar panel, and no network for days at a time.

**National health-record initiatives** are real and important, but they are slow, top-down, and
they do not help the nurse who needs the previous reading this afternoon.

**Patient-held paper cards** are the current system, and their failure mode is that paper gets
lost. Digitising the card without solving offline sync just moves the failure.

**Drug verification services** exist but are single-purpose. A verification tool nobody opens
between purchases has no distribution. It needs to live inside something a person already uses.

---

## The Product

Vitals is one clinical record with two faces.

**The clinic face** — a tablet application for a PHC. Patient registration, vitals, antenatal
visits, immunisation schedules, consultations, and drug stock. **Fully offline**: a nurse
works for a week with no network and nothing is lost, nothing is blocked, and nothing waits.

**The patient face** — a phone application holding a portable copy of their own record, which
they carry between facilities. Immunisation schedules with reminders. Antenatal visit
reminders. Drug verification by scanning the pack. Their own history, in their own hand,
readable by the next clinician.

The two faces exchange records by whatever channel is available: server sync when there is a
network, and **direct device-to-device transfer when there is not**.

---

## The Insight

**The hard problem is not the record. It is merging two records that were both edited while
neither could see the other.**

Two nurses on two tablets in the same clinic, offline for a week, both updating the same
patient. Or a patient's phone and a facility's tablet meeting after both have changed. A
conventional last-writer-wins system silently destroys clinical data in this situation, and in
this domain silent data loss is not a bug — it is a patient harm.

Vitals treats clinical observations as **immutable facts that merge by union, never by
overwrite**. A blood pressure reading taken on Tuesday and a blood pressure reading taken on
Wednesday are both true. They do not conflict. They both survive.

That single modelling decision is what makes a genuinely offline clinical record safe, and it
is the technical core of the product.

---

## Target User

**Primary — the PHC nurse or CHEW.** Runs a facility, often alone or with one colleague. Sees
30–80 patients a day. Uses a donated or programme-supplied Android tablet. Power is solar or
intermittent. Network is a phone hotspot on a good day.
**Needs:** the previous page, fast; a schedule that tells them who is overdue; stock visibility.
**Friction to avoid:** anything that takes longer than the paper card, anything that blocks on
a network, anything requiring a login per patient.

**Secondary — the patient, especially the pregnant woman and the mother of an under-five.**
Entry-level Android. Motivated by their child's immunisation schedule and by not repeating
tests.
**Needs:** their record with them; reminders; drug verification.
**Friction to avoid:** medical jargon, English-only, large downloads.

**Tertiary — the facility supervisor / LGA health officer.** Needs coverage figures, defaulter
lists, and stock-out visibility across facilities without driving to each one.

---

## Why Now

- **Tablets have reached PHCs** through immunisation and maternal-health programmes. The
  hardware is largely already deployed and largely underused.
- **Offline-first sync is a solved architectural problem** now that CRDT and
  immutable-fact patterns are well understood. It was genuinely hard a decade ago.
- **Data standards have matured.** Modelling to FHIR shapes from day one means a facility's
  data can join a national system later without a migration project.
- **Barcode and DataMatrix scanning is free and on-device**, so drug verification costs
  nothing per scan.

---

## The Wedge

**The immunisation schedule.**

It is the highest-frequency, highest-anxiety, most schedule-driven interaction in primary care.
A mother wants to know when the next dose is due and does not want to lose the card. A nurse
wants the defaulter list. Both get value on day one, at a single facility, with no other
facility participating.

And it builds the patient record as a side effect — which is what makes continuity of care
possible later.

---

## Explicitly Not

- **Not a tertiary hospital HIS.** No theatre management, no radiology, no billing.
- **Not telemedicine.** No remote consultation.
- **Not a diagnosis engine.** Vitals shows a clinician the record. It does not tell them what
  it means, and it does not compute a clinical decision. Decision support is a regulated
  medical device and a different product.
- **Not a pharmacy or drug marketplace.** Verification only.
- **Not an insurance or claims platform.** That is fintech-adjacent and out of scope.
