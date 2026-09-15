// Antenatal care (ADR-0008 rules 2 and 3). The pregnancy: the last period,
// with the expected day printed as *from the last period + 280 days*. The
// visit: ten questions the nurse answers yes or no, each one, before the
// visit can be recorded; the ones answered yes shown in the danger colour,
// one by one, and the next step the nurse's.
import 'package:flutter/material.dart' hide Card;
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/drafts.dart';
import '../store/ids.dart';
import '../store/records.dart';

class AncScreen extends StatelessWidget {
  const AncScreen(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      required this.drafts,
      required this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final Drafts drafts;
  final int today;

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
              final current = record?.current ?? const <Fact>[];
              final pregnancy = Pregnancy.of(current);
              final visits = AncVisit.of(current);
              return Column(children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(Gap.l),
                    children: [
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton2()),
                      Text(Strings.antenatal,
                          style: Type.display.copyWith(color: p.textPrimary)),
                      const SizedBox(height: Gap.m),
                      if (pregnancy == null)
                        Glass(
                            depth: Depth.low,
                            child: Text(Strings.noPregnancyYet,
                                style:
                                    Type.body.copyWith(color: p.textSecondary)))
                      else
                        Glass(
                          depth: Depth.low,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${pregnancy.weeksOn(today)} ${Strings.weeks}',
                                  style:
                                      Type.value.copyWith(color: p.textPrimary),
                                  key: const Key('weeks')),
                              Text(
                                  '${Strings.expectedDay} ${_date(pregnancy.eddDays)} · ${Strings.fromLastPeriod}',
                                  style: Type.secondary
                                      .copyWith(color: p.textSecondary)),
                              Text(
                                  'G${pregnancy.gravida} P${pregnancy.para}${pregnancy.lmpEstimated ? ' · ${Strings.estimated}' : ''}',
                                  style: Type.small
                                      .copyWith(color: p.textSecondary)),
                            ],
                          ),
                        ),
                      const SizedBox(height: Gap.m),
                      for (final v in visits.reversed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.s),
                          child: _VisitCard(visit: v),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Gap.l),
                  child: Column(children: [
                    PrimaryButton(
                      label: pregnancy == null
                          ? Strings.registerPregnancy
                          : Strings.recordVisit,
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => pregnancy == null
                            ? PregnancySheet(
                                records: records,
                                patient: patient,
                                ids: ids,
                                author: author,
                                today: today)
                            : VisitSheet(
                                records: records,
                                patient: patient,
                                ids: ids,
                                author: author,
                                drafts: drafts,
                                visitNumber: visits.length + 1,
                                today: today),
                      ),
                    ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}

String _date(int days) {
  final d = DateTime.utc(1970).add(Duration(days: days));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

int? _days(String text) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text.trim());
  if (m == null) return null;
  final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  return Gs1.daysOf(y, mo, d);
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit});
  final AncVisit visit;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final present = visit.present;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${Strings.visit} ${visit.visitNumber}, ${_date(visit.visitDays)}, ${present.isEmpty ? Strings.noSignAnsweredYes : '${Strings.answeredYesTo} ${present.map((s) => s.question).join(', ')}'}',
      child: Glass(
        depth: Depth.low,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${Strings.visit} ${visit.visitNumber} · ${_date(visit.visitDays)}',
                style: Type.title.copyWith(color: p.textPrimary)),
            const SizedBox(height: Gap.xs),
            if (present.isEmpty)
              Text(Strings.noSignAnsweredYes,
                  style: Type.secondary.copyWith(color: p.textSecondary))
            else ...[
              Text(Strings.answeredYesTo,
                  style: Type.secondary.copyWith(color: p.textSecondary)),
              for (final s in present)
                Row(children: [
                  Icon(Icons.error_outline, color: p.danger, size: 18),
                  const SizedBox(width: Gap.s),
                  Text(s.question, style: Type.body.copyWith(color: p.danger)),
                ]),
            ],
            if (visit.notes.isNotEmpty) ...[
              const SizedBox(height: Gap.xs),
              Text(visit.notes,
                  style: Type.secondary.copyWith(color: p.textPrimary)),
            ],
          ],
        ),
      ),
    );
  }
}

