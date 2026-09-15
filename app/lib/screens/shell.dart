// The two faces. The clinic: the whiteboard — today's due list in the
// largest type — over the registry. The patient: their record and its card.
// Phase 0 has the frames, the empty states, and the attribution chip; the
// phases after fill them.
import 'package:flutter/material.dart' hide Card;
import 'package:url_launcher/url_launcher.dart';
import 'package:vitals_domain/vitals_domain.dart';

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
              const SizedBox(height: Gap.m),
              // The whiteboard (ADR-0006 #7): every child with a dose due,
              // furthest behind first, in the largest type, readable from
              // the door. Each row opens the child.
              WhiteboardList(records: records),
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
              if (records.all.isEmpty)
                Glass(
                  depth: Depth.low,
                  child: Text(Strings.noRecordYet,
                      style: Type.body.copyWith(color: p.textSecondary)),
                )
              else
                Reminders(records: records),
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

/// The mother's phone (ADR-0006 #9): one card per child it holds, naming
/// the next vaccine and its day, in the largest type. A date compared to a
/// date, which is the schedule's arithmetic and nobody's judgement.
class Reminders extends StatelessWidget {
  const Reminders({super.key, required this.records, this.today});
  final Records records;
  final int? today;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final todayDays =
        today ?? DateTime.now().toUtc().difference(DateTime.utc(1970)).inDays;
    final children = <Widget>[];
    for (final e in records.all.entries) {
      final reg = Registration.of(e.value.current);
      if (reg == null) continue;
      final card = Card.of(
          bornDays: reg.bornDays,
          given: Given.of(e.value.current),
          todayDays: todayDays);
      final next = Card.next(card);
      final series = next != null &&
          Schedule.v1.where((d) => d.vaccine == next.due.vaccine).length > 1;
      final vaccine = next == null
          ? ''
          : series
              ? '${next.due.vaccine.label} ${next.due.dose}'
              : next.due.vaccine.label;
      final (line, colour) = switch (next?.status) {
        null => (Strings.cardComplete, p.fine),
        Status.overdue => (
            '$vaccine · ${todayDays - next!.dueOn!} ${Strings.daysOverdue}',
            p.attention
          ),
        Status.due => ('$vaccine · ${Strings.dueNowLower}', p.textPrimary),
        _ => (
            '$vaccine · ${Strings.inDays} ${next!.dueOn! - todayDays} ${Strings.days}',
            p.textPrimary
          ),
      };
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: Gap.s),
        child: Semantics(
          container: true,
          excludeSemantics: true,
          label: '${reg.fullName}: $line',
          child: Glass(
            depth: Depth.low,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reg.fullName,
                    style: Type.title.copyWith(color: p.textPrimary)),
                const SizedBox(height: Gap.xs),
                Text(line, style: Type.headline.copyWith(color: colour)),
                const SizedBox(height: Gap.xs),
                Text(Strings.reminderNote,
                    style: Type.small.copyWith(color: p.textSecondary)),
              ],
            ),
          ),
        ),
      ));
    }
    return Column(children: children);
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

/// The due list. Overdue is a word beside a triangle, never a colour alone.
class WhiteboardList extends StatelessWidget {
  const WhiteboardList({super.key, required this.records, this.today});
  final Records records;
  final int? today;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final todayDays =
        today ?? DateTime.now().toUtc().difference(DateTime.utc(1970)).inDays;
    final board = Whiteboard.today(records.all.values, todayDays: todayDays);
    final defaulters = board.where((c) => c.mostOverdueDays > 0).length;
    if (board.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text('${board.length} ${Strings.dueToday}',
                    style: Type.headline.copyWith(color: p.textPrimary),
                    key: const Key('boardCount'))),
            if (defaulters > 0)
              Semantics(
                container: true,
                excludeSemantics: true,
                label: '$defaulters ${Strings.defaulters}',
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      color: p.attention, size: 20),
                  const SizedBox(width: Gap.xs),
                  Text('$defaulters ${Strings.defaulters}',
                      style: Type.small.copyWith(color: p.attention)),
                ]),
              ),
          ],
        ),
        const SizedBox(height: Gap.s),
        for (final c in board)
          Padding(
            padding: const EdgeInsets.only(bottom: Gap.s),
            child: Semantics(
              button: true,
              label:
                  '${c.registration.fullName}: ${c.due.length} ${Strings.dueNow}${c.mostOverdueDays > 0 ? ', ${c.mostOverdueDays} ${Strings.daysOverdue}' : ''}',
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => PatientScreen(
                        records: records,
                        patient: c.patient,
                        ids: Ids.shared,
                        author: 'staff'))),
                child: Glass(
                  depth: Depth.low,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.registration.fullName,
                                style:
                                    Type.title.copyWith(color: p.textPrimary)),
                            const SizedBox(height: Gap.xs),
                            Text(
                              c.due
                                  .map((l) =>
                                      '${l.due.vaccine.label}${Schedule.v1.where((d) => d.vaccine == l.due.vaccine).length > 1 ? ' ${l.due.dose}' : ''}')
                                  .join(' · '),
                              style: Type.secondary
                                  .copyWith(color: p.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (c.mostOverdueDays > 0) ...[
                        Icon(Icons.warning_amber_rounded,
                            color: p.attention, size: 20),
                        const SizedBox(width: Gap.xs),
                        Text('${c.mostOverdueDays} d',
                            style: Type.small.copyWith(color: p.attention)),
                        if (c.registration.phone.isNotEmpty) ...[
                          const SizedBox(width: Gap.s),
                          // A defaulter SMS draft (ADR-0006 #8): the phone's own
                          // messages app, a message started, nothing sent by us.
                          IconButton(
                            tooltip: Strings.draftSms,
                            constraints: const BoxConstraints(
                                minWidth: Target.standard,
                                minHeight: Target.standard),
                            onPressed: () => launchUrl(Uri(
                                scheme: 'sms',
                                path: c.registration.phone,
                                queryParameters: {
                                  'body':
                                      '${Strings.smsBody} ${c.registration.givenName}: ${c.due.map((l) => l.due.vaccine.label).join(', ')}.',
                                })),
                            icon:
                                Icon(Icons.sms_outlined, color: p.textPrimary),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
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
