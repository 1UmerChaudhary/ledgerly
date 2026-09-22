import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../bootstrap/providers.dart';
import 'printing_service.dart';
import 'thermal_printer_service.dart';

final printingServiceProvider = Provider<PrintingService>(
  (ref) => RealPrintingService(ref.watch(globalPrefsProvider)),
);

final printerDiscoveryProvider = Provider<PrinterDiscovery>(
  (ref) => RealPrinterDiscovery(),
);

final thermalPrinterServiceProvider = Provider<ThermalPrinterService>(
  (ref) => RealThermalPrinterService(),
);

/// Builds the slip, sends it to the printer, and logs the print — the one
/// path every "print this bill" action goes through, whether triggered from
/// the bill form's Saved state or later from the ledger. On Android a saved
/// Bluetooth printer is tried first; anything short of a clean connect *and*
/// write — no printer saved, a refused connect, a failed write, or a thrown
/// PlatformException (adapter off, bond lost mid-write, permission revoked) —
/// falls through to the OS print path below instead of failing silently, the
/// same "ask" degradation the app already uses everywhere nothing is
/// configured.
Future<void> printSlip(WidgetRef ref, OpenFirm firm, String billId) async {
  // Built once, ahead of the branch: both paths render the same SlipModel,
  // and calling slipFor twice would stamp two different printedAt times for
  // one print.
  final slip = await firm.bills.slipFor(billId, printedAt: firm.ctx.stamp());
  final mac = ref.read(globalPrefsProvider).thermalPrinterMac;
  // Bluetooth thermal printing is Android-only by design — desktop renders
  // the same slip to PDF for its configured OS printer. Without this gate a
  // desktop user who once saved a Bluetooth printer would silently stop
  // printing to that OS printer.
  if (mac != null && defaultTargetPlatform == TargetPlatform.android) {
    final service = ref.read(thermalPrinterServiceProvider);
    try {
      try {
        if (await service.connect(mac) &&
            await service.writeBytes(buildSlipEscPos(slip))) {
          await firm.bills.logPrint(
            kind: 'slip',
            transactionId: billId,
            printedAt: slip.printedAt,
            printedBalanceAfter: slip.newBalance,
          );
          return;
        }
      } finally {
        // Every exit — the success return, a clean refusal, or a throw —
        // releases the socket. Skipping it on the throw path left the
        // Bluetooth connection open with nothing holding a reference. A
        // disconnect failure here is caught and ignored rather than
        // propagated: letting it replace the success path's pending return
        // would fall through to the PDF path below and print the same slip
        // a second time, even though the Bluetooth print already succeeded.
        try {
          await service.disconnect();
        } on Object {
          // Not actionable — the print already happened (or the connect/
          // write branch above already handles its own failure) — and
          // there is nothing left holding a reference to disconnect again.
        }
      }
    } on Object {
      // Deliberately swallowed: the PDF path below is the fallback the spec
      // asks for. Propagating here would leave a button's onPressed with an
      // unhandled async error — no print, no fallback, no message. Catches
      // Object (not just Exception) because the plugin's channel can also
      // surface a bare Error on a malformed response.
    }
  }
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
