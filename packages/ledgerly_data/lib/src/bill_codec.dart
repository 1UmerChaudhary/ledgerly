import 'dart:convert';

import 'package:ledgerly_core/ledgerly_core.dart';

import 'db/app_database.dart';

/// Bill <-> database rows <-> history snapshot JSON.
///
/// Snapshots carry `schema_version` so a future shape change can upcast old
/// rows instead of failing to read them.
abstract final class BillCodec {
  static const int snapshotVersion = 1;

  static Bill fromRows(TransactionRow h, List<TransactionLineRow> lines) =>
      Bill(
        id: h.id,
        customerId: h.customerId,
        type: TransactionType.values.byName(_camel(h.type)),
        entryDate: h.entryDate,
        description: h.description,
        version: h.version,
        displayNo: renderDisplayNo(h.deviceShortCode, h.displaySeq),
        typedAmount: lines.isEmpty ? Money(h.calculatedTotal) : null,
        overriddenTotal: h.overriddenTotal == null
            ? null
            : Money(h.overriddenTotal!),
        overriddenTotalBasis: h.overriddenTotalBasis == null
            ? null
            : Money(h.overriddenTotalBasis!),
        lines: ([...lines]..sort((a, b) => a.lineNo.compareTo(b.lineNo)))
            .map(lineFromRow)
            .toList(),
        deleted: h.deletedAt != null,
      );

  static BillLine lineFromRow(TransactionLineRow r) => BillLine(
    id: r.id,
    lineNo: r.lineNo,
    itemId: r.itemId,
    uom: Uom.values.byName(r.uom),
    saleMode: SaleMode.values.byName(_camel(r.saleMode)),
    bagCount: r.bagCount,
    bagWeight: r.bagWeightG == null ? null : Weight(r.bagWeightG!),
    totalWeight: r.totalWeightG == null ? null : Weight(r.totalWeightG!),
    quantity: r.quantity,
    rate: Money(r.ratePaisa),
    rateBase: r.rateBaseWeightG == null ? null : Weight(r.rateBaseWeightG!),
    overriddenTotal: r.overriddenTotal == null
        ? null
        : Money(r.overriddenTotal!),
  );

  static String snapshot(
    Bill b, {
    String? customerName,
    Map<String, String> itemNames = const {},
  }) => jsonEncode({
    'schema_version': snapshotVersion,
    'header': {
      'id': b.id,
      'customer_id': b.customerId,
      'type': snake(b.type.name),
      'entry_date': b.entryDate,
      'description': b.description,
      'version': b.version,
      'display_no': b.displayNo,
      'typed_amount': b.typedAmount?.paisa,
      'overridden_total': b.overriddenTotal?.paisa,
      'overridden_total_basis': b.overriddenTotalBasis?.paisa,
      'final_amount': b.finalAmount.paisa,
    },
    'lines': [
      for (final l in b.lines)
        {
          'id': l.id,
          'line_no': l.lineNo,
          'item_id': l.itemId,
          'uom': l.uom.name,
          'sale_mode': snake(l.saleMode.name),
          'bag_count': l.bagCount,
          'bag_weight_g': l.bagWeight?.grams,
          'total_weight_g': l.totalWeight?.grams,
          'quantity': l.quantity,
          'rate_paisa': l.rate.paisa,
          'rate_base_weight_g': l.rateBase?.grams,
          'overridden_total': l.overriddenTotal?.paisa,
        },
    ],
    'customer_name': customerName,
    'item_names': itemNames,
  });

  static Bill fromSnapshot(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    final h = m['header'] as Map<String, dynamic>;
    final lines = (m['lines'] as List<dynamic>).cast<Map<String, dynamic>>();
    return Bill(
      id: h['id'] as String,
      customerId: h['customer_id'] as String?,
      type: TransactionType.values.byName(_camel(h['type'] as String)),
      entryDate: h['entry_date'] as String,
      description: h['description'] as String?,
      version: h['version'] as int,
      displayNo: h['display_no'] as String?,
      typedAmount: (h['typed_amount'] as int?) == null
          ? null
          : Money(h['typed_amount'] as int),
      overriddenTotal: (h['overridden_total'] as int?) == null
          ? null
          : Money(h['overridden_total'] as int),
      overriddenTotalBasis: (h['overridden_total_basis'] as int?) == null
          ? null
          : Money(h['overridden_total_basis'] as int),
      lines: [
        for (final l in lines)
          BillLine(
            id: l['id'] as String,
            lineNo: l['line_no'] as int,
            itemId: l['item_id'] as String,
            uom: Uom.values.byName(l['uom'] as String),
            saleMode: SaleMode.values.byName(_camel(l['sale_mode'] as String)),
            bagCount: l['bag_count'] as int?,
            bagWeight: (l['bag_weight_g'] as int?) == null
                ? null
                : Weight(l['bag_weight_g'] as int),
            totalWeight: (l['total_weight_g'] as int?) == null
                ? null
                : Weight(l['total_weight_g'] as int),
            quantity: l['quantity'] as int?,
            rate: Money(l['rate_paisa'] as int),
            rateBase: (l['rate_base_weight_g'] as int?) == null
                ? null
                : Weight(l['rate_base_weight_g'] as int),
            overriddenTotal: (l['overridden_total'] as int?) == null
                ? null
                : Money(l['overridden_total'] as int),
          ),
      ],
    );
  }

  static String snake(String camel) =>
      camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static String _camel(String snake) {
    final parts = snake.split('_');
    return parts.first +
        parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }
}
