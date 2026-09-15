import 'fact.dart';
import 'text.dart';

/// The stock ledger (ADR-0006 #12): every movement a fact — a receipt, an
/// issue, a count, an adjustment with a reason — and the balance a sum over
/// them. A count is not an edit of the balance; it is a fact that says what
/// the shelf held, and the difference from the running sum is shown, never
/// silently absorbed. Stock facts are not a patient's: they hang on the
/// facility's own record id.
enum Movement {
  receipt(0),
  issue(1),
  count(2),
  adjustment(3),
  expired(4);

  const Movement(this.code);
  final int code;
}

final class StockMove {
  const StockMove(
      {required this.product,
      required this.movement,
      required this.units,
      required this.days,
      this.batch = '',
      this.expiryDays = 0,
      this.reason = ''});
  final String product;
  final Movement movement;

  /// Units moved; for a count, units on the shelf.
  final int units;
  final int days;
  final String batch;
  final int expiryDays;
  final String reason;

  List<int> encode() {
    final out = <int>[1];
    void str(String s) {
      final u = utf8Of(s);
      out.addAll([u.length >> 8, u.length & 0xff, ...u]);
    }

    str(product);
    out.add(movement.code);
    for (var s = 24; s >= 0; s -= 8) {
      out.add((units >> s) & 0xff);
    }
    for (var s = 24; s >= 0; s -= 8) {
      out.add((days >> s) & 0xff);
    }
    str(batch);
    for (var s = 24; s >= 0; s -= 8) {
      out.add((expiryDays >> s) & 0xff);
    }
    str(reason);
    return out;
  }

  static StockMove decode(List<int> b) {
    var i = 0;
    String str() {
      final n = (b[i++] << 8) | b[i++];
      final s = stringOf(b.sublist(i, i + n));
      i += n;
      return s;
    }

    int i32() {
      var v = 0;
      for (var k = 0; k < 4; k++) {
        v = (v << 8) | b[i++];
      }
      return v.toSigned(32);
    }

    if (b[i++] != 1) throw ArgumentError('stock version');
    final product = str();
    final m = Movement.values[b[i++]];
    final units = i32(), days = i32();
    final batch = str();
    final expiry = i32();
    final reason = str();
    return StockMove(
        product: product,
        movement: m,
        units: units,
        days: days,
        batch: batch,
        expiryDays: expiry,
        reason: reason);
  }

  static List<StockMove> of(Iterable<Fact> current) {
    final out = [
      for (final f in current)
        if (f.kind == FactKind.stockMovement) decode(f.payload)
    ];
    out.sort((a, b) => a.days.compareTo(b.days));
    return out;
  }
}

final class Balance {
  const Balance(
      {required this.product,
      required this.units,
      required this.lastCounted,
      required this.countDifference});
  final String product;
  final int units;

  /// Day of the last count, or null.
  final int? lastCounted;

  /// What the last count said minus what the ledger summed to at that
  /// moment; shown, never absorbed.
  final int countDifference;
}

abstract final class Ledger {
  /// The balance per product: receipts in, issues and expiries out,
  /// adjustments signed, a count resetting the running sum from that day.
  static Map<String, Balance> balances(List<StockMove> moves) {
    final sum = <String, int>{};
    final counted = <String, int>{};
    final diff = <String, int>{};
    for (final m in moves) {
      final have = sum[m.product] ?? 0;
      switch (m.movement) {
        case Movement.receipt:
          sum[m.product] = have + m.units;
        case Movement.issue:
        case Movement.expired:
          sum[m.product] = have - m.units;
        case Movement.adjustment:
          sum[m.product] = have + m.units;
        case Movement.count:
          diff[m.product] = m.units - have;
          sum[m.product] = m.units;
          counted[m.product] = m.days;
      }
    }
    return {
      for (final p in sum.keys)
        p: Balance(
            product: p,
            units: sum[p]!,
            lastCounted: counted[p],
            countDifference: diff[p] ?? 0),
    };
  }

  /// Products at or below a reorder level, and batches expiring within a
  /// window: arithmetic over the ledger, marked *attention* on the screen.
  static List<String> low(
          Map<String, Balance> b, Map<String, int> reorderLevel) =>
      [
        for (final e in b.entries)
          if (e.value.units <= (reorderLevel[e.key] ?? 0)) e.key
      ];

  static List<StockMove> expiringWithin(List<StockMove> moves,
          {required int todayDays, int days = 90}) =>
      [
        for (final m in moves)
          if (m.movement == Movement.receipt &&
              m.expiryDays > 0 &&
              m.expiryDays - todayDays <= days)
            m
      ];
}
