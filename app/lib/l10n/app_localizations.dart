import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L10n
/// returned by `L10n.of(context)`.
///
/// Applications need to include `L10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L10n.localizationsDelegates,
///   supportedLocales: L10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L10n.supportedLocales
/// property.
abstract class L10n {
  L10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L10n of(BuildContext context) {
    return Localizations.of<L10n>(context, L10n)!;
  }

  static const LocalizationsDelegate<L10n> delegate = _L10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Ledgerly'**
  String get appName;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your firm'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This appears once. You can change everything later in Settings.'**
  String get setupSubtitle;

  /// No description provided for @firmName.
  ///
  /// In en, this message translates to:
  /// **'Firm name'**
  String get firmName;

  /// No description provided for @contactNumber.
  ///
  /// In en, this message translates to:
  /// **'Contact number'**
  String get contactNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @createFirm.
  ///
  /// In en, this message translates to:
  /// **'Create firm'**
  String get createFirm;

  /// No description provided for @restoreFromBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search customer by name or phone… misspellings are fine'**
  String get searchHint;

  /// No description provided for @receivable.
  ///
  /// In en, this message translates to:
  /// **'Receivable · they owe you'**
  String get receivable;

  /// No description provided for @giveable.
  ///
  /// In en, this message translates to:
  /// **'Giveable · you owe them'**
  String get giveable;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet. Press Ctrl+N to record the first sale.'**
  String get noCustomersYet;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get navItems;

  /// No description provided for @navCashSales.
  ///
  /// In en, this message translates to:
  /// **'Cash sales'**
  String get navCashSales;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @keyMove.
  ///
  /// In en, this message translates to:
  /// **'move'**
  String get keyMove;

  /// No description provided for @keyOpenLedger.
  ///
  /// In en, this message translates to:
  /// **'open ledger'**
  String get keyOpenLedger;

  /// No description provided for @keySale.
  ///
  /// In en, this message translates to:
  /// **'sale'**
  String get keySale;

  /// No description provided for @keyPurchase.
  ///
  /// In en, this message translates to:
  /// **'purchase'**
  String get keyPurchase;

  /// No description provided for @keyCashIn.
  ///
  /// In en, this message translates to:
  /// **'cash in'**
  String get keyCashIn;

  /// No description provided for @keyCashOut.
  ///
  /// In en, this message translates to:
  /// **'cash out'**
  String get keyCashOut;

  /// No description provided for @keySearch.
  ///
  /// In en, this message translates to:
  /// **'search'**
  String get keySearch;

  /// No description provided for @keyNextField.
  ///
  /// In en, this message translates to:
  /// **'next field'**
  String get keyNextField;

  /// No description provided for @keyCreateFirm.
  ///
  /// In en, this message translates to:
  /// **'create firm'**
  String get keyCreateFirm;

  /// No description provided for @owes.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get owes;

  /// No description provided for @isOwed.
  ///
  /// In en, this message translates to:
  /// **'is owed'**
  String get isOwed;

  /// No description provided for @rs.
  ///
  /// In en, this message translates to:
  /// **'Rs'**
  String get rs;
}

class _L10nDelegate extends LocalizationsDelegate<L10n> {
  const _L10nDelegate();

  @override
  Future<L10n> load(Locale locale) {
    return SynchronousFuture<L10n>(lookupL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_L10nDelegate old) => false;
}

L10n lookupL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return L10nEn();
  }

  throw FlutterError(
    'L10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
