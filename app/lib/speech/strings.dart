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
  static const myRecord = 'My record';
  static const noRecordYet =
      'No record on this phone yet. A facility hands you yours.';
  static const receiveRecord = 'Receive my record';
  static const done = 'Done';
  static const cancel = 'Cancel';
  static const back = 'Back';
}
