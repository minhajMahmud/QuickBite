import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

final ValueNotifier<bool> _userSidebarCollapsed = ValueNotifier<bool>(false);

/// User Dashboard Sidebar Navigation
class UserDashboardSidebar extends ConsumerWidget {
  final String currentRoute;
  final bool compact;

  const UserDashboardSidebar({
    Key? key,
    required this.currentRoute,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allowCollapse = !compact;
    final showSideToggle =
        allowCollapse && MediaQuery.of(context).size.width >= 900;

    return ValueListenableBuilder<bool>(
      valueListenable: _userSidebarCollapsed,
      builder: (context, collapsed, _) {
        final effectiveCollapsed = allowCollapse ? collapsed : false;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width:
                  compact ? double.infinity : (effectiveCollapsed ? 72 : 300),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  right: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Logo Header
                  Container(
                    padding: EdgeInsets.all(effectiveCollapsed ? 12 : 24),
                    child: Row(
                      mainAxisAlignment: effectiveCollapsed
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Q',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (!effectiveCollapsed) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'QuickBite',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // MY ACCOUNT Section
                  if (!effectiveCollapsed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MY ACCOUNT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFFF6B35),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                          horizontal: effectiveCollapsed ? 8 : 12),
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.grid_view_rounded,
                          label: 'Overview',
                          route: '/dashboard',
                          collapsed: effectiveCollapsed,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.shopping_bag_outlined,
                          label: 'Orders',
                          route: '/dashboard/orders',
                          collapsed: effectiveCollapsed,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.favorite_border,
                          label: 'Favorites',
                          route: '/dashboard/favorites',
                          collapsed: effectiveCollapsed,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.location_on_outlined,
                          label: 'Addresses',
                          route: '/dashboard/addresses',
                          collapsed: effectiveCollapsed,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          route: '/dashboard/notifications',
                          collapsed: effectiveCollapsed,
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          route: '/dashboard/settings',
                          collapsed: effectiveCollapsed,
                        ),
                      ],
                    ),
                  ),

                  // Bottom Actions
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.all(effectiveCollapsed ? 8 : 12),
                    child: Column(
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.logout,
                          label: 'Logout',
                          collapsed: effectiveCollapsed,
                          onTap: () {
                            ref.read(authProvider.notifier).logout();
                            context.go('/login');
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          context,
                          icon: Icons.arrow_back,
                          label: 'Back to App',
                          collapsed: effectiveCollapsed,
                          onTap: () => context.go('/'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showSideToggle)
              Positioned(
                right: -14,
                top: 96,
                child: Material(
                  color: theme.cardColor,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      _userSidebarCollapsed.value =
                          !_userSidebarCollapsed.value;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        effectiveCollapsed
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool collapsed,
  }) {
    final theme = Theme.of(context);
    final isSelected = currentRoute == route;

    final menuItem = Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF6B35) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: collapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!collapsed) return menuItem;
    return Tooltip(message: label, child: menuItem);
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool collapsed,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    final actionButton = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 16, vertical: 12),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.textTheme.bodySmall?.color,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!collapsed) return actionButton;
    return Tooltip(message: label, child: actionButton);
  }
}
