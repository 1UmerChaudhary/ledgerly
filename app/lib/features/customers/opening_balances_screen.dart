import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../shell/breakpoints.dart';
import '../../theme/ledgerly_theme.dart';
import '../bills/bill_draft.dart';
import '../dashboard/dashboard_screen.dart';

/// One row the bookkeeper is typing or that a pasted CSV filled in.
class _RowDraft {
  _RowDraft({String? name, String? phone, String? balance})
    : name = TextEditingController(text: name ?? ''),
      phone = TextEditingController(text: phone ?? ''),
      balance = TextEditingController(text: balance ?? '');
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController balance;

  void dispose() {
    name.dispose();
    phone.dispose();
    balance.dispose();
  }
}

/// Onboards a firm's existing customers in bulk: type rows by hand, or paste
/// CSV copied from a spreadsheet ("name,phone,balance"; a header row is
/// optional). One save writes a customer plus a starting entry for every
/// valid row; a bad row (duplicate phone, unreadable amount) is reported
/// against its own row and never silently drops the others.
class OpeningBalancesScreen extends ConsumerStatefulWidget {
  const OpeningBalancesScreen({super.key});

  @override
  ConsumerState<OpeningBalancesScreen> createState() =>
      _OpeningBalancesScreenState();
}

class _OpeningBalancesScreenState extends ConsumerState<OpeningBalancesScreen> {
  final _rows = <_RowDraft>[_RowDraft()];
  final _csv = TextEditingController();
  bool _saving = false;
  int? _createdCount;
  final Map<int, String> _rowErrors = {};

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _csv.dispose();
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_RowDraft()));

  void _applyCsv() {
    final parsed = parseOpeningBalancesCsv(_csv.text);
    setState(() {
      for (final r in _rows) {
        r.dispose();
      }
      _rows.clear();
      for (final row in parsed.rows) {
        _rows.add(
          _RowDraft(
            name: row.name,
            phone: row.phone,
            balance: formatMoney(row.balance, symbol: false),
          ),
        );
      }
      if (_rows.isEmpty) _rows.add(_RowDraft());
      _rowErrors.clear();
      for (final e in parsed.errors) {
        _rowErrors[-1] = _rowErrors.containsKey(-1)
            ? '${_rowErrors[-1]}; line ${e.line}: ${e.message}'
            : 'line ${e.line}: ${e.message}';
      }
    });
  }

  Future<void> _save() async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    setState(() {
      _saving = true;
      _rowErrors.clear();
    });
    var created = 0;
    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final name = row.name.text.trim();
      if (name.isEmpty &&
          row.phone.text.trim().isEmpty &&
          row.balance.text.trim().isEmpty) {
        continue; // a blank trailing row is not an error
      }
      if (name.isEmpty) {
        _rowErrors[i] = 'A name is required.';
        continue;
      }
      final balance = row.balance.text.trim().isEmpty
          ? Money.zero
          : parseMoney(row.balance.text.trim());
      if (balance == null) {
        _rowErrors[i] = 'Could not read the balance amount.';
        continue;
      }
      try {
        final customer = await firm.customers.create(
          name: name,
          phone: row.phone.text.trim().isEmpty ? null : row.phone.text.trim(),
        );
        if (openingEntryTypeFor(balance) case final type?) {
          await firm.bills.saveNew(
            Bill(
              id: newId(),
              customerId: customer.id,
              type: type,
              entryDate: todayIso(),
              typedAmount: balance.abs(),
            ),
          );
        }
        created++;
      } on DuplicatePhoneException catch (e) {
        _rowErrors[i] = 'This number belongs to ${e.existing.name}.';
      }
    }
    ref.invalidate(customersListProvider);
    ref.invalidate(dashboardRowsProvider);
    setState(() {
      _saving = false;
      _createdCount = _rowErrors.isEmpty ? created : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (_createdCount case final n?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$n customer${n == 1 ? '' : 's'} added with their opening balance.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => context.go('/customers'),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
    return Padding(
      key: const Key('openingBalances.screen'),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < kCompactBreakpoint;
          return ListView(
            children: [
              Text(
                'IMPORT OPENING BALANCES',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                  color: c.ink3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'One row per customer. A positive balance means they owe you; a '
                'negative balance means you owe them.',
                style: TextStyle(color: c.ink2, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: c.rule),
                  borderRadius: BorderRadius.circular(4),
                  color: c.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Or paste rows copied from a spreadsheet (name, phone, balance):',
                      style: TextStyle(fontSize: 12.5, color: c.ink2),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('openingBalances.csvPaste'),
                      controller: _csv,
                      maxLines: 4,
                      style: numberStyle.copyWith(fontSize: 12.5),
                      decoration: const InputDecoration(
                        hintText: 'Rashid Traders,0300-1234567,620000',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        key: const Key('openingBalances.applyCsv'),
                        onPressed: _applyCsv,
                        child: const Text('Fill grid from pasted text'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_rowErrors[-1] case final generalError?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    generalError,
                    style: TextStyle(color: c.giveable),
                  ),
                ),
              for (var i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _rowFields(i, compact),
                      if (_rowErrors[i] case final e?)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            e,
                            style: TextStyle(fontSize: 12.5, color: c.giveable),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('openingBalances.addRow'),
                    onPressed: _addRow,
                    child: const Text('+ Add row'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('openingBalances.save'),
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save all'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Above [kCompactBreakpoint] this Row is unchanged: three fixed
  /// 240/160/140px SizedBoxes side by side. Below it those three alone
  /// want ~556px against a ~346px content width -- Balance (the last of
  /// the three) was the one pushed past the overflow edge and hidden --
  /// so each field stacks in its own full-width row instead.
  Widget _rowFields(int i, bool compact) {
    final name = TextField(
      key: Key('openingBalances.row.$i.name'),
      controller: _rows[i].name,
      decoration: const InputDecoration(hintText: 'Name'),
    );
    final phone = TextField(
      key: Key('openingBalances.row.$i.phone'),
      controller: _rows[i].phone,
      style: numberStyle.copyWith(fontSize: 14),
      decoration: const InputDecoration(hintText: 'Phone (optional)'),
    );
    final balance = TextField(
      key: Key('openingBalances.row.$i.balance'),
      controller: _rows[i].balance,
      textAlign: TextAlign.right,
      style: numberStyle.copyWith(fontSize: 14),
      decoration: const InputDecoration(hintText: 'Balance'),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          name,
          const SizedBox(height: 6),
          phone,
          const SizedBox(height: 6),
          balance,
        ],
      );
    }
    return Row(
      children: [
        SizedBox(width: 240, child: name),
        const SizedBox(width: 8),
        SizedBox(width: 160, child: phone),
        const SizedBox(width: 8),
        SizedBox(width: 140, child: balance),
      ],
    );
  }
}
