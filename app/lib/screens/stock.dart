// Stock and the fridge (ADR-0006 #11, #12). Tiles, one per product, with
// the balance the ledger sums to; a count mode where each tap is one unit
// on the shelf, for a nurse with one hand; a receipt with the vial's batch
// and expiry from its barcode; low stock and expiring batches marked
// *attention*. The fridge asks twice a day and a reading outside the
// printed range is marked the same way. Every movement is a fact on the
// facility's own record.
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/ids.dart';
import '../store/records.dart';

class StockScreen extends StatefulWidget {
  const StockScreen(
      {super.key,
      required this.records,
      required this.facility,
      required this.ids,
      required this.author,
      required this.today,
      required this.nowMinutes,
      this.products = const [
        'BCG',
        'Hep B birth dose',
        'OPV',
        'Penta',
        'PCV',
        'Rota',
        'IPV',
        'Measles',
        'Yellow fever',
        'Men A',
        'Vitamin A',
        'ORS',
        'Zinc',
        'Paracetamol',
        'Amoxicillin',
        'ACT',
        'RDT kits',
        'Syringes',
      ],
      this.reorderLevel = const {}});
  final Records records;
  final List<int> facility;
  final Ids ids;
  final String author;
  final int today;
  final int nowMinutes;
  final List<String> products;
  final Map<String, int> reorderLevel;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool _counting = false;
  final _count = <String, int>{};
  final _fridge = TextEditingController();

