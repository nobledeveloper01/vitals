// Every string the app shows, in one place, so `make copy-check` reads one
// list for the words a clinical record must never say — diagnosis, risk,
// triage, genuine, safe, synced, verified — and the tests read the same.
abstract final class Strings {
  static const appName = 'Vitals';
  static const tagline = 'The previous page, wherever the patient is.';
  static const clinic = 'Clinic';
  static const patient = 'My record';
  static const chooseFace = 'Who is this device for?';
  static const clinicHint =
      'A facility tablet: registry, encounters, stock, and the whiteboard.';
  static const settings = 'Settings';
  static const plainSurfaces = 'Plain surfaces';
  static const plainSurfacesHint =
      'No glass, no blur. The app is complete without them; older tablets are faster.';
  static const lessMotion = 'Less motion';
  static const lessMotionHint =
      'Nothing animates. The splash cuts. Progress is a count.';
  static const largeType = 'Large type for the ward';
  static const largeTypeHint = 'Set for arm\'s length and one hand.';
  static const locked = 'Vitals is locked.';
  static const lockedHint =
      'Enter the staff PIN. Every write is attributed to it.';
  static const unlock = 'Unlock';
  static const pin = 'Staff PIN';
  static const wrongPin = 'Not that PIN. Try again.';
  static const lastMet = 'Last met another device';
  static const never = 'never';
  static const justNow = 'just now';
  static const minutesAgo = 'minutes ago';
  static const hoursAgo = 'hours ago';
  static const daysAgo = 'days ago';
  static const patientsRegistered = 'patients registered';
  static const factsHeld = 'facts held';
  static const recordedBy = 'Recorded by';
  static const on = 'on';
  static const whiteboard = 'Today';
  static const nothingDue =
      'Nothing due today. The registry is empty until a patient is registered.';
  static const registerPatient = 'Register a patient';
  static const register = 'Register';
  static const registerAnyway = 'Register as a new patient anyway';
  static const givenName = 'Given name';
  static const otherNames = 'Other names';
  static const familyName = 'Family name';
  static const sex = 'Sex';
  static const female = 'Female';
  static const male = 'Male';
  static const notRecorded = 'Not recorded';
  static const dateOfBirth = 'Date of birth';
  static const chooseDate = 'Choose the date';
  static const dobEstimated = 'The date is estimated';
  static const motherName = 'Mother\'s name';
  static const mother = 'Mother';
  static const motherNotRecorded = 'mother not recorded';
  static const phone = 'Phone';
  static const address = 'Address';
  static const maybeAlreadyHere = 'This may be someone already registered';
  static const youDecide =
      'Open the one it is, or register a new patient. The app never merges two records by itself.';
  static const registry = 'Patients';
  static const searchHint = 'Name, mother\'s name, or phone';
  static const noPatientsYet = 'No patients registered yet.';
  static const noMatch =
      'Nobody matches. Try fewer letters, or the mother\'s name.';
  static const estimated = 'estimated';
  static const days = 'days';
  static const months = 'months';
  static const years = 'years';
  static const openRegistry = 'Patients';
  static const immunisationCard = 'Immunisation card';
  static const printCard = 'Print the card';
  static const recordVitals = 'Record vitals';
  static const noVitalsYet = 'No vitals recorded yet.';
  static const range = 'range';
  static const outsideRange = 'outside range';
  static const draftRestored = 'Restored what was typed before the app closed.';
  static const vitals = 'Vitals';
  static const antenatal = 'Antenatal';
  static const noPregnancyYet = 'No pregnancy registered.';
  static const weeks = 'weeks';
  static const expectedDay = 'Expected day';
  static const fromLastPeriod = 'from the last period + 280 days';
  static const registerPregnancy = 'Register a pregnancy';
  static const recordVisit = 'Record the visit';
  static const visit = 'Visit';
  static const lastPeriod = 'First day of the last period';
  static const dateHint = 'YYYY-MM-DD';
  static const pregnancies = 'Pregnancies';
  static const births = 'Births';
  static const dateEstimated = 'The date is estimated';
  static const dateNotUnderstood =
      'That date was not understood, or is after today.';
  static const countsNotUnderstood =
      'Pregnancies counts this one; births must be fewer.';
  static const dangerSignsAsk = 'Ask each. Every one needs an answer.';
  static const yes = 'Yes';
  static const no = 'No';
  static const notes = 'Notes';
  static const signsUnanswered = 'still to answer';
  static const noSignAnsweredYes = 'Every sign answered no.';
  static const answeredYesTo = 'The nurse answered yes to:';
  static const stock = 'Stock';
  static const receiveRecord = 'Receive a record';
  static const thisFacility = 'this facility';
  static const referralLetter = 'Referral letter';
  static const labResults = 'Lab results';
  static const noLabResults = 'None recorded.';
  static const addLabResult = 'Add a lab result';
  static const labHint =
      'As the laboratory printed it. The result is shown as text; the laboratory\'s own report carries its range.';
  static const labTest = 'Test';
  static const labResult = 'Result';
  static const labUnit = 'Unit';
  static const labName = 'Laboratory';
  static const eventAfterDose = 'Event after a dose';
  static const aefiHint =
      'The national AEFI form. Ask each sign; every one needs an answer.';
  static const formSeriousBox = 'The form\'s "serious" box';
  static const reportedOnward = 'Reported to the LGA';
  static const recordEvent = 'Record the event';
  static const eventsAfterDoses = 'Events after doses';
  static const scheduleCoversChildren =
      'The routine schedule covers children under five; no card here.';
  static const changeFace = 'Change who this device is for';
  static const replica = 'Replica';
  static const replicaHint =
      'A server this facility is enrolled with. It holds a copy and decides nothing; until a URL is typed here, nothing leaves the tablet.';
  static const replicaUrl = 'Replica URL';
  static const facilityName = 'This facility\'s name';
  static const meetTheReplica = 'Meet the replica now';
  static const replicaNotSet = 'A URL and a name are needed first.';
  static const pushed = 'Sent';
  static const pulled = 'received';
  static const couldNotMeet = 'Could not meet the replica:';
  static const wipedByReplica =
      'A supervisor asked this tablet to wipe. Every record on it is erased; the replica and the other tablets keep theirs.';
  static const auditExport = 'Audit export';
  static const auditExportHint =
      'Every write and every open, as a CSV signed by this tablet. A changed line is a failed signature; the check needs only Python.';
  static const exportTheAudit = 'Export the audit';
  static const tabletKey = 'This tablet\'s key:';
  static const auditShareText = 'Vitals audit export, signed by the tablet.';
  static const referTo = 'To which facility';
  static const reasonInYourWords = 'The reason, in your words';
  static const sectionsToInclude = 'Sections to include';
  static const writeTheLetter = 'Write the letter';
  static const countHint = 'Tap a tile once for each unit on the shelf.';
  static const countTheShelf = 'Count the shelf';
  static const recordCount = 'Record the count';
  static const receiveStock = 'Receive stock';
  static const counted = 'counted';
  static const lowStock = 'low stock';
  static const expiringSoon = 'expiring within 90 d';
  static const lastCountDiffered = 'count off by';
  static const fridge = 'Fridge';
  static const noFridgeReading = 'No reading yet.';
  static const lastReading = 'Last reading';
  static const morningReadingDue = 'The morning reading is due.';
  static const eveningReadingDue = 'The evening reading is due.';
  static const record = 'Record';
  static const product = 'Product';
  static const units = 'Units';
  static const dueToday = 'due today';
  static const defaulters = 'behind';
  static const daysOverdue = 'days overdue';
  static const draftSms = 'Draft a message to the mother';
  static const smsBody = 'Good day. Please bring your child to the clinic for';
  static const nothingDueForThisChild = 'Nothing due today.';
  static const dueNow = 'due now';
  static const given = 'given';
  static const due = 'due';
  static const overdue = 'overdue';
  static const notYet = 'not yet';
  static const afterTheFirst = 'after the first';
  static const history = 'History';
  static const recordDose = 'Record a dose';
  static const vialCode = 'Vial code';
  static const vialCodeHint =
      'Scan the barcode, or paste what it says. The batch and expiry fill themselves.';
  static const batch = 'Batch';
  static const expires = 'Expires';
  static const expiredVial =
      'This vial has expired. It is not recorded. Use another vial.';
  static const done = 'Done';
  static const backup = 'Backup';
  static const backupHint =
      'Every fact in one file under a passphrase, to a USB stick or a drive of yours. On the way back each one is checked before it is kept.';
  static const backUp = 'Back up all records';
  static const restore = 'Restore from a backup';
  static const restored = 'Kept';
  static const refused = 'refused';
  static const passphrase = 'Passphrase';
  static const backupShareText =
      'A Vitals backup. It opens only with its passphrase.';
  static const cancel = 'Cancel';
  static const back = 'Back';
}
