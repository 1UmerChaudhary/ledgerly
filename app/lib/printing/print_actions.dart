import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../bootstrap/providers.dart';
import 'printing_service.dart';

final printingServiceProvider = Provider<PrintingService>(
  (ref) => RealPrintingService(),
);

/// Builds the slip, sends it to the printer, and logs the print — the one
/// path every "print this bill" action goes through, whether triggered from
/// the bill form's Saved state or later from the ledger.
Future<void> printSlip(WidgetRef ref, OpenFirm firm, String billId) async {
  final slip = await firm.bills.slipFor(billId, printedAt: firm.ctx.stamp());
  final bytes = await buildSlipPdf(slip);
  await ref
      .read(printingServiceProvider)
      .print(bytes, jobName: 'Slip ${slip.displayNo}');
  await firm.bills.logPrint(
    kind: 'slip',
    transactionId: billId,
    printedAt: slip.printedAt,
    printedBalanceAfter: slip.newBalance,
  );
}

/// Same for a customer's ledger over a date range (either end may be null
/// for "unbounded").
Future<void> printLedger(
  WidgetRef ref,
  OpenFirm firm,
  String customerId, {
  String? fromDate,
  String? toDate,
}) async {
  final printedAt = firm.ctx.stamp();
  final model = await firm.bills.ledgerPrintFor(
    customerId,
    fromDate: fromDate,
    toDate: toDate,
    printedAt: printedAt,
  );
  final bytes = await buildLedgerPdf(model);
  await ref
      .read(printingServiceProvider)
      .print(bytes, jobName: 'Ledger ${model.customerName}');
  await firm.bills.logPrint(
    kind: 'ledger',
    customerId: customerId,
    printedAt: printedAt,
    printedBalanceAfter: model.closingBalance,
    rangeFrom: fromDate,
    rangeTo: toDate,
  );
}

Future<void> exportSlipPdf(WidgetRef ref, OpenFirm firm, String billId) async {
  final slip = await firm.bills.slipFor(billId, printedAt: firm.ctx.stamp());
  final bytes = await buildSlipPdf(slip);
  final saved = await ref
      .read(printingServiceProvider)
      .exportPdf(bytes, suggestedName: 'Slip-${slip.displayNo}.pdf');
  if (saved) {
    await firm.bills.logPrint(
      kind: 'export_pdf',
      transactionId: billId,
      printedAt: slip.printedAt,
      printedBalanceAfter: slip.newBalance,
    );
  }
}

Future<void> exportSlipPng(WidgetRef ref, OpenFirm firm, String billId) async {
  final slip = await firm.bills.slipFor(billId, printedAt: firm.ctx.stamp());
  final bytes = await buildSlipPdf(slip);
  final pages = await ref
      .read(printingServiceProvider)
      .exportPng(bytes, suggestedBaseName: 'Slip-${slip.displayNo}');
  if (pages > 0) {
    await firm.bills.logPrint(
      kind: 'export_png',
      transactionId: billId,
      printedAt: slip.printedAt,
      printedBalanceAfter: slip.newBalance,
    );
  }
}

Future<void> exportLedgerPdf(
  WidgetRef ref,
  OpenFirm firm,
  String customerId, {
  String? fromDate,
  String? toDate,
}) async {
  final printedAt = firm.ctx.stamp();
  final model = await firm.bills.ledgerPrintFor(
    customerId,
    fromDate: fromDate,
    toDate: toDate,
    printedAt: printedAt,
  );
  final bytes = await buildLedgerPdf(model);
  final saved = await ref
      .read(printingServiceProvider)
      .exportPdf(bytes, suggestedName: 'Ledger-${model.customerName}.pdf');
  if (saved) {
    await firm.bills.logPrint(
      kind: 'export_pdf',
      customerId: customerId,
      printedAt: printedAt,
      printedBalanceAfter: model.closingBalance,
      rangeFrom: fromDate,
      rangeTo: toDate,
    );
  }
}
