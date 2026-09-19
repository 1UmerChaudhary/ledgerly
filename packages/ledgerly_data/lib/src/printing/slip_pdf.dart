import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'print_models.dart';

/// Builds the 80 mm thermal slip as PDF bytes. `PdfPageFormat.roll80` is the
/// `pdf` package's own preset for continuous roll paper — indefinite height,
/// so the page is exactly as tall as the content, never padded or cut short.
/// Uses the library's default font for now (Helvetica-family, base-14, no
/// asset files needed); bundling Noto Sans + Noto Nastaliq Urdu for non-Latin
/// customer names is a follow-up once real font files are added as assets.
Future<Uint8List> buildSlipPdf(SlipModel s) async {
  final doc = pw.Document();
  final mono = pw.TextStyle(fontSize: 8.5, font: pw.Font.courier());
  final monoBold = mono.copyWith(fontWeight: pw.FontWeight.bold, fontSize: 9.5);
  pw.Widget line(String left, {String? right, pw.TextStyle? style}) => pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Text(left, style: style ?? mono),
      if (right != null) pw.Text(right, style: style ?? mono),
    ],
  );
  final divider = pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Container(height: 0.5, color: PdfColors.grey700),
  );

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80.copyWith(
        marginLeft: 4 * PdfPageFormat.mm,
        marginRight: 4 * PdfPageFormat.mm,
        marginTop: 3 * PdfPageFormat.mm,
        marginBottom: 3 * PdfPageFormat.mm,
      ),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(child: pw.Text(s.firmName, style: monoBold)),
          if (s.firmAddress case final a?)
            pw.Center(child: pw.Text(a, style: mono)),
          pw.Center(child: pw.Text(s.firmContact, style: mono)),
          divider,
          line(
            s.lines.isEmpty
                ? 'ENTRY'
                : (s.customerName == null ? 'CASH SALE' : 'SALE'),
            right: 'Bill ${s.displayNo}',
            style: monoBold,
          ),
          pw.Text(_formatDateTime(s.entryDate), style: mono),
          pw.Text(s.customerName ?? 'Cash Sale', style: mono),
          divider,
          for (final l in s.lines) ...[
            pw.Text(l.itemName, style: mono),
            line('  ${l.quantityDescription}', style: mono),
            line(
              '  ${l.rateDescription}',
              right: formatMoney(l.amount, symbol: false),
              style: mono,
            ),
          ],
          divider,
          line(
            'TOTAL',
            right: formatMoney(s.total, symbol: false),
            style: monoBold,
          ),
          if (s.previousBalance != null)
            line(
              'Previous balance',
              right: formatMoney(s.previousBalance!.abs(), symbol: false),
              style: mono,
            ),
          if (s.newBalance case final n?)
            line(
              'BALANCE (${n.isNegative ? 'is owed' : 'owes'})',
              right: formatMoney(n.abs(), symbol: false),
              style: monoBold,
            ),
          if (s.newBalance != null)
            pw.Text('as of ${_formatTime(s.printedAt)}', style: mono),
          if (s.edited) pw.Text('(edited)', style: mono),
          divider,
          line(
            'Printed ${_formatDateTime2(s.printedAt)}',
            right: s.deviceCode,
            style: mono,
          ),
        ],
      ),
    ),
  );
  return doc.save();
}

String _formatDateTime(String isoDate) {
  final p = isoDate.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : isoDate;
}

String _two(int n) => n.toString().padLeft(2, '0');

String _formatTime(int hlcMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(hlcMs);
  return '${_two(t.day)}/${_two(t.month)}/${t.year} ${_two(t.hour)}:${_two(t.minute)}';
}

String _formatDateTime2(int hlcMs) => _formatTime(hlcMs);
