import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';

/// User Dashboard Screen - User overview with KPIs and recent orders
class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 520 ? 1 : 2;
    final aspectRatio = crossAxisCount == 1 ? 1.3 : 1.1;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Dashboard'),
        elevation: 0,
        backgroundColor: AppColors.lightBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// KPI Cards
              GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: aspectRatio,
                children: [
                  _KPICard(
                    title: 'Total Orders',
                    value: '24',
                    icon: Icons.shopping_bag_outlined,
                    color: AppColors.primaryOrange,
                  ),
                  _KPICard(
                    title: 'Total Spent',
                    value: '\$856.50',
                    icon: Icons.wallet_giftcard,
                    color: AppColors.success,
                  ),
                  _KPICard(
                    title: 'Loyalty Points',
                    value: '2,540',
                    icon: Icons.star_outlined,
                    color: AppColors.warning,
                  ),
                  _KPICard(
                    title: 'Saved Addresses',
                    value: '3',
                    icon: Icons.location_on_outlined,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// Dashboard Menu
              Text(
                'Account',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _DashboardMenuItem(
                icon: Icons.receipt_long,
                title: 'Order History',
                subtitle: 'View all your orders',
                onTap: () => context.push('/dashboard/orders'),
              ),
              _DashboardMenuItem(
                icon: Icons.favorite_outline,
                title: 'Favorites',
                subtitle: 'Your favorite restaurants',
                onTap: () => context.push('/dashboard/favorites'),
              ),
              _DashboardMenuItem(
                icon: Icons.location_on,
                title: 'Addresses',
                subtitle: 'Manage delivery addresses',
                onTap: () => context.push('/dashboard/addresses'),
              ),
              _DashboardMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Order updates and offers',
                onTap: () => context.push('/dashboard/notifications'),
              ),
              _DashboardMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Account preferences',
                onTap: () => context.push('/dashboard/settings'),
              ),
              const SizedBox(height: 24),

              /// Admin Access
              Text(
                'Admin',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _DashboardMenuItem(
                icon: Icons.admin_panel_settings,
                title: 'Admin Panel',
                subtitle: 'Manage platform',
                onTap: () => context.push('/admin'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedPanelBottomNav(
        items: [
          CurvedNavItemData(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
            isSelected: true,
            onTap: () => context.go('/dashboard'),
          ),
          CurvedNavItemData(
            icon: Icons.travel_explore_outlined,
            selectedIcon: Icons.travel_explore,
            label: 'Browse',
            isSelected: false,
            onTap: () => context.go('/browse'),
          ),
          CurvedNavItemData(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
            label: 'Orders',
            isSelected: false,
            onTap: () => context.go('/dashboard/orders'),
          ),
          CurvedNavItemData(
            icon: Icons.notifications_outlined,
            selectedIcon: Icons.notifications,
            label: 'Alerts',
            isSelected: false,
            onTap: () => context.go('/dashboard/notifications'),
          ),
          CurvedNavItemData(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Settings',
            isSelected: false,
            onTap: () => context.go('/dashboard/settings'),
          ),
        ],
      ),
    );
  }
}

class _KPICard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KPICard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  State<_KPICard> createState() => _KPICardState();
}

class _KPICardState extends State<_KPICard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _hovered ? 1.015 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(_hovered ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.title,
                        style:
                            const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DashboardMenuItem> createState() => _DashboardMenuItemState();
}

class _DashboardMenuItemState extends State<_DashboardMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _hovered ? 1.008 : 1,
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: _hovered ? 3 : 1,
          shadowColor: AppColors.primaryOrange.withOpacity(0.2),
          child: ListTile(
            leading: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _hovered
                    ? AppColors.primaryOrange.withOpacity(0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(widget.icon, color: AppColors.primaryOrange),
            ),
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle:
                Text(widget.subtitle, style: const TextStyle(fontSize: 12)),
            trailing: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              offset: _hovered ? const Offset(0.06, 0) : Offset.zero,
              child: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
