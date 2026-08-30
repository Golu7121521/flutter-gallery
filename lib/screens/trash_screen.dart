import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../providers/trash_provider.dart';
import '../widgets/media_grid.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trash = context.watch<TrashProvider>();
    final assets = trash.items.map((e) => e.asset).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash bin'),
        actions: [
          if (assets.isNotEmpty)
            TextButton(
              onPressed: () => _confirmEmptyTrash(context),
              child: const Text('Empty'),
            ),
        ],
      ),
      body: assets.isEmpty
          ? Center(
              child: Text(
                'Trash is empty',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  padding: const EdgeInsets.all(12),
                  child: const Text(
                    'Items are permanently removed from Trash automatically '
                    'once deleted from your device. Restore to bring them back to Gallery.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(child: MediaGrid(assets: assets)),
              ],
            ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty trash?'),
        content: const Text(
            'This will permanently delete all items currently in the trash from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final trashProvider = ctx.read<TrashProvider>();
              final ids = trashProvider.items.map((e) => e.asset.id).toList();
              await PhotoManager.editor.deleteWithIds(ids);
              trashProvider.clear();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
  }
}
