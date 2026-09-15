// Register a patient: names, sex, date of birth (known or estimated), the
// mother, a phone, an address. Before the fact is written, the registry is
// asked whether this might be someone already here — and shows them side by
// side. The nurse decides; the app never merges (ADR-0006 #14, #21).
import 'package:flutter/material.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/ids.dart';
import '../store/records.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen(
      {super.key,
      required this.records,
      required this.ids,
      required this.author});
  final Records records;
  final Ids ids;
  final String author;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _given = TextEditingController();
  final _family = TextEditingController();
  final _other = TextEditingController();
  final _mother = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  int _sex = 2;
  DateTime? _dob;
  bool _estimated = false;
  List<Candidate> _candidates = [];
  bool _checked = false;

  Registration? get _registration {
    if (_given.text.trim().isEmpty ||
        _family.text.trim().isEmpty ||
        _dob == null) {
      return null;
    }
    return Registration(
      givenName: _given.text.trim(),
      familyName: _family.text.trim(),
      otherNames: _other.text.trim(),
      sex: _sex,
      bornDays: _dob!.toUtc().difference(DateTime.utc(1970)).inDays,
      dobEstimated: _estimated,
      motherName: _mother.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final reg = _registration;
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Gap.l),
                  children: [
                    Text(Strings.registerPatient,
                        style: Type.display.copyWith(color: p.textPrimary)),
                    const SizedBox(height: Gap.m),
                    Glass(
                      depth: Depth.low,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(_given, Strings.givenName,
                              key: 'given', autofocus: true),
                          _field(_other, Strings.otherNames, key: 'other'),
                          _field(_family, Strings.familyName, key: 'family'),
                          const SizedBox(height: Gap.s),
                          Text(Strings.sex,
                              style: Type.secondary
                                  .copyWith(color: p.textSecondary)),
                          const SizedBox(height: Gap.xs),
                          Row(
                            children: [
                              for (final (i, label) in [
                                (0, Strings.female),
                                (1, Strings.male),
                                (2, Strings.notRecorded)
                              ].indexed) ...[
                                if (i > 0) const SizedBox(width: Gap.s),
                                Expanded(
                                    child: _Choice(
                                        label: label.$2,
                                        selected: _sex == label.$1,
                                        onTap: () =>
                                            setState(() => _sex = label.$1))),
                              ],
                            ],
                          ),
                          const SizedBox(height: Gap.m),
                          Text(Strings.dateOfBirth,
                              style: Type.secondary
                                  .copyWith(color: p.textSecondary)),
                          const SizedBox(height: Gap.xs),
                          SecondaryButton(
                            label: _dob == null
                                ? Strings.chooseDate
                                : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
                            onPressed: _pickDate,
                          ),
                          Material(
                            color: Colors.transparent,
                            child: SwitchListTile(
                              key: const Key('estimated'),
                              contentPadding: EdgeInsets.zero,
                              value: _estimated,
                              onChanged: (v) => setState(() => _estimated = v),
                              activeTrackColor: p.accent,
                              title: Text(Strings.dobEstimated,
                                  style:
                                      Type.body.copyWith(color: p.textPrimary)),
                            ),
                          ),
                          _field(_mother, Strings.motherName, key: 'mother'),
                          _field(_phone, Strings.phone,
                              key: 'phone', keyboard: TextInputType.phone),
                          _field(_address, Strings.address, key: 'address'),
                        ],
                      ),
                    ),
                    if (_checked && _candidates.isNotEmpty) ...[
                      const SizedBox(height: Gap.m),
                      _Candidates(candidates: _candidates),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Gap.l),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: _checked && _candidates.isNotEmpty
                          ? Strings.registerAnyway
                          : Strings.register,
                      onPressed: reg == null ? null : () => _register(reg),
                    ),
                    const SizedBox(height: Gap.s),
                    SecondaryButton(
                        label: Strings.cancel,
                        onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {required String key, bool autofocus = false, TextInputType? keyboard}) {
    final p = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: TextField(
        key: Key(key),
        controller: c,
        autofocus: autofocus,
        keyboardType: keyboard,
        // A name is not a word the phone knows: no autocorrect, no suggestions,
        // and each name capitalised the way it is written.
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: keyboard == TextInputType.phone
            ? TextCapitalization.none
            : TextCapitalization.words,
        style: Type.body.copyWith(color: p.textPrimary),
        onChanged: (_) => setState(() => _checked = false),
        decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radius2.input))),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: _dob ?? now,
        firstDate: DateTime(1900),
        lastDate: now);
    if (d != null) setState(() => _dob = d);
  }

  Future<void> _register(Registration reg) async {
    final patient = widget.ids.patient();
    if (!_checked) {
      final listed = Registry.list(widget.records.all.values);
      final candidates = Registry.duplicates(listed, Listed(patient, reg));
      setState(() {
        _candidates = candidates;
        _checked = true;
      });
      if (candidates.isNotEmpty) return;
    }
    await widget.records.record([
      Fact(
          id: widget.ids.fact(),
          patient: patient,
          kind: FactKind.registration,
          stamp: widget.ids.stamp(),
          author: widget.author,
          payload: reg.encode(),
          supersedes: null),
    ]);
    if (mounted) Navigator.of(context).pop(patient);
  }
}

class _Choice extends StatelessWidget {
  const _Choice(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: Target.standard,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? p.brand : null,
            color: selected ? null : p.solidMid,
            borderRadius: BorderRadius.circular(Radius2.chip),
            border:
                Border.all(color: selected ? Colors.transparent : p.hairline),
          ),
          child: Text(label,
              style: Type.small
                  .copyWith(color: selected ? p.textOnAccent : p.textPrimary),
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Side by side: who is already here that this might be, and why. Nothing
/// is merged; the nurse reads and chooses.
class _Candidates extends StatelessWidget {
  const _Candidates({required this.candidates});
  final List<Candidate> candidates;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Glass(
      depth: Depth.mid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: p.attention),
              const SizedBox(width: Gap.s),
              Expanded(
                  child: Text(Strings.maybeAlreadyHere,
                      style: Type.title.copyWith(color: p.textPrimary))),
            ],
          ),
          const SizedBox(height: Gap.s),
          for (final c in candidates) ...[
            Text(c.a.registration.fullName,
                style: Type.body.copyWith(color: p.textPrimary),
                key: const Key('candidate')),
            Text(
                '${Strings.mother}: ${c.a.registration.motherName.isEmpty ? Strings.notRecorded : c.a.registration.motherName} · ${c.reasons.join(' · ')}',
                style: Type.secondary.copyWith(color: p.textSecondary)),
            const SizedBox(height: Gap.s),
          ],
          Text(Strings.youDecide,
              style: Type.secondary.copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}
