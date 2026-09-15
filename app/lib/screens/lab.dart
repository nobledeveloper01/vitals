// Lab results and events after a dose (Phase 6). A result is what the
// laboratory printed — the test, the result, the unit, the laboratory,
// the days — shown as text and never compared to anything here. An event
// after a dose is the national AEFI form's checklist, every sign answered,
// the form's own serious box kept as the nurse's answer, and whether it
// was reported onward.
import 'package:flutter/material.dart' hide Card;
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/ids.dart';
import '../store/records.dart';

class LabCard extends StatelessWidget {
  const LabCard({super.key, required this.results, required this.onAdd});
  final List<LabResult> results;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Glass(
      depth: Depth.low,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
                child: Text(Strings.labResults,
                    style: Type.title.copyWith(color: p.textPrimary))),
            IconButton(
                tooltip: Strings.addLabResult,
                icon: Icon(Icons.biotech_outlined, color: p.textPrimary),
                onPressed: onAdd),
          ]),
          if (results.isEmpty)
            Text(Strings.noLabResults,
                style: Type.secondary.copyWith(color: p.textSecondary))
          else
            for (final r in results.take(8))
              Semantics(
                container: true,
                excludeSemantics: true,
                label:
                    '${r.test}: ${r.result} ${r.unit}, ${r.lab}, ${_date(r.reportedDays)}',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.xs),
                  child: Row(children: [
                    Expanded(
                        child: Text(r.test,
                            style: Type.body.copyWith(color: p.textPrimary))),
                    Text('${r.result} ${r.unit}'.trim(),
                        style: Type.body.copyWith(color: p.textPrimary)),
                    const SizedBox(width: Gap.s),
                    Text(
                        '${r.lab.isEmpty ? '' : '${r.lab} · '}${_date(r.reportedDays)}',
                        style: Type.small.copyWith(color: p.textSecondary)),
                  ]),
                ),
              ),
        ],
      ),
    );
  }
}

class LabSheet extends StatefulWidget {
  const LabSheet(
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
  State<LabSheet> createState() => _LabSheetState();
}

class _LabSheetState extends State<LabSheet> {
  final _test = TextEditingController();
  final _result = TextEditingController();
  final _unit = TextEditingController();
  final _lab = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    InputDecoration deco(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radius2.input)));
    final ready =
        _test.text.trim().isNotEmpty && _result.text.trim().isNotEmpty;
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
              Text(Strings.addLabResult,
                  style: Type.headline.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.xs),
              Text(Strings.labHint,
                  style: Type.secondary.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.m),
              TextField(
                  key: const Key('labTest'),
                  controller: _test,
                  onChanged: (_) => setState(() {}),
                  style: Type.body.copyWith(color: p.textPrimary),
                  decoration: deco(Strings.labTest)),
              const SizedBox(height: Gap.sm),
              Row(children: [
                Expanded(
                    flex: 2,
                    child: TextField(
                        key: const Key('labResult'),
                        controller: _result,
                        onChanged: (_) => setState(() {}),
                        style: Type.body.copyWith(color: p.textPrimary),
                        decoration: deco(Strings.labResult))),
                const SizedBox(width: Gap.s),
                Expanded(
                    child: TextField(
                        key: const Key('labUnit'),
                        controller: _unit,
                        style: Type.body.copyWith(color: p.textPrimary),
                        decoration: deco(Strings.labUnit))),
              ]),
              const SizedBox(height: Gap.sm),
              TextField(
                  key: const Key('labName'),
                  controller: _lab,
                  style: Type.body.copyWith(color: p.textPrimary),
                  decoration: deco(Strings.labName)),
              const SizedBox(height: Gap.l),
              PrimaryButton(
                  label: Strings.addLabResult,
                  onPressed: ready ? _record : null),
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
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.lab,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: LabResult(
                  test: _test.text.trim(),
                  result: _result.text.trim(),
                  unit: _unit.text.trim(),
                  lab: _lab.text.trim(),
                  sampledDays: widget.today,
                  reportedDays: widget.today)
              .encode(),
          supersedes: null)
    ]);
    if (mounted) Navigator.of(context).pop();
  }
}

