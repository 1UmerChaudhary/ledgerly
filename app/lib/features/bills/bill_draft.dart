import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../dashboard/dashboard_screen.dart';
import '../ledger/ledger_screen.dart';

/// What the clerk has typed into one grid row. Text stays text until it is
/// parsed, so a half-typed number never throws; totals appear once valid.
class LineDraft {
  const LineDraft({
    required this.id,
    this.item,
    this.mode = SaleMode.byBags,
    this.bags = '',
    this.bagKg = '',
    this.totalKg = '',
    this.rate = '',
    this.base = '',
    this.override = '',
    this.bagKgTouched = false,
    this.baseTouched = false,
  });

  final String id;
  final Item? item;
  final SaleMode mode;
  final String bags, bagKg, totalKg, rate, base, override;
  final bool bagKgTouched, baseTouched;

  int? get bagCount => int.tryParse(bags.trim());
  Weight? get bagWeight => parseKg(bagKg);
  Weight? get totalWeight => mode == SaleMode.byBags
      ? (bagCount != null && bagWeight != null ? bagWeight! * bagCount! : null)
      : parseKg(totalKg);
  Money? get rateMoney => parseMoney(rate);
  Weight? get rateBase => parseKg(base);
  bool get isBlank =>
      item == null &&
      bags.isEmpty &&
      bagKg.isEmpty &&
      totalKg.isEmpty &&
      rate.isEmpty;

  BillLine? toLine(int lineNo) {
    final i = item;
    final r = rateMoney;
    final w = totalWeight;
    final b = rateBase;
    if (i == null ||
        r == null ||
        !r.isPositive ||
        w == null ||
        w.grams <= 0 ||
        b == null ||
        b.grams <= 0) {
      return null;
    }
    if (mode == SaleMode.byBags && (bagCount == null || bagCount! <= 0)) {
      return null;
    }
    final ov = parseMoney(override);
    return BillLine(
      id: id,
      lineNo: lineNo,
      itemId: i.id,
      saleMode: mode,
      bagCount: mode == SaleMode.byBags ? bagCount : null,
      bagWeight: mode == SaleMode.byBags ? bagWeight : null,
      totalWeight: w,
      rate: r,
      rateBase: b,
      overriddenTotal: ov != null && ov.isPositive ? ov : null,
    );
  }

  LineDraft copyWith({
    Item? item,
    SaleMode? mode,
    String? bags,
    String? bagKg,
    String? totalKg,
    String? rate,
    String? base,
    String? override,
    bool? bagKgTouched,
    bool? baseTouched,
  }) => LineDraft(
    id: id,
    item: item ?? this.item,
    mode: mode ?? this.mode,
    bags: bags ?? this.bags,
    bagKg: bagKg ?? this.bagKg,
    totalKg: totalKg ?? this.totalKg,
    rate: rate ?? this.rate,
    base: base ?? this.base,
    override: override ?? this.override,
    bagKgTouched: bagKgTouched ?? this.bagKgTouched,
    baseTouched: baseTouched ?? this.baseTouched,
  );
}

class BillDraft {
  const BillDraft({
    required this.type,
    required this.entryDate,
    this.customer,
    this.description = '',
    this.lines = const [],
    this.overrideText = '',
    this.amountText = '',
    this.saved,
    this.error,
    this.dirty = false,
    this.editing,
    this.isWalkIn = false,
  });

  final TransactionType type;
  final Customer? customer;
  final String entryDate; // ISO yyyy-MM-dd
  final String description;

  /// A counter sale with no customer: never appears in any ledger. Only
  /// meaningful when [type] is sale; the UI only shows the toggle then.
  final bool isWalkIn;
  final List<LineDraft> lines;
  final String overrideText;
  final String amountText; // cash / opening / adjustment
  final Bill? saved;
  final String? error;
  final bool dirty;

  /// The stored bill this draft edits; null when creating a new one.
  final Bill? editing;

  bool get hasLines =>
      type == TransactionType.sale || type == TransactionType.purchase;

  List<BillLine> get validLines => [
    for (var i = 0; i < lines.length; i++) ?lines[i].toLine(i + 1),
  ];

  Money get calculatedTotal => hasLines
      ? validLines.fold(Money.zero, (s, l) => s + l.finalTotal)
      : (parseMoney(amountText) ?? Money.zero);

  Money get finalAmount => hasLines
      ? (parseMoney(overrideText) ?? calculatedTotal)
      : calculatedTotal;

