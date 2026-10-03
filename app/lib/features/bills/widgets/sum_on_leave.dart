import 'package:flutter/widgets.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

/// For the override boxes, which take sums ("10000+500", "40000-500"): when
/// focus leaves [child], a finished sum in [controller] is replaced by what
/// it comes to and reported through [onChanged], the way a spreadsheet cell
/// shows its result -- so the box never keeps showing the working once the
/// clerk has moved on. A plain or half-typed entry is left as typed.
class SumOnLeave extends StatelessWidget {
  const SumOnLeave({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.child,
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) => Focus(
    // Listens only: the TextField inside stays the thing that takes focus.
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: (hasFocus) {
      if (hasFocus) return;
      final result = moneySumText(controller.text);
      if (result == null) return;
      controller.value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
      onChanged(result);
    },
    child: child,
  );
}

/// The keypad for a box that takes sums. Android's decimal pad has no "+"
/// on most keyboards (Gboard included); the phone pad has "+" and "-".
const sumKeyboard = TextInputType.phone;
