import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

/// Enhanced Admin User Details Screen
class AdminUserDetailsScreen extends ConsumerStatefulWidget {
  final String userId;

  const AdminUserDetailsScreen({
    required this.userId,
    super.key,
  });

  @override
  ConsumerState<AdminUserDetailsScreen> createState() =>
      _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState
    extends ConsumerState<AdminUserDetailsScreen> {
  Map<String, dynamic>? _userDetails;
  bool _isLoading = true;
  String? _error;
  String? _updatingStatus;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'Not authenticated');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ApiClient();
      final data = await api.getAdminUserDetails(
        token: token,
        userId: widget.userId,
      );

      if (!mounted) return;
      setState(() {
        _userDetails = data['data'];
        _selectedStatus = _userDetails?['user']?['status'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserStatus(String newStatus) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty || newStatus == _selectedStatus) return;

    setState(() => _updatingStatus = newStatus);
    try {
      final api = ApiClient();
      await api.updateAdminUserStatus(
        token: token,
        userId: widget.userId,
        status: newStatus,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User status updated to: $newStatus'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() => _selectedStatus = newStatus);
      await _loadUserDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = null);
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

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.amber;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _userDetails == null
                    ? const Center(child: Text('No user data'))
                    : _buildDetailedView(context, theme),
      ),
    );
  }

  Widget _buildDetailedView(BuildContext context, ThemeData theme) {
    final user = _userDetails?['user'] as Map<String, dynamic>? ?? {};
    final orders = _userDetails?['orders'] as List? ?? [];
    final deliveryDetails =
        _userDetails?['deliveryDetails'] as Map<String, dynamic>?;

    final name = user['name']?.toString() ?? 'Unknown';
    final email = user['email']?.toString() ?? '-';
    final role = user['role']?.toString();
    final status = user['status']?.toString() ?? 'active';
    final roleColor = _roleColor(role);
    final statusColor = _statusColor(status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Header Card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [roleColor.withValues(alpha: 0.1), Colors.transparent],
                begin: Alignment.topLeft,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: roleColor.withValues(alpha: 0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(email, style: theme.textTheme.bodySmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildBadge(
                                _roleLabel(role),
                                roleColor,
                                Icons.badge,
                              ),
                              _buildBadge(
                                status.toUpperCase(),
                                statusColor,
                                Icons.info,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                // User Stats
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatTile(
                      'Total Orders',
                      user['total_orders']?.toString() ?? '0',
                      Icons.shopping_cart,
                      Colors.blue,
                    ),
                    _buildStatTile(
                      'Total Spent',
                      '\$${double.tryParse(user['total_spent']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.money,
                      Colors.green,
                    ),
                    _buildStatTile(
                      'Member Since',
                      _formatDate(user['joined_at']),
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Status Management Section
        if (role != 'admin')
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Status Management',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final st in ['active', 'inactive', 'banned'])
                        FilledButton(
                          onPressed: _updatingStatus == null && st != status
                              ? () => _updateUserStatus(st)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _statusColor(st).withValues(
                              alpha: st == status ? 1.0 : 0.3,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: st == _updatingStatus
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(st.toUpperCase()),
                        ),
                    ],
                  ),
                  if (status == 'banned')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '⚠️ This user is banned and cannot access the platform.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.red),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        // Orders Section (for customers)
        if (role == 'customer' && orders.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Orders (${orders.length})',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...orders.map((order) => _buildOrderCard(context, order)),
            ],
          ),
        // Delivery Details Section (for delivery partners)
        if (role == 'delivery_partner' && deliveryDetails != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.two_wheeler, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Statistics',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildStatTile(
                    'Total Deliveries',
                    deliveryDetails['totaldeliveries']?.toString() ?? '0',
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                  _buildStatTile(
                    'Avg. Rating',
                    (double.tryParse(
                          deliveryDetails['avgrating']?.toString() ?? '0',
                        )?.toStringAsFixed(1)) ??
                        '0.0' + '⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final theme = Theme.of(context);
    final orderId = order['id']?.toString() ?? '';
    final restaurantName = order['restaurantname']?.toString() ?? 'Unknown';
    final total = double.tryParse(order['totalamount']?.toString() ?? '0') ?? 0;
    final status = order['status']?.toString() ?? 'pending';
    final itemCount = order['itemcount']?.toString() ?? '0';

    Color statusColor = Colors.grey;
    if (status == 'completed') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'confirmed') statusColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.receipt, color: statusColor, size: 20),
        ),
        title: Text(restaurantName),
        subtitle: Text('$itemCount items • $status'),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '\$$total.toStringAsFixed(2)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(order['createdat']),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('MMM d, yyyy').format(parsed);
      }
      return '-';
    } catch (_) {
      return '-';
    }
  }
}