  /// Signed effect on the customer's balance, or null while the amount is invalid.
  Money? get signedEffect {
    final a = finalAmount;
    if (type == TransactionType.adjustment ? a.isZero : !a.isPositive) {
      return null;
    }
    return signedAmountFor(type, a);
  }

  BillDraft copyWith({
    Customer? customer,
    bool clearCustomer = false,
    String? entryDate,
    String? description,
    List<LineDraft>? lines,
    String? overrideText,
    String? amountText,
    Bill? saved,
    String? error,
    bool clearError = false,
    bool? dirty,
    Bill? editing,
    bool? isWalkIn,
  }) => BillDraft(
    type: type,
    editing: editing ?? this.editing,
    customer: clearCustomer ? null : (customer ?? this.customer),
    entryDate: entryDate ?? this.entryDate,
    description: description ?? this.description,
    lines: lines ?? this.lines,
    overrideText: overrideText ?? this.overrideText,
    amountText: amountText ?? this.amountText,
    saved: saved ?? this.saved,
    error: clearError ? null : (error ?? this.error),
    dirty: dirty ?? this.dirty,
    isWalkIn: isWalkIn ?? this.isWalkIn,
  );
}

String todayIso() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

typedef BillFormKey = ({TransactionType type, String? editId});

class BillDraftController extends Notifier<BillDraft> {
  BillDraftController(this.key);
  final BillFormKey key;
  TransactionType get type => key.type;

  @override
  BillDraft build() => BillDraft(
    type: type,
    entryDate: todayIso(),
    lines: type == TransactionType.sale || type == TransactionType.purchase
        ? [LineDraft(id: newId())]
        : const [],
  );

