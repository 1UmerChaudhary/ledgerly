import 'package:flutter/material.dart';

/// Milestone 4 builds the real bill form. This placeholder exists so the
/// shortcuts and routes are wired and testable now.
class BillScreen extends StatelessWidget {
  const BillScreen({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('bill.screen'),
      padding: const EdgeInsets.all(22),
      child: Text(
        'New $type',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}
