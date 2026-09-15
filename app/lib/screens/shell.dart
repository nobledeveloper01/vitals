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
import 'settings.dart';

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
                    Text(Strings.nothingDue,
                        style: Type.body.copyWith(color: p.textSecondary)),
                    const SizedBox(height: Gap.m),
                    const SyncChip(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Gap.l),
          child:
              PrimaryButton(label: Strings.registerPatient, onPressed: () {}),
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
  const SyncChip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Semantics(
      label: '${Strings.lastMet}: ${Strings.never}',
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.s),
        decoration: BoxDecoration(
            border: Border.all(color: p.hairline),
            borderRadius: BorderRadius.circular(Radius2.chip)),
        child: Text('${Strings.lastMet}: ${Strings.never}',
            style: Type.small.copyWith(color: p.textSecondary)),
      ),
    );
  }
}

/// The attribution chip (ADR-0006 #23): who, when, on which device, on
/// anything written. Phase 0 draws it; Phase 1 fills it from the fact.
class AttributionChip extends StatelessWidget {
  const AttributionChip(
      {super.key,
      required this.author,
      required this.when,
      required this.device});
  final String author, when, device;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Text('${Strings.recordedBy} $author · $when · $device',
        style: Type.small.copyWith(color: p.textSecondary));
  }
}