  /// Fill the draft from a stored bill so the clerk edits what they see.
  /// Line ids are kept, which is what lets the history diff match lines.
  Future<void> loadExisting(String billId) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    final bill = await firm.bills.byId(billId);
    if (bill == null) return;
    final customer = bill.customerId == null
        ? null
        : await firm.customers.byId(bill.customerId!);
    final items = {for (final i in await firm.items.all()) i.id: i};
    state = BillDraft(
      type: bill.type,
      editing: bill,
      customer: customer,
      entryDate: bill.entryDate,
      description: bill.description ?? '',
      amountText: bill.lines.isEmpty
          ? formatMoney(bill.finalAmount, symbol: false)
          : '',
      overrideText: bill.overriddenTotal == null
          ? ''
          : formatMoney(bill.overriddenTotal!, symbol: false),
      lines: [
        for (final l in bill.lines)
          LineDraft(
            id: l.id,
            item: items[l.itemId],
            mode: l.saleMode,
            bags: l.bagCount?.toString() ?? '',
            bagKg: l.bagWeight == null ? '' : formatKg(l.bagWeight!),
            totalKg: l.saleMode == SaleMode.byWeight && l.totalWeight != null
                ? formatKg(l.totalWeight!)
                : '',
            rate: formatMoney(l.rate, symbol: false),
            base: l.rateBase == null ? '' : formatKg(l.rateBase!, trim: true),
            override: l.overriddenTotal == null
                ? ''
                : formatMoney(l.overriddenTotal!, symbol: false),
            bagKgTouched: true,
            baseTouched: true,
          ),
      ],
    );
  }

  void setCustomer(Customer? c) => state = state.copyWith(
    customer: c,
    clearCustomer: c == null,
    dirty: true,
    clearError: true,
  );
  void setWalkIn(bool v) => state = state.copyWith(
    isWalkIn: v,
    clearCustomer: v,
    dirty: true,
    clearError: true,
  );
  void setDate(String iso) =>
      state = state.copyWith(entryDate: iso, dirty: true);
  void setDescription(String v) =>
      state = state.copyWith(description: v, dirty: true);
  void setOverride(String v) =>
      state = state.copyWith(overrideText: v, dirty: true);
  void setAmount(String v) =>
      state = state.copyWith(amountText: v, dirty: true, clearError: true);

  void updateLine(int index, LineDraft Function(LineDraft) change) {
    final lines = [...state.lines];
    lines[index] = change(lines[index]);
    state = state.copyWith(lines: lines, dirty: true, clearError: true);
  }

  /// Picking an item fills bag weight and rate base from its defaults, but
  /// only into cells the clerk has not typed in.
  void pickItem(int index, Item item) => updateLine(index, (l) {
    var next = l.copyWith(item: item);
    if (!l.bagKgTouched && item.defaultBagWeight != null) {
      next = next.copyWith(bagKg: formatKg(item.defaultBagWeight!));
    }
    if (!l.baseTouched && item.defaultRateBase != null) {
      next = next.copyWith(base: formatKg(item.defaultRateBase!));
    }
    return next;
  });

  /// Any input change on a line clears that line's override (spec, Section 3).
  void editLineField(int index, String field, String value) =>
      updateLine(index, (l) {
        final cleared = l.copyWith(override: '');
        return switch (field) {
          'bags' => cleared.copyWith(bags: value),
          'bagKg' => cleared.copyWith(bagKg: value, bagKgTouched: true),
          'totalKg' => cleared.copyWith(totalKg: value),
          'rate' => cleared.copyWith(rate: value),
          'base' => cleared.copyWith(base: value, baseTouched: true),
          'override' => l.copyWith(override: value),
          _ => l,
        };
      });

  void toggleMode(int index) => updateLine(
    index,
    (l) => l.copyWith(
      mode: l.mode == SaleMode.byBags ? SaleMode.byWeight : SaleMode.byBags,
      bags: '',
      bagKg: l.mode == SaleMode.byBags ? '' : l.bagKg,
      totalKg: '',
    ),
  );

  int addLine() {
    state = state.copyWith(
      lines: [
        ...state.lines,
        LineDraft(id: newId()),
      ],
      dirty: true,
    );
    return state.lines.length - 1;
  }

  void removeLine(int index) {
    if (state.lines.length == 1) return;
    final lines = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: lines, dirty: true);
  }

  Future<Bill?> save(OpenFirm firm) async {
    final d = state;
    final walkIn = d.type == TransactionType.sale && d.isWalkIn;
    if (d.customer == null && !walkIn) {
      state = d.copyWith(error: 'Pick a customer first, or check Walk-in.');
      return null;
    }
    if (d.hasLines && d.validLines.isEmpty) {
      state = d.copyWith(
        error: 'Add at least one complete line: item, quantity and rate.',
      );
      return null;
    }
    if (d.signedEffect == null) {
      state = d.copyWith(error: 'The amount must be greater than zero.');
      return null;
    }
    final override = d.hasLines ? parseMoney(d.overrideText) : null;
    final editing = d.editing;
    final bill = Bill(
      id: editing?.id ?? newId(),
      version: editing?.version ?? 1,
      displayNo: editing?.displayNo,
      customerId: d.customer?.id,
      type: d.type,
      entryDate: d.entryDate,
      description: d.description.trim().isEmpty ? null : d.description.trim(),
      lines: d.validLines,
      typedAmount: d.hasLines ? null : d.calculatedTotal,
      overriddenTotal: override,
      overriddenTotalBasis: override == null ? null : d.calculatedTotal,
    );
    final saved = editing == null
        ? await firm.bills.saveNew(bill)
        : await firm.bills.edit(bill);
    state = d.copyWith(saved: saved, dirty: false, clearError: true);
    ref.invalidate(dashboardRowsProvider);
    if (d.customer case final customer?) {
      ref.invalidate(customerBalanceProvider(customer.id));
      ref.invalidate(
        ledgerEntriesProvider((customerId: customer.id, includeDeleted: false)),
      );
      ref.invalidate(
        ledgerEntriesProvider((customerId: customer.id, includeDeleted: true)),
      );
    }
    if (editing != null) ref.invalidate(billHistoryProvider(editing.id));
    return saved;
  }

  /// Ctrl+N from the Saved state: a fresh bill for the same customer.
  void startNextForSameCustomer() {
    final c = state.customer;
    state = build().copyWith(customer: c);
  }
}

final billDraftProvider = NotifierProvider.autoDispose
    .family<BillDraftController, BillDraft, BillFormKey>(
      BillDraftController.new,
    );

final customerBalanceProvider = FutureProvider.family<Money, String>((
  ref,
  customerId,
) async {
  final firm = await ref.watch(openFirmProvider.future);
  if (firm == null) return Money.zero;
  return firm.bills.balanceFor(customerId);
});

final customersListProvider = FutureProvider<List<Customer>>((ref) async {
  final firm = await ref.watch(openFirmProvider.future);
  return firm == null ? const [] : firm.customers.all();
});

final itemsListProvider = FutureProvider<List<Item>>((ref) async {
  final firm = await ref.watch(openFirmProvider.future);
  return firm == null ? const [] : firm.items.all();
});
