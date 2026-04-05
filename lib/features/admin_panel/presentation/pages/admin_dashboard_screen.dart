import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/stat_card.dart';
import '../../../../presentation/widgets/chart_card.dart';
import '../../../../presentation/widgets/status_badge.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../widgets/admin_sidebar.dart';

/// Admin Dashboard - Main overview screen with KPIs and stats
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _error;
  int _totalUsers = 0;
  int _totalOrders = 0;
  int _activeRestaurants = 0;
  int _activeDeliveries = 0;
  double _revenueToday = 0;
  double _monthlyRevenue = 0;
  List<_RecentOrderView> _recentOrders = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOverview());
  }

  Future<void> _loadOverview() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in as admin to view dashboard overview.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiClient();

      final usersFuture = api.getAdminUsers(token: token);
      final ordersFuture = api.getMyOrders(token: token);
      final restaurantsFuture = api.getCatalogRestaurants();

      final users = await usersFuture;
      final orders = await ordersFuture;
      final restaurants = await restaurantsFuture;

      final usersById = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final id = user['id']?.toString();
        if (id != null && id.isNotEmpty) {
          usersById[id] = user;
        }
      }

      final now = DateTime.now();
      double revenueToday = 0;
      double monthlyRevenue = 0;
      int activeDeliveries = 0;

      for (final order in orders) {
        final amount = _toDouble(order['totalAmount'] ?? order['total_amount']);
        final createdAt = _parseDate(order['createdAt'] ?? order['created_at']);
        final status = (order['status'] ?? order['order_status'] ?? '')
            .toString()
            .toLowerCase();

        if (createdAt != null) {
          final isToday = createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
          final isThisMonth =
              createdAt.year == now.year && createdAt.month == now.month;

          if (isToday) revenueToday += amount;
          if (isThisMonth) monthlyRevenue += amount;
        }

        if (status == 'pending' ||
            status == 'confirmed' ||
            status == 'preparing' ||
            status == 'ready' ||
            status == 'on_the_way') {
          activeDeliveries += 1;
        }
      }

      final recentOrders = orders.take(6).map((order) {
        final userId =
            order['userId']?.toString() ?? order['user_id']?.toString();
        final userName =
            usersById[userId]?['name']?.toString() ?? userId ?? 'Unknown User';
        final restaurantName = order['restaurantName']?.toString() ??
            order['restaurant_name']?.toString() ??
            '-';
        final orderId = order['id']?.toString() ?? '';
        final totalAmount =
            _toDouble(order['totalAmount'] ?? order['total_amount']);
        final status =
            (order['status'] ?? order['order_status'] ?? 'pending').toString();
        final createdAt = _parseDate(order['createdAt'] ?? order['created_at']);

        return _RecentOrderView(
          id: orderId,
          userName: userName,
          restaurantName: restaurantName,
          totalAmount: totalAmount,
          status: status,
          dateLabel: _formatDate(createdAt),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _totalUsers = users.length;
        _totalOrders = orders.length;
        _activeRestaurants = restaurants.length;
        _activeDeliveries = activeDeliveries;
        _revenueToday = revenueToday;
        _monthlyRevenue = monthlyRevenue;
        _recentOrders = recentOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Failed to load dashboard overview',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(_error!),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadOverview,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
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
                            value: '$_totalUsers',
                            change: null,
                            icon: Icons.people,
                            index: 0,
                          ),
                          StatCard(
                            title: 'Total Orders',
                            value: '$_totalOrders',
                            change: null,
                            icon: Icons.shopping_bag,
                            index: 1,
                          ),
                          StatCard(
                            title: 'Revenue Today',
                            value: '\$${_revenueToday.toStringAsFixed(2)}',
                            change: null,
                            icon: Icons.attach_money,
                            index: 2,
                          ),
                          StatCard(
                            title: 'Monthly Revenue',
                            value: '\$${_monthlyRevenue.toStringAsFixed(2)}',
                            change: null,
                            icon: Icons.trending_up,
                            index: 3,
                          ),
                          StatCard(
                            title: 'Active Restaurants',
                            value: '$_activeRestaurants',
                            change: null,
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
                            rows: _recentOrders.map((order) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    '#${order.id.length >= 6 ? order.id.substring(0, 6) : order.id}',
                                  )),
                                  DataCell(Text(order.userName)),
                                  DataCell(Text(order.restaurantName)),
                                  DataCell(Text(
                                      '\$${order.totalAmount.toStringAsFixed(2)}')),
                                  DataCell(StatusBadge(status: order.status)),
                                  DataCell(Text(order.dateLabel)),
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
                            subtitle: '$_totalUsers users',
                            onTap: () {
                              context.go('/admin/users');
                            },
                          ),
                          _AdminActionCard(
                            icon: Icons.restaurant,
                            title: 'Restaurants',
                            subtitle: '$_activeRestaurants active',
                            onTap: () {
                              context.go('/admin/restaurant-panel');
                            },
                          ),
                          _AdminActionCard(
                            icon: Icons.local_shipping,
                            title: 'Deliveries',
                            subtitle: '$_activeDeliveries active',
                            onTap: () {
                              context.go('/admin/deliveries');
                            },
                          ),
                          _AdminActionCard(
                            icon: Icons.card_giftcard,
                            title: 'Coupons',
                            subtitle: 'Manage campaigns',
                            onTap: () {
                              context.go('/admin/coupons');
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
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
        floatingActionButton: FloatingActionButton(
          heroTag: 'admin-dashboard-refresh-fab-mobile',
          onPressed: _loadOverview,
          child: const Icon(Icons.refresh),
        ),
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin-dashboard-refresh-fab-desktop',
        onPressed: _loadOverview,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _RecentOrderView {
  final String id;
  final String userName;
  final String restaurantName;
  final double totalAmount;
  final String status;
  final String dateLabel;

  const _RecentOrderView({
    required this.id,
    required this.userName,
    required this.restaurantName,
    required this.totalAmount,
    required this.status,
    required this.dateLabel,
  });
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
