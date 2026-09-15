import 'names.dart';
import 'record.dart';
import 'registration.dart';

/// One patient as the registry lists them: id, the registration shown, and
/// the phonetic keys the search and the duplicate check use.
final class Listed {
  Listed(this.patient, this.registration)
      : nameKeys = Names.keys(
            '${registration.givenName} ${registration.otherNames} ${registration.familyName}'),
        motherKeys = Names.keys(registration.motherName);
  final List<int> patient;
  final Registration registration;
  final List<String> nameKeys;
  final List<String> motherKeys;
}

/// A search hit: the patient and why they matched, with a rank a list can
/// sort by. The rank is for order, never for a decision.
final class Hit {
  const Hit(this.listed, this.rank);
  final Listed listed;
  final int rank;
}

/// Why two patients might be one. Presented side by side; a person decides.
final class Candidate {
  const Candidate(this.a, this.b, this.reasons);
  final Listed a, b;
  final List<String> reasons;
}

abstract final class Registry {
  static List<Listed> list(Iterable<Record> records) {
    final out = <Listed>[];
    for (final r in records) {
      final reg = Registration.of(r.current);
      if (reg != null) out.add(Listed(r.patient, reg));
    }
    return out;
  }

  /// Search by name, phonetically, and by phone. Every token of the query
  /// must match some key of the patient or mother — a nurse typing "ade ok"
  /// wants both, not either.
  static List<Hit> search(List<Listed> listed, String query) {
    final q = query.trim();
    if (q.isEmpty) return [];
    final digits = q.replaceAll(RegExp(r'\D'), '');
    final qKeys = Names.keys(q);
    final hits = <Hit>[];
    for (final l in listed) {
      var rank = 0;
      if (digits.length >= 4 &&
          l.registration.phone.replaceAll(RegExp(r'\D'), '').contains(digits)) {
        rank += 50;
      }
      if (qKeys.isNotEmpty) {
        var all = true;
        for (final k in qKeys) {
          if (l.nameKeys.contains(k)) {
            rank += 20;
          } else if (l.nameKeys.any((n) => n.startsWith(k)) ||
              l.motherKeys.contains(k)) {
            rank += 8;
          } else {
            all = false;
          }
        }
        if (!all) rank = digits.length >= 4 ? rank : 0;
      }
      if (rank > 0) hits.add(Hit(l, rank));
    }
    hits.sort((a, b) {
      final c = b.rank.compareTo(a.rank);
      return c != 0
          ? c
          : a.listed.registration.fullName
              .compareTo(b.listed.registration.fullName);
    });
    return hits;
  }

  /// Might this be someone already registered? Same name keys and a date of
  /// birth within a year, or same name and mother, or same name and phone.
  /// Twins share a mother, a birthday and a phone and differ in given name;
  /// that difference is what keeps them two — which is why a shared family
  /// phone is never a reason on its own.
  static List<Candidate> duplicates(List<Listed> listed, Listed candidate) {
    final out = <Candidate>[];
    for (final l in listed) {
      if (_same(l.patient, candidate.patient)) continue;
      final reasons = <String>[];
      final sameGiven = l.nameKeys.isNotEmpty &&
          candidate.nameKeys.isNotEmpty &&
          l.nameKeys.first == candidate.nameKeys.first;
      final sameFamily = l.nameKeys.last == candidate.nameKeys.last;
      final daysApart =
          (l.registration.bornDays - candidate.registration.bornDays).abs();
      final sameMother = l.motherKeys.isNotEmpty &&
          l.motherKeys.join(' ') == candidate.motherKeys.join(' ');
      final samePhone = l.registration.phone.isNotEmpty &&
          l.registration.phone == candidate.registration.phone;
      if (sameGiven && sameFamily && daysApart <= 366) {
        reasons.add('same name, born within a year');
      }
      if (sameGiven && sameFamily && sameMother) {
        reasons.add('same name and mother');
      }
      if (samePhone && sameFamily && sameGiven) {
        reasons.add('same name and phone');
      }
      if (reasons.isNotEmpty) out.add(Candidate(l, candidate, reasons));
    }
    return out;
  }

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
