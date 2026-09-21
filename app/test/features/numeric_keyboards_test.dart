import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/bootstrap/router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../support/pump_app.dart';

/// Every money/weight field must raise the decimal pad and every phone field
/// the dialpad. Only LineCard's own fields got this in the touch sweep, so a
/// phone user typing an amount, a bag weight or a phone number still got the
/// alphabetic keyboard everywhere else.
Future<void> seed(AppDatabase db, DeviceContext ctx) async {
  await FirmSetup(db, ctx).createFirm(name: 'Mill', contactNumber: '0300');
  await CustomersRepository(db, ctx).create(name: 'Rashid Traders');
}

const _decimal = TextInputType.numberWithOptions(decimal: true);
const _signedDecimal = TextInputType.numberWithOptions(
  decimal: true,
  signed: true,
);

TextInputType? _keyboardOf(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(Key(key))).keyboardType;

Future<void> _scrollTo(WidgetTester tester, String key) async {
  await tester.dragUntilVisible(
    find.byKey(Key(key)),
    find.byType(ListView).first,
    const Offset(0, -200),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the cash amount field raises the decimal pad', (tester) async {
    final container = await pumpLedgerly(
      tester,
      seed: seed,
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/bills/new?type=cash_in');
    await tester.pumpAndSettle();

    expect(_keyboardOf(tester, 'cash.amount'), _decimal);
  }, variant: phoneOnly);

  testWidgets('the bill override-total field raises the decimal pad', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: seed,
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/bills/new?type=sale');
    await tester.pumpAndSettle();
    await _scrollTo(tester, 'bill.override');

    expect(_keyboardOf(tester, 'bill.override'), _decimal);
  }, variant: phoneOnly);

  testWidgets('the item form weight and rate fields raise the decimal pad', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: seed,
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/items/new');
    await tester.pumpAndSettle();

    expect(_keyboardOf(tester, 'item.bagKg'), _decimal);
    expect(_keyboardOf(tester, 'item.base'), _decimal);
  }, variant: phoneOnly);

  testWidgets('the customer form phone field raises the dialpad', (
    tester,
  ) async {
    final container = await pumpLedgerly(
      tester,
      seed: seed,
      viewSize: const Size(390, 844),
    );
    container.read(routerProvider).go('/customers/new');
    await tester.pumpAndSettle();

    expect(_keyboardOf(tester, 'customer.phone'), TextInputType.phone);
  }, variant: phoneOnly);

  testWidgets(
    'opening-balances rows raise the dialpad for phone and a signed decimal '
    'pad for balance',
    (tester) async {
      final container = await pumpLedgerly(
        tester,
        seed: seed,
        viewSize: const Size(390, 844),
      );
      container.read(routerProvider).go('/customers/opening-balances');
      await tester.pumpAndSettle();

      expect(
        _keyboardOf(tester, 'openingBalances.row.0.phone'),
        TextInputType.phone,
      );
      // Signed as well as decimal: a negative opening balance is how the
      // form expresses "you owe them".
      expect(
        _keyboardOf(tester, 'openingBalances.row.0.balance'),
        _signedDecimal,
      );
    },
    variant: phoneOnly,
  );
}
