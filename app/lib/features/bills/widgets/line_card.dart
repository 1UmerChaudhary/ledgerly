import 'package:flutter/material.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../bill_draft.dart';
import 'item_search_sheet.dart';

/// Touch equivalent of a grid row: one line of a bill as a tappable card
/// instead of Tab/Enter-driven cells. Calls the exact same
/// [BillDraftController] mutation methods the desktop grid calls — this
/// widget owns no state of its own beyond text-field controllers.
class LineCard extends StatelessWidget {
  const LineCard({
    super.key,
    required this.index,
    required this.line,
    required this.items,
    required this.onPickItem,
    required this.onEdit,
    required this.onToggleMode,
    required this.onDelete,
  });

  final int index;
  final LineDraft line;
  final List<Item> items;
  final void Function(Item) onPickItem;
  final void Function(String field, String value) onEdit;
  final VoidCallback onToggleMode;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('bill.line.$index.card'),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: Key('bill.line.$index.card.itemButton'),
                    onPressed: () async {
                      final picked = await ItemSearchSheet.show(context, items);
                      if (picked != null) onPickItem(picked);
                    },
                    child: Text(line.item?.name ?? 'Pick item'),
                  ),
                ),
                IconButton(
                  key: Key('bill.line.$index.card.deleteButton'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            // Bags/Weight only — byCount is a phase-5 placeholder not wired
            // into any UI yet (desktop's _ModeCell doesn't offer it either,
            // and BillDraftController.toggleMode only flips bags<->weight).
            SegmentedButton<SaleMode>(
              key: Key('bill.line.$index.card.modeToggle'),
              segments: const [
                ButtonSegment(value: SaleMode.byBags, label: Text('Bags')),
                ButtonSegment(value: SaleMode.byWeight, label: Text('Weight')),
              ],
              selected: {line.mode},
              onSelectionChanged: (_) => onToggleMode(),
            ),
            if (line.mode == SaleMode.byBags) ...[
              _numberField('bags', 'Bags', line.bags),
              _numberField('bagKg', 'Bag weight (kg)', line.bagKg),
            ] else if (line.mode == SaleMode.byWeight)
              _numberField('totalKg', 'Total weight (kg)', line.totalKg),
            Wrap(
              spacing: 6,
              children: [
                for (final preset in RateBase.presets)
                  ActionChip(
                    key: Key(
                      'bill.line.$index.card.basePreset.${preset.grams}',
                    ),
                    label: Text('${preset.grams / 1000}kg'),
                    onPressed: () =>
                        onEdit('base', (preset.grams / 1000).toString()),
                  ),
              ],
            ),
            _numberField('rate', 'Rate', line.rate),
          ],
        ),
      ),
    );
  }

  Widget _numberField(String field, String label, String value) {
    return _LineCardNumberField(
      fieldKey: Key('bill.line.$index.card.$field'),
      label: label,
      value: value,
      onChanged: (v) => onEdit(field, v),
    );
  }
}

/// Same fix as the desktop grid's `_CellField` (bill_screen.dart): a plain
/// `TextFormField(initialValue: ...)` only honours `initialValue` on first
/// build, so an external change (e.g. pickItem auto-filling bagKg from the
/// item's default) never reaches the screen even though [LineDraft] state is
/// correct underneath. Retaining the controller and pushing external value
/// changes into it in [didUpdateWidget] mirrors `_CellField`'s pattern
/// exactly.
class _LineCardNumberField extends StatefulWidget {
  const _LineCardNumberField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final Key fieldKey;
  final String label;
  final String value;
  final void Function(String) onChanged;

  @override
  State<_LineCardNumberField> createState() => _LineCardNumberFieldState();
}

class _LineCardNumberFieldState extends State<_LineCardNumberField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant _LineCardNumberField old) {
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
    key: widget.fieldKey,
    controller: _controller,
    decoration: InputDecoration(labelText: widget.label),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: widget.onChanged,
  );
}
