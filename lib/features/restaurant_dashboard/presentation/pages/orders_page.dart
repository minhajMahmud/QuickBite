import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../providers/dashboard_providers.dart';

class OrdersPage extends ConsumerStatefulWidget {
  final String? restaurantId;

  const OrdersPage({Key? key, this.restaurantId}) : super(key: key);

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    if (widget.restaurantId != null) {
      Future.microtask(() {
        ref.read(selectedRestaurantIdProvider.notifier).state =
            widget.restaurantId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider(selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedStatus == null,
                  onPressed: () => setState(() => selectedStatus = null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending',
                  isSelected: selectedStatus == 'pending',
                  onPressed: () => setState(() => selectedStatus = 'pending'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Preparing',
                  isSelected: selectedStatus == 'preparing',
                  onPressed: () => setState(() => selectedStatus = 'preparing'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Ready',
                  isSelected: selectedStatus == 'ready',
                  onPressed: () => setState(() => selectedStatus = 'ready'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Delivered',
                  isSelected: selectedStatus == 'delivered',
                  onPressed: () => setState(() => selectedStatus = 'delivered'),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) =>
                      _OrderCard(order: orders[index]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                child: Text('Error: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      backgroundColor: Colors.transparent,
      selectedColor: Theme.of(context).primaryColor,
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormatter = DateFormat('dd MMM, hh:mm a');
    final currencyFormatter =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      order.customerName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                _OrderStatusBadge(status: order.orderStatus),
              ],
            ),
            const SizedBox(height: 12),
            Divider(),
            const SizedBox(height: 12),
            // Order details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  currencyFormatter.format(order.totalAmount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  dateFormatter.format(order.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items preview
            Text(
              '${order.items.length} item(s)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOrderDetails(context, order),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                if (order.orderStatus != 'delivered' &&
                    order.orderStatus != 'cancelled')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(context, ref, order),
                      child: const Text('Update Status'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order #${order.id.substring(0, 8).toUpperCase()}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: ${order.customerName}'),
                Text('Status: ${order.orderStatus}'),
                Text('Items:'),
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: Text('• ${item.name} x${item.quantity}'),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _updateOrderStatus(BuildContext context, WidgetRef ref, Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final statuses = [
          'confirmed',
          'preparing',
          'ready',
          'on_the_way',
          'delivered',
        ];
        String? selectedStatus = order.orderStatus;

        return AlertDialog(
          title: const Text('Update Order Status'),
          content: DropdownButton<String>(
            value: selectedStatus,
            items: statuses
                .map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    ))
                .toList(),
            onChanged: (value) {
              selectedStatus = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedStatus != null) {
                  // Update order status
                  ref.refresh(ordersProvider(null));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Order updated to $selectedStatus'),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String status;

  const _OrderStatusBadge({required this.status});

  Color _getStatusColor() {
    switch (status) {
      case 'pending':
        return const Color(0xFFFDAB2F);
      case 'confirmed':
        return const Color(0xFF74B9FF);
      case 'preparing':
        return const Color(0xFFFF7675);
      case 'ready':
        return const Color(0xFF0984E3);
      case 'on_the_way':
        return const Color(0xFF6C5CE7);
      case 'delivered':
        return const Color(0xFF00B894);
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getStatusColor(),
        ),
      ),
    );
  }
}
