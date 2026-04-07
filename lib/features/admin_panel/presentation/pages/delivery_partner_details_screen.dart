import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class DeliveryPartnerDetailsScreen extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerEmail;
  final String currentStatus;

  const DeliveryPartnerDetailsScreen({
    Key? key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    required this.currentStatus,
  }) : super(key: key);

  @override
  ConsumerState<DeliveryPartnerDetailsScreen> createState() =>
      _DeliveryPartnerDetailsScreenState();
}

class _DeliveryPartnerDetailsScreenState
    extends ConsumerState<DeliveryPartnerDetailsScreen> {
  Map<String, dynamic>? _partnerDetails;
  bool _isLoading = true;
  String? _error;
  String? _updatingStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPartnerDetails());
  }

  Future<void> _loadPartnerDetails() async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) {
      setState(() {
        _error = 'Authentication required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final details =
          await api.getAdminUserDetails(token: token, userId: widget.partnerId);

      if (!mounted) return;
      setState(() {
        _partnerDetails = details['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(details['data'] as Map)
            : details;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load partner details: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final token = ref.read(authProvider).token;
    if (token == null || token.isEmpty) return;

    setState(() {
      _updatingStatus = newStatus;
      _error = null;
    });

    try {
      await ApiClient().updateAdminUserStatus(
        token: token,
        userId: widget.partnerId,
        status: newStatus,
      );

      if (!mounted) return;
      setState(() {
        if (_partnerDetails?['user'] is Map) {
          (_partnerDetails!['user'] as Map)['status'] = newStatus;
        } else {
          _partnerDetails?['status'] = newStatus;
        }
        _updatingStatus = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partner status updated to $newStatus'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to update status: $e';
        _updatingStatus = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('MMM d, yyyy').format(parsed);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partner Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final details = _partnerDetails ?? {};
    final user = details['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(details['user'] as Map)
        : details;
    final name = widget.partnerName;
    final email = widget.partnerEmail;
    final status = (user['status'] as String?)?.toLowerCase() ?? 'active';
    const roleColor = Colors.blue;
    const deliveryColor = Color(0xFFFF8A00);

    final totalDeliveries = user['total_orders'] ?? 0;
    final totalEarnings =
        double.tryParse(user['total_spent']?.toString() ?? '0') ?? 0.0;
    final joinedDate = _formatDate(user['joined_at']);
    final lastLogin = _formatDate(user['last_login']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Partner Details'),
        elevation: 0,
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ?? 'Error loading details',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPartnerDetails,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Partner Profile Header
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: deliveryColor.withOpacity(0.2),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: deliveryColor,
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
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _StatusBadge(
                                        label: 'Delivery Partner',
                                        color: roleColor,
                                        icon: Icons.local_shipping,
                                      ),
                                      _StatusBadge(
                                        label: status.toUpperCase(),
                                        color: _getStatusColor(status),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Stats
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _StatTile(
                      icon: Icons.local_shipping_outlined,
                      label: 'Total Deliveries',
                      value: '$totalDeliveries',
                      color: Colors.blue,
                    ),
                    _StatTile(
                      icon: Icons.attach_money,
                      label: 'Total Earnings',
                      value: '\$${totalEarnings.toStringAsFixed(2)}',
                      color: Colors.green,
                    ),
                    _StatTile(
                      icon: Icons.calendar_today,
                      label: 'Member Since',
                      value: joinedDate,
                      color: Colors.purple,
                    ),
                    _StatTile(
                      icon: Icons.login,
                      label: 'Last Login',
                      value: lastLogin,
                      color: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Status Management
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.05),
                    border: Border.all(
                      color: Colors.yellow.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Manage Partner Status',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (status == 'banned')
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.05),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning,
                                      color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'This partner is currently banned and cannot access the platform.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final st in ['active', 'inactive', 'banned'])
                            ElevatedButton(
                              onPressed: st != status && _updatingStatus == null
                                  ? () => _updateStatus(st)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: st == 'active'
                                    ? Colors.green
                                    : st == 'inactive'
                                        ? Colors.orange
                                        : Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: _updatingStatus == st
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(st.toUpperCase()),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Delivery Performance Section
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance Metrics',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _MetricRow(
                          label: 'Approval Status',
                          value: user['approved'] == true
                              ? '✓ Approved'
                              : '◯ Pending Approval',
                          valueColor: user['approved'] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const Divider(),
                        _MetricRow(
                          label: 'Account Status',
                          value: status.toUpperCase(),
                          valueColor: _getStatusColor(status),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
