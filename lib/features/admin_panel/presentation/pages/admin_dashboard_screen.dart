import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/stat_card.dart';
import '../../../../presentation/widgets/chart_card.dart';
import '../../../../presentation/widgets/status_badge.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../../data/datasources/mock_data_service.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Dashboard - Main overview screen with KPIs and stats
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = MockDataService.generateMockOrders().take(6).toList();
    final isMobile = MediaQuery.of(context).size.width < 900;

    Widget buildContent() {
      return CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            automaticallyImplyLeading: isMobile,
            floating: true,
            backgroundColor: theme.cardColor,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Welcome back, Admin',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isTiny = width < 430;
                    final crossAxisCount = width > 1400
                        ? 5
                        : width > 1100
                            ? 4
                            : width > 820
                                ? 3
                                : 2;

                    final childAspectRatio = crossAxisCount >= 4
                        ? 1.05
                        : crossAxisCount == 3
                            ? 1.0
                            : isTiny
                                ? 0.84
                                : 0.98;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        StatCard(
                          title: 'Total Users',
                          value: '2,847',
                          change: 12.5,
                          icon: Icons.people,
                          index: 0,
                        ),
                        StatCard(
                          title: 'Total Orders',
                          value: '5,328',
                          change: 8.3,
                          icon: Icons.shopping_bag,
                          index: 1,
                        ),
                        StatCard(
                          title: 'Revenue Today',
                          value: '\$3,240',
                          change: 15.2,
                          icon: Icons.attach_money,
                          index: 2,
                        ),
                        StatCard(
                          title: 'Monthly Revenue',
                          value: '\$82.5K',
                          change: -2.1,
                          icon: Icons.trending_up,
                          index: 3,
                        ),
                        StatCard(
                          title: 'Active Restaurants',
                          value: '156',
                          change: 5.0,
                          icon: Icons.restaurant,
                          index: 4,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Recent Orders Section
                ChartCard(
                  title: 'Recent Orders',
                  subtitle: 'Latest activity',
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Order ID')),
                            DataColumn(label: Text('Customer')),
                            DataColumn(label: Text('Restaurant')),
                            DataColumn(label: Text('Total')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Date')),
                          ],
                          rows: orders.map((order) {
                            return DataRow(
                              cells: [
                                DataCell(Text('#${order.id.substring(0, 6)}')),
                                DataCell(Text(order.userName)),
                                DataCell(Text(order.restaurant)),
                                DataCell(Text(
                                    '\$${order.total.toStringAsFixed(2)}')),
                                DataCell(StatusBadge(status: order.status)),
                                DataCell(Text(order.date)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Management Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isTiny = width < 430;
                    final crossAxisCount = width > 1250
                        ? 4
                        : width > 900
                            ? 3
                            : 2;

                    final childAspectRatio = crossAxisCount >= 4
                        ? 1.15
                        : crossAxisCount == 3
                            ? 1.08
                            : isTiny
                                ? 0.9
                                : 1.02;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: isTiny ? 12 : 16,
                      crossAxisSpacing: isTiny ? 12 : 16,
                      children: [
                        _AdminActionCard(
                          icon: Icons.people,
                          title: 'User Management',
                          subtitle: '2,847 users',
                          onTap: () {
                            context.go('/admin/users');
                          },
                        ),
                        _AdminActionCard(
                          icon: Icons.restaurant,
                          title: 'Restaurants',
                          subtitle: '156 restaurants',
                          onTap: () {
                            context.go('/admin/restaurant-panel');
                          },
                        ),
                        _AdminActionCard(
                          icon: Icons.local_shipping,
                          title: 'Deliveries',
                          subtitle: '84 active',
                          onTap: () {
                            context.go('/admin/deliveries');
                          },
                        ),
                        _AdminActionCard(
                          icon: Icons.card_giftcard,
                          title: 'Coupons',
                          subtitle: '23 campaigns',
                          onTap: () {
                            context.go('/admin/coupons');
                          },
                        ),
                      ],
                    );
                  },
                ),
              ]),
            ),
          ),
        ],
      );
    }

    if (isMobile) {
      return Scaffold(
        drawer: const Drawer(
          child: SafeArea(
            child: AdminSidebar(
              currentRoute: '/admin',
              compact: true,
            ),
          ),
        ),
        body: buildContent(),
        bottomNavigationBar: CurvedPanelBottomNav(
          items: [
            CurvedNavItemData(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: 'Dashboard',
              isSelected: true,
              onTap: () => context.go('/admin'),
            ),
            CurvedNavItemData(
              icon: Icons.people_outline,
              selectedIcon: Icons.people,
              label: 'Users',
              isSelected: false,
              onTap: () => context.go('/admin/users'),
            ),
            CurvedNavItemData(
              icon: Icons.local_shipping_outlined,
              selectedIcon: Icons.local_shipping,
              label: 'Delivery',
              isSelected: false,
              onTap: () => context.go('/admin/deliveries'),
            ),
            CurvedNavItemData(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
              isSelected: false,
              onTap: () => context.go('/admin/settings'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/admin'),
          Expanded(child: buildContent()),
        ],
      ),
    );
  }
}

/// Admin Action Card for navigation
class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 170;

          return Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                )
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 10 : 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: compact ? 48 : 60,
                    height: compact ? 48 : 60,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(compact ? 14 : 16),
                    ),
                    child: Icon(
                      icon,
                      color: theme.primaryColor,
                      size: compact ? 24 : 32,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 13 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: compact ? 11 : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 300),
        );
  }
}
