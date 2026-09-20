import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';
import 'package:test/test.dart';

void main() {
  test('slip renders firm name, customer, and total as plain text between init and cut', () {
    final slip = SlipModel(
      firmName: 'Test Mill',
      firmContact: '0300-1234567',
      firmAddress: null,
      displayNo: 'A3F9-1',
      entryDate: '2026-09-20',
      customerName: 'Ali Traders',
      lines: [
        const SlipLineView(
          itemName: 'Cotton oil',
          quantityDescription: '2 bags x 37.324kg',
          rateDescription: 'Rs 5,000/maund',
          amount: Money(1000000),
        ),
      ],
      total: const Money(1000000),
      previousBalance: const Money(0),
      newBalance: const Money(1000000),
      edited: false,
      printedAt: 1700000000000,
      deviceCode: 'AB12',
    );

    final bytes = buildSlipEscPos(slip);
    final text = String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7f));

    expect(bytes.first, 0x1B); // ESC
    expect(bytes[1], 0x40); // @ -- init command
    expect(text, contains('Test Mill'));
    expect(text, contains('Ali Traders'));
    expect(text, contains('Cotton oil'));
    expect(bytes.sublist(bytes.length - 4), [0x1D, 0x56, 0x00, 0x00]); // GS V 0 0 -- full cut
  });

  test('a walk-in sale (no customer) prints "Cash Sale" instead of a name', () {
    final slip = SlipModel(
      firmName: 'Test Mill',
      firmContact: '0300-1234567',
      firmAddress: null,
      displayNo: 'A3F9-2',
      entryDate: '2026-09-20',
      customerName: null,
      lines: const [],
      total: const Money(50000),
      previousBalance: null,
      newBalance: null,
      edited: false,
      printedAt: 1700000000000,
      deviceCode: 'AB12',
    );

    final bytes = buildSlipEscPos(slip);
    final text = String.fromCharCodes(bytes.where((b) => b >= 0x20 && b < 0x7f));

    expect(text, contains('Cash Sale'));
  });
}
