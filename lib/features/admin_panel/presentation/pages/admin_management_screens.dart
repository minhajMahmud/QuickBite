import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../presentation/widgets/curved_panel_bottom_nav.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
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
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  bool _isLoading = false;
  String? _updatingUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUsers());
  }

  Future<void> _loadUsers() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in as admin to manage users.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiClient();
      final users = await api.getAdminUsers(token: token);
      final pending = await api.getPendingApprovalUsers(token: token);
      if (!mounted) return;
      setState(() {
        _users = users;
        _pendingUsers = pending;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setApproval({
    required String userId,
    required bool approved,
  }) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() => _updatingUserId = userId);
    try {
      final res = await ApiClient().setUserApprovalStatus(
        token: token,
        userId: userId,
        approved: approved,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (res['message']?.toString().isNotEmpty ?? false)
                ? res['message'].toString()
                : (approved
                    ? 'Account approved successfully'
                    : 'Account rejected successfully'),
          ),
        ),
      );

      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _updatingUserId = null);
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'restaurant':
        return 'Restaurant';
      case 'delivery_partner':
        return 'Delivery Partner';
      case 'admin':
        return 'Admin';
      default:
        return 'Customer';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'restaurant':
        return Colors.deepOrange;
      case 'delivery_partner':
        return Colors.indigo;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approvedCount = _users.where((u) => u['approved'] == true).length;
    final pendingCount = _pendingUsers.length;

    return _AdminPageScaffold(
      currentRoute: '/admin/users',
      title: 'User Management',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _AccountSummaryCard(
                        icon: Icons.groups_2_outlined,
                        label: 'Total Users',
                        value: '${_users.length}',
                      ),
                      _AccountSummaryCard(
                        icon: Icons.hourglass_top,
                        label: 'Pending Approval',
                        value: '$pendingCount',
                        valueColor: Colors.orange,
                      ),
                      _AccountSummaryCard(
                        icon: Icons.verified_outlined,
                        label: 'Approved',
                        value: '$approvedCount',
                        valueColor: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Pending Signups',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_pendingUsers.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          'No pending account approvals 🎉',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ..._pendingUsers.map((user) {
                      final role = user['role']?.toString();
                      final color = _roleColor(role);
                      final userId = user['id']?.toString() ?? '';
                      final isUpdating = _updatingUserId == userId;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withOpacity(0.12),
                                    child: Text(
                                      (user['name']?.toString().isNotEmpty ??
                                              false)
                                          ? user['name'].toString()[0]
                                          : '?',
                                      style: TextStyle(color: color),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['name']?.toString() ?? 'Unknown',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        Text(
                                          user['email']?.toString() ?? '-',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      _roleLabel(role),
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: isUpdating
                                        ? null
                                        : () => _setApproval(
                                              userId: userId,
                                              approved: true,
                                            ),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: isUpdating
                                        ? null
                                        : () => _setApproval(
                                              userId: userId,
                                              approved: false,
                                            ),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Reject'),
                                  ),
                                  if (isUpdating)
                                    const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadUsers,
        heroTag: 'admin-users-fab',
        child: const Icon(Icons.refresh),
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
class DeliveryManagementScreen extends StatefulWidget {
  const DeliveryManagementScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen> {
  final List<_DeliveryPartnerAccount> _accounts = [
    _DeliveryPartnerAccount(
      name: 'Mike Reynolds',
      email: 'mike.reynolds@quickbite.com',
      rating: 4.9,
      deliveries: 2340,
      isActive: true,
      isSuspended: false,
    ),
    _DeliveryPartnerAccount(
      name: 'Sarah Kim',
      email: 'sarah.kim@quickbite.com',
      rating: 4.8,
      deliveries: 1890,
      isActive: true,
      isSuspended: false,
    ),
    _DeliveryPartnerAccount(
      name: 'Carlos Mendez',
      email: 'carlos.mendez@quickbite.com',
      rating: 4.7,
      deliveries: 1560,
      isActive: false,
      isSuspended: false,
    ),
    _DeliveryPartnerAccount(
      name: 'Priya Sharma',
      email: 'priya.sharma@quickbite.com',
      rating: 4.9,
      deliveries: 2100,
      isActive: true,
      isSuspended: false,
    ),
  ];

  Future<void> _showAddAccountDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Delivery Partner'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
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
                final name = nameController.text.trim();
                final email = emailController.text.trim().toLowerCase();
                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and email are required.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  _accounts.insert(
                    0,
                    _DeliveryPartnerAccount(
                      name: name,
                      email: email,
                      rating: 0,
                      deliveries: 0,
                      isActive: true,
                      isSuspended: false,
                    ),
                  );
                });

                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery partner account added.'),
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
  }

  Future<void> _removeAccount(int index) async {
    final account = _accounts[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove account'),
          content: Text(
            'Delete ${account.name} (${account.email})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      _accounts.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Delivery partner account removed.')),
    );
  }

  void _toggleActive(int index) {
    final account = _accounts[index];
    if (account.isSuspended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unsuspend account first before activating.'),
        ),
      );
      return;
    }

    setState(() {
      _accounts[index] = account.copyWith(isActive: !account.isActive);
    });
  }

  void _toggleSuspended(int index) {
    final account = _accounts[index];
    final nextSuspended = !account.isSuspended;
    setState(() {
      _accounts[index] = account.copyWith(
        isSuspended: nextSuspended,
        isActive: nextSuspended ? false : account.isActive,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAccounts = _accounts.length;
    final activeAccounts = _accounts.where((a) => a.isActive).length;
    final suspendedAccounts = _accounts.where((a) => a.isSuspended).length;

    return _AdminPageScaffold(
      currentRoute: '/admin/deliveries',
      title: 'Delivery Partner Accounts',
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAccountDialog,
        heroTag: 'admin-delivery-accounts-fab',
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AccountSummaryCard(
                icon: Icons.people_outline,
                label: 'Total Accounts',
                value: '$totalAccounts',
              ),
              _AccountSummaryCard(
                icon: Icons.check_circle_outline,
                label: 'Active',
                value: '$activeAccounts',
                valueColor: Colors.green,
              ),
              _AccountSummaryCard(
                icon: Icons.block_outlined,
                label: 'Suspended',
                value: '$suspendedAccounts',
                valueColor: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Manage Delivery Partner Accounts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _showAddAccountDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Account'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_accounts.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No delivery partner accounts yet.',
                  style:
                      theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            ...List.generate(_accounts.length, (index) {
              final account = _accounts[index];
              final statusColor = account.isSuspended
                  ? Colors.redAccent
                  : account.isActive
                      ? Colors.green
                      : Colors.grey;
              final statusLabel = account.isSuspended
                  ? 'Suspended'
                  : account.isActive
                      ? 'Active'
                      : 'Inactive';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withOpacity(0.12),
                    child: Text(
                      account.name.isNotEmpty
                          ? account.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(account.name),
                  subtitle: Text(
                    '${account.email}\n${account.deliveries} deliveries • ★ ${account.rating.toStringAsFixed(1)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'toggle_active':
                          _toggleActive(index);
                          break;
                        case 'toggle_suspend':
                          _toggleSuspended(index);
                          break;
                        case 'remove':
                          _removeAccount(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle_active',
                        child: Text(
                          account.isActive ? 'Deactivate' : 'Activate',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_suspend',
                        child: Text(
                          account.isSuspended ? 'Unsuspend' : 'Suspend',
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text('Remove Account'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DeliveryPartnerAccount {
  final String name;
  final String email;
  final double rating;
  final int deliveries;
  final bool isActive;
  final bool isSuspended;

  const _DeliveryPartnerAccount({
    required this.name,
    required this.email,
    required this.rating,
    required this.deliveries,
    required this.isActive,
    required this.isSuspended,
  });

  _DeliveryPartnerAccount copyWith({
    String? name,
    String? email,
    double? rating,
    int? deliveries,
    bool? isActive,
    bool? isSuspended,
  }) {
    return _DeliveryPartnerAccount(
      name: name ?? this.name,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      deliveries: deliveries ?? this.deliveries,
      isActive: isActive ?? this.isActive,
      isSuspended: isSuspended ?? this.isSuspended,
    );
  }
}

class _AccountSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _AccountSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
