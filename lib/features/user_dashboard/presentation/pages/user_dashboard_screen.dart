import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';

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
    );
  }
}

class _KPICard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMenuItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryOrange),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
