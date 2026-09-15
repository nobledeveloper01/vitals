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
  static const patientHint =
      'Your own phone: your record, your card, who has opened it.';
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
  static const cardComplete = 'Every dose on the card is given.';
  static const dueNowLower = 'due now';
  static const inDays = 'in';
  static const reminderNote =
      'From the national schedule and the dates on the card.';
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
  static const myRecord = 'My record';
  static const noRecordYet =
      'No record on this phone yet. A facility hands you yours.';
  static const receiveRecord = 'Receive my record';
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
