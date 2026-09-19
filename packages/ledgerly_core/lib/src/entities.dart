import 'package:meta/meta.dart';

import 'balance_engine.dart';
import 'money.dart';
import 'rate_calculator.dart';
import 'weight.dart';

enum SaleMode { byBags, byWeight, byCount }

/// Unit of measure for a line. Weight-based today; `unit` exists so tins and
/// drums can be sold by count in the inventory phase without a migration.
enum Uom { kg, unit }

@immutable
class BillLine {
  const BillLine({
    required this.id,
    required this.lineNo,
    required this.itemId,
    required this.saleMode,
    required this.rate,
    this.uom = Uom.kg,
    this.bagCount,
    this.bagWeight,
    this.totalWeight,
    this.quantity,
    this.rateBase,
    this.overriddenTotal,
  });

  final String id;
  final int lineNo;
  final String itemId;
  final Uom uom;
  final SaleMode saleMode;
  final int? bagCount;
  final Weight? bagWeight;
  final Weight? totalWeight;
  final int? quantity;
  final Money rate;
  final Weight? rateBase;
  final Money? overriddenTotal;

  Money get calculatedTotal => switch (uom) {
    Uom.kg => lineTotalByWeight(
      rate: rate,
      totalWeight: totalWeight!,
      rateBase: rateBase!,
    ),
    Uom.unit => lineTotalByCount(rate: rate, quantity: quantity!),
  };

  Money get finalTotal => overriddenTotal ?? calculatedTotal;

  BillLine copyWith({
    Money? rate,
    Money? overriddenTotal,
    Weight? totalWeight,
  }) => BillLine(
    id: id,
    lineNo: lineNo,
    itemId: itemId,
    uom: uom,
    saleMode: saleMode,
    bagCount: bagCount,
    bagWeight: bagWeight,
    totalWeight: totalWeight ?? this.totalWeight,
    quantity: quantity,
    rate: rate ?? this.rate,
    rateBase: rateBase,
    overriddenTotal: overriddenTotal ?? this.overriddenTotal,
  );
}

/// A transaction header with its lines: a sale or purchase carries lines; cash,
/// opening-balance and adjustment entries carry a typed amount and no lines.
@immutable
class Bill {
  const Bill({
    required this.id,
    required this.customerId,
    required this.type,
    required this.entryDate,
    this.lines = const [],
    this.typedAmount,
    this.overriddenTotal,
    this.overriddenTotalBasis,
    this.description,
    this.version = 1,
  });

  final String id;

  /// Null means a walk-in cash sale with no ledger.
  final String? customerId;
  final TransactionType type;

  /// ISO yyyy-MM-dd, the device's local calendar day.
  final String entryDate;
  final List<BillLine> lines;
  final Money? typedAmount;
  final Money? overriddenTotal;

  /// The calculated total at the moment the override was typed. If lines have
  /// changed since, the override is kept but flagged (see [overrideIsStale]).
  final Money? overriddenTotalBasis;
  final String? description;
  final int version;

  Money get calculatedTotal => lines.isEmpty
      ? (typedAmount ?? Money.zero)
      : lines.fold(Money.zero, (sum, l) => sum + l.finalTotal);

  Money get finalAmount => overriddenTotal ?? calculatedTotal;

  bool get overrideIsStale =>
      overriddenTotal != null && overriddenTotalBasis != calculatedTotal;

  Money get signedAmount => signedAmountFor(type, finalAmount);

  Bill copyWith({
    List<BillLine>? lines,
    Money? overriddenTotal,
    Money? overriddenTotalBasis,
    String? description,
    int? version,
  }) => Bill(
    id: id,
    customerId: customerId,
    type: type,
    entryDate: entryDate,
    lines: lines ?? this.lines,
    typedAmount: typedAmount,
    overriddenTotal: overriddenTotal ?? this.overriddenTotal,
    overriddenTotalBasis: overriddenTotalBasis ?? this.overriddenTotalBasis,
    description: description ?? this.description,
    version: version ?? this.version,
  );
}
