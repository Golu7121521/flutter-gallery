import 'package:flutter/material.dart';

/// A pill shaped floating tab bar shown at the bottom of the Home screen.
/// Has 4 tabs (Recent / Photos / Videos / Favorites) plus a separate
/// three-dot button to the right that opens a menu (Trash, Settings, About).
class FloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMenuTap;

  const FloatingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onMenuTap,
  });

  static const _tabs = [
    _TabData(icon: Icons.access_time_filled_rounded, label: 'Recent'),
    _TabData(icon: Icons.image_rounded, label: 'Photos'),
    _TabData(icon: Icons.videocam_rounded, label: 'Videos'),
    _TabData(icon: Icons.favorite_rounded, label: 'Favorites'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xE61C1C22) : const Color(0xE6FFFFFF);
    final shadowColor = Colors.black.withOpacity(isDark ? 0.4 : 0.12);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 2, bottom: 4),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                          color: shadowColor, blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_tabs.length, (i) {
                      final selected = i == currentIndex;
                      return _buildTab(context, i, selected, isDark);
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: shadowColor, blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: IconButton(
                  onPressed: onMenuTap,
                  icon: Icon(Icons.more_vert_rounded,
                      color: isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, int index, bool selected, bool isDark) {
    final tab = _tabs[index];
    final activeColor = index == 3 && selected
        ? Colors.redAccent
        : Theme.of(context).colorScheme.primary;
    final inactiveColor = isDark ? Colors.white54 : Colors.black45;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
        constraints: const BoxConstraints(minWidth: 44),
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 20, color: selected ? activeColor : inactiveColor),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabData {
  final IconData icon;
  final String label;
  const _TabData({required this.icon, required this.label});
}
