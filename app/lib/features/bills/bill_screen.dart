import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../bootstrap/providers.dart';
import '../../theme/ledgerly_theme.dart';
import 'bill_draft.dart';
import 'widgets/date_field.dart';
import 'widgets/entity_autocomplete.dart';

TransactionType _typeFrom(String s) => switch (s) {
  'purchase' => TransactionType.purchase,
  'cash_in' => TransactionType.cashIn,
  'cash_out' => TransactionType.cashOut,
  'opening_balance' => TransactionType.openingBalance,
  'adjustment' => TransactionType.adjustment,
  _ => TransactionType.sale,
};

String _title(TransactionType t) => switch (t) {
  TransactionType.sale => 'NEW SALE',
  TransactionType.purchase => 'NEW PURCHASE',
  TransactionType.cashIn => 'CASH RECEIVED',
  TransactionType.cashOut => 'CASH PAID',
  TransactionType.openingBalance => 'OPENING BALANCE',
  TransactionType.adjustment => 'ADJUSTMENT',
};

String _owesPhrase(Money balance) => balance.isNegative
    ? 'is owed ${formatMoney(-balance)}'
    : 'owes ${formatMoney(balance)}';

/// One screen for every transaction type. Sales and purchases show the lines
/// grid; cash, opening balance and adjustment show a single amount.
class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key, required this.type, this.editBillId});
  final String type;

  /// When set, the form edits this stored bill and saving writes a new version.
  final String? editBillId;

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
  late final TransactionType _type = _typeFrom(widget.type);
  late final BillFormKey _key = (type: _type, editId: widget.editBillId);

  @override
  void initState() {
    super.initState();
    if (widget.editBillId case final id?) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _ctl.loadExisting(id),
      );
    }
  }

  final _lineFocus = <String, FocusNode>{};
  final _customerFocus = FocusNode(debugLabel: 'bill.customer');
  // Holds focus once the form is gone (Saved state) so Esc/Ctrl+N still reach
  // this screen's shortcuts instead of the shell's.
  final _screenFocus = FocusNode(debugLabel: 'bill.screen');

  FocusNode _focusFor(String key) =>
      _lineFocus.putIfAbsent(key, () => FocusNode(debugLabel: key));

  @override
  void dispose() {
    for (final n in _lineFocus.values) {
      n.dispose();
    }
    _customerFocus.dispose();
    _screenFocus.dispose();
    super.dispose();
  }

  BillDraftController get _ctl => ref.read(billDraftProvider(_key).notifier);

  Future<void> _save() async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    final saved = await _ctl.save(firm);
    if (saved != null && mounted) _screenFocus.requestFocus();
  }

  Future<void> _escape(BillDraft d) async {
    if (d.saved case final saved?) {
      // A walk-in cash sale has no customer, so no ledger to open — the
      // dashboard is the closest sensible place to land.
      context.go(
        saved.customerId == null
            ? '/'
            : '/customers/${saved.customerId}?select=${saved.id}',
      );
      return;
    }
    if (!d.dirty) {
      context.go('/');
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('bill.discardDialog'),
        title: const Text('Discard this bill?'),
        content: const Text('Nothing has been saved yet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.go('/');
  }

  /// Enter rule for grid cells: on the rate cell or later of the LAST line,
  /// when that line is complete, Enter adds a line; otherwise it moves on.
  void _enterOn(int index, String field, BillDraft d) {
    const tail = {'rate', 'base', 'override'};
    final isLast = index == d.lines.length - 1;
    if (isLast &&
        tail.contains(field) &&
        d.lines[index].toLine(index + 1) != null) {
      final newIndex = _ctl.addLine();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusFor('bill.line.$newIndex.item').requestFocus(),
      );
    } else {
      FocusScope.of(context).nextFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final d = ref.watch(billDraftProvider(_key));
    final customers =
        ref.watch(customersListProvider).value ?? const <Customer>[];
    final items = ref.watch(itemsListProvider).value ?? const <Item>[];
    final balance = d.customer == null
        ? null
        : ref.watch(customerBalanceProvider(d.customer!.id)).value;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (d.saved == null) _save();
        },
        const SingleActivator(
          LogicalKeyboardKey.numpadEnter,
          control: true,
        ): () {
          if (d.saved == null) _save();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () => _escape(d),
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          if (d.saved != null) _ctl.startNextForSameCustomer();
        },
        const SingleActivator(LogicalKeyboardKey.minus, control: true): () {
          final focused = FocusManager.instance.primaryFocus?.debugLabel ?? '';
          final m = RegExp(r'^bill\.line\.(\d+)\.').firstMatch(focused);
          if (m != null) _ctl.removeLine(int.parse(m[1]!));
        },
      },
      child: Focus(
        focusNode: _screenFocus,
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Padding(
            key: const Key('bill.screen'),
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: ListView(
              children: [
                Row(
                  children: [
                    Text(
                      d.editing == null
                          ? _title(_type)
                          : _title(_type).replaceFirst('NEW ', 'EDIT '),
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: c.ink3,
                      ),
                    ),
                    const Spacer(),
                    if (d.saved?.displayNo case final no?)
                      Text(
                        'Bill $no',
                        style: numberStyle.copyWith(
                          fontSize: 13,
                          color: c.ink2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (d.saved case final saved?)
                  _SavedBanner(
                    saved: saved,
                    customer: d.customer,
                    balance: balance,
                  ),
                if (d.saved == null) ...[
                  _Header(
                    d: d,
                    customers: customers,
                    customerFocus: _customerFocus,
                    balance: balance,
                    onCustomer: _ctl.setCustomer,
                    onDate: _ctl.setDate,
                    onDescription: _ctl.setDescription,
                    onWalkIn: _ctl.setWalkIn,
                  ),
                  const SizedBox(height: 14),
                  if (d.hasLines)
                    _LinesGrid(
                      d: d,
                      items: items,
                      focusFor: _focusFor,
                      onPickItem: _ctl.pickItem,
                      onEdit: _ctl.editLineField,
                      onToggleMode: _ctl.toggleMode,
                      onEnter: (i, f) => _enterOn(i, f, d),
                    )
                  else
                    _AmountRow(d: d, onAmount: _ctl.setAmount),
                  const SizedBox(height: 14),
                  _Totals(d: d, balance: balance, onOverride: _ctl.setOverride),
                  if (d.error case final e?)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(e, style: TextStyle(color: c.giveable)),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.d,
    required this.customers,
    required this.customerFocus,
    required this.balance,
    required this.onCustomer,
    required this.onDate,
    required this.onDescription,
    required this.onWalkIn,
  });
  final BillDraft d;
  final List<Customer> customers;
  final FocusNode customerFocus;
  final Money? balance;
  final void Function(Customer?) onCustomer;
  final void Function(String) onDate;
  final void Function(String) onDescription;
  final void Function(bool) onWalkIn;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget label(String t) => SizedBox(
      width: 90,
      child: Text(t, style: TextStyle(color: c.ink2)),
    );
    final canWalkIn = d.type == TransactionType.sale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            label('Customer'),
            if (canWalkIn && d.isWalkIn)
              Expanded(
                child: Text(
                  'Walk-in — a counter sale for cash, not tracked in any customer ledger.',
                  style: TextStyle(fontSize: 13, color: c.ink2),
                ),
              )
            else
              SizedBox(
                width: 320,
                child: FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: EntityAutocomplete<Customer>(
                    fieldKey: const Key('bill.customer'),
                    autofocus: true,
                    options: customers,
                    labelOf: (c) => c.name,
                    selected: d.customer,
                    hint: 'Type a name or phone',
                    onSelected: onCustomer,
                    onSubmittedWithoutOptions: () =>
                        FocusScope.of(context).nextFocus(),
                  ),
                ),
              ),
            const SizedBox(width: 14),
            if (!d.isWalkIn && d.customer != null && balance != null)
              Expanded(
                child: Text(
                  _owesPhrase(balance!),
                  overflow: TextOverflow.ellipsis,
                  style: numberStyle.copyWith(
                    fontSize: 13,
                    color: balance!.isNegative ? c.giveable : c.receivable,
                  ),
                ),
              ),
            if (canWalkIn) ...[
              const SizedBox(width: 14),
              Checkbox(
                key: const Key('bill.walkIn'),
                value: d.isWalkIn,
                onChanged: (v) => onWalkIn(v ?? false),
              ),
              Text('Walk-in', style: TextStyle(fontSize: 13, color: c.ink2)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            label('Date'),
            SizedBox(
              width: 150,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(2),
                child: DateField(
                  fieldKey: const Key('bill.date'),
                  iso: d.entryDate,
                  onChanged: onDate,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text('Description', style: TextStyle(color: c.ink2)),
            const SizedBox(width: 10),
            Expanded(
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: TextField(
                  key: const Key('bill.description'),
                  onChanged: onDescription,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.d, required this.onAmount});
  final BillDraft d;
  final void Function(String) onAmount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text('Amount', style: TextStyle(color: c.ink2)),
        ),
        SizedBox(
          width: 220,
          child: FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: TextField(
              key: const Key('cash.amount'),
              style: numberStyle.copyWith(fontSize: 15),
              textAlign: TextAlign.right,
              onChanged: onAmount,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                prefixText: 'Rs ',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LinesGrid extends StatelessWidget {
  const _LinesGrid({
    required this.d,
    required this.items,
    required this.focusFor,
    required this.onPickItem,
    required this.onEdit,
    required this.onToggleMode,
    required this.onEnter,
  });
  final BillDraft d;
  final List<Item> items;
  final FocusNode Function(String) focusFor;
  final void Function(int, Item) onPickItem;
  final void Function(int, String, String) onEdit;
  final void Function(int) onToggleMode;
  final void Function(int index, String field) onEnter;

  static const _cols = <(String, int, bool)>[
    ('#', 32, false),
    ('Item', 200, false),
    ('Mode', 70, false),
    ('Bags', 70, true),
    ('Bag kg', 90, true),
    ('Total kg', 110, true),
    ('Rate', 110, true),
    ('per kg', 90, true),
    ('Line total', 120, true),
    ('✎', 100, true),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.rule),
          borderRadius: BorderRadius.circular(4),
          color: c.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.rule)),
              ),
              child: Row(
                children: [
                  for (final (label, w, num) in _cols)
                    SizedBox(
                      width: w.toDouble(),
                      child: Text(
                        label.toUpperCase(),
                        textAlign: num ? TextAlign.right : TextAlign.left,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w600,
                          color: c.ink3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (var i = 0; i < d.lines.length; i++)
              _LineRow(
                index: i,
                line: d.lines[i],
                items: items,
                focusFor: focusFor,
                onPickItem: onPickItem,
                onEdit: onEdit,
                onToggleMode: onToggleMode,
                onEnter: onEnter,
              ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Enter on the rate adds a line · Ctrl+− removes one · Space toggles bags ↔ weight · 1–5 picks base 30 / 34 / 37.324 / 40 / 56',
                style: TextStyle(fontSize: 12, color: c.ink3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.index,
    required this.line,
    required this.items,
    required this.focusFor,
    required this.onPickItem,
    required this.onEdit,
    required this.onToggleMode,
    required this.onEnter,
  });
  final int index;
  final LineDraft line;
  final List<Item> items;
  final FocusNode Function(String) focusFor;
  final void Function(int, Item) onPickItem;
  final void Function(int, String, String) onEdit;
  final void Function(int) onToggleMode;
  final void Function(int index, String field) onEnter;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final byBags = line.mode == SaleMode.byBags;
    final calc = line.toLine(index + 1)?.calculatedTotal;
    final order = 10.0 + index * 10;
    Widget cell(
      String field, {
      required int width,
      String? value,
      bool enabled = true,
      int order = 0,
      bool digitsPreset = false,
    }) {
      final key = 'bill.line.$index.$field';
      return SizedBox(
        width: width.toDouble(),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: FocusTraversalOrder(
            order: NumericFocusOrder(order.toDouble()),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is! KeyDownEvent) return KeyEventResult.ignored;
                if ((event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
                    !HardwareKeyboard.instance.isControlPressed) {
                  onEnter(index, field);
                  return KeyEventResult.handled;
                }
                if (digitsPreset && (value ?? '').isEmpty) {
                  final i =
                      LogicalKeyboardKey.digit1.keyId <=
                              event.logicalKey.keyId &&
                          event.logicalKey.keyId <=
                              LogicalKeyboardKey.digit5.keyId
                      ? event.logicalKey.keyId - LogicalKeyboardKey.digit1.keyId
                      : -1;
                  if (i >= 0) {
                    onEdit(
                      index,
                      field,
                      formatKg(RateBase.presets[i], trim: true),
                    );
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: _CellField(
                key: Key(key),
                focusNode: focusFor(key),
                value: value ?? '',
                enabled: enabled,
                onChanged: (v) => onEdit(index, field, v),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ruleSoft)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: numberStyle.copyWith(fontSize: 13, color: c.ink3),
            ),
          ),
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: FocusTraversalOrder(
                order: NumericFocusOrder(order + 1),
                child: EntityAutocomplete<Item>(
                  key: ValueKey('ac.${line.id}'),
                  fieldKey: Key('bill.line.$index.item'),
                  options: items,
                  labelOf: (i) => i.name,
                  selected: line.item,
                  hint: 'Item',
                  onSelected: (i) => onPickItem(index, i),
                  onSubmittedWithoutOptions: () => onEnter(index, 'item'),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: FocusTraversalOrder(
              order: NumericFocusOrder(order + 2),
              child: _ModeCell(
                key: Key('bill.line.$index.mode'),
                byBags: byBags,
                onToggle: () => onToggleMode(index),
              ),
            ),
          ),
          cell(
            'bags',
            width: 70,
            value: line.bags,
            enabled: byBags,
            order: (order + 3).toInt(),
          ),
          cell(
            'bagKg',
            width: 90,
            value: line.bagKg,
            enabled: byBags,
            order: (order + 4).toInt(),
          ),
          byBags
              ? SizedBox(
                  width: 110,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      line.totalWeight == null
                          ? ''
                          : formatKg(line.totalWeight!),
                      textAlign: TextAlign.right,
                      style: numberStyle.copyWith(
                        fontSize: 13.5,
                        color: c.ink2,
                      ),
                    ),
                  ),
                )
              : cell(
                  'totalKg',
                  width: 110,
                  value: line.totalKg,
                  order: (order + 5).toInt(),
                ),
          cell(
            'rate',
            width: 110,
            value: line.rate,
            order: (order + 6).toInt(),
          ),
          cell(
            'base',
            width: 90,
            value: line.base,
            order: (order + 7).toInt(),
            digitsPreset: true,
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                calc == null ? '' : formatMoney(calc, symbol: false),
                textAlign: TextAlign.right,
                style: numberStyle.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          cell(
            'override',
            width: 100,
            value: line.override,
            order: (order + 8).toInt(),
          ),
        ],
      ),
    );
  }
}

/// A grid cell keeps its own controller so the caret survives rebuilds, but
/// takes its text from the draft when the draft changes it (item defaults).
class _CellField extends StatefulWidget {
  const _CellField({
    super.key,
    required this.focusNode,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });
  final FocusNode focusNode;
  final String value;
  final bool enabled;
  final void Function(String) onChanged;

  @override
  State<_CellField> createState() => _CellFieldState();
}

class _CellFieldState extends State<_CellField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _CellField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    focusNode: widget.focusNode,
    enabled: widget.enabled,
    textAlign: TextAlign.right,
    style: numberStyle.copyWith(fontSize: 13.5),
    onChanged: widget.onChanged,
    decoration: const InputDecoration(
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      isDense: true,
    ),
  );
}

class _ModeCell extends StatelessWidget {
  const _ModeCell({super.key, required this.byBags, required this.onToggle});
  final bool byBags;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Focus(
      onKeyEvent: (node, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.space) {
          onToggle();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) => InkWell(
          onTap: onToggle,
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: Focus.of(context).hasFocus ? c.accent : c.rule,
                width: Focus.of(context).hasFocus ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              byBags ? 'bags' : 'weight',
              style: numberStyle.copyWith(fontSize: 12.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({
    required this.d,
    required this.balance,
    required this.onOverride,
  });
  final BillDraft d;
  final Money? balance;
  final void Function(String) onOverride;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final effect = d.signedEffect;
    final after = balance != null && effect != null ? balance! + effect : null;
    final noun = d.hasLines ? 'after this bill' : 'after this';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.paper,
              borderRadius: BorderRadius.circular(4),
            ),
            child: d.isWalkIn
                ? Text(
                    'Walk-in cash sale — not tracked in any customer ledger.',
                    style: TextStyle(color: c.ink3),
                  )
                : d.customer == null
                ? Text(
                    'Pick a customer to see the balance change.',
                    style: TextStyle(color: c.ink3),
                  )
                : Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${d.customer!.name} ',
                        style: TextStyle(color: c.ink2),
                      ),
                      if (balance != null)
                        Text(
                          _owesPhrase(balance!),
                          style: numberStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (after != null) ...[
                        Text('  →  ', style: TextStyle(color: c.ink3)),
                        Text(
                          '$noun ${_owesPhrase(after)}',
                          style: numberStyle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: after.isNegative ? c.giveable : c.receivable,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (d.hasLines) ...[
                _kv(
                  context,
                  'Calculated total',
                  Text(
                    formatMoney(d.calculatedTotal, symbol: false),
                    style: numberStyle.copyWith(fontSize: 13.5),
                  ),
                ),
                _kv(
                  context,
                  'Override total',
                  SizedBox(
                    width: 130,
                    child: TextField(
                      key: const Key('bill.override'),
                      textAlign: TextAlign.right,
                      style: numberStyle.copyWith(fontSize: 13.5),
                      onChanged: onOverride,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.ink)),
                ),
                child: Row(
                  children: [
                    Text(
                      d.hasLines ? 'FINAL' : 'AMOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w600,
                        color: c.ink2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatMoney(d.finalAmount),
                      style: numberStyle.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.colors.ink2),
          ),
        ),
        const SizedBox(width: 8),
        value,
      ],
    ),
  );
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({
    required this.saved,
    required this.customer,
    required this.balance,
  });
  final Bill saved;

  /// Null for a walk-in cash sale, which has no customer ledger to report.
  final Customer? customer;
  final Money? balance;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: const Key('bill.saved'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.receivableSoft,
        border: Border.all(color: c.receivable),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.receivable,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '✓',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              customer == null
                  ? 'Saved. Bill ${saved.displayNo} · Cash sale of ${formatMoney(saved.finalAmount)}.'
                  : 'Saved. Bill ${saved.displayNo} · ${formatMoney(saved.finalAmount)} · ${customer!.name} now ${balance == null ? '' : _owesPhrase(balance!)}',
              style: const TextStyle(fontSize: 13.5),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Ctrl+P print · Ctrl+N next · Esc ledger',
            style: TextStyle(fontSize: 12.5, color: c.ink2),
          ),
        ],
      ),
    );
  }
}
