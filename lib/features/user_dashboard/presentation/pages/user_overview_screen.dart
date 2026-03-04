import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/stat_card.dart';
import '../../../../presentation/widgets/chart_card.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../../data/datasources/mock_data_service.dart';
import '../widgets/user_dashboard_sidebar.dart';

/// User Dashboard Overview Screen
class UserOverviewScreen extends StatelessWidget {
  const UserOverviewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orders = MockDataService.generateMockOrders();
    final restaurants = MockDataService.restaurants.take(3).toList();
    final kpi = MockDataService.getMockUserKPI();
    final isMobile = MediaQuery.of(context).size.width < 900;

    final content = CustomScrollView(
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
                'My Dashboard',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Welcome back, Emma!',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            ],
          ),
        ),
        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WelcomeBanner(onOrderNow: () => context.go('/browse')),
              const SizedBox(height: 16),
              // KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const crossAxisCount = 2;
                  final cardAspectRatio = width < 380
                      ? 0.82
                      : width < 560
                          ? 0.95
                          : 1.0;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: cardAspectRatio,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      StatCard(
                        title: 'Total Orders',
                        value: '${kpi.totalOrders}',
                        icon: Icons.shopping_bag,
                        change: 12,
                        index: 0,
                      ),
                      StatCard(
                        title: 'Total Spent',
                        value: '\$${kpi.totalSpent.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        change: 8.5,
                        index: 1,
                      ),
                      StatCard(
                        title: 'Loyalty Points',
                        value: '${kpi.loyaltyPoints}',
                        icon: Icons.card_giftcard,
                        change: 22,
                        index: 2,
                      ),
                      StatCard(
                        title: 'Saved Addresses',
                        value: '${kpi.savedAddresses}',
                        icon: Icons.location_on,
                        index: 3,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 1100;
                  final spending = _buildSpendingOverview(theme);
                  final quickActions = _buildQuickActions(context, theme);

                  if (isNarrow) {
                    return Column(
                      children: [
                        spending,
                        const SizedBox(height: 16),
                        quickActions,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: spending),
                      const SizedBox(width: 16),
                      Expanded(child: quickActions),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 1100;
                  final recent = _buildRecentOrdersSection(orders, theme);
                  final favorites =
                      _buildFavoriteRestaurantsSection(restaurants, theme);

                  if (isNarrow) {
                    return Column(
                      children: [
                        recent,
                        const SizedBox(height: 16),
                        favorites,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: recent),
                      const SizedBox(width: 16),
                      Expanded(child: favorites),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildSavedAddresses(theme),
            ]),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        drawer: const Drawer(
          child: SafeArea(
            child: UserDashboardSidebar(
              currentRoute: '/dashboard',
              compact: true,
            ),
          ),
        ),
        body: content,
        bottomNavigationBar: CurvedPanelBottomNav(
          items: [
            CurvedNavItemData(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: false,
              onTap: () => context.go('/'),
            ),
            CurvedNavItemData(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              label: 'Orders',
              isSelected: false,
              onTap: () => context.go('/dashboard/orders'),
            ),
            CurvedNavItemData(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: 'Panel',
              isSelected: true,
              onTap: () => context.go('/dashboard'),
            ),
            CurvedNavItemData(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              label: 'Settings',
              isSelected: false,
              onTap: () => context.go('/dashboard/settings'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const UserDashboardSidebar(currentRoute: '/dashboard'),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildSpendingOverview(ThemeData theme) {
    return ChartCard(
      title: 'Spending Overview',
      subtitle: 'Last 6 months',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '↗ +18.2%',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: _SpendingLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    final actions = [
      ('Browse Restaurants', Icons.restaurant_menu, '/browse'),
      ('Order History', Icons.history, '/dashboard/orders'),
      ('My Favorites', Icons.favorite_border, '/dashboard/favorites'),
    ];

    return ChartCard(
      title: 'Quick Actions',
      subtitle: 'Shortcuts',
      child: Column(
        children: actions
            .map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.$2, color: theme.primaryColor, size: 18),
                ),
                title: Text(item.$1),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(item.$3),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildRecentOrdersSection(List orders, ThemeData theme) {
    final recent = orders.take(4).toList();

    return ChartCard(
      title: 'Recent Orders',
      subtitle: 'Latest activity',
      child: Column(
        children: List.generate(recent.length, (index) {
          final order = recent[index];
          return Container(
            margin:
                EdgeInsets.only(bottom: index == recent.length - 1 ? 0 : 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.restaurant,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      Text(
                        order.items.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusPill(status: order.status),
                    const SizedBox(height: 6),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 350),
                delay: Duration(milliseconds: index * 40),
              );
        }),
      ),
    );
  }

  Widget _buildFavoriteRestaurantsSection(List restaurants, ThemeData theme) {
    return ChartCard(
      title: 'Favorite Restaurants',
      subtitle: 'Top picks',
      child: Column(
        children: List.generate(restaurants.length, (index) {
          final restaurant = restaurants[index];
          return Container(
            margin: EdgeInsets.only(
                bottom: index == restaurants.length - 1 ? 0 : 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    restaurant.image,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        restaurant.cuisine.split('•').first.trim(),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 18),
                    const SizedBox(width: 4),
                    Text('${restaurant.rating}'),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSavedAddresses(ThemeData theme) {
    final addresses = const [
      ('Home', '123 Main Street, Apt 4B, New York, NY 10001', true),
      ('Work', '456 Business Ave, Floor 12, New York, NY 10016', false),
      ('Mom\'s Place', '789 Oak Lane, Brooklyn, NY 11201', false),
    ];

    return ChartCard(
      title: 'Saved Addresses',
      subtitle: 'Manage destinations',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width > 1300
              ? 3
              : width > 800
                  ? 2
                  : 1;
          final childAspectRatio = crossAxisCount == 1
              ? (width < 420 ? 2.15 : 2.5)
              : (width > 1200 ? 2.8 : 2.45);

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: addresses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: address.$3
                      ? const Color(0xFFFF8A00).withOpacity(0.06)
                      : (theme.brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: address.$3
                        ? const Color(0xFFFF8A00).withOpacity(0.4)
                        : theme.dividerColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: Color(0xFFFF6B35)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            address.$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (address.$3) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFFF6B35).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'DEFAULT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFFF6B35),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address.$2,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final VoidCallback onOrderNow;

  const _WelcomeBanner({required this.onOrderNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFFA319)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good afternoon, Emma! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You have 2 unread notifications and 2,450 loyalty points to redeem.',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onOrderNow,
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Order Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'on_the_way'
        ? Colors.orange
        : normalized == 'delivered'
            ? Colors.green
            : Colors.amber.shade700;

    final label = normalized.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '• ${label[0].toUpperCase()}${label.substring(1)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SpendingLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const values = [90.0, 120.0, 100.0, 180.0, 140.0, 165.0];

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 5,
        minY: 40,
        maxY: 200,
        gridData: FlGridData(
          horizontalInterval: 45,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.2),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                '\$${value.toInt()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                final i = value.toInt();
                if (i < 0 || i >= labels.length) {
                  return const SizedBox.shrink();
                }
                return Text(labels[i]);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              values.length,
              (i) => FlSpot(i.toDouble(), values[i]),
            ),
            isCurved: true,
            color: const Color(0xFFFF6B00),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFFF6B00).withOpacity(0.12),
            ),
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
