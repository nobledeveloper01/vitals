// The two faces. The clinic: the whiteboard — today's due list in the
// largest type — over the registry. The patient: their record and its card.
// Phase 0 has the frames, the empty states, and the attribution chip; the
// phases after fill them.
import 'package:flutter/material.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/preferences.dart';
import '../store/records.dart';
import 'patient.dart';
import 'register.dart';
import 'registry.dart';
import 'settings.dart';
import '../store/ids.dart';

class Shell extends StatelessWidget {
  const Shell({super.key, required this.records});
  final Records records;

  @override
  Widget build(BuildContext context) {
    final clinic = Preferences.shared.face == Face.clinic;
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: records,
            builder: (context, _) => clinic
                ? _ClinicHome(records: records)
                : _PatientHome(records: records),
          ),
        ),
      ),
    );
  }
}

class _ClinicHome extends StatelessWidget {
  const _ClinicHome({required this.records});
  final Records records;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              _Header(title: Strings.whiteboard, records: records),
              const SizedBox(height: Gap.m),
              Glass(
                depth: Depth.low,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      records.patients == 0
                          ? Strings.nothingDue
                          : '${records.patients} ${Strings.patientsRegistered} · ${records.facts} ${Strings.factsHeld}',
                      style: Type.body.copyWith(
                          color: records.patients == 0
                              ? p.textSecondary
                              : p.textPrimary),
                    ),
                    const SizedBox(height: Gap.m),
                    SyncChip(lastMet: records.lastMet),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Column(
            children: [
              PrimaryButton(
                label: Strings.registerPatient,
                onPressed: () async {
                  final patient = await Navigator.of(context).push(
                      MaterialPageRoute<List<int>?>(
                          builder: (_) => RegisterScreen(
                              records: records,
                              ids: Ids.shared,
                              author: 'staff')));
                  // Registered: straight to the card, where the first doses are due.
                  if (patient != null && context.mounted) {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => PatientScreen(
                            records: records,
                            patient: patient,
                            ids: Ids.shared,
                            author: 'staff')));
                  }
                },
              ),
              const SizedBox(height: Gap.s),
              SecondaryButton(
                label: Strings.openRegistry,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => RegistryScreen(records: records))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PatientHome extends StatelessWidget {
  const _PatientHome({required this.records});
  final Records records;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Gap.l),
            children: [
              _Header(title: Strings.myRecord, records: records),
              const SizedBox(height: Gap.m),
              Glass(
                depth: Depth.low,
                child: Text(Strings.noRecordYet,
                    style: Type.body.copyWith(color: p.textSecondary)),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: PrimaryButton(label: Strings.receiveRecord, onPressed: () {}),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.records});
  final String title;
  final Records records;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: Type.display.copyWith(color: p.textPrimary))),
        Semantics(
          button: true,
          label: Strings.settings,
          child: IconButton(
            iconSize: 28,
            tooltip: Strings.settings,
            constraints: const BoxConstraints(
                minWidth: Target.standard, minHeight: Target.standard),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(records: records))),
            icon: Icon(Icons.tune, color: p.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Sync honesty (ADR-0006 #28): when another device was last met. Never
/// "synced".
class SyncChip extends StatelessWidget {
  const SyncChip({super.key, required this.lastMet});
  final DateTime? lastMet;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final when =
        lastMet == null ? Strings.never : Dates.ago(lastMet!, DateTime.now());
    final text = '${Strings.lastMet}: $when';
    return Semantics(
      label: text,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.s),
        decoration: BoxDecoration(
            border: Border.all(color: p.hairline),
            borderRadius: BorderRadius.circular(Radius2.chip)),
        child: Text(text, style: Type.small.copyWith(color: p.textSecondary)),
      ),
    );
  }
}

/// How long ago, in the words a nurse reads at a glance. The phone's own
/// clock, for the chip only; never a clock the record trusts.
abstract final class Dates {
  static String ago(DateTime then, DateTime now) {
    final d = now.difference(then);
    if (d.inMinutes < 1) return Strings.justNow;
    if (d.inHours < 1) return '${d.inMinutes} ${Strings.minutesAgo}';
    if (d.inDays < 1) return '${d.inHours} ${Strings.hoursAgo}';
    return '${d.inDays} ${Strings.daysAgo}';
  }
}

/// The attribution chip (ADR-0006 #23): who, when, on which device, on
/// anything written. Phase 0 draws it; Phase 1 fills it from the fact.
class AttributionChip extends StatelessWidget {
  const AttributionChip(
      {super.key,
      required this.author,
      required this.when,
      required this.device,
      this.kind = ''});
  final String author, when, device, kind;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Text(
        '${kind.isEmpty ? '' : '$kind · '}${Strings.recordedBy} $author · $when · $device',
        style: Type.small.copyWith(color: p.textSecondary));
  }
}
