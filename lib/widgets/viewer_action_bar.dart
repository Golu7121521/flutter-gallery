import 'package:flutter/material.dart';

/// Transparent bottom bar with icon-only buttons shown while viewing a
/// photo or video: Share, Edit, Favorite, Delete, More.
class ViewerActionBar extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onFavorite;
  final bool isFavorite;
  final VoidCallback onDelete;
  final VoidCallback onMore;

  const ViewerActionBar({
    super.key,
    required this.onShare,
    required this.onEdit,
    required this.onFavorite,
    required this.isFavorite,
    required this.onDelete,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(icon: Icons.share_rounded, label: 'Share', onTap: onShare),
            _ActionButton(icon: Icons.tune_rounded, label: 'Edit', onTap: onEdit),
            _ActionButton(
              icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: 'Favorite',
              iconColor: isFavorite ? Colors.redAccent : Colors.white,
              onTap: onFavorite,
            ),
            _ActionButton(icon: Icons.delete_outline_rounded, label: 'Delete', onTap: onDelete),
            _ActionButton(icon: Icons.more_vert_rounded, label: 'More', onTap: onMore),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
