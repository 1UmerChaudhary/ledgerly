import 'package:flutter/material.dart';

import '../../bills/widgets/date_field.dart';

class PrintRange {
  const PrintRange({this.fromDate, this.toDate});
  final String? fromDate;
  final String? toDate;
}

/// Asks how far back to print, exactly as the spec requires before any
/// ledger print or export: the whole history, this calendar month, or two
/// typed dates.
Future<PrintRange?> showPrintRangeDialog(BuildContext context) {
  return showDialog<PrintRange>(
    context: context,
    builder: (context) => const _PrintRangeDialog(),
  );
}

class _PrintRangeDialog extends StatefulWidget {
  const _PrintRangeDialog();

  @override
  State<_PrintRangeDialog> createState() => _PrintRangeDialogState();
}

class _PrintRangeDialogState extends State<_PrintRangeDialog> {
  bool _custom = false;
  String _from = _isoToday();
  String _to = _isoToday();

  static String _isoToday() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String _firstOfThisMonth() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-01';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('printRange.dialog'),
      title: const Text('Print ledger'),
      content: _custom
          ? SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('From'),
                  DateField(
                    fieldKey: const Key('printRange.fromDate'),
                    iso: _from,
                    onChanged: (v) => setState(() => _from = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('To'),
                  DateField(
                    fieldKey: const Key('printRange.toDate'),
                    iso: _to,
                    onChanged: (v) => setState(() => _to = v),
                  ),
                ],
              ),
            )
          : const Text('How far back should this print go?'),
      actions: _custom
          ? [
              TextButton(
                onPressed: () => setState(() => _custom = false),
                child: const Text('Back'),
              ),
              FilledButton(
                key: const Key('printRange.go'),
                onPressed: () => Navigator.pop(
                  context,
                  PrintRange(fromDate: _from, toDate: _to),
                ),
                child: const Text('Print'),
              ),
            ]
          : [
              TextButton(
                key: const Key('printRange.all'),
                onPressed: () => Navigator.pop(context, const PrintRange()),
                child: const Text('All'),
              ),
              TextButton(
                key: const Key('printRange.thisMonth'),
                onPressed: () => Navigator.pop(
                  context,
                  PrintRange(
                    fromDate: _firstOfThisMonth(),
                    toDate: _isoToday(),
                  ),
                ),
                child: const Text('This month'),
              ),
              TextButton(
                key: const Key('printRange.custom'),
                onPressed: () => setState(() => _custom = true),
                child: const Text('Custom'),
              ),
            ],
    );
  }
}
