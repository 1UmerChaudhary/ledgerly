import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

SlipModel slip({
  List<SlipLineView> lines = const [],
  String? customerName = 'Rashid Traders',
  bool edited = false,
  Money? previousBalance = const Money(62000000),
  Money? newBalance = const Money(69716215),
}) => SlipModel(
  firmName: 'Al-Madina Oil Mills',
  firmContact: '0300-1234567',
  firmAddress: 'Main Road, Sahiwal',
  displayNo: 'A3F9-1044',
  entryDate: '2026-09-18',
  customerName: customerName,
  lines: lines,
  total: const Money(7716215),
  previousBalance: previousBalance,
  newBalance: newBalance,
  edited: edited,
  printedAt: 1758270720000,
  deviceCode: 'A3F9',
);

LedgerPrintModel ledgerPrint(int rowCount) => LedgerPrintModel(
  firmName: 'Al-Madina Oil Mills',
  firmContact: '0300-1234567',
  firmAddress: 'Main Road, Sahiwal',
  customerName: 'Rashid Traders',
  fromDate: '2026-09-01',
  toDate: '2026-09-30',
  openingBalance: Money.rupees(100000),
  rows: [
    for (var i = 0; i < rowCount; i++)
      LedgerPrintRow(
        date: '2026-09-${(i % 28) + 1}',
        displayNo: 'A3F9-${i + 1}',
        typeLabel: 'Sale',
        description: 'Row $i',
        debit: Money.rupees(1000),
        credit: null,
        runningBalance: Money.rupees(100000 + i * 1000),
      ),
  ],
  closingBalance: Money.rupees(100000 + rowCount * 1000),
  printedAt: 1758270720000,
);

bool looksLikePdf(List<int> bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46; // %PDF

void main() {
  // buildSlipPdf/buildLedgerPdf are async (Document.save() is a Future).

  group('buildSlipPdf', () {
    test('produces a valid, non-trivial PDF for a sale with lines', () async {
      final bytes = await buildSlipPdf(
        slip(
          lines: [
            const SlipLineView(
              itemName: 'Oil',
              quantityDescription: '20 bg x 16.000 = 320.000 kg',
              rateDescription: '@ 9,000 / 37.324',
              amount: Money(7716215),
            ),
          ],
        ),
      );
      expect(looksLikePdf(bytes), isTrue);
      expect(bytes.length, greaterThan(500));
    });

    test('a walk-in slip (no customer, no balance) does not throw', () async {
      final bytes = await buildSlipPdf(
        slip(
          customerName: null,
          previousBalance: null,
          newBalance: null,
          lines: [
            const SlipLineView(
              itemName: 'Oil',
              quantityDescription: '10.000 kg',
              rateDescription: '@ 500 / 10',
              amount: Money(50000),
            ),
          ],
        ),
      );
      expect(looksLikePdf(bytes), isTrue);
    });

    test('a cash entry with no lines does not throw', () async {
      final bytes = await buildSlipPdf(slip());
      expect(looksLikePdf(bytes), isTrue);
    });
  });

  group('buildLedgerPdf', () {
    test('produces a valid PDF for a short ledger', () async {
      final bytes = await buildLedgerPdf(ledgerPrint(3));
      expect(looksLikePdf(bytes), isTrue);
    });

    test('a long ledger that spans several pages produces proportionally more bytes', () async {
      final short = await buildLedgerPdf(ledgerPrint(3));
      final long = await buildLedgerPdf(ledgerPrint(80));
      expect(looksLikePdf(long), isTrue);
      expect(long.length, greaterThan(short.length));
    });
  });
}