/// The AEFI form for a dose that was given.
class AefiSheet extends StatefulWidget {
  const AefiSheet(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids,
      required this.author,
      required this.given,
      required this.today});
  final Records records;
  final List<int> patient;
  final Ids ids;
  final String author;
  final List<Given> given;
  final int today;

  @override
  State<AefiSheet> createState() => _AefiSheetState();
}

class _AefiSheetState extends State<AefiSheet> {
  late Given _dose = widget.given.last;
  final _answers = <AefiSign, bool>{};
  final _notes = TextEditingController();
  bool _serious = false;
  bool _reported = false;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final complete = AefiSign.values.every(_answers.containsKey);
    final left = AefiSign.values.length - _answers.length;
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
              Text(Strings.eventAfterDose,
                  style: Type.headline.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.xs),
              Text(Strings.aefiHint,
                  style: Type.secondary.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.m),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final g in widget.given)
                    ChoiceChip(
                      key: Key('aefi-${g.vaccine.name}-${g.dose}'),
                      label: Text('${g.vaccine.label} ${g.dose}'),
                      selected: identical(g, _dose),
                      selectedColor: p.accent,
                      labelStyle: Type.small.copyWith(
                          color: identical(g, _dose)
                              ? p.textOnAccent
                              : p.textPrimary),
                      onSelected: (_) => setState(() => _dose = g),
                    ),
                ],
              ),
              const SizedBox(height: Gap.m),
              for (final s in AefiSign.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s),
                  child: Row(children: [
                    Expanded(
                        child: Text(s.question,
                            style: Type.body.copyWith(color: p.textPrimary))),
                    _Answer(
                        key: Key('aefi-yes-${s.name}'),
                        label: Strings.yes,
                        selected: _answers[s] == true,
                        colour: p.danger,
                        onTap: () => setState(() => _answers[s] = true)),
                    const SizedBox(width: Gap.xs),
                    _Answer(
                        key: Key('aefi-no-${s.name}'),
                        label: Strings.no,
                        selected: _answers[s] == false,
                        colour: p.accent,
                        onTap: () => setState(() => _answers[s] = false)),
                  ]),
                ),
              TextField(
                key: const Key('aefiNotes'),
                controller: _notes,
                maxLines: 2,
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.notes,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              Row(children: [
                Expanded(
                    child: Text(Strings.formSeriousBox,
                        style: Type.body.copyWith(color: p.textPrimary))),
                Switch(
                    key: const Key('aefiSerious'),
                    value: _serious,
                    onChanged: (v) => setState(() => _serious = v)),
              ]),
              Row(children: [
                Expanded(
                    child: Text(Strings.reportedOnward,
                        style: Type.body.copyWith(color: p.textPrimary))),
                Switch(
                    key: const Key('aefiReported'),
                    value: _reported,
                    onChanged: (v) => setState(() => _reported = v)),
              ]),
              const SizedBox(height: Gap.s),
              if (!complete)
                Text('$left ${Strings.signsUnanswered}',
                    style: Type.secondary.copyWith(color: p.attention),
                    key: const Key('aefiUnanswered')),
              const SizedBox(height: Gap.s),
              PrimaryButton(
                  label: Strings.recordEvent,
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
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.aefi,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: Aefi(
                  vaccine: _dose.vaccine.code,
                  dose: _dose.dose,
                  onsetDays: widget.today,
                  answers: Map.of(_answers),
                  notes: _notes.text.trim(),
                  seriousAnswered: _serious,
                  reported: _reported)
              .encode(),
          supersedes: null)
    ]);
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

String _date(int days) {
  final d = DateTime.utc(1970).add(Duration(days: days));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
