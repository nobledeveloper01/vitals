// The stock ledger: movements as facts, the balance a sum, a count a fact
// that resets the sum and shows its difference, low stock and expiring
// batches as arithmetic.
import 'package:test/test.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  test('a movement round-trips with batch, expiry and reason', () {
    final m = StockMove(
        product: 'Penta',
        movement: Movement.adjustment,
        units: -3,
        days: 20_000,
        batch: 'P-9',
        expiryDays: 20_400,
        reason: 'broken vials');
    final back = StockMove.decode(m.encode());
    expect((
      back.product,
      back.movement,
      back.units,
      back.days,
      back.batch,
      back.expiryDays,
      back.reason
    ), (
      'Penta',
      Movement.adjustment,
      -3,
      20_000,
      'P-9',
      20_400,
      'broken vials'
    ));
  });

  test('the balance sums; a count resets it and keeps the difference', () {
    final moves = [
      StockMove(
          product: 'BCG',
          movement: Movement.receipt,
          units: 100,
          days: 1,
          expiryDays: 200),
      StockMove(product: 'BCG', movement: Movement.issue, units: 30, days: 2),
      StockMove(product: 'BCG', movement: Movement.expired, units: 5, days: 3),
      StockMove(product: 'BCG', movement: Movement.count, units: 60, days: 4),
      StockMove(product: 'BCG', movement: Movement.issue, units: 10, days: 5),
      StockMove(
          product: 'OPV',
          movement: Movement.receipt,
          units: 20,
          days: 1,
          expiryDays: 60),
    ];
    final b = Ledger.balances(moves);
    expect(b['BCG']!.units, 50);
    expect(b['BCG']!.countDifference, -5,
        reason: '65 on the ledger, 60 on the shelf; shown, not absorbed');
    expect(b['BCG']!.lastCounted, 4);
    expect(b['OPV']!.units, 20);
    expect(b['OPV']!.lastCounted, isNull);
    expect(Ledger.low(b, {'BCG': 50, 'OPV': 10}), ['BCG']);
    expect(
        Ledger.expiringWithin(moves, todayDays: 10, days: 90)
            .map((m) => m.product),
        ['OPV']);
  });
}
