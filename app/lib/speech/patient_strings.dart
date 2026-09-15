// The patient face in five languages (ADR-0006 #27): English, Naijá,
// Yorùbá, Hausa and Igbo. Every patient-facing string is a key here, each
// language is a complete table of the same keys — `make l10n-check` fails
// on one missing — and the clinic face stays English. A language whose
// table has not been read by a speaker says so where it is chosen.
import '../store/preferences.dart';
import 'translations/hausa.dart';
import 'translations/igbo.dart';
import 'translations/pidgin.dart';
import 'translations/yoruba.dart';

extension LangName on Lang {
  /// The language's name in itself.
  String get own => switch (this) {
        Lang.english => 'English',
        Lang.pidgin => 'Naijá',
        Lang.yoruba => 'Yorùbá',
        Lang.hausa => 'Hausa',
        Lang.igbo => 'Igbo',
      };

  /// Read by a speaker of the language, or still a draft.
  bool get reviewed => this == Lang.english;
}

abstract final class PatientStrings {
  static const Map<String, String> english = {
    'patient': 'My record',
    'patientHint': 'A copy of your own health record, on your phone.',
    'myRecord': 'My record',
    'noRecordYet': 'No record on this phone yet. A facility hands you yours.',
    'receiveRecord': 'Receive my record',
    'cardComplete': 'Every dose on the card is given.',
    'dueNow': 'due now',
    'inDays': 'in',
    'days': 'days',
    'daysOverdue': 'days overdue',
    'reminderNote': 'From the national schedule and the dates on the card.',
    'language': 'Language',
    'draftLanguage': 'a draft, not yet read by a speaker',
    'shareRecord': 'Hand over my record',
    'toWhom': 'To which clinic',
    'whichParts': 'Which parts',
    'nameAlwaysGoes': 'Your name and date of birth always go with it.',
    'forHowLong': 'For how long',
    'showCode': 'Show the code',
    'holdStill': 'Hold the phone still for the clinic\'s camera',
    'until': 'until',
    'done': 'Done',
    'code': 'Code',
    'of': 'of',
    'previous': 'Previous',
    'next': 'Next',
    'kind.immunisation': 'Immunisations',
    'kind.vitals': 'Vital signs',
    'kind.ancVisit': 'Antenatal',
    'kind.note': 'Notes',
    'whoOpened': 'Who opened my record',
    'nobodyYet': 'Nobody yet.',
    'checkAPack': 'Check a pack',
    'listDated': 'List dated',
    'listCovers': 'covers numbers starting',
    'nafdacNumber': 'NAFDAC number on the pack',
    'nafdacHint': 'Like A4-1234. Type what is printed.',
    'check': 'Check',
    'onTheList': 'On the list',
    'onTheListMeans':
        'This number is on the list for this product. A printed number can be copied; the list does not see the pack.',
    'notOnTheList': 'Not on the list',
    'notOnTheListMeans':
        'The list covers numbers like this one and does not have it. Ask the pharmacist; report it at the counter.',
    'cannotSay': 'The list cannot say',
    'cannotSayMeans':
        'No number was read, or the list does not cover numbers starting this way. A newer list may.',
  };

  static const Map<Lang, Map<String, String>> tables = {
    Lang.english: english,
    Lang.pidgin: pidgin,
    Lang.yoruba: yoruba,
    Lang.hausa: hausa,
    Lang.igbo: igbo,
  };

  /// The string in the phone's chosen language; English where a table has
  /// no entry, which the gate keeps from happening.
  static String t(String key, {Lang? lang}) {
    final l = lang ?? Preferences.shared.lang;
    return tables[l]?[key] ?? english[key] ?? key;
  }
}
