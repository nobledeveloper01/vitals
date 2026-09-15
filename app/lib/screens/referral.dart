// The referral sheet (ADR-0006 #19): to whom, the reason in the nurse's
// words, and the sections to include — chosen by a person, the rest never
// in the bytes.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Card;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vitals_domain/vitals_domain.dart';

import '../design/glass.dart';
import '../design/palette.dart';
import '../design/type.dart';
import '../report/referral_pdf.dart';
import '../speech/strings.dart';

class ReferralSheet extends StatefulWidget {
  const ReferralSheet(
      {super.key,
      required this.reg,
      required this.current,
      required this.author,
      required this.facility,
      required this.today,
      this.share});
  final Registration reg;
  final List<Fact> current;
  final String author;
  final String facility;
  final int today;
  final Future<void> Function(Uint8List pdf, String name)? share;

  @override
  State<ReferralSheet> createState() => _ReferralSheetState();
}

class _ReferralSheetState extends State<ReferralSheet> {
  final _to = TextEditingController();
  final _reason = TextEditingController();
  final _chosen = <Section>{Section.card};

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final ready = _to.text.trim().isNotEmpty && _reason.text.trim().isNotEmpty;
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
              Text(Strings.referralLetter,
                  style: Type.headline.copyWith(color: p.textPrimary)),
              const SizedBox(height: Gap.m),
              TextField(
                key: const Key('to'),
                controller: _to,
                onChanged: (_) => setState(() {}),
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.referTo,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.sm),
              TextField(
                key: const Key('reason'),
                controller: _reason,
                onChanged: (_) => setState(() {}),
                maxLines: 3,
                style: Type.body.copyWith(color: p.textPrimary),
                decoration: InputDecoration(
                    labelText: Strings.reasonInYourWords,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radius2.input))),
              ),
              const SizedBox(height: Gap.m),
              Text(Strings.sectionsToInclude,
                  style: Type.secondary.copyWith(color: p.textSecondary)),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final s in Section.values)
                    FilterChip(
                      key: Key('section-${s.name}'),
                      label: Text(switch (s) {
                        Section.card => Strings.immunisationCard,
                        Section.vitals => Strings.vitals,
                        Section.antenatal => Strings.antenatal,
                        Section.notes => Strings.notes,
                      }),
                      selected: _chosen.contains(s),
                      selectedColor: p.accent,
                      labelStyle: Type.small.copyWith(
                          color: _chosen.contains(s)
                              ? p.textOnAccent
                              : p.textPrimary),
                      onSelected: (v) => setState(
                          () => v ? _chosen.add(s) : _chosen.remove(s)),
                    ),
                ],
              ),
              const SizedBox(height: Gap.l),
              PrimaryButton(
                  label: Strings.writeTheLetter,
                  onPressed: ready ? _write : null),
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

  Future<void> _write() async {
    final sections = ReferralPdf.lines(
        current: widget.current, chosen: _chosen, todayDays: widget.today);
    final pdf = await ReferralPdf.render(
        reg: widget.reg,
        sections: sections,
        to: _to.text.trim(),
        from: widget.facility,
        reason: _reason.text.trim(),
        author: widget.author,
        todayDays: widget.today);
    final name =
        'referral-${widget.reg.fullName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase()}.pdf';
    if (widget.share != null) {
      await widget.share!(pdf, name);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(pdf);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    }
    if (mounted) Navigator.of(context).pop();
  }
}
