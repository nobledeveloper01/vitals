// The referral letter (ADR-0006 #19): the facility referred to, the reason
// in the nurse's words, and the excerpt of the record the nurse chose —
// section by section, the unchosen ones absent from the bytes. The
// sections are the record's own lines; nothing on the letter is a finding
// the software made.
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitals_domain/vitals_domain.dart';

import '../design/palette.dart';

enum Section { card, vitals, antenatal, notes }

abstract final class ReferralPdf {
  /// The lines each chosen section contributes: what the letter will say,
  /// computed once so a test can read it and the page can print it.
  static Map<Section, List<String>> lines(
      {required Iterable<Fact> current,
      required Set<Section> chosen,
      required int todayDays}) {
    final out = <Section, List<String>>{};
    final reg = Registration.of(current);
    if (chosen.contains(Section.card) && reg != null) {
      final card = Card.of(
          bornDays: reg.bornDays,
          given: Given.of(current),
          todayDays: todayDays);
      out[Section.card] = [
        for (final l in card)
          '${_label(l.due)}: ${switch (l.status) {
            Status.given =>
              'given ${_date(l.given!.givenDays)}${l.given!.batch.isEmpty ? '' : ' batch ${l.given!.batch}'}',
            Status.due => 'due',
            Status.overdue => 'overdue',
            Status.notYet => 'not yet',
            Status.seriesNotStarted => 'after the first',
          }}'
      ];
    }
    if (chosen.contains(Section.vitals)) {
      final obs = Observation.of(current);
      out[Section.vitals] = [
        for (final o in obs.reversed.take(20))
          '${_date(o.takenMinutes ~/ 1440)}: ${o.measure.label} ${o.display} ${o.measure.unit}'
      ];
    }
    if (chosen.contains(Section.antenatal)) {
      final preg = Pregnancy.of(current);
      out[Section.antenatal] = [
        if (preg != null)
          'Last period ${_date(preg.lmpDays)}${preg.lmpEstimated ? ' (estimated)' : ''}, expected ${_date(preg.eddDays)} (last period + 280 days), G${preg.gravida} P${preg.para}',
        for (final v in AncVisit.of(current))
          'Visit ${v.visitNumber} ${_date(v.visitDays)}: ${v.present.isEmpty ? 'every sign answered no' : 'answered yes to ${v.present.map((s) => s.question).join(', ')}'}${v.notes.isEmpty ? '' : ' — ${v.notes}'}',
      ];
    }
    if (chosen.contains(Section.notes)) {
      out[Section.notes] = [for (final n in Note.of(current)) n.text];
    }
    return out;
  }

  static Future<Uint8List> render(
      {required Registration reg,
      required Map<Section, List<String>> sections,
      required String to,
      required String from,
      required String reason,
      required String author,
      required int todayDays}) async {
    final light = Palette.light;
    final ink = PdfColor.fromInt(light.textPrimary.toARGB32());
    final inkSoft = PdfColor.fromInt(light.textSecondary.toARGB32());
    final doc =
        pw.Document(title: 'Referral: ${reg.fullName}', author: 'Vitals');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont()
          .copyWith(defaultTextStyle: pw.TextStyle(color: ink, fontSize: 10)),
      build: (ctx) => [
        pw.Text('REFERRAL',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.Text('From $from · ${_date(todayDays)}',
            style: pw.TextStyle(fontSize: 9, color: inkSoft)),
        pw.SizedBox(height: 10),
        pw.Text('To: $to', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text(reg.fullName,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
        pw.Text(
            'Born ${_date(reg.bornDays)}${reg.dobEstimated ? ' (estimated)' : ''}${reg.motherName.isEmpty ? '' : ' · Mother ${reg.motherName}'}${reg.phone.isEmpty ? '' : ' · ${reg.phone}'}',
            style: pw.TextStyle(fontSize: 9, color: inkSoft)),
        pw.SizedBox(height: 10),
        pw.Text('Reason, in the referring nurse\'s words',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(reason),
        for (final e in sections.entries) ...[
          pw.SizedBox(height: 10),
          pw.Text(_title(e.key),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          if (e.value.isEmpty)
            pw.Text('Nothing recorded.', style: pw.TextStyle(color: inkSoft))
          else
            for (final l in e.value) pw.Bullet(text: l),
        ],
        pw.SizedBox(height: 16),
        pw.Text(
            'Referred by $author. The lines above are the facility\'s record as recorded on its tablet; nothing on this letter is a judgement made by software.',
            style: pw.TextStyle(fontSize: 8, color: inkSoft)),
      ],
    ));
    return doc.save();
  }

  static String _title(Section s) => switch (s) {
        Section.card => 'Immunisation card',
        Section.vitals => 'Vital signs, latest first',
        Section.antenatal => 'Antenatal',
        Section.notes => 'Notes',
      };

  static String _label(Due d) =>
      Schedule.v1.where((x) => x.vaccine == d.vaccine).length > 1
          ? '${d.vaccine.label} ${d.dose}'
          : d.vaccine.label;

  static String _date(int days) {
    final d = DateTime.utc(1970).add(Duration(days: days));
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
