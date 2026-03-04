import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/providers/app_providers.dart';
import '../../../../presentation/widgets/status_badge.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../../data/datasources/mock_data_service.dart';
import '../widgets/user_dashboard_sidebar.dart';
import '../dialogs/add_address_dialog.dart';

/// User Order History Screen
class UserOrderHistoryScreen extends ConsumerWidget {
  const UserOrderHistoryScreen({Key? key}) : super(key: key);

  Future<void> _showRatingDialog(BuildContext context, String restaurant) {
    double rating = 4;
    final feedbackController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate $restaurant'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rating: ${rating.toStringAsFixed(1)} / 5'),
                  Slider(
                    value: rating,
                    min: 1,
                    max: 5,
                    divisions: 8,
                    label: rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setDialogState(() => rating = value);
                    },
                  ),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Share your feedback...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Thanks! Your ${rating.toStringAsFixed(1)}★ review was submitted.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orders = MockDataService.generateMockOrders();
    final ongoingOrders = ref.watch(ongoingOrdersProvider);
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/orders',
                  compact: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order History'),
            Text(
              '${orders.length} orders',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 0,
        automaticallyImplyLeading: isCompact,
        actions: _buildAppBarActions(isCompact),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const UserDashboardSidebar(currentRoute: '/dashboard/orders'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (ongoingOrders.isNotEmpty) ...[
                    Text(
                      'Ongoing Orders',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...ongoingOrders.map(
                      (ongoing) => Card(
                        color: const Color(0xFFFFF7ED),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            '#${ongoing.id.substring(ongoing.id.length - 6)} • ${ongoing.restaurantName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${ongoing.items.join(', ')}\nETA: ${ongoing.etaMinutes} min',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => context.go(
                              '/order-tracking?orderId=${ongoing.id}',
                            ),
                            child: const Text('Track'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Past Orders',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                  ],
                  ...orders.map((order) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 360;
                                final idText = Text(
                                  '#${order.id.substring(0, 6)}',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                );
                                final badge = StatusBadge(status: order.status);

                                if (narrow) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      idText,
                                      const SizedBox(height: 6),
                                      badge,
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [idText, badge],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              order.restaurant,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.items.join(', '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 320;
                                final date = Text(
                                  order.date,
                                  style: theme.textTheme.bodySmall,
                                );
                                final total = Text(
                                  '\$${order.total.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                );

                                if (narrow) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      date,
                                      const SizedBox(height: 6),
                                      total
                                    ],
                                  );
                                }

                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [date, total],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showRatingDialog(
                                      context, order.restaurant),
                                  icon: const Icon(Icons.star_border, size: 18),
                                  label: const Text('Rate & Review'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _userPanelBottomNav(context, currentRoute: '/dashboard/orders'),
    );
  }
}

/// User Favorites Screen
class UserFavoritesScreen extends StatelessWidget {
  const UserFavoritesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restaurants = MockDataService.restaurants;
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/favorites',
                  compact: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My Favorites'),
            Text(
              '${restaurants.length} restaurants',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        elevation: 0,
        automaticallyImplyLeading: isCompact,
        actions: _buildAppBarActions(isCompact),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const UserDashboardSidebar(currentRoute: '/dashboard/favorites'),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 900
                      ? 3
                      : width > 620
                          ? 2
                          : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: crossAxisCount == 1 ? 1.3 : 0.9,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: crossAxisCount == 1 ? 160 : 120,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      restaurant.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      restaurant.cuisine,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              '${restaurant.rating}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const Icon(
                                          Icons.favorite,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _userPanelBottomNav(context, currentRoute: '/dashboard/favorites'),
    );
  }
}

/// User Addresses Screen
class UserAddressesScreen extends StatefulWidget {
  const UserAddressesScreen({Key? key}) : super(key: key);

  @override
  State<UserAddressesScreen> createState() => _UserAddressesScreenState();
}

class _UserAddressesScreenState extends State<UserAddressesScreen> {
  late List<Address> addresses;

  @override
  void initState() {
    super.initState();
    addresses = [
      Address(
        id: 'addr_1',
        label: 'Home',
        address: '123 Main Street',
        cityStateZip: 'New York, NY 10001',
        isDefault: true,
      ),
      Address(
        id: 'addr_2',
        label: 'Office',
        address: '456 Park Avenue',
        cityStateZip: 'New York, NY 10022',
        isDefault: false,
      ),
      Address(
        id: 'addr_3',
        label: 'Gym',
        address: '789 Fitness Lane',
        cityStateZip: 'New York, NY 10010',
        isDefault: false,
      ),
    ];
  }

  void _showAddAddressDialog({Address? address}) {
    showDialog(
      context: context,
      builder: (context) => AddAddressDialog(
        initialAddress: address,
        onSave: (newAddress) {
          setState(() {
            if (address != null) {
              // Edit existing address
              final index = addresses.indexWhere((a) => a.id == address.id);
              if (index >= 0) {
                addresses[index] = newAddress;
              }
            } else {
              // Add new address
              addresses.add(newAddress);
            }
          });
        },
      ),
    );
  }

  void _deleteAddress(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                addresses.removeWhere((a) => a.id == id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(String id) {
    setState(() {
      // Remove default from all addresses and set new default
      addresses = addresses.map((addr) {
        return addr.copyWith(isDefault: addr.id == id);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      drawer: isCompact
          ? const Drawer(
              child: SafeArea(
                child: UserDashboardSidebar(
                  currentRoute: '/dashboard/addresses',
                  compact: true,
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: const Text('Saved Addresses'),
        elevation: 0,
        automaticallyImplyLeading: isCompact,
        actions: _buildAppBarActions(isCompact),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              const UserDashboardSidebar(currentRoute: '/dashboard/addresses'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                itemBuilder: (context, index) {
                  final addr = addresses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 360;

                              final labelRow = Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    addr.label,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              );

                              final badge = addr.isDefault
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();

                              if (narrow) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    labelRow,
                                    if (addr.isDefault) ...[
                                      const SizedBox(height: 6),
                                      badge,
                                    ],
                                  ],
                                );
                              }

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [labelRow, badge],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            addr.address,
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            addr.cityStateZip,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (!addr.isDefault)
                                TextButton(
                                  onPressed: () => _setAsDefault(addr.id),
                                  child: const Text('Set Default'),
                                ),
                              TextButton(
                                onPressed: () =>
                                    _showAddAddressDialog(address: addr),
                                child: const Text('Edit'),
                              ),
                              TextButton(
                                onPressed: () => _deleteAddress(addr.id),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(),
        heroTag: 'user-addresses-fab',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar:
          _userPanelBottomNav(context, currentRoute: '/dashboard/addresses'),
    );
  }
}

Widget _userPanelBottomNav(BuildContext context,
    {required String currentRoute}) {
  return CurvedPanelBottomNav(
    items: [
      CurvedNavItemData(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
        isSelected: currentRoute == '/dashboard',
        onTap: () => context.go('/'),
      ),
      CurvedNavItemData(
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
        label: 'Orders',
        isSelected: currentRoute == '/dashboard/orders',
        onTap: () => context.go('/dashboard/orders'),
      ),
      CurvedNavItemData(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: 'Fav',
        isSelected: currentRoute == '/dashboard/favorites',
        onTap: () => context.go('/dashboard/favorites'),
      ),
      CurvedNavItemData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
        isSelected: currentRoute == '/dashboard/settings' ||
            currentRoute == '/dashboard/addresses',
        onTap: () => context.go('/dashboard/settings'),
      ),
    ],
  );
}

List<Widget> _buildAppBarActions(bool compact) {
  if (compact) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        iconSize: 20,
      ),
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        iconSize: 20,
      ),
      IconButton(
        icon: const Icon(Icons.person),
        onPressed: () {},
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        iconSize: 20,
      ),
      const SizedBox(width: 8),
    ];
  }

  return [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {},
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {},
    ),
    const SizedBox(width: 8),
    const CircleAvatar(
      backgroundColor: Color(0xFFFF6B35),
      child: Icon(Icons.person, color: Colors.white),
    ),
    const SizedBox(width: 16),
  ];
}
