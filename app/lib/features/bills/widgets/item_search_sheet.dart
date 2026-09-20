import 'package:flutter/material.dart';
import 'package:ledgerly_core/ledgerly_core.dart';

/// Full-screen item search for touch — the phone equivalent of typing into
/// [EntityAutocomplete] and pressing Enter. Pops with the picked [Item], or
/// null if the user backs out without picking one.
class ItemSearchSheet extends StatefulWidget {
  const ItemSearchSheet({super.key, required this.items});
  final List<Item> items;

  static Future<Item?> show(BuildContext context, List<Item> items) {
    return Navigator.of(context).push<Item>(
      MaterialPageRoute(builder: (_) => ItemSearchSheet(items: items)),
    );
  }

  @override
  State<ItemSearchSheet> createState() => _ItemSearchSheetState();
}

class _ItemSearchSheetState extends State<ItemSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.items
        .where((i) => i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('itemSearch.field'),
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search items'),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, i) => ListTile(
          key: Key('itemSearch.result.${matches[i].id}'),
          title: Text(matches[i].name),
          onTap: () => Navigator.of(context).pop(matches[i]),
        ),
      ),
    );
  }
}
