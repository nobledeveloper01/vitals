// Stock on the screen: a receipt becomes a fact and the tile shows the
// balance; a count by tapping tiles resets the balance and shows the
// difference; low and expiring marked; the fridge asks for its reading and
// marks one outside the range.
import 'dart:io';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitals/screens/stock.dart';
import 'package:vitals/speech/strings.dart';
import 'package:vitals/store/ids.dart';
import 'package:vitals/store/records.dart';
import 'package:vitals_domain/vitals_domain.dart';

void main() {
  late Directory dir;
  late Records records;
  final ids = Ids(device: 'tab-test');
  final facility = List<int>.filled(16, 0xfa);
  final today = Gs1.daysOf(2026, 9, 15);
  final morning = today * 1440 + 8 * 60;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vitals-stock-');
    records = await Records.at(
        File('${dir.path}/facts.log'), List<int>.generate(32, (i) => i + 7));
  });
  tearDown(() async => dir.delete(recursive: true));

  Future<void> io(WidgetTester t, Future<void> Function() body) async {
    await t.runAsync(() async {
      await body();
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
  }

  Widget app({int nowMinutes = 0}) => MaterialApp(
      home: StockScreen(
          records: records,
          facility: facility,
          ids: ids,
          author: 'staff',
          today: today,
          nowMinutes: nowMinutes == 0 ? morning : nowMinutes,
          products: const ['BCG', 'OPV', 'Penta'],
          reorderLevel: const {'OPV': 20}));

  Future<void> receive(WidgetTester t, String product, int units,
      {int expiryDays = 0}) async {
    await t.runAsync(() => records.record([
          Fact(
              id: ids.fact(),
              patient: facility,
              kind: FactKind.stockMovement,
              stamp: ids.stamp(),
              author: 'staff',
              payload: StockMove(
                      product: product,
                      movement: Movement.receipt,
                      units: units,
                      days: today - 1,
                      expiryDays: expiryDays)
                  .encode(),
              supersedes: null)
        ]));
  }

  testWidgets('a count by tapping resets the balance and shows the difference',
      (t) async {
    final semantics = t.ensureSemantics();
    await receive(t, 'BCG', 50);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('BCG, 50'), findsOneWidget);
    await t.tap(find.text(Strings.countTheShelf));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('countHint')), findsOneWidget);
    for (var i = 0; i < 47; i++) {
      await t.tap(find.byKey(const Key('tile-BCG')));
    }
    await t.pump();
    expect(find.bySemanticsLabel('BCG, ${Strings.counted} 47'), findsOneWidget);
    await io(t, () => t.tap(find.text(Strings.recordCount)));
    expect(find.bySemanticsLabel('BCG, 47, ${Strings.lastCountDiffered} -3'),
        findsOneWidget,
        reason: 'the ledger said 50, the shelf said 47; shown, not absorbed');
    final moves = StockMove.of(records.all.values.single.current);
    expect(moves.last.movement, Movement.count);
    expect(moves.last.units, 47);
    expect(records.all.values.single.all.last.author, 'staff');
    semantics.dispose();
  });

  testWidgets(
      'a receipt from the sheet, low stock and an expiring batch marked',
      (t) async {
    final semantics = t.ensureSemantics();
    await receive(t, 'OPV', 10, expiryDays: today + 30);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(
        find.bySemanticsLabel(
            'OPV, 10, ${Strings.lowStock}, ${Strings.expiringSoon}'),
        findsOneWidget);
    await t.tap(find.text(Strings.receiveStock));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('product')));
    await t.pumpAndSettle();
    await t.tap(find.text('Penta').last);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('units')), '40');
    await t.enterText(
        find.byKey(const Key('scan')), '(01)05012345678900(17)281231(10)PT-4');
    await t.pump();
    expect(find.text('PT-4'), findsOneWidget);
    await io(t, () => t.tap(find.text(Strings.receiveStock).last));
    expect(find.bySemanticsLabel('Penta, 40'), findsOneWidget);
    final m = StockMove.of(records.all.values.single.current).last;
    expect((m.product, m.batch, m.expiryDays),
        ('Penta', 'PT-4', Gs1.daysOf(2028, 12, 31)));
    semantics.dispose();
  });

  testWidgets(
      'the fridge asks in the morning, marks outside the range, and stops asking',
      (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text(Strings.morningReadingDue), findsOneWidget);
    expect(find.text(Strings.noFridgeReading), findsOneWidget);
    await t.enterText(find.byKey(const Key('fridgeField')), '9.5');
    await io(t, () => t.tap(find.text(Strings.record)));
    expect(find.byKey(const Key('fridgeDue')), findsNothing);
    expect(find.text('${Strings.lastReading} 9.5 °C · ${Strings.outsideRange}'),
        findsOneWidget);
    final r = FridgeReading.of(records.all.values.single.current).single;
    expect((r.tenths, r.outside), (95, true));
    expect(StockMove.of(records.all.values.single.current), isEmpty,
        reason: 'a fridge reading is not a movement');
    await t.pumpWidget(app(nowMinutes: today * 1440 + 15 * 60));
    await t.pumpAndSettle();
    expect(find.text(Strings.eveningReadingDue), findsOneWidget);
  });
}
