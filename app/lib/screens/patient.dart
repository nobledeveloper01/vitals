// A patient's record: the card — every scheduled dose, given or due or
// not yet, with catch-up — and the shutter for a dose: vaccine, batch and
// expiry from the vial's barcode or by hand, an expired vial refused
// before anything is written. Every dose is a fact with its attribution.
import 'package:flutter/material.dart' hide Card;
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/ids.dart';
import '../store/records.dart';
import 'shell.dart' show AttributionChip, Dates;

class PatientScreen extends StatelessWidget {
  const PatientScreen(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;

  /// Days since 1970; the phone's own unless a test pins it.
  final int? today;

  int get _today =>
      today ?? DateTime.now().toUtc().difference(DateTime.utc(1970)).inDays;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: records,
            builder: (context, _) {
              final record = records.all[_hex(patient)];
              final reg =
                  record == null ? null : Registration.of(record.current);
              if (record == null || reg == null) {
                return Center(
                    child: Text(Strings.noRecordYet,
                        style: Type.body.copyWith(color: p.textSecondary)));
              }
              final given = Given.of(record.current);
              final card = Card.of(
                  bornDays: reg.bornDays, given: given, todayDays: _today);
              final due = Card.dueNow(card);
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(Gap.l),
                      children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: BackButton2()),
                        Text(reg.fullName,
                            style: Type.display.copyWith(color: p.textPrimary)),
                        const SizedBox(height: Gap.xs),
                        Text(
                          '${_age(reg)} · ${reg.motherName.isEmpty ? Strings.motherNotRecorded : '${Strings.mother}: ${reg.motherName}'}',
                          style:
                              Type.secondary.copyWith(color: p.textSecondary),
                        ),
                        const SizedBox(height: Gap.m),
                        Glass(
                          depth: Depth.low,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Strings.immunisationCard,
                                  style: Type.title
                                      .copyWith(color: p.textPrimary)),
                              const SizedBox(height: Gap.xs),
                              Text(
                                due.isEmpty
                                    ? Strings.nothingDueForThisChild
                                    : '${due.length} ${Strings.dueNow}',
                                style: Type.secondary.copyWith(
                                    color: due.any(
                                            (l) => l.status == Status.overdue)
                                        ? p.attention
                                        : p.textSecondary),
                                key: const Key('dueCount'),
                              ),
                              const SizedBox(height: Gap.s),
                              for (final line in card)
                                _CardRow(line: line, today: _today),
                            ],
                          ),
                        ),
                        const SizedBox(height: Gap.m),
                        Glass(
                          depth: Depth.low,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Strings.history,
                                  style: Type.title
                                      .copyWith(color: p.textPrimary)),
                              const SizedBox(height: Gap.xs),
                              for (final f in record.all.reversed.take(8))
                                Padding(
                                  padding: const EdgeInsets.only(top: Gap.xs),
                                  child: AttributionChip(
                                    author: f.author,
                                    when: Dates.ago(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            f.stamp.wallMillis,
                                            isUtc: true),
                                        DateTime.now().toUtc()),
                                    device: f.stamp.device,
                                    kind: f.kind.name,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Gap.l),
                    child: PrimaryButton(
                      label: Strings.recordDose,
                      onPressed: due.isEmpty
                          ? null
                          : () => showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => DoseSheet(
                                    records: records,
                                    patient: patient,
                                    ids: ids,
                                    author: author,
                                    due: due,
                                    today: _today),
                              ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _age(Registration r) {
    final days = _today - r.bornDays;
    final est = r.dobEstimated ? ' (${Strings.estimated})' : '';
    if (days < 60) return '$days ${Strings.days}$est';
    if (days < 730) return '${days ~/ 30} ${Strings.months}$est';
    return '${days ~/ 365} ${Strings.years}$est';
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.line, required this.today});
  final CardLine line;
  final int today;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final (icon, colour, word) = switch (line.status) {
      Status.given => (Icons.check_circle, p.fine, Strings.given),
      Status.due => (Icons.radio_button_unchecked, p.textPrimary, Strings.due),
      Status.overdue => (
          Icons.warning_amber_rounded,
          p.attention,
          Strings.overdue
        ),
      Status.notYet => (Icons.schedule, p.textSecondary, Strings.notYet),
      Status.seriesNotStarted => (
          Icons.remove_circle_outline,
          p.textSecondary,
          Strings.afterTheFirst
        ),
    };
    // The dose number where the vaccine is a series; BCG is BCG.
    final series =
        Schedule.v1.where((d) => d.vaccine == line.due.vaccine).length > 1;
    final label = series
        ? '${line.due.vaccine.label} ${line.due.dose}'
        : line.due.vaccine.label;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $word',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Row(
          children: [
            Icon(icon, color: colour, size: 20),
            const SizedBox(width: Gap.s),
            Expanded(
                child: Text(label,
                    style: Type.body.copyWith(
                        color: line.status == Status.notYet
                            ? p.textSecondary
                            : p.textPrimary))),
            Text(
              line.status == Status.given
                  ? '${line.given!.givenDays - (line.dueOn! - line.due.dueDays)} d'
                  : word,
              style: Type.small.copyWith(color: colour),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dose sheet: which of the due doses, the vial's batch and expiry —
/// pasted from a scan or typed — and an expired vial refused with a word.
class DoseSheet extends StatefulWidget {
  const DoseSheet(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      required this.due,
      required this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final List<CardLine> due;
  final int today;

  @override
  State<DoseSheet> createState() => _DoseSheetState();
}

class _DoseSheetState extends State<DoseSheet> {
  late CardLine _chosen = widget.due.first;
  final _scan = TextEditingController();
  final _batch = TextEditingController();
  int? _expiry;
  String? _refusal;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Glass(
        depth: Depth.high,
        radius: Radius2.sheet,
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(Strings.recordDose,
                style: Type.headline.copyWith(color: p.textPrimary)),
            const SizedBox(height: Gap.m),
            Wrap(
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: [
                for (final l in widget.due)
                  ChoiceChip(
                    key: Key('dose-${l.due.vaccine.name}-${l.due.dose}'),
                    label: Text('${l.due.vaccine.label} ${l.due.dose}'),
                    selected: identical(l, _chosen),
                    onSelected: (_) => setState(() => _chosen = l),
                    selectedColor: p.accent,
                    labelStyle: Type.small.copyWith(
                        color: identical(l, _chosen)
                            ? p.textOnAccent
                            : p.textPrimary),
                  ),
              ],
            ),
            const SizedBox(height: Gap.m),
            TextField(
              key: const Key('scan'),
              controller: _scan,
              onChanged: _fromScan,
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
              onChanged: (_) => setState(() => _refusal = null),
              style: Type.body.copyWith(color: p.textPrimary),
              decoration: InputDecoration(
                  labelText: Strings.batch,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radius2.input))),
            ),
            if (_expiry != null) ...[
              const SizedBox(height: Gap.s),
              Text('${Strings.expires} ${_date(_expiry!)}',
                  style: Type.secondary.copyWith(
                      color:
                          _expiry! < widget.today ? p.danger : p.textSecondary),
                  key: const Key('expiry')),
            ],
            if (_refusal != null) ...[
              const SizedBox(height: Gap.s),
              Row(children: [
                Icon(Icons.block, color: p.danger, size: 20),
                const SizedBox(width: Gap.s),
                Expanded(
                    child: Text(_refusal!,
                        style: Type.body.copyWith(color: p.danger),
                        key: const Key('refusal')))
              ]),
            ],
            const SizedBox(height: Gap.l),
            PrimaryButton(label: Strings.recordDose, onPressed: _record),
            const SizedBox(height: Gap.s),
            SecondaryButton(
                label: Strings.cancel,
                onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  void _fromScan(String raw) {
    final g = Gs1.parse(raw);
    setState(() {
      _refusal = null;
      if (g == null) return;
      if (g.batch.isNotEmpty) _batch.text = g.batch;
      _expiry = g.expiryDays;
    });
  }

  Future<void> _record() async {
    if (_expiry != null && _expiry! < widget.today) {
      setState(() => _refusal = Strings.expiredVial);
      return;
    }
    final given = Given(
        vaccine: _chosen.due.vaccine,
        dose: _chosen.due.dose,
        givenDays: widget.today,
        batch: _batch.text.trim(),
        expiryDays: _expiry ?? 0);
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.immunisation,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: given.encode(),
          supersedes: null),
    ]);
    if (mounted) Navigator.of(context).pop();
  }

  static String _date(int days) {
    final d = DateTime.utc(1970).add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
