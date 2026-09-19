import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

import '../../../theme/ledgerly_theme.dart';

/// Keyboard-first picker. The Enter rule from the spec: while the list is
/// open, Enter picks the highlighted match and nothing else; it never creates.
/// Arrow keys move the highlight; Esc closes the list only.
class EntityAutocomplete<T> extends StatefulWidget {
  const EntityAutocomplete({
    super.key,
    required this.options,
    required this.labelOf,
    required this.onSelected,
    this.trailingOf,
    this.selected,
    this.hint,
    this.fieldKey,
    this.autofocus = false,
    this.onSubmittedWithoutOptions,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final String? Function(T)? trailingOf;
  final void Function(T) onSelected;
  final T? selected;
  final String? hint;
  final Key? fieldKey;
  final bool autofocus;

  /// Enter while the list is closed (e.g. the clerk already picked): lets the
  /// parent treat Enter as "next cell".
  final VoidCallback? onSubmittedWithoutOptions;

  @override
  State<EntityAutocomplete<T>> createState() => _EntityAutocompleteState<T>();
}

class _EntityAutocompleteState<T> extends State<EntityAutocomplete<T>> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _link = LayerLink();
  final _overlay = OverlayPortalController();
  List<T> _matches = const [];
  int _highlight = 0;
  bool _typing = false;

  @override
  void initState() {
    super.initState();
    if (widget.selected != null) {
      _controller.text = widget.labelOf(widget.selected as T);
    }
    _focus.addListener(() {
      if (!_focus.hasFocus && mounted) _close();
    });
  }

  @override
  void didUpdateWidget(covariant EntityAutocomplete<T> old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected &&
        widget.selected != null &&
        !_typing) {
      _controller.text = widget.labelOf(widget.selected as T);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search(String query) {
    _typing = true;
    final byLabel = {for (final o in widget.options) widget.labelOf(o): o};
    final hits = fuzzySearch(
      query,
      byLabel.keys,
    ).map((h) => byLabel[h.value]!).toList();
    setState(() {
      _matches = query.trim().isEmpty ? const [] : hits.take(8).toList();
      _highlight = 0;
    });
    _matches.isEmpty ? _close() : _overlay.show();
  }

  void _pick(T option) {
    _typing = false;
    _controller.text = widget.labelOf(option);
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _close();
    widget.onSelected(option);
  }

  void _close() {
    if (!mounted) return;
    if (_overlay.isShowing) _overlay.hide();
    setState(() => _matches = const []);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final k = event.logicalKey;
    final open = _matches.isNotEmpty;
    if (open && k == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlight = (_highlight + 1) % _matches.length);
      return KeyEventResult.handled;
    }
    if (open && k == LogicalKeyboardKey.arrowUp) {
      setState(
        () => _highlight = (_highlight - 1 + _matches.length) % _matches.length,
      );
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      if (HardwareKeyboard.instance.isControlPressed) {
        return KeyEventResult.ignored; // Ctrl+Enter = save
      }
      if (open) {
        _pick(_matches[_highlight]);
      } else {
        widget.onSubmittedWithoutOptions?.call();
      }
      return KeyEventResult.handled;
    }
    if (open && k == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlay,
        overlayChildBuilder: (context) => Positioned(
          width: 320,
          child: CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(4),
              color: c.surface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _matches.length; i++)
                    InkWell(
                      onTap: () => _pick(_matches[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: i == _highlight ? c.selection : null,
                          border: Border(
                            left: BorderSide(
                              color: i == _highlight
                                  ? c.accent
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.labelOf(_matches[i]),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            if (widget.trailingOf?.call(_matches[i])
                                case final t?)
                              Text(
                                t,
                                style: numberStyle.copyWith(
                                  fontSize: 12.5,
                                  color: c.ink2,
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
        ),
        child: Focus(
          onKeyEvent: _onKey,
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            focusNode: _focus,
            autofocus: widget.autofocus,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: widget.hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
