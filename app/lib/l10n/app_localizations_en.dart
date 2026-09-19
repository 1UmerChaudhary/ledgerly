// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class L10nEn extends L10n {
  L10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ledgerly';

  @override
  String get setupTitle => 'Set up your firm';

  @override
  String get setupSubtitle =>
      'This appears once. You can change everything later in Settings.';

  @override
  String get firmName => 'Firm name';

  @override
  String get contactNumber => 'Contact number';

  @override
  String get address => 'Address';

  @override
  String get optional => 'optional';

  @override
  String get createFirm => 'Create firm';

  @override
  String get restoreFromBackup => 'Restore from backup';

  @override
  String get searchHint =>
      'Search customer by name or phone… misspellings are fine';

  @override
  String get receivable => 'Receivable · they owe you';

  @override
  String get giveable => 'Giveable · you owe them';

  @override
  String get noCustomersYet =>
      'No customers yet. Press Ctrl+N to record the first sale.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navItems => 'Items';

  @override
  String get navCashSales => 'Cash sales';

  @override
  String get navSettings => 'Settings';

  @override
  String get keyMove => 'move';

  @override
  String get keyOpenLedger => 'open ledger';

  @override
  String get keySale => 'sale';

  @override
  String get keyPurchase => 'purchase';

  @override
  String get keyCashIn => 'cash in';

  @override
  String get keyCashOut => 'cash out';

  @override
  String get keySearch => 'search';

  @override
  String get keyNextField => 'next field';

  @override
  String get keyCreateFirm => 'create firm';

  @override
  String get owes => 'owes';

  @override
  String get isOwed => 'is owed';

  @override
  String get rs => 'Rs';
}
