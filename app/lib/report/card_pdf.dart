// The immunisation card on paper (ADR-0006 #4): A5, the national card's own
// layout — the child at the top, one row per scheduled dose with the date
// given, the batch, and the words due, overdue or not yet where nothing
// was given. A rendering of the facts; nothing on it is interpreted.
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:vitals_domain/vitals_domain.dart';

import '../design/palette.dart';

abstract final class CardPdf {
  static Future<Uint8List> render(
      {required Registration reg,
      required List<CardLine> card,
      required int todayDays,
      required String facility}) async {
    final doc = pw.Document(
        title: 'Immunisation card: ${reg.fullName}', author: 'Vitals');
    String date(int days) {
      final d = DateTime.utc(1970).add(Duration(days: days));
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    String label(Due d) =>
        Schedule.v1.where((x) => x.vaccine == d.vaccine).length > 1
            ? '${d.vaccine.label} ${d.dose}'
            : d.vaccine.label;
    // Paper is the light palette's ink; the gate keeps it so.
    final light = Palette.light;
    final ink = PdfColor.fromInt(light.textPrimary.toARGB32());
    final inkSoft = PdfColor.fromInt(light.textSecondary.toARGB32());
    final sex = switch (reg.sex) {
      0 => 'Female',
      1 => 'Male',
      _ => 'Sex not recorded',
    };
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      theme: pw.ThemeData.withFont()
          .copyWith(defaultTextStyle: pw.TextStyle(color: ink)),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('IMMUNISATION CARD',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(facility, style: pw.TextStyle(fontSize: 9, color: inkSoft)),
          pw.SizedBox(height: 10),
          pw.Text(reg.fullName,
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text(
              'Born ${date(reg.bornDays)}${reg.dobEstimated ? ' (estimated)' : ''} · $sex',
              style: const pw.TextStyle(fontSize: 9)),
          if (reg.motherName.isNotEmpty)
            pw.Text(
                'Mother: ${reg.motherName}${reg.phone.isNotEmpty ? ' · ${reg.phone}' : ''}',
                style: const pw.TextStyle(fontSize: 9)),
          if (reg.address.isNotEmpty)
            pw.Text(reg.address, style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: ['Vaccine', 'Due', 'Given', 'Batch'],
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellHeight: 14,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.4),
              2: const pw.FlexColumnWidth(1.4),
              3: const pw.FlexColumnWidth(1.6)
            },
            data: [
              for (final l in card)
                [
                  label(l.due),
                  l.dueOn == null ? '' : date(l.dueOn!),
                  switch (l.status) {
                    Status.given => date(l.given!.givenDays),
                    Status.due => 'due',
                    Status.overdue => 'overdue',
                    Status.notYet => '',
                    Status.seriesNotStarted => '',
                  },
                  l.given?.batch ?? '',
                ],
            ],
          ),
          pw.Spacer(),
          pw.Text(
              'Printed ${date(todayDays)} from Vitals. Schedule version ${Schedule.version}. The dates are those recorded on the facility\'s tablet; nothing on this card is a judgement.',
              style: pw.TextStyle(fontSize: 7, color: inkSoft)),
        ],
      ),
    ));
    return doc.save();
  }
}
