import 'package:flutter/material.dart';

class CurvedNavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CurvedNavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
}

class CurvedPanelBottomNav extends StatelessWidget {
  final List<CurvedNavItemData> items;

  const CurvedPanelBottomNav({
    Key? key,
    required this.items,
  })  : assert(
            items.length == 4, 'CurvedPanelBottomNav expects exactly 4 items.'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBackground = isDark ? const Color(0xFF1F2024) : Colors.white;
    final activeColor = const Color(0xFF7B42F6);
    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF2F2F2F);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: navBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.12),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                  child: _NavItem(
                      item: items[0],
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      isDark: isDark)),
              Expanded(
                  child: _NavItem(
                      item: items[1],
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      isDark: isDark)),
              Expanded(
                  child: _NavItem(
                      item: items[2],
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      isDark: isDark)),
              Expanded(
                  child: _NavItem(
                      item: items[3],
                      activeColor: activeColor,
                      inactiveColor: inactiveColor,
                      isDark: isDark)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final CurvedNavItemData item;
  final Color activeColor;
  final Color inactiveColor;
  final bool isDark;

  const _NavItem({
    required CurvedNavItemData item,
    required Color activeColor,
    required Color inactiveColor,
    required bool isDark,
  })  : item = item,
        activeColor = activeColor,
        inactiveColor = inactiveColor,
        isDark = isDark;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.item.isSelected || _isHovering;
    final color = isActive ? widget.activeColor : widget.inactiveColor;
    final icon =
        widget.item.isSelected ? widget.item.selectedIcon : widget.item.icon;
    final highlightColor = widget.item.isSelected
        ? widget.activeColor.withOpacity(widget.isDark ? 0.24 : 0.14)
        : widget.activeColor.withOpacity(widget.isDark ? 0.14 : 0.08);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.item.onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? highlightColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: widget.item.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
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
