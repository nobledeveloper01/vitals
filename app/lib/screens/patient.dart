// A patient's record: the card — every scheduled dose, given or due or
// not yet, with catch-up — and the shutter for a dose: vaccine, batch and
// expiry from the vial's barcode or by hand, an expired vial refused
// before anything is written. Every dose is a fact with its attribution.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Card;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../report/card_pdf.dart';
import '../speech/patient_strings.dart';
import '../speech/strings.dart';
import '../store/ids.dart';
import '../store/drafts.dart';
import '../store/records.dart';
import 'anc.dart';
import 'shell.dart' show AttributionChip, Dates;
import 'vitals.dart';

class PatientScreen extends StatefulWidget {
  const PatientScreen(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      this.today,
      this.share,
      this.facility = '',
      this.drafts,
      this.nowMinutes,
      this.facilityRecord = const [],
      this.openedAt});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;

  /// Days since 1970; the phone's own unless a test pins it.
  final int? today;

  /// Where the printed card goes: the platform share sheet unless a test
  /// hands one in.
  final Future<void> Function(Uint8List pdf, String name)? share;
  final String facility;

  /// Where forms keep what was typed; the app's own directory unless a test
  /// hands one in.
  final Drafts? drafts;
  final int? nowMinutes;

  /// The facility's record id for the stock decrement; empty on a phone.
  final List<int> facilityRecord;

  /// The facility's name, when a clinic opens the record: the open is
  /// written to the record as a fact the patient will see (ADR-0006 #15).
  /// Null on the patient's own phone, which opens its own record.
  final String? openedAt;

  @override
  State<PatientScreen> createState() => _PatientScreenState();
}

class _PatientScreenState extends State<PatientScreen> {
  Records get records => widget.records;
  List<int> get patient => widget.patient;
  Ids get ids => widget.ids;
  String get author => widget.author;
  int? get today => widget.today;
  Future<void> Function(Uint8List pdf, String name)? get share => widget.share;
  String get facility => widget.facility;
  Drafts? get drafts => widget.drafts;
  int? get nowMinutes => widget.nowMinutes;
  List<int> get facilityRecord => widget.facilityRecord;

  @override
  void initState() {
    super.initState();
    final at = widget.openedAt;
    if (at != null && records.all.containsKey(_hex(patient))) {
      records.record([
        Fact(
            id: ids.fact(),
            patient: patient,
            kind: FactKind.access,
            stamp: ids.stamp(),
            author: author,
            payload: Access(
                    who: author,
                    minutes: _nowMinutes,
                    device: ids.device,
                    facility: at)
                .encode(),
            supersedes: null)
      ]);
    }
  }

  int get _nowMinutes =>
      nowMinutes ?? DateTime.now().toUtc().millisecondsSinceEpoch ~/ 60000;

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
                    child: Text(PatientStrings.t('noRecordYet'),
                        style: Type.body.copyWith(color: p.textSecondary)));
              }
              final given = Given.of(record.current);
              final card = Card.of(
                  bornDays: reg.bornDays, given: given, todayDays: _today);
              final due = Card.dueNow(card);
              final observations = Observation.of(record.current);
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
                        // The pulse card (ADR-0006 #1): the last vitals with
                        // the trend behind the numbers, by ADR-0008's rules.
                        PulseCard(
                            observations: observations,
                            ageDays: _today - reg.bornDays),
                        const SizedBox(height: Gap.m),
                        Glass(
                          depth: Depth.low,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(Strings.immunisationCard,
                                        style: Type.title
                                            .copyWith(color: p.textPrimary))),
                                IconButton(
                                  tooltip: Strings.printCard,
                                  icon: Icon(Icons.print_outlined,
                                      color: p.textPrimary),
                                  onPressed: () => _print(reg, card),
                                ),
                              ]),
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
                    child: Column(children: [
                      PrimaryButton(
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
                                      today: _today,
                                      facility: facilityRecord),
                                ),
                      ),
                      const SizedBox(height: Gap.s),
                      if (reg.sex == 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.s),
                          child: SecondaryButton(
                            label: Strings.antenatal,
                            onPressed: () async {
                              final drafts = this.drafts ?? await Drafts.open();
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                      builder: (_) => AncScreen(
                                          records: records,
                                          patient: patient,
                                          ids: ids,
                                          author: author,
                                          drafts: drafts,
                                          today: _today)));
                            },
                          ),
                        ),
                      SecondaryButton(
                        label: Strings.recordVitals,
                        onPressed: () async {
                          final drafts = this.drafts ?? await Drafts.open();
                          if (!context.mounted) return;
                          await showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => VitalsSheet(
                                records: records,
                                patient: patient,
                                ids: ids,
                                author: author,
                                drafts: drafts,
                                nowMinutes: _nowMinutes),
                          );
                        },
                      ),
                    ]),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _print(Registration reg, List<CardLine> card) async {
    final pdf = await CardPdf.render(
        reg: reg, card: card, todayDays: _today, facility: facility);
    final name =
        'card-${reg.fullName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase()}.pdf';
    if (share != null) return share!(pdf, name);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(pdf);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
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
      required this.today,
      this.facility = const []});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final List<CardLine> due;
  final int today;

  /// The facility's record, where one unit leaves the stock ledger with
  /// every dose; empty for a phone that keeps no stock.
  final List<int> facility;

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
      // The stock decrement: one unit issued, on the facility's own record,
      // in the same write as the dose so neither exists without the other.
      if (widget.facility.isNotEmpty)
        Fact(
            id: widget.ids.fact(),
            patient: widget.facility,
            kind: FactKind.stockMovement,
            stamp: widget.ids.stamp(),
            author: widget.author,
            payload: StockMove(
                    product: _chosen.due.vaccine.label,
                    movement: Movement.issue,
                    units: 1,
                    days: widget.today,
                    batch: _batch.text.trim())
                .encode(),
            supersedes: null),
    ]);
    if (mounted) Navigator.of(context).pop();
  }

  static String _date(int days) {
    final d = DateTime.utc(1970).add(Duration(days: days));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
