import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/ledgerly_theme.dart';

/// Typed date, dd/MM/yyyy. T = today, Up/Down = ±1 day, PgUp/PgDn = ±1 month.
/// Reports ISO yyyy-MM-dd, the only form the database accepts.
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.iso,
    required this.onChanged,
    this.fieldKey,
  });
  final String iso;
  final void Function(String iso) onChanged;
  final Key? fieldKey;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late final _controller = TextEditingController(text: _display(widget.iso));
  bool _invalid = false;

  static String _display(String iso) {
    final p = iso.split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
  }

  static String? _toIso(String text) {
    final m = RegExp(r'^\s*(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})\s*$')
        .firstMatch(text);
    if (m == null) return null;
    final d = int.parse(m[1]!), mo = int.parse(m[2]!), y = int.parse(m[3]!);
    final date = DateTime(y, mo, d);
    if (date.month != mo || date.day != d) return null;
    return '$y-${mo.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  void _shift({int days = 0, int months = 0}) {
    final base = DateTime.tryParse(widget.iso) ?? DateTime.now();
    final next = DateTime(base.year, base.month + months, base.day + days);
    _set(
      '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}',
    );
  }

  void _set(String iso) {
    _controller.text = _display(iso);
    setState(() => _invalid = false);
    widget.onChanged(iso);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.keyT) {
      final n = DateTime.now();
      _set(
        '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}',
      );
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowUp) {
      _shift(days: 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowDown) {
      _shift(days: -1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.pageUp) {
      _shift(months: 1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.pageDown) {
      _shift(months: -1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Focus(
      onKeyEvent: _onKey,
      child: TextField(
        key: widget.fieldKey,
        controller: _controller,
        style: numberStyle.copyWith(fontSize: 14),
        onChanged: (v) {
          final iso = _toIso(v);
          setState(() => _invalid = iso == null);
          if (iso != null) widget.onChanged(iso);
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          suffixText: 'T',
          suffixStyle: numberStyle.copyWith(fontSize: 11, color: c.ink3),
          errorText: _invalid ? 'dd/mm/yyyy' : null,
        ),
      ),
    );
  }
}
