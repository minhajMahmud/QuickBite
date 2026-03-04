import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../widgets/admin_sidebar.dart';

class _AdminPageScaffold extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  const _AdminPageScaffold({
    required this.currentRoute,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          elevation: 0,
        ),
        drawer: Drawer(
          child: SafeArea(
            child: AdminSidebar(
              currentRoute: currentRoute,
              compact: true,
            ),
          ),
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: _adminBottomNav(context, currentRoute),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(currentRoute: currentRoute),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(title),
                  elevation: 0,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: _adminBottomNav(context, currentRoute),
    );
  }
}

/// User Management Screen
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AdminPageScaffold(
      currentRoute: '/admin/users',
      title: 'User Management',
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Text('U${index + 1}'),
              ),
              title: Text('User ${index + 1}'),
              subtitle: const Text('user@example.com'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    child: Text('Ban'),
                  ),
                  const PopupMenuItem(
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'admin-users-fab',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Restaurant Management Screen
class RestaurantManagementScreen extends StatelessWidget {
  const RestaurantManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AdminPageScaffold(
      currentRoute: '/admin/restaurants',
      title: 'Restaurant Management',
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.restaurant, color: theme.primaryColor),
              title: Text('Restaurant ${index + 1}'),
              subtitle: const Text('Italian • Pizza • 4.7★'),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    child: Text('View Orders'),
                  ),
                  const PopupMenuItem(
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'admin-restaurants-fab',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Delivery Management Screen
class DeliveryManagementScreen extends StatelessWidget {
  const DeliveryManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 900;
    final agents = [
      {
        'name': 'Mike Reynolds',
        'rating': 4.9,
        'status': 'Delivering',
        'deliveries': 2340
      },
      {
        'name': 'Sarah Kim',
        'rating': 4.8,
        'status': 'Online',
        'deliveries': 1890
      },
      {
        'name': 'Carlos Mendez',
        'rating': 4.7,
        'status': 'Delivering',
        'deliveries': 1560
      },
      {
        'name': 'Priya Sharma',
        'rating': 4.9,
        'status': 'Online',
        'deliveries': 2100
      },
      {
        'name': 'Tom Anderson',
        'rating': 4.5,
        'status': 'Offline',
        'deliveries': 980
      },
      {
        'name': 'Lisa Wang',
        'rating': 4.6,
        'status': 'Online',
        'deliveries': 1340
      },
      {
        'name': 'Jake Morrison',
        'rating': 4.4,
        'status': 'Offline',
        'deliveries': 720
      },
      {
        'name': 'Ana Rodriguez',
        'rating': 4.8,
        'status': 'Delivering',
        'deliveries': 1670
      },
    ];

    final onlineAgents = agents
        .where((a) => a['status'] == 'Online' || a['status'] == 'Delivering')
        .length;

    final content = CustomScrollView(
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: isMobile,
          floating: true,
          backgroundColor: theme.cardColor,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Management',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$onlineAgents agents online',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1200
                      ? 3
                      : width > 760
                          ? 2
                          : 2;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: width < 430 ? 1.45 : 2.2,
                    children: const [
                      _DeliveryStatCard(
                        icon: Icons.local_shipping_outlined,
                        value: '6',
                        label: 'Online Agents',
                        delta: '↗ 5.2%',
                      ),
                      _DeliveryStatCard(
                        icon: Icons.local_shipping_outlined,
                        value: '22',
                        label: 'Active Deliveries',
                      ),
                      _DeliveryStatCard(
                        icon: Icons.star_border,
                        value: '4.7',
                        label: 'Avg Rating',
                        delta: '↗ 1.3%',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Delivery Agents',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1400
                      ? 4
                      : width > 1020
                          ? 3
                          : width > 680
                              ? 2
                              : 2;

                  return GridView.builder(
                    itemCount: agents.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: width < 430 ? 0.78 : 0.95,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final agent = agents[index];
                      return _DeliveryAgentCard(
                        name: agent['name'] as String,
                        rating: agent['rating'] as double,
                        status: agent['status'] as String,
                        deliveries: agent['deliveries'] as int,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Map',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_shipping_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );

    if (isMobile) {
      return Scaffold(
        drawer: const Drawer(
          child: SafeArea(
            child: AdminSidebar(
              currentRoute: '/admin/deliveries',
              compact: true,
            ),
          ),
        ),
        body: content,
        bottomNavigationBar: _adminBottomNav(context, '/admin/deliveries'),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(currentRoute: '/admin/deliveries'),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: _adminBottomNav(context, '/admin/deliveries'),
    );
  }
}

Widget _adminBottomNav(BuildContext context, String currentRoute) {
  return CurvedPanelBottomNav(
    items: [
      CurvedNavItemData(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        isSelected: currentRoute == '/admin',
        onTap: () => context.go('/admin'),
      ),
      CurvedNavItemData(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Users',
        isSelected: currentRoute == '/admin/users',
        onTap: () => context.go('/admin/users'),
      ),
      CurvedNavItemData(
        icon: Icons.local_shipping_outlined,
        selectedIcon: Icons.local_shipping,
        label: 'Delivery',
        isSelected: currentRoute == '/admin/deliveries',
        onTap: () => context.go('/admin/deliveries'),
      ),
      CurvedNavItemData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
        isSelected: currentRoute == '/admin/settings' ||
            currentRoute == '/admin/coupons' ||
            currentRoute == '/admin/restaurants',
        onTap: () => context.go('/admin/settings'),
      ),
    ],
  );
}

class _DeliveryStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? delta;

  const _DeliveryStatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.orange),
                ),
                if (delta != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      delta!,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryAgentCard extends StatelessWidget {
  final String name;
  final double rating;
  final String status;
  final int deliveries;

  const _DeliveryAgentCard({
    required this.name,
    required this.rating,
    required this.status,
    required this.deliveries,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = status == 'Online';
    final isDelivering = status == 'Delivering';

    final chipColor = isDelivering
        ? Colors.orange
        : isOnline
            ? Colors.green
            : Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Colors.grey[200],
              child: Text(
                name.isNotEmpty ? name[0] : '?',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                const SizedBox(width: 4),
                Text('$rating'),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '• $status',
                style: TextStyle(
                  color: chipColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${deliveries.toString()} deliveries',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coupon Management Screen
class CouponManagementScreen extends StatelessWidget {
  const CouponManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final coupons = [
      {'code': 'SAVE20', 'discount': '20%', 'used': '342', 'status': 'Active'},
      {
        'code': 'WELCOME10',
        'discount': '10%',
        'used': '1,280',
        'status': 'Active'
      },
      {
        'code': 'SUMMER30',
        'discount': '30%',
        'used': '156',
        'status': 'Inactive'
      },
      {
        'code': 'FREEDELIV',
        'discount': 'Free Delivery',
        'used': '89',
        'status': 'Active'
      },
    ];

    return _AdminPageScaffold(
      currentRoute: '/admin/coupons',
      title: 'Coupon Management',
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: coupons.length,
        itemBuilder: (context, index) {
          final coupon = coupons[index];
          final isActive = coupon['status'] == 'Active';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        coupon['code']!,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          coupon['status']!,
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Discount: ${coupon['discount']!}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Used: ${coupon['used']!} times',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        heroTag: 'admin-coupons-fab',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Admin Settings Screen
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _allowNewUsers = true;
  bool _allowNewRestaurants = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AdminPageScaffold(
      currentRoute: '/admin/settings',
      title: 'Admin Settings',
      body: ListView(
        children: [
          // System Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'System Settings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Disable app for all users'),
            value: _maintenanceMode,
            onChanged: (bool value) {
              setState(() => _maintenanceMode = value);
            },
          ),
          const Divider(height: 32),
          // Platform Settings
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Platform Settings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Allow New User Registration'),
            value: _allowNewUsers,
            onChanged: (bool value) {
              setState(() => _allowNewUsers = value);
            },
          ),
          SwitchListTile(
            title: const Text('Allow New Restaurant Registration'),
            value: _allowNewRestaurants,
            onChanged: (bool value) {
              setState(() => _allowNewRestaurants = value);
            },
          ),
          const Divider(height: 32),
          // System Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'System Information',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Database'),
            subtitle: const Text('Connected'),
          ),
          ListTile(
            title: const Text('Last Backup'),
            subtitle: const Text('2 hours ago'),
          ),
        ],
      ),
    );
  }
}
