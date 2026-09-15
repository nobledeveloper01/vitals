// The emergency card (ADR-0006 #17): blood group, allergies, a current
// pregnancy — typed by the patient, shown on the lock face while they say
// so, and nothing else. Opting out is a fact, not a deletion.
import 'package:flutter/material.dart' hide Card;
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/patient_strings.dart';
import '../store/ids.dart';
import '../store/records.dart';

class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key, required this.card});
  final Emergency card;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lines = [
      if (card.bloodGroup.isNotEmpty)
        '${PatientStrings.t('bloodGroup')}: ${card.bloodGroup}',
      if (card.allergies.isNotEmpty)
        '${PatientStrings.t('allergies')}: ${card.allergies}',
      if (card.pregnant) PatientStrings.t('pregnantNow'),
    ];
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '${PatientStrings.t('emergencyCard')}. ${lines.join('. ')}',
      child: Glass(
        depth: Depth.low,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.emergency_outlined, color: p.danger, size: 20),
              const SizedBox(width: Gap.s),
              Text(PatientStrings.t('emergencyCard'),
                  style: Type.title.copyWith(color: p.textPrimary)),
            ]),
            const SizedBox(height: Gap.xs),
            for (final (i, l) in lines.indexed)
              Text(l,
                  style: Type.headline.copyWith(color: p.textPrimary),
                  key: Key('emergencyLine-$i')),
          ],
        ),
      ),
    );
  }
}

class EmergencySheet extends StatefulWidget {
  const EmergencySheet(
      {super.key,
      required this.records,
      required this.patient,
      required this.ids});
  final Records records;
  final List<int> patient;
  final Ids ids;

  @override
  State<EmergencySheet> createState() => _EmergencySheetState();
}

class _EmergencySheetState extends State<EmergencySheet> {
  late final Emergency? _current = Emergency.of(
      widget.records.all[_hex(widget.patient)]?.current ?? const []);
  late final _blood = TextEditingController(text: _current?.bloodGroup ?? '');
  late final _allergies =
      TextEditingController(text: _current?.allergies ?? '');
  late bool _pregnant = _current?.pregnant ?? false;
  late bool _shown = _current?.shown ?? false;

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
            Text(PatientStrings.t('emergencyCard'),
                style: Type.headline.copyWith(color: p.textPrimary)),
            const SizedBox(height: Gap.xs),
            Text(PatientStrings.t('emergencyHint'),
                style: Type.secondary.copyWith(color: p.textSecondary)),
            const SizedBox(height: Gap.m),
            TextField(
              key: const Key('bloodGroup'),
              controller: _blood,
              style: Type.body.copyWith(color: p.textPrimary),
              decoration: InputDecoration(
                  labelText: PatientStrings.t('bloodGroup'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radius2.input))),
            ),
            const SizedBox(height: Gap.sm),
            TextField(
              key: const Key('allergies'),
              controller: _allergies,
              style: Type.body.copyWith(color: p.textPrimary),
              decoration: InputDecoration(
                  labelText: PatientStrings.t('allergies'),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(Radius2.input))),
            ),
            Row(children: [
              Expanded(
                  child: Text(PatientStrings.t('pregnantNow'),
                      style: Type.body.copyWith(color: p.textPrimary))),
              Switch(
                  key: const Key('pregnant'),
                  value: _pregnant,
                  onChanged: (v) => setState(() => _pregnant = v)),
            ]),
            Row(children: [
              Expanded(
                  child: Text(PatientStrings.t('showOnLockFace'),
                      style: Type.body.copyWith(color: p.textPrimary))),
              Switch(
                  key: const Key('shown'),
                  value: _shown,
                  onChanged: (v) => setState(() => _shown = v)),
            ]),
            const SizedBox(height: Gap.l),
            PrimaryButton(label: PatientStrings.t('save'), onPressed: _save),
            const SizedBox(height: Gap.s),
            SecondaryButton(
                label: PatientStrings.t('cancel'),
                onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: widget.patient,
          kind: FactKind.note,
          stamp: widget.ids.stamp(),
          author: 'patient',
          payload: Emergency(
                  shown: _shown,
                  bloodGroup: _blood.text.trim(),
                  allergies: _allergies.text.trim(),
                  pregnant: _pregnant)
              .encode(),
          supersedes: null)
    ]);
    if (mounted) Navigator.of(context).pop();
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
}
