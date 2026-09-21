import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../bootstrap/providers.dart';
import '../../shell/breakpoints.dart';
import '../../theme/ledgerly_theme.dart';
import '../bills/bill_draft.dart';

class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = ref.watch(itemsListProvider).value ?? const <Item>[];
    TextStyle head() => TextStyle(
      fontSize: 11,
      letterSpacing: .6,
      fontWeight: FontWeight.w600,
      color: c.ink3,
    );
    // Below kCompactBreakpoint the three fixed pixel columns (120+120+80 =
    // 320px) alone are wider than the ~316px table width, squeezing NAME's
    // Expanded share to nothing and forcing its header label to wrap
    // mid-word ("NA"/"ME"). Below the breakpoint every column becomes a
    // proportional Expanded slice instead of a fixed pixel width, so the
    // Row always exactly fills the available width; above it, the
    // SizedBox widths are unchanged.
    // Measured from the constraints this screen is handed, not MediaQuery's
    // window width: above kCompactBreakpoint AppShell puts a 96px rail
    // beside the content, so a 640dp window leaves ~544dp here -- the
    // 600-699dp band where MediaQuery said "not compact" and the fixed
    // pixel columns below then overflowed. Still derived once for the whole
    // screen, so header and rows can never disagree.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kCompactBreakpoint;
        Widget col(Widget child, {required double width, required int flex}) =>
            compact
            ? Expanded(flex: flex, child: child)
            : SizedBox(width: width, child: child);
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
                context.go('/items/new'),
          },
          child: Focus(
            autofocus: true,
            child: Padding(
              key: const Key('items.screen'),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTitleRow(context, compact, items.length),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: c.rule),
                        borderRadius: BorderRadius.circular(4),
                        color: c.surface,
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: c.rule)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: compact ? 3 : 1,
                                  child: Text('NAME', style: head()),
                                ),
                                col(
                                  Text(
                                    'BAG KG',
                                    textAlign: TextAlign.right,
                                    style: head(),
                                  ),
                                  width: 120,
                                  flex: 2,
                                ),
                                col(
                                  Text(
                                    'RATE PER KG',
                                    textAlign: TextAlign.right,
                                    style: head(),
                                  ),
                                  width: 120,
                                  flex: 2,
                                ),
                                col(
                                  Text(
                                    'UNIT',
                                    textAlign: TextAlign.right,
                                    style: head(),
                                  ),
                                  width: 80,
                                  flex: 1,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: items.length,
                              itemBuilder: (context, idx) {
                                final i = items[idx];
                                return Container(
                                  key: const Key('items.row'),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(color: c.ruleSoft),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: compact ? 3 : 1,
                                        child: Text(
                                          i.name,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                      col(
                                        Text(
                                          i.defaultBagWeight == null
                                              ? '—'
                                              : formatKg(i.defaultBagWeight!),
                                          textAlign: TextAlign.right,
                                          style: numberStyle.copyWith(
                                            fontSize: 13,
                                          ),
                                        ),
                                        width: 120,
                                        flex: 2,
                                      ),
                                      col(
                                        Text(
                                          i.defaultRateBase == null
                                              ? '—'
                                              : formatKg(
                                                  i.defaultRateBase!,
                                                  trim: true,
                                                ),
                                          textAlign: TextAlign.right,
                                          style: numberStyle.copyWith(
                                            fontSize: 13,
                                          ),
                                        ),
                                        width: 120,
                                        flex: 2,
                                      ),
                                      col(
                                        Text(
                                          i.defaultUom.name,
                                          textAlign: TextAlign.right,
                                          style: numberStyle.copyWith(
                                            fontSize: 13,
                                            color: c.ink2,
                                          ),
                                        ),
                                        width: 80,
                                        flex: 1,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Above [kCompactBreakpoint] this Row is unchanged. Below it, the title
  /// and summary text together are wider than a ~346px content width
  /// (confirmed: overflows by ~33px), so they stack instead of sitting
  /// side by side with a Spacer between them.
  Widget _buildTitleRow(BuildContext context, bool compact, int total) {
    final c = context.colors;
    final title = Text(
      'ITEMS',
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1,
        fontWeight: FontWeight.w600,
        color: c.ink3,
      ),
    );
    final summary = Text(
      '$total total · Ctrl+N adds one',
      style: TextStyle(fontSize: 12.5, color: c.ink3),
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 4), summary],
      );
    }
    return Row(children: [title, const Spacer(), summary]);
  }
}

class ItemFormScreen extends ConsumerStatefulWidget {
  const ItemFormScreen({super.key});

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _name = TextEditingController();
  final _bagKg = TextEditingController();
  final _base = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _bagKg.dispose();
    _base.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final firm = ref.read(openFirmProvider).value;
    if (firm == null) return;
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'A name is required.');
      return;
    }
    final bag = _bagKg.text.trim().isEmpty ? null : parseKg(_bagKg.text);
    final base = _base.text.trim().isEmpty ? null : parseKg(_base.text);
    if ((_bagKg.text.trim().isNotEmpty && bag == null) ||
        (_base.text.trim().isNotEmpty && base == null)) {
      setState(
        () => _error =
            'Weights are kilograms with up to three decimals, e.g. 37.324.',
      );
      return;
    }
    await firm.items.create(
      name: _name.text.trim(),
      defaultBagWeight: bag,
      defaultRateBase: base,
    );
    ref.invalidate(itemsListProvider);
    if (mounted) context.go('/items');
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
            context.go('/items'),
      },
      child: Padding(
        key: const Key('item.form'),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Same fix as customer_form_screen.dart: the 560px fixed width
            // and label-then-field Row fit the desktop form but overflow a
            // phone viewport (~390px), so below kCompactBreakpoint the form
            // takes the available width and each field's label stacks above
            // it, matching bill_screen.dart's _Header compact split.
            final compact = constraints.maxWidth < kCompactBreakpoint;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEW ITEM',
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
                    key: const Key('item.name'),
                    controller: _name,
                    autofocus: true,
                  ),
                  compact: compact,
                ),
                _field(
                  'Usual bag kg',
                  TextField(
                    key: const Key('item.bagKg'),
                    controller: _bagKg,
                    style: numberStyle.copyWith(fontSize: 14),
                    decoration: const InputDecoration(hintText: 'e.g. 50'),
                  ),
                  compact: compact,
                ),
                _field(
                  'Rate per kg',
                  TextField(
                    key: const Key('item.base'),
                    controller: _base,
                    style: numberStyle.copyWith(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: '30 · 34 · 37.324 · 40 · 56',
                    ),
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
                  // Same reasoning as customer_form_screen.dart's Task 11
                  // fix: a touch-only device can never send Ctrl+Enter, so
                  // below kCompactBreakpoint this is the only way to save.
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton(
                          key: const Key('item.compactSave'),
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
