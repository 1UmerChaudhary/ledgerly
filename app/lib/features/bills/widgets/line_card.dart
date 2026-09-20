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
            SegmentedButton<SaleMode>(
              key: Key('bill.line.$index.card.modeToggle'),
              segments: const [
                ButtonSegment(value: SaleMode.byBags, label: Text('Bags')),
                ButtonSegment(value: SaleMode.byWeight, label: Text('Weight')),
                ButtonSegment(value: SaleMode.byCount, label: Text('Count')),
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
    return TextFormField(
      key: Key('bill.line.$index.card.$field'),
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onEdit(field, v),
    );
  }
}