class PregnancySheet extends StatefulWidget {
  const PregnancySheet(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      required this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final int today;

  @override
  State<PregnancySheet> createState() => _PregnancySheetState();
}

class _PregnancySheetState extends State<PregnancySheet> {
  final _lmp = TextEditingController();
  final _gravida = TextEditingController(text: '1');
  final _para = TextEditingController(text: '0');
  bool _estimated = false;
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
            Text(Strings.registerPregnancy,
                style: Type.headline.copyWith(color: p.textPrimary)),
            const SizedBox(height: Gap.m),
            TextField(
              key: const Key('lmp'),
              controller: _lmp,
              onChanged: (_) => setState(() => _refusal = null),
              style: Type.body.copyWith(color: p.textPrimary),
              decoration: InputDecoration(
                  labelText: Strings.lastPeriod,
                  helperText: Strings.dateHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radius2.input))),
            ),
            const SizedBox(height: Gap.sm),
            Row(children: [
              Expanded(
                  child: TextField(
                      key: const Key('gravida'),
                      controller: _gravida,
                      keyboardType: TextInputType.number,
                      style: Type.body.copyWith(color: p.textPrimary),
                      decoration: InputDecoration(
                          labelText: Strings.pregnancies,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(Radius2.input))))),
              const SizedBox(width: Gap.s),
              Expanded(
                  child: TextField(
                      key: const Key('para'),
                      controller: _para,
                      keyboardType: TextInputType.number,
                      style: Type.body.copyWith(color: p.textPrimary),
                      decoration: InputDecoration(
                          labelText: Strings.births,
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(Radius2.input))))),
            ]),
            Row(children: [
              Expanded(
                  child: Text(Strings.dateEstimated,
                      style: Type.body.copyWith(color: p.textPrimary))),
              Switch(
                  value: _estimated,
                  onChanged: (v) => setState(() => _estimated = v)),
            ]),
            if (_refusal != null)
              Text(_refusal!,
                  style: Type.body.copyWith(color: p.danger),
                  key: const Key('refusal')),
            const SizedBox(height: Gap.l),
            PrimaryButton(label: Strings.registerPregnancy, onPressed: _record),
            const SizedBox(height: Gap.s),
            SecondaryButton(
                label: Strings.cancel,
                onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Future<void> _record() async {
    final lmp = _days(_lmp.text);
    final g = int.tryParse(_gravida.text.trim());
    final pa = int.tryParse(_para.text.trim());
    if (lmp == null || lmp > widget.today) {
      setState(() => _refusal = Strings.dateNotUnderstood);
      return;
    }
    if (g == null || pa == null || g < 1 || pa < 0 || pa >= g) {
      setState(() => _refusal = Strings.countsNotUnderstood);
      return;
    }
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.ancVisit,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: Pregnancy(
                  lmpDays: lmp, gravida: g, para: pa, lmpEstimated: _estimated)
              .encode(),
          supersedes: null)
    ]);
    if (mounted) Navigator.of(context).pop();
  }
}

/// The visit sheet: every sign answered, drafted as it goes.
class VisitSheet extends StatefulWidget {
  const VisitSheet(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      required this.drafts,
      required this.visitNumber,
      required this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final Drafts drafts;
  final int visitNumber;
  final int today;

  String get draftKey =>
      'anc-${patient.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';

  @override
  State<VisitSheet> createState() => _VisitSheetState();
}

class _VisitSheetState extends State<VisitSheet> {
  final _answers = <DangerSign, bool>{};
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.drafts.read(widget.draftKey).then((d) {
      if (!mounted) return;
      setState(() {
        for (final s in DangerSign.values) {
          final v = d[s.name];
          if (v == 'yes') _answers[s] = true;
          if (v == 'no') _answers[s] = false;
        }
        _notes.text = d['notes'] ?? '';
      });
    });
  }

  void _draft() => widget.drafts.write(widget.draftKey, {
        for (final e in _answers.entries) e.key.name: e.value ? 'yes' : 'no',
        if (_notes.text.isNotEmpty) 'notes': _notes.text,
      });

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final complete = DangerSign.values.every(_answers.containsKey);
    final left = DangerSign.values.length - _answers.length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Glass(
        depth: Depth.high,
        radius: Radius2.sheet,
        padding: const EdgeInsets.all(Gap.l),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${Strings.visit} ${widget.visitNumber}',
                  style: Type.headline.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.xs),
              Text(Strings.dangerSignsAsk,
                  style: Type.secondary.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.m),
              for (final s in DangerSign.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s),
                  child: Row(children: [
                    Expanded(
                        child: Text(s.question,
                            style: Type.body.copyWith(color: p.textPrimary))),
                    _Answer(
                        key: Key('yes-${s.name}'),
                        label: Strings.yes,
                        selected: _answers[s] == true,
                        colour: p.danger,
                        onTap: () => setState(() {
                              _answers[s] = true;
                              _draft();
                            })),
                    const SizedBox(width: Gap.xs),
                    _Answer(
                        key: Key('no-${s.name}'),
                        label: Strings.no,
                        selected: _answers[s] == false,
                        colour: p.accent,
                        onTap: () => setState(() {
                              _answers[s] = false;
                              _draft();
                            })),
                  ]),
                ),
              TextField(
                key: const Key('notes'),
                controller: _notes,
                onChanged: (_) => _draft(),
                maxLines: 2,
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.notes,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.m),
              if (!complete)
                Text('$left ${Strings.signsUnanswered}',
                    style: Type.secondary.copyWith(color: p.attention),
                    key: const Key('unanswered')),
              const SizedBox(height: Gap.s),
              PrimaryButton(
                  label: Strings.recordVisit,
                  onPressed: complete ? _record : null),
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
    final visit = AncVisit(
        visitNumber: widget.visitNumber,
        visitDays: widget.today,
        answers: Map.of(_answers),
        notes: _notes.text.trim());
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.ancVisit,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: visit.encode(),
          supersedes: null)
    ]);
    await widget.drafts.clear(widget.draftKey);
    if (mounted) Navigator.of(context).pop();
  }
}

class _Answer extends StatelessWidget {
  const _Answer(
      {super.key,
      required this.label,
      required this.selected,
      required this.colour,
      required this.onTap});
  final String label;
  final bool selected;
  final Color colour;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radius2.chip),
        child: Container(
          constraints: const BoxConstraints(
              minWidth: Target.standard, minHeight: Target.standard),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: selected ? colour : Colors.transparent,
              border: Border.all(color: selected ? colour : p.hairline),
              borderRadius: BorderRadius.circular(Radius2.chip)),
          child: Text(label,
              style: Type.body
                  .copyWith(color: selected ? p.textOnAccent : p.textPrimary)),
        ),
      ),
    );
  }
}
