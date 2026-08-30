import 'package:flutter/material.dart';

/// Shows a confirmation dialog before deleting media.
/// Returns true if the user confirmed deletion.
Future<bool> showDeleteConfirmDialog(BuildContext context, {int count = 1}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete?'),
      content: Text(
        count == 1
            ? 'This item will be moved to Trash and removed from your device.'
            : 'These $count items will be moved to Trash and removed from your device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
