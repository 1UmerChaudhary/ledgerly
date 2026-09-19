import 'dart:typed_data';

import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'print_models.dart';

/// Builds the A4 customer ledger as PDF bytes. `pw.MultiPage` paginates
/// automatically — a long range simply continues onto more pages, each
/// repeating the header (`TableRow.repeat`).
Future<Uint8List> buildLedgerPdf(LedgerPrintModel m) async {
  final doc = pw.Document();
  final headerStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
  final cellStyle = const pw.TextStyle(fontSize: 9);
  final rangeText = m.fromDate == null && m.toDate == null
      ? 'All'
      // A plain hyphen, not an en-dash: the default PDF font has no glyph for
      // U+2013 and silently draws a box instead — caught by eye, not by any
      // byte-level test, which is why printed output gets a visual check.
      : '${_display(m.fromDate) ?? 'start'} - ${_display(m.toDate) ?? 'now'}';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => context.pageNumber == 1
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  m.firmName,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (m.firmAddress case final a?) pw.Text(a, style: cellStyle),
                pw.Text(m.firmContact, style: cellStyle),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Ledger: ${m.customerName}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text('Range: $rangeText', style: cellStyle),
                pw.Text(
                  'Opening balance: ${formatMoney(m.openingBalance)}',
                  style: cellStyle,
                ),
                pw.SizedBox(height: 8),
              ],
            )
          : pw.SizedBox(height: 4),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Printed ${_formatDateTime(m.printedAt)}', style: cellStyle),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: cellStyle,
          ),
        ],
      ),
      build: (context) => [
        pw.TableHelper.fromTextArray(
          headers: const [
            'Date',
            'No',
            'Type',
            'Description',
            'Debit',
            'Credit',
            'Balance',
          ],
          headerStyle: headerStyle,
          cellStyle: cellStyle,
          cellAlignments: const {
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
            6: pw.Alignment.centerRight,
          },
          data: [
            for (final r in m.rows)
              [
                r.date,
                r.displayNo,
                r.typeLabel,
                r.description ?? '',
                r.debit == null ? '' : formatMoney(r.debit!, symbol: false),
                r.credit == null ? '' : formatMoney(r.credit!, symbol: false),
                formatMoney(r.runningBalance.abs(), symbol: false),
              ],
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Closing balance: ${formatMoney(m.closingBalance)}',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  return doc.save();
}

String? _display(String? iso) {
  if (iso == null) return null;
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}

String _formatDateTime(int hlcMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(hlcMs);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}
