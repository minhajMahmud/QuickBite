import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

final ValueNotifier<bool> _adminSidebarCollapsed = ValueNotifier<bool>(false);

/// Admin Panel Sidebar Navigation
class AdminSidebar extends ConsumerWidget {
  final String currentRoute;
  final bool compact;

  const AdminSidebar({
    Key? key,
    required this.currentRoute,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allowCollapse = !compact;

    return ValueListenableBuilder<bool>(
      valueListenable: _adminSidebarCollapsed,
      builder: (context, collapsedValue, _) {
        if (compact && collapsedValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_adminSidebarCollapsed.value) {
              _adminSidebarCollapsed.value = false;
            }
          });
        }

        final collapsed = allowCollapse ? collapsedValue : false;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: compact ? double.infinity : (collapsed ? 84 : 280),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(
              right: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Logo Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Q',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 12),
                      Text(
                        'QuickBite',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Admin Panel Label
              if (!collapsed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Navigation Items
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
                  child: Column(
                    children: [
                      _NavItem(
                        icon: Icons.dashboard,
                        label: 'Overview',
                        route: '/admin',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin'),
                      ),
                      _NavItem(
                        icon: Icons.people,
                        label: 'Users',
                        route: '/admin/users',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin/users'),
                      ),
                      _NavItem(
                        icon: Icons.restaurant,
                        label: 'Restaurants',
                        route: '/admin/restaurants',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin/restaurants'),
                      ),
                      _NavItem(
                        icon: Icons.local_shipping,
                        label: 'Deliveries',
                        route: '/admin/deliveries',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin/deliveries'),
                      ),
                      _NavItem(
                        icon: Icons.local_offer,
                        label: 'Coupons',
                        route: '/admin/coupons',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin/coupons'),
                      ),
                      _NavItem(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        route: '/admin/analytics',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin/analytics'),
                      ),
                      _NavItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        route: '/admin/settings',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () => context.go('/admin/settings'),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Actions
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _NavItem(
                      icon: isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      route: '',
                      currentRoute: currentRoute,
                      collapsed: collapsed,
                      onTap: () {
                        ref.read(themeModeProvider.notifier).toggle();
                      },
                    ),
                    const SizedBox(height: 8),
                    _NavItem(
                      icon: Icons.logout,
                      label: 'Logout',
                      route: '',
                      currentRoute: currentRoute,
                      collapsed: collapsed,
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                      },
                    ),
                    const SizedBox(height: 8),
                    _NavItem(
                      icon: Icons.arrow_back,
                      label: 'Back to App',
                      route: '',
                      currentRoute: currentRoute,
                      collapsed: collapsed,
                      onTap: () => context.go('/'),
                    ),
                    if (allowCollapse) ...[
                      const SizedBox(height: 8),
                      _NavItem(
                        icon: collapsed
                            ? Icons.chevron_right
                            : Icons.chevron_left,
                        label: collapsed ? 'Expand' : 'Collapse',
                        route: '',
                        currentRoute: currentRoute,
                        collapsed: collapsed,
                        onTap: () {
                          _adminSidebarCollapsed.value =
                              !_adminSidebarCollapsed.value;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentRoute == route;

    final item = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isActive ? Colors.orange : Colors.transparent,
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
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[800],
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!collapsed) return item;

    return Tooltip(message: label, child: item);
  }
}
