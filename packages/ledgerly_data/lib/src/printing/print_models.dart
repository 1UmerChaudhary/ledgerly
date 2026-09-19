import 'package:ledgerly_core/ledgerly_core.dart';

/// One line as it appears on a printed slip.
class SlipLineView {
  const SlipLineView({
    required this.itemName,
    required this.quantityDescription,
    required this.rateDescription,
    required this.amount,
  });
  final String itemName;
  final String quantityDescription;
  final String rateDescription;
  final Money amount;
}

/// Everything the 80 mm slip template needs, already assembled from the
/// database — the template itself does no lookups.
class SlipModel {
  const SlipModel({
    required this.firmName,
    required this.firmContact,
    required this.firmAddress,
    required this.displayNo,
    required this.entryDate,
    required this.customerName,
    required this.lines,
    required this.total,
    required this.previousBalance,
    required this.newBalance,
    required this.edited,
    required this.printedAt,
    required this.deviceCode,
  });

  final String firmName;
  final String firmContact;
  final String? firmAddress;
  final String displayNo;
  final String entryDate;

  /// Null for a walk-in cash sale — the slip prints "Cash Sale" instead.
  final String? customerName;
  final List<SlipLineView> lines;
  final Money total;

  /// Null for a walk-in (no customer): there is no balance to report, not a
  /// balance that happens to be zero.
  final Money? previousBalance;
  final Money? newBalance;
  final bool edited;

  /// HLC ms at the moment of printing — the slip states this as "as of" so a
  /// later backdated entry can never make the paper look wrong in hindsight.
  final int printedAt;
  final String deviceCode;
}

class LedgerPrintRow {
  const LedgerPrintRow({
    required this.date,
    required this.displayNo,
    required this.typeLabel,
    required this.description,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
  final String date;
  final String displayNo;
  final String typeLabel;
  final String? description;
  final Money? debit;
  final Money? credit;
  final Money runningBalance;
}

/// Everything the A4 ledger template needs for one customer over a range.
class LedgerPrintModel {
  const LedgerPrintModel({
    required this.firmName,
    required this.firmContact,
    required this.firmAddress,
    required this.customerName,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.rows,
    required this.closingBalance,
    required this.printedAt,
  });

  final String firmName;
  final String firmContact;
  final String? firmAddress;
  final String customerName;

  /// Null on either end means "no lower/upper bound" (a full-history print).
  final String? fromDate;
  final String? toDate;
  final Money openingBalance;
  final List<LedgerPrintRow> rows;
  final Money closingBalance;
  final int printedAt;
}
