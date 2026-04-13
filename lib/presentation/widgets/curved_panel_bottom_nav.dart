import 'dart:ui';

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
            items.length >= 2,
            'CurvedPanelBottomNav expects at least 2 items.',
          ),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedIndex = items.indexWhere((item) => item.isSelected);
    final effectiveSelectedIndex = selectedIndex < 0 ? 0 : selectedIndex;

    final navBackground = isDark
        ? Colors.black.withOpacity(0.68)
        : Colors.white.withOpacity(0.76);
    const gradientStart = Color(0xFF3B82F6);
    const gradientEnd = Color(0xFF8B5CF6);
    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: navBackground,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.10)
                      : Colors.white.withOpacity(0.72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.34 : 0.12),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: gradientEnd.withOpacity(isDark ? 0.22 : 0.12),
                    blurRadius: 26,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / items.length;
                  final indicatorWidth = itemWidth * 0.52;
                  final indicatorLeft = (itemWidth * effectiveSelectedIndex) +
                      ((itemWidth - indicatorWidth) / 2);

                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        left: indicatorLeft,
                        bottom: 6,
                        child: Container(
                          width: indicatorWidth,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [gradientStart, gradientEnd],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: gradientEnd.withOpacity(0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (final item in items)
                            Expanded(
                              child: _NavItem(
                                key: ValueKey(item.label),
                                item: item,
                                activeGradient: const [gradientStart, gradientEnd],
                                inactiveColor: inactiveColor,
                                isDark: isDark,
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final CurvedNavItemData item;
  final List<Color> activeGradient;
  final Color inactiveColor;
  final bool isDark;

  const _NavItem({
    super.key,
    required CurvedNavItemData item,
    required List<Color> activeGradient,
    required Color inactiveColor,
    required bool isDark,
  })  : item = item,
      activeGradient = activeGradient,
        inactiveColor = inactiveColor,
        isDark = isDark;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.item.isSelected || _isHovering;
    final color = isActive ? Colors.white : widget.inactiveColor;
    final icon =
        widget.item.isSelected ? widget.item.selectedIcon : widget.item.icon;
    final highlightOpacity = widget.item.isSelected ? 0.26 : 0.18;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          radius: 30,
          splashColor: widget.activeGradient.first.withOpacity(0.20),
          highlightColor: widget.activeGradient.last.withOpacity(0.12),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.item.onTap,
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              scale: _isPressed
                  ? 0.92
                  : isActive
                      ? 1.08
                      : 1,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 180),
                offset: isActive ? const Offset(0, -0.03) : Offset.zero,
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? LinearGradient(
                            colors: widget.activeGradient
                                .map((color) =>
                                    color.withOpacity(highlightOpacity))
                                .toList(),
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? widget.activeGradient.last.withOpacity(0.36)
                          : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color:
                                  widget.activeGradient.last.withOpacity(0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : const [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.88, end: 1)
                                  .animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Icon(
                          icon,
                          key: ValueKey(icon.codePoint),
                          size: 22,
                          color: color,
                        ),
                      ),
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
          ),
        ),
      ),
    );
  }
}