  String get _hex =>
      widget.facility.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.records,
            builder: (context, _) {
              final current =
                  widget.records.all[_hex]?.current ?? const <Fact>[];
              final moves = StockMove.of(current);
              final balances = Ledger.balances(moves);
              final low = Ledger.low(balances, widget.reorderLevel).toSet();
              final expiring =
                  Ledger.expiringWithin(moves, todayDays: widget.today)
                      .map((m) => m.product)
                      .toSet();
              final readings = FridgeReading.of(current);
              final due = FridgeReading.duePrompts(readings,
                  nowMinutes: widget.nowMinutes);
              final products = {...widget.products, ...balances.keys}.toList();
              return Column(children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(Gap.l),
                    children: [
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton2()),
                      Text(Strings.stock,
                          style: Type.display.copyWith(color: p.textPrimary)),
                      const SizedBox(height: Gap.m),
                      _FridgeCard(
                          readings: readings,
                          due: due,
                          controller: _fridge,
                          onRecord: _recordFridge),
                      const SizedBox(height: Gap.m),
                      if (_counting)
                        Text(Strings.countHint,
                            style: Type.secondary.copyWith(color: p.accent),
                            key: const Key('countHint')),
                      const SizedBox(height: Gap.s),
                      Wrap(
                        spacing: Gap.s,
                        runSpacing: Gap.s,
                        children: [
                          for (final name in products)
                            _Tile(
                              name: name,
                              balance: balances[name],
                              low: low.contains(name),
                              expiring: expiring.contains(name),
                              counting: _counting,
                              counted: _count[name],
                              onTap: _counting
                                  ? () => setState(() =>
                                      _count[name] = (_count[name] ?? 0) + 1)
                                  : null,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: Column(children: [
                    if (_counting) ...[
                      PrimaryButton(
                          label: Strings.recordCount,
                          onPressed: _count.isEmpty ? null : _recordCount),
                      const SizedBox(height: Gap.s),
                      SecondaryButton(
                          label: Strings.cancel,
                          onPressed: () => setState(() {
                                _counting = false;
                                _count.clear();
                              })),
                    ] else ...[
                      PrimaryButton(
                          label: Strings.countTheShelf,
                          onPressed: () => setState(() => _counting = true)),
                      const SizedBox(height: Gap.s),
                      SecondaryButton(
                          label: Strings.receiveStock,
                          onPressed: () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => ReceiptSheet(
                                    products: products,
                                    onRecord: _recordReceipt),
                              )),
                    ],
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  Fact _fact(FactKind kind, List<int> payload) => Fact(
      id: widget.ids.fact(),
      patient: widget.facility,
      kind: kind,
      stamp: widget.ids.stamp(),
      author: widget.author,
      payload: payload,
      supersedes: null);

  Future<void> _recordCount() async {
    await widget.records.record([
      for (final e in _count.entries)
        _fact(
            FactKind.stockMovement,
            StockMove(
                    product: e.key,
                    movement: Movement.count,
                    units: e.value,
                    days: widget.today)
                .encode())
    ]);
    if (mounted) {
      setState(() {
        _counting = false;
        _count.clear();
      });
    }
  }

  Future<void> _recordReceipt(StockMove m) async {
    await widget.records.record([_fact(FactKind.stockMovement, m.encode())]);
  }

  Future<void> _recordFridge() async {
    final d = double.tryParse(_fridge.text.trim());
    if (d == null) return;
    await widget.records.record([
      _fact(
          FactKind.vitals,
          FridgeReading(tenths: (d * 10).round(), minutes: widget.nowMinutes)
              .encode())
    ]);
    _fridge.clear();
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.name,
      required this.balance,
      required this.low,
      required this.expiring,
      required this.counting,
      required this.counted,
      required this.onTap});
  final String name;
  final Balance? balance;
  final bool low, expiring, counting;
  final int? counted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final units = balance?.units ?? 0;
    final marks = [
      if (low) Strings.lowStock,
      if (expiring) Strings.expiringSoon,
      if (balance != null && balance!.countDifference != 0)
        '${Strings.lastCountDiffered} ${balance!.countDifference > 0 ? '+' : ''}${balance!.countDifference}',
    ];
    final label = counting
        ? '$name, ${Strings.counted} ${counted ?? 0}'
        : '$name, $units${marks.isEmpty ? '' : ', ${marks.join(', ')}'}';
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: counting,
      label: label,
      child: InkWell(
        key: Key('tile-$name'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radius2.card),
        child: Glass(
          depth: counting && counted != null ? Depth.high : Depth.low,
          padding: const EdgeInsets.all(Gap.sm),
          child: SizedBox(
            width: 140,
            height: Target.nurse + Gap.l,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: Type.small.copyWith(color: p.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(counting ? '${counted ?? 0}' : '$units',
                    style: Type.value.copyWith(
                        color: counting
                            ? p.accent
                            : (low || expiring)
                                ? p.attention
                                : p.textPrimary),
                    key: Key('units-$name')),
                if (!counting && marks.isNotEmpty)
                  Text(marks.first,
                      style: Type.small.copyWith(color: p.attention),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FridgeCard extends StatelessWidget {
  const _FridgeCard(
      {required this.readings,
      required this.due,
      required this.controller,
      required this.onRecord});
  final List<FridgeReading> readings;
  final List<String> due;
  final TextEditingController controller;
  final Future<void> Function() onRecord;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final last = readings.isEmpty ? null : readings.last;
    final lastText = last == null
        ? Strings.noFridgeReading
        : '${Strings.lastReading} ${(last.tenths / 10).toStringAsFixed(1)} °C${last.outside ? ' · ${Strings.outsideRange}' : ''}';
    return Glass(
      depth: due.isEmpty ? Depth.low : Depth.high,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Strings.fridge,
              style: Type.title.copyWith(color: p.textPrimary)),
          const SizedBox(height: Gap.xs),
          Text(lastText,
              style: Type.secondary.copyWith(
                  color: last != null && last.outside
                      ? p.attention
                      : p.textSecondary),
              key: const Key('fridgeLast')),
          if (due.isNotEmpty) ...[
            const SizedBox(height: Gap.s),
            Text(
                due.first == 'morning'
                    ? Strings.morningReadingDue
                    : Strings.eveningReadingDue,
                style: Type.body.copyWith(color: p.textPrimary),
                key: const Key('fridgeDue')),
            const SizedBox(height: Gap.s),
            Row(children: [
              SizedBox(
                width: 120,
                child: TextField(
                  key: const Key('fridgeField'),
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.\-]'))
                  ],
                  style: Type.body.copyWith(color: p.textPrimary),
                  decoration: InputDecoration(
                      suffixText: '°C',
                      helperText: '${Strings.range} 2.0–8.0',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Radius2.input))),
                ),
              ),
              const SizedBox(width: Gap.s),
              Expanded(
                  child: SecondaryButton(
                      label: Strings.record, onPressed: onRecord)),
            ]),
          ],
        ],
      ),
    );
  }
}

/// A receipt: the product, how many, and the batch and expiry from the
/// vial's barcode or by hand.
class ReceiptSheet extends StatefulWidget {
  const ReceiptSheet(
      {super.key, required this.products, required this.onRecord});
  final List<String> products;
  final Future<void> Function(StockMove) onRecord;

  @override
  State<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<ReceiptSheet> {
  late String _product = widget.products.first;
  final _units = TextEditingController();
  final _scan = TextEditingController();
  final _batch = TextEditingController();
  int? _expiry;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Glass(
        depth: Depth.high,
        radius: Radius2.sheet,
        padding: sheetPadding(context),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(Strings.receiveStock,
                  style: Type.headline.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.m),
              DropdownButtonFormField<String>(
                key: const Key('product'),
                initialValue: _product,
                items: [
                  for (final n in widget.products)
                    DropdownMenuItem(value: n, child: Text(n))
                ],
                onChanged: (v) => setState(() => _product = v ?? _product),
                decoration: InputDecoration(
                    labelText: Strings.product,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.sm),
              TextField(
                key: const Key('units'),
                controller: _units,
                keyboardType: TextInputType.number,
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.units,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.sm),
              TextField(
                key: const Key('scan'),
                controller: _scan,
                onChanged: (raw) {
                  final g = Gs1.parse(raw);
                  setState(() {
                    if (g == null) return;
                    if (g.batch.isNotEmpty) _batch.text = g.batch;
                    _expiry = g.expiryDays;
                  });
                },
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.vialCode,
                    helperText: Strings.vialCodeHint,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.sm),
              TextField(
                key: const Key('batch'),
                controller: _batch,
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.batch,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.l),
              PrimaryButton(label: Strings.receiveStock, onPressed: _record),
              const SizedBox(height: Gap.s),
              SecondaryButton(
                  label: Strings.cancel,
                  onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _record() async {
    final n = int.tryParse(_units.text.trim());
    if (n == null || n <= 0) return;
    await widget.onRecord(StockMove(
        product: _product,
        movement: Movement.receipt,
        units: n,
        days: DateTime.now().toUtc().difference(DateTime.utc(1970)).inDays,
        batch: _batch.text.trim(),
        expiryDays: _expiry ?? 0));
    if (mounted) Navigator.of(context).pop();
  }
}
