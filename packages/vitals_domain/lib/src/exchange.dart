import 'fact.dart';
import 'record.dart';

/// What one device must hand another so both hold the same record: the
/// facts the other lacks. Because the merge is union, this is set
/// difference, and an exchange is two of these. What has never been seen by
/// anyone else — the outbox — is the same question asked of an empty set.
abstract final class Exchange {
  /// The facts in [from] that [to] does not hold, in stamp order.
  static List<Fact> delta({required Record from, required Record to}) =>
      from.all.where((f) => !to.contains(f)).toList();

  /// A digest of what a device holds, small enough to send first: the count
  /// and a fold of every fact key, so two devices can tell in one message
  /// whether they already agree. Not a signature; a shortcut.
  static (int count, int fold) fingerprint(Record r) {
    var fold = 0;
    for (final f in r.all) {
      fold = (fold * 31 + f.hashCode) & 0x7fffffff;
    }
    return (r.length, fold);
  }
}
