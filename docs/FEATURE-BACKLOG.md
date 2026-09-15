# Feature backlog

What is not in scope, and why. Each row was considered and put here rather
than forgotten. The thirty that were accepted are in
[ADR-0006](adr/0006-thirty-more-things-each-checked-against-the-rules.md).

| Idea | Why not now |
|---|---|
| A danger-sign **score** | A score is a triage category. Vitals presents the checklist and the nurse answers it; the sum is the nurse's. Rule 1. |
| An **anaemia flag** from haemoglobin | A flag from a threshold is a diagnosis by another name. The value is drawn on its reference range; the word is the clinician's. Rule 1. |
| A **growth faltering** alert | The curve is drawn on the WHO reference (ADR-0006 #2); an alert from its slope is interpretation. Rule 1. |
| Dose calculators | A stated dose makes Vitals a medical device. Never. |
| Server-side validation of facts | The server is a replica with no authority (ADR-0004). A fact a tablet accepted is never rejected elsewhere. |
| Cloud sync of patient records by default | A record leaves only in the patient's hand or by a facility's explicit enrolment. Rule 6. |
| A chatbot for patients | Every answer it could give is either clinical or a lookup the app already does without a network. |
| Telemedicine | A different product with a different regulator. |
| Payment for drug verification reports | Not a fintech line to cross, and the report's value is the outbreak signal, not the fee. |
| Blood bank / lab integration | Phase 7 at the earliest, behind the FHIR export. |
