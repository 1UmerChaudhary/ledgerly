import 'entities.dart';
import 'money.dart';
import 'weight.dart';

class FieldChange {
  const FieldChange(this.label, this.from, this.to);
  final String label;
  final String from;
  final String to;
}

/// What changed between two versions of a bill, in the words the history
/// panel shows: "Oilcake rate 2,000 → 2,400". Lines are matched by id, which
/// is why line ids stay stable across edits.
List<FieldChange> diffBills(
  Bill a,
  Bill b, {
  Map<String, String> itemNames = const {},
}) {
  final out = <FieldChange>[];
  String name(String itemId) => itemNames[itemId] ?? 'Item';
  String money(Money? m) => m == null ? '—' : formatMoney(m, symbol: false);
  String kg(Weight? w) => w == null ? '—' : formatKg(w, trim: true);

  if (a.entryDate != b.entryDate) {
    out.add(FieldChange('Date', a.entryDate, b.entryDate));
  }
  if ((a.description ?? '') != (b.description ?? '')) {
    out.add(
      FieldChange('Description', a.description ?? '—', b.description ?? '—'),
    );
  }
  if (a.customerId != b.customerId) {
    out.add(FieldChange('Customer', a.customerId ?? '—', b.customerId ?? '—'));
  }

  final before = {for (final l in a.lines) l.id: l};
  final after = {for (final l in b.lines) l.id: l};
  for (final l in b.lines) {
    final o = before[l.id];
    final n = name(l.itemId);
    if (o == null) {
      out.add(FieldChange('Line added: $n', '—', money(l.finalTotal)));
      continue;
    }
    if (o.itemId != l.itemId) out.add(FieldChange('Item', name(o.itemId), n));
    if (o.rate != l.rate) {
      out.add(FieldChange('$n rate', money(o.rate), money(l.rate)));
    }
    if (o.bagCount != l.bagCount) {
      out.add(
        FieldChange('$n bags', '${o.bagCount ?? '—'}', '${l.bagCount ?? '—'}'),
      );
    }
    if (o.bagWeight != l.bagWeight) {
      out.add(FieldChange('$n bag kg', kg(o.bagWeight), kg(l.bagWeight)));
    }
    if (o.totalWeight != l.totalWeight) {
      out.add(FieldChange('$n total kg', kg(o.totalWeight), kg(l.totalWeight)));
    }
    if (o.rateBase != l.rateBase) {
      out.add(FieldChange('$n base kg', kg(o.rateBase), kg(l.rateBase)));
    }
    if (o.quantity != l.quantity) {
      out.add(
        FieldChange(
          '$n quantity',
          '${o.quantity ?? '—'}',
          '${l.quantity ?? '—'}',
        ),
      );
    }
    if (o.overriddenTotal != l.overriddenTotal) {
      out.add(
        FieldChange(
          '$n override',
          money(o.overriddenTotal),
          money(l.overriddenTotal),
        ),
      );
    }
  }
  for (final l in a.lines) {
    if (!after.containsKey(l.id)) {
      out.add(
        FieldChange(
          'Line removed: ${name(l.itemId)}',
          money(l.finalTotal),
          '—',
        ),
      );
    }
  }
  if (a.overriddenTotal != b.overriddenTotal) {
    out.add(
      FieldChange(
        'Override total',
        money(a.overriddenTotal),
        money(b.overriddenTotal),
      ),
    );
  }
  if (a.typedAmount != b.typedAmount && a.lines.isEmpty && b.lines.isEmpty) {
    out.add(FieldChange('Amount', money(a.typedAmount), money(b.typedAmount)));
  }
  if (a.finalAmount != b.finalAmount) {
    out.add(FieldChange('Final', money(a.finalAmount), money(b.finalAmount)));
  }
  return out;
}
