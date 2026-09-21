import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';
import 'package:ledgerly_data/ledgerly_data.dart';

import '../../bootstrap/providers.dart';
import '../../shell/breakpoints.dart';
import '../../theme/ledgerly_theme.dart';
import '../bills/bill_draft.dart';
import '../dashboard/dashboard_screen.dart';

/// New customer. Phone is the hard duplicate check (blocked, names the owner);
/// a similar name is only a warning shown while typing.
class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  List<Customer> _similar = const [];
  String? _error;
  Customer? _clash;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _checkSimilar(String name) async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null || name.trim().length < 3) {
      setState(() => _similar = const []);
      return;
    }
    final similar = await firm.customers.similarNames(name);
    if (mounted) setState(() => _similar = similar);
  }

  Future<void> _save() async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'A name is required.');
      return;
    }
    try {
      final created = await firm.customers.create(
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      );
      ref.invalidate(customersListProvider);
      ref.invalidate(dashboardRowsProvider);
      if (mounted) context.go('/customers?select=${created.id}');
    } on DuplicatePhoneException catch (e) {
      setState(() {
        _clash = e.existing;
        _error =
            'This number belongs to ${e.existing.name}. Press Enter to open them instead.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.numpadEnter, control: true):
            _save,
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            context.go('/customers'),
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (_clash != null) context.go('/customers/${_clash!.id}');
        },
      },
      child: Padding(
        key: const Key('customer.form'),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The 560px fixed width and label-then-field Row below fit the
            // desktop form; below kCompactBreakpoint they'd overflow a phone
            // viewport (~390px), so the form takes the available width and
            // each field's label stacks above it instead, same convention
            // as bill_screen.dart's _Header compact split.
            final compact = constraints.maxWidth < kCompactBreakpoint;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEW CUSTOMER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: c.ink3,
                  ),
                ),
                const SizedBox(height: 14),
                _field(
                  'Name',
                  TextField(
                    key: const Key('customer.name'),
                    controller: _name,
                    autofocus: true,
                    onChanged: _checkSimilar,
                  ),
                  compact: compact,
                ),
                if (_similar.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      left: compact ? 0 : 130,
                      bottom: 8,
                    ),
                    child: Text(
                      'Similar: ${_similar.map((s) => s.name).join(', ')}',
                      style: TextStyle(fontSize: 12.5, color: c.giveable),
                    ),
                  ),
                _field(
                  'Phone',
                  TextField(
                    key: const Key('customer.phone'),
                    controller: _phone,
                    style: numberStyle.copyWith(fontSize: 14),
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: '0300-1234567',
                    ),
                  ),
                  compact: compact,
                ),
                _field(
                  'Notes',
                  TextField(
                    key: const Key('customer.notes'),
                    controller: _notes,
                  ),
                  compact: compact,
                ),
                if (_error case final e?)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(e, style: TextStyle(color: c.giveable)),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Ctrl+Enter save · Esc back',
                  style: TextStyle(fontSize: 12.5, color: c.ink3),
                ),
                if (compact)
                  // Desktop already has Ctrl+Enter/Esc for this, shown in
                  // the hint above -- no on-screen equivalent needed there.
                  // A touch-only device can never send Ctrl+Enter, so
                  // below kCompactBreakpoint this is the only way to save
                  // at all, same pattern as bill_screen.dart's Task 9 fix.
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          key: const Key('customer.compactSave'),
                          onPressed: _save,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
            return compact ? content : SizedBox(width: 560, child: content);
          },
        ),
      ),
    );
  }

  Widget _field(String label, Widget child, {required bool compact}) {
    final labelWidget = Text(
      label,
      style: TextStyle(color: context.colors.ink2),
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [labelWidget, const SizedBox(height: 4), child],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 130, child: labelWidget),
          Expanded(child: child),
        ],
      ),
    );
  }
}
