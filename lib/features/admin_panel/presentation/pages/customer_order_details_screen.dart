import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../authentication/data/services/api_client.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class CustomerOrderDetailsScreen extends ConsumerStatefulWidget {
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String orderId;
  final double orderAmount;
  final String orderStatus;
  final List<String> orderItems;
  final DateTime? orderDate;

  const CustomerOrderDetailsScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.orderId,
    required this.orderAmount,
    required this.orderStatus,
    required this.orderItems,
    this.orderDate,
  }) : super(key: key);

  @override
  ConsumerState<CustomerOrderDetailsScreen> createState() =>
      _CustomerOrderDetailsScreenState();
}

class _CustomerOrderDetailsScreenState
    extends ConsumerState<CustomerOrderDetailsScreen> {
  Map<String, dynamic>? _customerDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCustomerDetails());
  }

  Future<void> _loadCustomerDetails() async {
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
      // Get customer user details from admin API
      final details = await api.getAdminUserDetails(
          token: token, userId: widget.customerId);

      if (!mounted) return;
      setState(() {
        _customerDetails = details;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load customer details: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        final parsed = DateTime.parse(date);
        return DateFormat('MMM d, yyyy').format(parsed);
      }
      if (date is DateTime) {
        return DateFormat('MMM d, yyyy').format(date);
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _customerDetails ?? {};
    final totalOrders = details['total_orders'] ?? 0;
    final totalSpent =
        double.tryParse(details['total_spent']?.toString() ?? '0') ?? 0.0;
    final joinedDate = _formatDate(details['joined_at']);
    final approvalStatus = details['approved'] == true ? 'Approved' : 'Pending';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Order Details'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
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
                          onPressed: _loadCustomerDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Current Order Card
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
                            Text(
                              'Current Order',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Order ID',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    Text(
                                      widget.orderId,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Total',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                    Text(
                                      '\$${double.tryParse(widget.orderAmount.toString())?.toStringAsFixed(2) ?? '0.00'}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.orderStatus == 'completed'
                                    ? Colors.green.withOpacity(0.12)
                                    : widget.orderStatus == 'pending'
                                        ? Colors.orange.withOpacity(0.12)
                                        : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.orderStatus.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: widget.orderStatus == 'completed'
                                      ? Colors.green
                                      : widget.orderStatus == 'pending'
                                          ? Colors.orange
                                          : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (widget.orderItems.isNotEmpty) ...[
                              Text(
                                'Items (${widget.orderItems.length})',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(
                                    widget.orderItems.length,
                                    (index) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              size: 16, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              widget.orderItems[index],
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Customer Profile Card
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
                                  radius: 32,
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  child: Text(
                                    widget.customerName.isNotEmpty
                                        ? widget.customerName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.customerName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.customerEmail,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey,
                                        ),
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

                    // Customer Statistics
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _StatCard(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Total Orders',
                          value: '$totalOrders',
                          color: Colors.blue,
                        ),
                        _StatCard(
                          icon: Icons.attach_money,
                          label: 'Total Spent',
                          value: '\$${totalSpent.toStringAsFixed(2)}',
                          color: Colors.green,
                        ),
                        _StatCard(
                          icon: Icons.calendar_today,
                          label: 'Member Since',
                          value: joinedDate,
                          color: Colors.purple,
                        ),
                        _StatCard(
                          icon: Icons.verified_user,
                          label: 'Account Status',
                          value: approvalStatus,
                          color: approvalStatus == 'Approved'
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Quick Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This customer has placed $totalOrders order(s) totaling \$${totalSpent.toStringAsFixed(2)}.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
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
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
