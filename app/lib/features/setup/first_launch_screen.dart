import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/ledgerly_theme.dart';

class FirstLaunchScreen extends ConsumerStatefulWidget {
  const FirstLaunchScreen({super.key});

  @override
  ConsumerState<FirstLaunchScreen> createState() => _FirstLaunchScreenState();
}

class _FirstLaunchScreenState extends ConsumerState<FirstLaunchScreen> {
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = L10n.of(context);
    if (_name.text.trim().isEmpty || _contact.text.trim().isEmpty) {
      setState(
        () =>
            _error = '${l10n.firmName} and ${l10n.contactNumber} are required.',
      );
      return;
    }
    setState(() => _busy = true);
    await ref
        .read(firmCreatorProvider)
        .create(
          name: _name.text.trim(),
          contactNumber: _contact.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = L10n.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _create,
      },
      child: Scaffold(
        backgroundColor: c.paper,
        body: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WELCOME',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                    color: c.ink3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.setupTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(l10n.setupSubtitle, style: TextStyle(color: c.ink2)),
                const SizedBox(height: 22),
                _Field(
                  label: l10n.firmName,
                  child: TextField(
                    key: const Key('setup.firmName'),
                    controller: _name,
                    autofocus: true,
                  ),
                ),
                _Field(
                  label: l10n.contactNumber,
                  child: TextField(
                    key: const Key('setup.contact'),
                    controller: _contact,
                  ),
                ),
                _Field(
                  label: l10n.address,
                  child: TextField(
                    key: const Key('setup.address'),
                    controller: _address,
                    decoration: InputDecoration(hintText: l10n.optional),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: TextStyle(color: c.giveable)),
                  ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _create,
                  style: FilledButton.styleFrom(backgroundColor: c.accent),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.createFirm),
                      const SizedBox(width: 10),
                      Text(
                        'Ctrl+Enter',
                        style: numberStyle.copyWith(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: context.colors.ink2)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
