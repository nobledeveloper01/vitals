// The registry: every patient, searched as a nurse types — by any spelling,
// by the mother, by four digits of a phone. Under 500 ms across fifty
// thousand is Phase 2's gate; in memory it is well under.
import 'package:flutter/material.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../speech/strings.dart';
import '../store/ids.dart';
import '../store/records.dart';
import 'patient.dart';

class RegistryScreen extends StatefulWidget {
  const RegistryScreen({super.key, required this.records});
  final Records records;

  @override
  State<RegistryScreen> createState() => _RegistryScreenState();
}

class _RegistryScreenState extends State<RegistryScreen> {
  final _query = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Scaffold(
      body: Mesh(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: widget.records,
            builder: (context, _) {
              final listed = Registry.list(widget.records.all.values);
              final q = _query.text.trim();
              final shown = q.isEmpty
                  ? listed.map((l) => Hit(l, 0)).toList()
                  : Registry.search(listed, q);
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, 0),
                    child: Row(
                      children: [
                        const BackButton2(),
                        Expanded(
                            child: Text(Strings.registry,
                                style: Type.display
                                    .copyWith(color: p.textPrimary))),
                        Text('${listed.length}',
                            style:
                                Type.headline.copyWith(color: p.textSecondary),
                            key: const Key('count')),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(Gap.l),
                    child: Glass(
                      depth: Depth.mid,
                      padding: const EdgeInsets.symmetric(horizontal: Gap.m),
                      child: TextField(
                        key: const Key('search'),
                        controller: _query,
                        onChanged: (_) => setState(() {}),
                        style: Type.body.copyWith(color: p.textPrimary),
                        decoration: InputDecoration(
                          hintText: Strings.searchHint,
                          hintStyle: Type.body.copyWith(color: p.textSecondary),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: p.textSecondary),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: shown.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(Gap.l),
                            child: Text(
                                q.isEmpty
                                    ? Strings.noPatientsYet
                                    : Strings.noMatch,
                                style:
                                    Type.body.copyWith(color: p.textSecondary)),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: Gap.l),
                            itemCount: shown.length,
                            itemBuilder: (context, i) {
                              final r = shown[i].listed.registration;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: Gap.s),
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                          builder: (_) => PatientScreen(
                                              records: widget.records,
                                              patient: shown[i].listed.patient,
                                              ids: Ids.shared,
                                              author: 'staff'))),
                                  child: Glass(
                                    depth: Depth.low,
                                    child: Semantics(
                                      button: true,
                                      label: r.fullName,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(r.fullName,
                                              style: Type.title.copyWith(
                                                  color: p.textPrimary)),
                                          const SizedBox(height: Gap.xs),
                                          Text(
                                            '${_age(r)} · ${r.motherName.isEmpty ? Strings.motherNotRecorded : '${Strings.mother}: ${r.motherName}'}${r.phone.isEmpty ? '' : ' · ${r.phone}'}',
                                            style: Type.secondary.copyWith(
                                                color: p.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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

  /// An age in the unit a clinic uses — days, then months, then years — and
  /// marked estimated when the date was. A number, not a judgement.
  static String _age(Registration r) {
    final born = DateTime.utc(1970).add(Duration(days: r.bornDays));
    final days = DateTime.now().toUtc().difference(born).inDays;
    final est = r.dobEstimated ? ' (${Strings.estimated})' : '';
    if (days < 60) return '$days ${Strings.days}$est';
    if (days < 730) return '${days ~/ 30} ${Strings.months}$est';
    return '${days ~/ 365} ${Strings.years}$est';
  }
}
